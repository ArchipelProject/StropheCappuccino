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
    CPString        _password               @accessors(property=password);
    float           _giveupTimeout          @accessors(property=giveupTimeout);
    id              _currentStatus          @accessors(getter=currentStatus);
    id              _delegate               @accessors(getter=delegate);
    int             _connectionTimeout      @accessors(property=connectionTimeout);
    int             _maxConnections         @accessors(property=maxConnections);

    CPArray         _registeredHandlers;
    CPArray         _registeredTimedHandlers;
    CPString        _boshService;
    CPString        _userPresenceShow;
    CPString        _userPresenceStatus;
    CPTimer         _giveUpTimer;
    id              _connection;
    TNStropheJID    _JID;
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
+ (TNStropheConnection)connectionWithService:(CPString)aService andDelegate:(id)aDelegate
{
    return [[TNStropheConnection alloc] initWithService:aService andDelegate:aDelegate];
}


#pragma mark -
#pragma mark Initialization

/*! initialize the TNStropheConnection

    @param aService a url of a bosh service (MUST be complete url with http://)
*/
- (id)initWithService:(CPString)aService andDelegate:(id)aDelegate
{
    if (self = [super init])
    {
        _registeredHandlers         = [CPArray array];
        _registeredTimedHandlers    = [CPArray array];
        _connected                  = NO;
        _maxConnections             = 10;
        _connectionTimeout          = 3600;
        _giveupTimeout              = 8.0;
        _currentStatus              = Strophe.Status.DISCONNECTED;
        _boshService                = aService;
        _connection                 = new Strophe.Connection(_boshService);
        _delegate                   = aDelegate;
    }

    return self;
}


#pragma mark -
#pragma mark Connection

- (TNStropheJID)JID
{
    if ([_delegate respondsToSelector:@selector(JID)])
        return [_delegate JID];
    else
        return _JID;
}

/*! connect to the XMPP Bosh Service. on different events, messages are sent to delegate and notification are sent
*/
- (void)connectWithJID:(TNStropheJID)aJID andPassword:(CPString)aPassword
{
    if (_currentStatus !== Strophe.Status.DISCONNECTED)
        return;

    _JID = aJID;

    _connection.connect([aJID full], aPassword, function (status, errorCond)
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
                            [self reset]
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
                    if (_connected)
                    {
                        selector            = @selector(onStropheDisconnecting:);
                        notificationName    = TNStropheConnectionStatusDisconnecting;
                        break;
                    }
                case Strophe.Status.DISCONNECTED:
                    [self deleteAllRegisteredSelectors];
                    selector            = @selector(onStropheDisconnected:);
                    notificationName    = TNStropheConnectionStatusDisconnected;
                    _connected          = NO;
                    break;
                case Strophe.Status.CONNECTED:
                    selector            = @selector(onStropheConnected:);
                    notificationName    = TNStropheConnectionStatusConnected;
                    _connected          = YES;
                    if (_giveUpTimer)
                        [_giveUpTimer invalidate];
                    break;
            }
        }

        if (selector && [_delegate respondsToSelector:selector])
            [_delegate performSelector:selector withObject:self];

        if (notificationName)
            [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:self];

        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheConnectionStatusDidChangeNotification object:self];
    }, /* wait */ _connectionTimeout, /* hold */ _maxConnections);
}

/*! this disconnect the XMPP connection
*/
- (void)disconnect
{
    if (_currentStatus === Strophe.Status.DISCONNECTED)
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

- (TNStropheJID)JID
{
    return [_delegate JID];
}


#pragma mark -
#pragma mark Sending

/*! send a TNStropheStanza object
    @param aStanza: the stanza to send
*/
- (void)send:(TNStropheStanza)aStanza
{
    if (_currentStatus == Strophe.Status.CONNECTED)
    {
        CPLog.trace("StropheCappuccino Stanza Send:")
        CPLog.trace(aStanza);
        _connection.send([aStanza tree]);
    }
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
        handlerId =  _connection.addHandler(function(stanza)
            {
                var stanzaObject    = [TNStropheStanza stanzaWithStanza:stanza],
                    ret             = [anObject performSelector:aSelector withObject:stanzaObject];

                CPLog.trace("StropheCappuccino stanza received that trigger selector : " + [anObject class] + "." + aSelector);
                CPLog.trace(stanzaObject);

                // experimental thing
                delete aDict.options;

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
        handlerId =  _connection.addHandler(function(stanza)
            {
                var stanzaObject    = [TNStropheStanza stanzaWithStanza:stanza],
                    ret             = [anObject performSelector:aSelector withObject:stanzaObject withObject:someUserInfo];

                CPLog.trace("StropheCappuccino stanza received that trigger selector : " + [anObject class] + "." + aSelector);
                CPLog.trace(stanzaObject);

                // experimental thing
                delete aDict.options;
                delete someUserInfo;

                someUserInfo    = nil;

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

                    // experimental thing
                    delete aDict.options;

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
    _connection.deleteHandler(aHandlerId);
}

/*! delete a registered timed selector
    @param aHandlerId the handler id to remove
*/
- (void)deleteRegisteredTimedSelector:(id)aTimedHandlerId
{
    _connection.deleteTimedHandler(aTimedHandlerId);
}

/*! unrgister all registered selectors (including timeouted ones)
*/
- (void)deleteAllRegisteredSelectors
{
    for (var i = 0; i < [_registeredHandlers count]; i++)
        [self deleteRegisteredSelector:[_registeredHandlers objectAtIndex:i]];
    for (var i = 0; i < [_registeredTimedHandlers count]; i++)
        [self deleteRegisteredTimedSelector:[_registeredTimedHandlers objectAtIndex:i]];

    [_registeredHandlers removeAllObjects];
    [_registeredTimedHandlers removeAllObjects];
}

- (void)rawInputRegisterSelector:(SEL)aSelector ofObject:(id)anObject
{
    _connection.xmlInput = function(elem) {
        [anObject performSelector:aSelector withObject:[TNStropheStanza nodeWithXMLNode:elem]];
    }
}

- (void)rawOutputRegisterSelector:(SEL)aSelector ofObject:(id)anObject
{
    _connection.xmlOutput = function(elem) {
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
    [aCoder encodeObject:_boshService forKey:@"_boshService"];
    [aCoder encodeObject:_connection forKey:@"_connection"];
    [aCoder encodeObject:_registeredHandlers forKey:@"_registeredHandlers"];
    [aCoder encodeObject:_registeredTimedHandlers forKey:@"_registeredTimedHandlers"];
}

@end
