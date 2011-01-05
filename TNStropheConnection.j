/*
 * TNStropheConnection.j
 *
 * Copyright (C) 2010  Antoine Mercadal <antoine.mercadal@inframonde.eu>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3.0 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

@import <Foundation/Foundation.j>

@import "TNStropheJID.j"
@import "TNStropheStanza.j"
@import "Resources/Strophe/sha1.js"
@import "TNStropheGlobals.j"


/*! @ingroup strophecappuccino
    this is an Cappuccino implementation of an XMPP connection
    using javascript library Strophe by Stanziq.

    @par Delegate Methods

    \c -onStropheConnecting:
    when strophe is connecting (notification TNStropheConnectionStatusConnecting sent)

    \c -onStropheConnectFail:
    if strophe connection fails (notification TNStropheConnectionStatusFailure sent)

    \c -onStropheDisconnecting
    when strophe is disconnecting (notification TNStropheConnectionStatusDisconnecting sent)

    \c  -onStropheConnected:
    when strophe is disconnected (notification TNStropheConnectionStatusDisconnected sent)

    \c  -onStropheConnecting:
    when strophe is connected (notification TNStropheConnectionStatusConnected sent)

    @par Notifications:

    The following notifications are sent by TNStropheConnection:

    #TNStropheConnectionStatusConnecting

    #TNStropheConnectionStatusConnected

    #TNStropheConnectionStatusDisconnecting

    #TNStropheConnectionStatusDisconnected

    #TNStropheConnectionStatusConnectionFailure

    # TNStropheConnectionStatusAuthFailure

    #TNStropheConnectionStatusError
*/

@implementation TNStropheConnection : CPObject
{
    BOOL            _connected              @accessors(getter=isConnected);
    CPArray         _features               @accessors(readonly);
    CPString        _clientNode             @accessors(property=clientNode);
    CPString        _identityCategory       @accessors(property=identityCategory);
    CPString        _identityName           @accessors(property=identityName);
    CPString        _identityType           @accessors(property=identityType);
    CPString        _password               @accessors(property=password);
    float           _giveupTimeout          @accessors(property=giveupTimeout);
    id              _currentStatus          @accessors(getter=currentStatus);
    id              _delegate               @accessors(property=delegate);
    int             _connectionTimeout      @accessors(property=connectionTimeout);
    int             _maxConnections         @accessors(property=maxConnections);
    TNStropheJID    _JID                    @accessors(property=JID);

    CPArray         _registeredHandlers;
    CPArray         _registeredTimedHandlers;
    CPString        _boshService;
    id              _connection;
    CPTimer         _giveUpTimer;
    CPString        _userPresenceShow;
    CPString        _userPresenceStatus;
}

#pragma mark -
#pragma mark Class methods

+ (void)addNamespaceWithName:(CPString)aName value:(CPString)aValue
{
    Strophe.addNamespace(aName, aValue);
}

/*! instanciate a TNStropheConnection object

    @param aService a url of a bosh service (MUST be complete url with http://)

    @return a valid TNStropheConnection
*/
+ (TNStropheConnection)connectionWithService:(CPString)aService
{
    return [[TNStropheConnection alloc] initWithService:aService];
}

/*! instanciate a TNStropheConnection object

    @param aService a url of a bosh service (MUST be complete url with http://)
    @param aJID a JID to connect to the XMPP server
    @param aPassword the password associated to the JID

    @return a valid TNStropheConnection
*/
+ (TNStropheConnection)connectionWithService:(CPString)aService JID:(TNStropheJID)aJID password:(CPString)aPassword
{
    return [[TNStropheConnection alloc] initWithService:aService JID:aJID password:aPassword];
}


#pragma mark -
#pragma mark Initialization

/*! initialize the TNStropheConnection

    @param aService a url of a bosh service (MUST be complete url with http://)
*/
- (id)initWithService:(CPString)aService
{
    if (self = [super init])
    {
        _boshService                = aService;
        _registeredHandlers         = [CPArray array];
        _registeredTimedHandlers    = [CPArray array];;
        _connected                  = NO;
        _maxConnections             = 10;
        _connectionTimeout          = 3600;
        _giveupTimeout              = 8.0;
        _currentStatus              = Strophe.Status.DISCONNECTED;
        _connection                 = new Strophe.Connection(_boshService);
        _userPresenceShow           = TNStropheContactStatusOffline;
        _userPresenceStatus         = @"";
        _clientNode                 = @"http://cappuccino.org";
        _identityCategory           = @"client";
        _identityName               = @"StropheCappuccino";
        _identityType               = @"web";
        _features                   = [Strophe.NS.CAPS, Strophe.NS.DISCO_INFO, Strophe.NS.DISCO_ITEMS];
    }

    return self;
}

/*! initialize the TNStropheConnection

    @param aService a url of a bosh service (MUST be complete url with http://)
    @param aJID a JID to connect to the XMPP server
    @param aPassword the password associated to the JID
*/
- (id)initWithService:(CPString)aService JID:(TNStropheJID)aJID password:(CPString)aPassword
{
    if (self = [self initWithService:aService])
    {
        _JID        = aJID;
        _password   = aPassword;
    }

    return self;
}


#pragma mark -
#pragma mark Connection

/*! connect to the XMPP Bosh Service. on different events, messages are sent to delegate and notification are sent
*/
- (void)connect
{
    if (_currentStatus !== Strophe.Status.DISCONNECTED)
        return;

    [self registerSelector:@selector(_didReceivePing:) ofObject:self withDict:[CPDictionary dictionaryWithObjectsAndKeys:@"iq", @"name", @"get", @"type"]];

    _connection.connect([_JID full], _password, function (status, errorCond)
    {
        var selector,
            notificationName;

        _currentStatus = status;

        if (errorCond)
        {
            _currentStatus = Strophe.Status.DISCONNECTED;

            if ([_delegate respondsToSelector:@selector(connection:errorCondition:)])
                [_delegate connection:self errorCondition:errorCond];
        }
        else
        {
            switch (status)
            {
                case Strophe.Status.ERROR:
                    selector            = @selector(onStropheError:);
                    notificationName    = TNStropheConnectionStatusError;
                    break;
                case Strophe.Status.CONNECTING:
                    selector            = @selector(onStropheConnecting:);
                    notificationName    = TNStropheConnectionStatusConnecting;

                    _giveUpTimer = [CPTimer scheduledTimerWithTimeInterval:_giveupTimeout callback:function(aTimer) {
                            _currentStatus  = Strophe.Status.DISCONNECTED;
                            _giveUpTimer    = nil;
                            _connection     = nil; // free
                            _connection     = new Strophe.Connection(_boshService);
                            if ((_currentStatus === Strophe.Status.CONNECTING) && ([_delegate respondsToSelector:@selector(connection:errorCondition:)]))
                                [_delegate connection:self errorCondition:@"Cannot connect"];
                        } repeats:NO];

                    break;
                case Strophe.Status.CONNFAIL:
                    selector            = @selector(onStropheConnectFail:);
                    notificationName    = TNStropheConnectionStatusConnectionFailure;
                    break;
                case Strophe.Status.AUTHENTICATING:
                    selector            = @selector(onStropheAuthenticating:);
                    notificationName    = TNStropheConnectionStatusAuthenticating;
                    break;
                case Strophe.Status.AUTHFAIL:
                    selector            = @selector(onStropheAuthFail:);
                    notificationName    = TNStropheConnectionStatusAuthFailure;
                    break;
                case Strophe.Status.DISCONNECTING:
                    selector            = @selector(onStropheDisconnecting:);
                    notificationName    = TNStropheConnectionStatusDisconnecting;
                    break;
                case Strophe.Status.DISCONNECTED:
                    [self deleteAllRegisteredSelectors];
                    _userPresenceShow   = TNStropheContactStatusOffline;
                    _userPresenceStatus = @"";
                    selector            = @selector(onStropheDisconnected:);
                    notificationName    = TNStropheConnectionStatusDisconnected;
                    _connected          = NO;
                    break;
                case Strophe.Status.CONNECTED:
                    var presenceHandleParams = [CPDictionary dictionaryWithObjectsAndKeys:@"presence", @"name", [_JID bare], @"from", {@"matchBare": true}, @"options"];
                    [self registerSelector:@selector(_didPresenceUpdate:) ofObject:self withDict:presenceHandleParams];
                    [self setPresenceShow:TNStropheContactStatusOnline status:@""];
                    [self sendCAPS];
                    selector            = @selector(onStropheConnected:);
                    notificationName    = TNStropheConnectionStatusConnected;
                    _connected          = YES;
                    if (_giveUpTimer)
                        [_giveUpTimer invalidate];
                    break;
            }
        }
        if ([_delegate respondsToSelector:selector])
            [_delegate performSelector:selector withObject:self];

        [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
    }, /* wait */ _connectionTimeout, /* hold */ _maxConnections);
}

/*! this disconnect the XMPP connection
*/
- (void)disconnect
{
    if (_currentStatus !== Strophe.Status.CONNECTED)
        return;

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheConnectionStatusWillDisconnect object:self];
    _connection.disconnect();
}

/*! Reset the current connection
*/
- (void)reset
{
    if (_connection)
        _connection.reset();
}

/*! pause the current connection
*/
- (void)pause
{
    if (_connection)
        _connection.pause();
}

/*! resume the current connection if paused
*/
- (void)resume
{
    if (_connection)
        _connection.pause();
}

/*! Immediately send any pending outgoing data
*/
- (void)flush
{
    _connection.flush();
}

- (BOOL)_didReceivePing:(TNStropheStanza)aStanza
{
    if ([aStanza containsChildrenWithName:@"ping"] && [[aStanza firstChildWithName:@"ping"] namespace] == Strophe.NS.PING)
    {
        CPLog.debug("Ping received. Sending pong.");
        [self send:[TNStropheStanza iqWithAttributes:{'to': [[aStanza from] bare], 'id': [aStanza ID], 'type': 'result'}]];
    }
    return YES;
}


#pragma mark -
#pragma mark Features

- (void)addFeature:(CPString)aFeatureNamespace
{
    [_features addObject:aFeatureNamespace];
}

- (void)removeFeature:(CPString)aFeatureNamespace
{
    [_features removeObjectIdenticalTo:aFeatureNamespace];
}

- (CPString)_clientVer
{
    return SHA1.b64_sha1(_features.join());
}

- (void)sendCAPS
{
    var caps = [TNStropheStanza presence];
    [caps addChildWithName:@"c" andAttributes:{ "xmlns":Strophe.NS.CAPS, "node":_clientNode, "hash":"sha-1", "ver":[self _clientVer] }];

    [self registerSelector:@selector(handleFeaturesDisco:)
                  ofObject:self
                  withDict:[CPDictionary dictionaryWithObjectsAndKeys:@"iq", @"name", @"get", @"type", Strophe.NS.DISCO_INFO, "namespace"]];

    [self send:caps];
}

- (BOOL)handleFeaturesDisco:(TNStropheStanza)aStanza
{
    var resp = [TNStropheStanza iqWithAttributes:{"id":[self getUniqueId], "type":"result"}];

    [resp setTo:[aStanza from]];

    [resp addChildWithName:@"query" andAttributes:{"xmlns":Strophe.NS.DISCO_INFO, "node":(_clientNode + '#' + [self _clientVer])}];
    [resp addChildWithName:@"identity" andAttributes:{"category":_identityCategory, "name":_identityName, "type":_identityType}];
    [resp up];

    for (var i = 0; i < [_features count]; i++)
    {
        [resp addChildWithName:@"feature" andAttributes:{"var":[_features objectAtIndex:i]}];
        [resp up];
    }

    [self send:resp];

    return YES;
}


#pragma mark -
#pragma mark Sending

/*! send a TNStropheStanza object
    @param aStanza: the stanza to send
*/
- (void)send:(TNStropheStanza)aStanza
{
    if (_currentStatus == Strophe.Status.CONNECTED)
        [[CPRunLoop currentRunLoop] performSelector:@selector(_performSend:) target:self argument:aStanza order:0 modes:[CPDefaultRunLoopMode]];
}

- (void)_performSend:(TNStropheStanza)aStanza
{
    if (_currentStatus == Strophe.Status.CONNECTED)
    {
        CPLog.trace("StropheCappuccino Stanza Send:")
        CPLog.trace(aStanza);
        _connection.send([aStanza tree]);
        [self flush];
    }
}

/*! publish a PEP payload
    @param aPayload: the payload to send
    @param aNode: the node to publish to
*/
- (void)publishPEPPayload:(TNXMLNode)aPayload toNode:(CPString)aNode
{
    var uid     = [self getUniqueId],
        stanza  = [TNStropheStanza iqWithAttributes:{"type":"set", "id":uid}],
        params  = [CPDictionary dictionaryWithObject:uid forKey:@"id"];

    [stanza addChildWithName:@"pubsub" andAttributes:{"xmlns":Strophe.NS.PUBSUB}]
    [stanza addChildWithName:@"publish" andAttributes:{"node":aNode}];
    [stanza addChildWithName:@"item"];
    [stanza addNode:aPayload];

    [self registerSelector:@selector(_didPublishPEP:) ofObject:self withDict:params]
    [self send:stanza];
}

- (void)_didPublishPEP:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        CPLog.debug("Publish succeeded!");
    else
        CPLog.error("Cannot publish the pubsub item in node with name: " + _nodeName);

    return NO;
}

/*! generates an unique identifier
*/
- (CPString)getUniqueId
{
    return [self getUniqueIdWithSuffix:null];
}

/*! generates an unique identifier prefixed by

    @param prefix will prefixes the unique identifier
*/
- (CPString)getUniqueIdWithSuffix:(CPString)suffix
{
    return _connection.getUniqueId(suffix);
}

#pragma mark -
#pragma mark Presence

- (void)setPresenceShow:(CPString)aPresenceShow status:(CPString)aStatus
{
    if (aPresenceShow === _userPresenceShow && aStatus === _userPresenceStatus)
        return;

    var presence = [TNStropheStanza presence];

    _userPresenceShow   = aPresenceShow || _userPresenceShow;
    _userPresenceStatus = aStatus || _userPresenceStatus;

    [presence addChildWithName:@"status"];
    [presence addTextNode:_userPresenceStatus];
    [presence up]
    [presence addChildWithName:@"show"];
    [presence addTextNode:_userPresenceShow];

    [self send:presence];
}

- (BOOL)_didPresenceUpdate:(TNStropheStanza)aStanza
{
    var shouldNotify = NO;

    if ([aStanza firstChildWithName:@"show"])
    {
        _userPresenceShow = [[aStanza firstChildWithName:@"show"] text];
        shouldNotify = YES;
    }

    if ([aStanza firstChildWithName:@"status"])
    {
        _userPresenceStatus = [[aStanza firstChildWithName:@"status"] text];
        shouldNotify = YES;
    }

    if (shouldNotify)
    {
        var presenceInformation = [CPDictionary dictionaryWithObjectsAndKeys:_userPresenceShow, @"show", _userPresenceStatus, @"status"];
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheConnectionPresenceUpdatedNotification object:self userInfo:presenceInformation];
    }

    return YES;
}


#pragma mark -
#pragma mark vCard

/*! get the vCard of the connection JID
*/
- (void)getVCard
{
    var uid         = [self getUniqueId],
        vcardStanza = [TNStropheStanza iqWithAttributes:{@"type": @"get", @"id": uid}],
        params      = [CPDictionary dictionaryWithObjectsAndKeys: uid, @"id"];

    [vcardStanza addChildWithName:@"vCard" andAttributes:{@"xmlns": @"vcard-temp"}];

    [self registerSelector:@selector(_didReceiveCurrentUserVCard:) ofObject:self withDict:params];
    [self send:vcardStanza];
}

/*! compute the answer of the vCard stanza
    @param aStanza the stanza containing the vCard
*/
- (void)_didReceiveCurrentUserVCard:(TNStropheStanza)aStanza
{
    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheConnectionVCardReceived object:self userInfo:aStanza];
}

/*! set the vCard of the connection JID and send the given message of of the given object with the given user info
    @param aVCard TNXMLNode containing the vCard
    @param anObject the target object
    @param aSelector the selector to send to the target object
    @param someUserInfo random informations
*/
- (void)setVCard:(TNXMLNode)aVCard object:(CPObject)anObject selector:(SEL)aSelector userInfo:(id)someUserInfo
{
    var uid     = [self getUniqueId],
        stanza  = [TNStropheStanza iqWithAttributes:{@"id": uid, @"type": @"set"}],
        params  = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [stanza addNode:aVCard];

    [self registerSelector:@selector(notifyVCardUpdate:) ofObject:self withDict:params];
    [self registerSelector:aSelector ofObject:anObject withDict:params userInfo:someUserInfo];
    [self send:stanza];
}

/*! notify XMPP user for changes in vCard
*/
- (void)notifyVCardUpdate:(TNStropheStanza)aStanza
{
    var uid     = [self getUniqueId],
        stanza  = [TNStropheStanza presenceWithAttributes:{@"id": uid}],
        params  = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [stanza addChildWithName:@"status"];
    [stanza addTextNode:_userPresenceStatus];
    [stanza up]
    [stanza addChildWithName:@"show"];
    [stanza addTextNode:_userPresenceShow];
    [stanza up]
    [stanza addChildWithName:@"x" andAttributes:{"xmlns": "vcard-temp:x:update"}];

    // debug
    //[self registerSelector:@selector(_didNotifyVCardUpdate:) ofObject:self withDict:params];

    [self send:stanza];
}

/*! called when notification of vCard changes have been sent
*/
- (void)_didNotifyVCardUpdate:(TNStropheStanza)aStanza
{
    CPLog.trace([aStanza stringValue]);
}


#pragma mark -
#pragma mark Handlers

/*! allows to register a selector for beeing fired on XMPP events, according to the content of a dictionnary parameter.
    The dictionnary should contains zero to many of the followings :
     - <b>namespace</b>: the namespace of the stanza or of the first child (like query)
     - <b>name</b>: the name of the stanza (message, iq or presence)
     - <b>type</b>: the type of the stanza
     - <b>id</b>: the unique identifier
     - <b>from</b>: the stanza sender
     - <b>options</b>: an array of options. only {MatchBare: True} works.
    if all the conditions are mets, the selector is fired and the stanza is given as parameter.

    The selector should return YES to not be unregistered. If it returns NO or nothing, it will be
    unregistered

    @param aSelector the selector to be performed
    @param anObject the receiver of the selector
    @param aDict a dictionnary of parameters

    @return an id of the handler registration used to remove it
*/
- (id)registerSelector:(SEL)aSelector ofObject:(CPObject)anObject withDict:(id)aDict
{
    var from = ([[aDict valueForKey:@"from"] class] == CPString) ? [aDict valueForKey:@"from"] : [[aDict valueForKey:@"from"] stringValue],
        handlerId =  _connection.addHandler(function(stanza) {
                var stanzaObject    = [TNStropheStanza stanzaWithStanza:stanza],
                    ret             = [anObject performSelector:aSelector withObject:stanzaObject];

                CPLog.trace("StropheCappuccino stanza received that trigger selector : " + [anObject class] + "." + aSelector);
                CPLog.trace(stanzaObject);

                aDict           = null;
                from            = null;
                stanzaObject    = null;
                stanza          = null;

                return ret;
            },
            [aDict valueForKey:@"namespace"],
            [aDict valueForKey:@"name"],
            [aDict valueForKey:@"type"],
            [aDict valueForKey:@"id"],
            from,
            [aDict valueForKey:@"options"]);

    [_registeredHandlers addObject:handlerId];

    return handlerId;
}

/*! allows to register a selector for beeing fired on XMPP events, according to the content of a dictionnary parameter.
    The dictionnary should contains zero to many of the followings :
     - <b>namespace</b>: the namespace of the stanza or of the first child (like query)
     - <b>name</b>: the name of the stanza (message, iq or presence)
     - <b>type</b>: the type of the stanza
     - <b>id</b>: the unique identifier
     - <b>from</b>: the stanza sender
     - <b>options</b>: an array of options. only {MatchBare: True} works.
    if all the conditions are mets, the selector is fired and the stanza is given as parameter.

    The selector should return YES to not be unregistered. If it returns NO or nothing, it will be
    unregistered

    @param aSelector the selector to be performed
    @param anObject the receiver of the selector
    @param aDict a dictionnary of parameters
    @param someUserInfo user infos

    @return an id of the handler registration used to remove it
*/
- (id)registerSelector:(SEL)aSelector ofObject:(CPObject)anObject withDict:(id)aDict userInfo:(id)someUserInfo
{
    var from = ([[aDict valueForKey:@"from"] class] == CPString) ? [aDict valueForKey:@"from"] : [[aDict valueForKey:@"from"] stringValue],
        handlerId =  _connection.addHandler(function(stanza) {
                var stanzaObject    = [TNStropheStanza stanzaWithStanza:stanza],
                    ret             = [anObject performSelector:aSelector withObject:stanzaObject withObject:someUserInfo];

                CPLog.trace("StropheCappuccino stanza received that trigger selector : " + [anObject class] + "." + aSelector);
                CPLog.trace(stanzaObject);

                // be sure to let the garbage collector all this stuff
                someUserInfo    = null;
                aDict           = null;
                from            = null;
                stanzaObject    = null;
                stanza          = null;

                return ret;
            },
            [aDict valueForKey:@"namespace"],
            [aDict valueForKey:@"name"],
            [aDict valueForKey:@"type"],
            [aDict valueForKey:@"id"],
            from,
            [aDict valueForKey:@"options"]);

    [_registeredHandlers addObject:handlerId];

    return handlerId;
}

/*! Registred selector will be performed if the stanza response is not received after a given amout of time.
    The selector will be performed at every timeout interval until it returns NO.

    @param aTimeoutSelector the selector to be performed if stanza timeouts
    @param anObject the receiver of the selector
    @param aDict a dictionnary of parameters
    @param timeout float timeout of the handler

    @return an id of the handler registration used to remove it
*/
- (id)registerTimeoutSelector:(SEL)aTimeoutSelector ofObject:(CPObject)anObject withDict:(id)aDict forTimeout:(float)aTimeout
{
    var from = ([[aDict valueForKey:@"from"] class] == CPString) ? [aDict valueForKey:@"from"] : [[aDict valueForKey:@"from"] stringValue],
        handlerId =  _connection.addTimedHandler(aTimeout, function(stanza) {
                if (!stanza)
                {
                    var ret = [anObject performSelector:aTimeoutSelector];

                    CPLog.trace("StropheCappuccino stanza timeout that trigger selector : " + [anObject class] + "." + aTimeoutSelector);

                    // be sure to let the garbage collector all this stuff
                    aDict   = null;
                    from    = null;
                    stanza  = null;

                    return ret;
                }
                return NO;
            },
            [aDict valueForKey:@"namespace"],
            [aDict valueForKey:@"name"],
            [aDict valueForKey:@"type"],
            [aDict valueForKey:@"id"],
            from,
            [aDict valueForKey:@"options"]);

    [_registeredTimedHandlers addObject:handlerId];

    return handlerId;
}

/*! delete a registered selector
    @param aHandlerId the handler id to remove
*/
- (void)deleteRegisteredSelector:(id)aHandlerId
{
    _connection.deleteHandler(aHandlerId)
}

/*! delete a registered timed selector
    @param aHandlerId the handler id to remove
*/
- (void)deleteRegisteredTimedSelector:(id)aTimedHandlerId
{
    _connection.deleteTimedHandler(aTimedHandlerId)
}

/*! unrgister all registered selectors (including timeouted ones)
*/
- (void)deleteAllRegisteredSelectors
{
    for (var i = 0; i < [_registeredHandlers count]; i++)
        [self deleteRegisteredSelector:[_registeredHandlers objectAtIndex:i]]
    for (var i = 0; i < [_registeredTimedHandlers count]; i++)
        [self deleteRegisteredTimedSelector:[_registeredTimedHandlers objectAtIndex:i]]
}


- (void)rawInputRegisterSelector:(SEL)aSelector ofObject:(id)anObject
{
    _connection.xmlInput = function(elem){
        [anObject performSelector:aSelector withObject:[TNStropheStanza nodeWithXMLNode:elem]];
    }
}

- (void)rawOutputRegisterSelector:(SEL)aSelector ofObject:(id)anObject
{
    _connection.xmlOutput = function(elem){
        [anObject performSelector:aSelector withObject:[TNStropheStanza nodeWithXMLNode:elem]];
    }
}

@end

@implementation TNStropheConnection (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _JID                        = [aCoder decodeObjectForKey:@"_JID"];
        _password                   = [aCoder decodeObjectForKey:@"_password"];
        _delegate                   = [aCoder decodeObjectForKey:@"_delegate"];
        _boshService                = [aCoder decodeObjectForKey:@"_boshService"];
        _connection                 = [aCoder decodeObjectForKey:@"_connection"];
        _registeredHandlers         = [aCoder decodeObjectForKey:@"_registeredHandlers"];
        _registeredTimedHandlers    = [aCoder decodeObjectForKey:@"_registeredTimedHandlers"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_JID forKey:@"_JID"];
    [aCoder encodeObject:_password forKey:@"_password"];
    [aCoder encodeObject:_boshService forKey:@"_boshService"];
    [aCoder encodeObject:_connection forKey:@"_connection"];
    [aCoder encodeObject:_registeredHandlers forKey:@"_registeredHandlers"];
    [aCoder encodeObject:_registeredTimedHandlers forKey:@"_registeredTimedHandlers"];
}

@end
