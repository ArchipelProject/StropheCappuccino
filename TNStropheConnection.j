/*  
 * TNStropheConnection.j
 * TNStropheConnection
 *    
 *  Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 * 
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

@import <Foundation/Foundation.j>
@import "TNStropheStanza.j"

/*! 
    @global
    @group TNStropheConnectionStatus
    Notification sent on connecting 
*/
TNStropheConnectionStatusConnecting       = @"TNStropheConnectionStatusConnecting";
/*! 
    @global
    @group TNStropheConnectionStatus
    Notification sent when connected 
*/
TNStropheConnectionStatusConnected        = @"TNStropheConnectionStatusConnected";
/*! 
    @global
    @group TNStropheConnectionStatus
    Notification sent on connection fail 
*/
TNStropheConnectionStatusConnectionFailure      = @"TNStropheConnectionStatusConnectionFailure";
/*! @global
    @group TNStropheConnectionStatus
    Notification sent when authenticating

*/
TNStropheConnectionStatusAuthenticating         = @"TNStropheConnectionStatusAuthenticating"
/*! 
    @global
    @group TNStropheConnectionStatus
    Notification sent on auth fail 
*/
TNStropheConnectionStatusAuthFailure          = @"TNStropheConnectionStatusAuthFailure";

/*! 
    @global
    @group TNStropheConnectionStatus
    Notification sent on disconnecting 
*/
TNStropheConnectionStatusDisconnecting    = @"TNStropheConnectionStatusDisconnecting";
/*! 
    @global
    @group TNStropheConnectionStatus
    Notification sent when disconnected 
*/
TNStropheConnectionStatusDisconnected     = @"TNStropheConnectionStatusDisconnected";

/*! 
    @global
    @group TNStropheConnectionStatus
    Notification sent when other error occurs 
*/
TNStropheConnectionStatusError              = @"TNStropheConnectionStatusError";


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

@implementation TNStropheConnection: CPObject 
{    
    CPString        _JID                    @accessors(property=JID); 
    CPString        _fullJID                @accessors(property=fullJID); 
    CPString        _resource               @accessors(property=resource); 
    CPString        _password               @accessors(property=password); 
    id              _delegate               @accessors(property=delegate);
    int             _maxConnections         @accessors(property=maxConnections);
    BOOL            _soundEnabled           @accessors(getter=isSoundEnabled, setter=setSoundEnabled:);
    
    CPString        _boshService;
    id              _connection;
    CPDictionary    _registredHandlerDict;
    
    id              _audioTagReceive;
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
+ (TNStropheConnection)connectionWithService:(CPString)aService JID:(CPString)aJID password:(CPString)aPassword 
{
    return [[TNStropheConnection alloc] initWithService:aService JID:aJID password:aPassword];
}

+ (TNStropheConnection)connectionWithService:(CPString)aService JID:(CPString)aJID resource:(CPString)aResource password:(CPString)aPassword 
{
    return [[TNStropheConnection alloc] initWithService:aService JID:aJID resource:aResource password:aPassword];
}


/*! initialize the TNStropheConnection

    @param aService a url of a bosh service (MUST be complete url with http://)
*/
- (id)initWithService:(CPString)aService
{
    if (self = [super init])
    {
        _boshService            = aService;
        _registredHandlerDict   = [[CPDictionary alloc] init];
        _soundEnabled           = YES;
        _maxConnections         = 10;
        _connection             = new Strophe.Connection(_boshService);
        
        var bundle  = [CPBundle bundleForClass:[self class]];
        var sound   = [bundle pathForResource:@"Receive.mp3"];

        _audioTagReceive = document.createElement('audio');
        _audioTagReceive.setAttribute("src", sound);
        _audioTagReceive.setAttribute("autobuffer", "autobuffer");
        document.body.appendChild(_audioTagReceive);
    }
    
    return self;
}

/*! initialize the TNStropheConnection

    @param aService a url of a bosh service (MUST be complete url with http://)
    @param aJID a JID to connect to the XMPP server
    @param aPassword the password associated to the JID
*/
- (id)initWithService:(CPString)aService JID:(CPString)aJID password:(CPString)aPassword
{
    if (self = [self initWithService:aService])
    {
        _JID        = aJID;
        _password   = aPassword;
    }
    
    return self;
}

- (id)initWithService:(CPString)aService JID:(CPString)aJID  resource:(CPString)aResource password:(CPString)aPassword
{
    if (self = [self initWithService:aService JID:aJID password:aPassword])
    {
        _resource   = aResource;
    }
    
    return self;
}

- (void)addNamespaceWithName:(CPString)aName value:(CPString)aValue
{
    Strophe.addNamespace(aName, aValue)
}

/*! connect to the XMPP Bosh Service. on different events, messages are sent to delegate and notification are sent

*/
- (void)connect
{
    _fullJID = _JID + @"/" + _resource;
    
    _connection.connect(_fullJID, _password, function (status, errorCond) 
    {
        var center = [CPNotificationCenter defaultCenter];

        if (status == Strophe.Status.CONNECTING)
        {
            if ([_delegate respondsToSelector:@selector(onStropheConnecting:)])
   	            [_delegate onStropheConnecting:self];

   	        [center postNotificationName:TNStropheConnectionStatusConnecting object:self]; 
        } 
        else if (status == Strophe.Status.CONNFAIL) 
        {
            if ([_delegate respondsToSelector:@selector(onStropheConnectFail:)])
   	            [_delegate onStropheConnectFail:self];

   	        [center postNotificationName:TNStropheConnectionStatusConnectionFailure object:self];
        }
        else if (status == Strophe.Status.AUTHFAIL) 
        {
            if ([_delegate respondsToSelector:@selector(onStropheAuthFail:)])
   	            [_delegate onStropheAuthFail:self];

   	        [center postNotificationName:TNStropheConnectionStatusAuthFailure object:self];
        }
        else if (status == Strophe.Status.ERROR) 
        {
            if ([_delegate respondsToSelector:@selector(onStropheError:)])
   	            [_delegate onStropheError:self];

   	        [center postNotificationName:TNStropheConnectionStatusError object:self];
        } 
        else if (status == Strophe.Status.DISCONNECTING) 
        {
   	        if ([_delegate respondsToSelector:@selector(onStropheDisconnecting:)])
   	            [_delegate onStropheDisconnecting:self];

   	        [center postNotificationName:TNStropheConnectionStatusDisconnecting object:self];
        }
        else if (status == Strophe.Status.AUTHENTICATING) 
        {
   	        if ([_delegate respondsToSelector:@selector(onStropheAuthenticating:)])
   	            [_delegate onStropheAuthenticating:self];

            [center postNotificationName:TNStropheConnectionStatusAuthenticating object:self];
        }
        else if (status == Strophe.Status.DISCONNECTED) 
        {
            if ([_delegate respondsToSelector:@selector(onStropheDisconnected:)])
            [_delegate onStropheDisconnected:self];

                [center postNotificationName:TNStropheConnectionStatusDisconnected object:self];
        } 
        else if (status == Strophe.Status.CONNECTED)
        {    
            _connection.send($pres().tree());
            var caps = [TNStropheStanza presence];
            [caps addChildName:@"c" withAttributes:{
                "xmlns": "http://jabber.org/protocol/caps",
                "node": "http://archipelproject.org/#1.0",
                "hash": "sha-1",
                "ver": "DndJUicxxxq1gHH7upVXwqpBoMI=" }];
            
            [self registerSelector:@selector(handleFeaturesDisco:) ofObject:self withDict:[CPDictionary dictionaryWithObjectsAndKeys:
                @"iq", @"name", @"http://jabber.org/protocol/disco#info", "namespace"]];
            
            [self send:caps];
            
            
            if ([_delegate respondsToSelector:@selector(onStropheConnected:)])
                [_delegate onStropheConnected:self];

            [center postNotificationName:TNStropheConnectionStatusConnected object:self];
        }
    }, /* wait */ 3600, /* hold */ _maxConnections);
}

- (BOOL)handleFeaturesDisco:(TNStropheStanza)aStanza
{
    console.log("==========================================================================================");
    console.log("==========================================================================================");
    console.log("aStanza: " + aStanza);
    
    var uid = [self getUniqueId];
    var resp = [TNStropheStanza iqWithAttributes:{"id": uid, "type": "result"}];
    [resp setTo:[aStanza from]];
    
    [resp addChildName:@"query" withAttributes:{"xmlns": "http://jabber.org/protocol/disco#info"}];
    [resp addChildName:@"identity" withAttributes:{"category": "client", "name": "Archipel 1.0", "type": "web"}];
    [resp up];
    [resp addChildName:@"feature" withAttributes:{"var": "http://jabber.org/protocol/pubsub"}];
    [resp up];
    [resp addChildName:@"feature" withAttributes:{"var": "http://jabber.org/protocol/pubsub+notify"}];
    
    console.log("RESP: " + resp);
    console.log("==========================================================================================");
    console.log("==========================================================================================");
    
    var params = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
    [self registerSelector:@selector(handlServerResponse:) ofObject:self withDict:params];
        
    [self send:resp];
    
    return YES;
}

- (void)handlServerResponse:(TNStropheStanza)aStanza
{
     console.log("##########################################################################################");
     CPLog.info(aStanza)
      console.log("##########################################################################################");
}


/*! this disconnect the XMPP connection
*/
- (void)disconnect 
{
    _connection.disconnect();
}


/*! send a TNStropheStanza object
    
    @param aStanza: the stanza to send
*/
- (void)send:(TNStropheStanza)aStanza
{
    CPLog.debug("StropheCappuccino Stanza Send:")
    CPLog.debug(aStanza);
    
    _connection.send([aStanza tree]);
}

/*! generates an unique identifier 
*/
- (void)getUniqueId
{
    return _connection.getUniqueId(null);
}

/*! generates an unique identifier prefixed by 
    
    @param prefix will prefixes the unique identifier
*/
- (void)getUniqueId:(CPString)prefix
{
    return _connection.getUniqueId(prefix);
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
- (void)reset
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


/*! allows to register a selector for beeing fired on XMPP events, according to the content of a dictionnary parameter.
    The dictionnary should contains zero to many of the followings :
     - <b>namespace</b>: the namespace of the stanza or of the first child (like query)
     - <b>name</b>: the name of the stanza (message, iq or presence)
     - <b>type</b>: the type of the stanza
     - <b>id</b>: the unique identifier 
     - <b>from</b>: the stanza sender
     - <b>options</b>: an array of options. only {MatchBare: True} works.
    if all the conditions are mets, the selector is fired and the stanza is given as parameter.
    
    The selector should return YES to not be unregistred. If it returns NO or nothing, it will be 
    unregistred
    
    @param aSelector the selector to be performed
    @param anObject the receiver of the selector
    @param aDict a dictionnary of parameters
    
    @return an id of the handler registration used to remove it
*/
- (id)registerSelector:(SEL)aSelector ofObject:(CPObject)anObject withDict:(id)aDict
{    
   var handlerId =  _connection.addHandler(function(stanza) {
                var stanzaObject = [TNStropheStanza stanzaWithStanza:stanza];
                CPLog.debug("StropheCappuccino stanza received that trigger selector : " + [anObject class] + "." + aSelector);
                CPLog.debug(stanzaObject);
                return [anObject performSelector:aSelector withObject:stanzaObject]; 
            }, 
            [aDict valueForKey:@"namespace"], 
            [aDict valueForKey:@"name"], 
            [aDict valueForKey:@"type"], 
            [aDict valueForKey:@"id"], 
            [aDict valueForKey:@"from"],
            [aDict valueForKey:@"options"]);
    
    return handlerId;
}

/*! same than registerSelector:ofObject:withDict but with a timeout
    
    @param aSelector the selector to be performed
    @param anObject the receiver of the selector
    @param aDict a dictionnary of parameters
    @timeout CPNumber timeout of the handler
    
    @return an id of the handler registration used to remove it
*/
- (void)registerSelector:(SEL)aSelector ofObject:(CPObject)anObject withDict:(id)aDict timeout:(CPNumber)aTimeout
{    
    var handlerId =  _connection.addTimeHandler(aTimeout, function(stanza) {
                var stanzaObject = [TNStropheStanza stanzaWithStanza:stanza];
                CPLog.debug("StropheCappuccino stanza received that trigger selector : " + [anObject class] + "." + aSelector);
                CPLog.debug(stanza);
                
                return [anObject performSelector:aSelector withObject:stanzaObject]; 
            }, 
            [aDict valueForKey:@"namespace"], 
            [aDict valueForKey:@"name"], 
            [aDict valueForKey:@"type"], 
            [aDict valueForKey:@"id"], 
            [aDict valueForKey:@"from"],
            [aDict valueForKey:@"options"]);
    
    return handlerId;
}

/*! delete an registred selector
    
    @param aHandlerId the handler id to remove
*/
- (void)deleteRegistredSelector:(id)aHandlerId
{
    _connection.deleteHandler(aHandlerId)
}

/*! delete an registred timed selector
    
    @param aHandlerId the handler id to remove
*/
- (void)deleteRegistredTimedSelector:(id)aTimedHandlerId
{
    _connection.deleteTimedHandler(aTimedHandlerId)
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

/*! Immediately send any pending outgoing data.
    
*/
- (void)flush
{
    _connection.flush();
}


- (void)playReceivedSound
{
    if (_soundEnabled)
    {
        _audioTagReceive.play();
    }
    
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    
    if (self)
    {
        _JID                = [aCoder decodeObjectForKey:@"_JID"];
        _password           = [aCoder decodeObjectForKey:@"_password"];
        _resource           = [aCoder decodeObjectForKey:@"_resource"];
        _delegate           = [aCoder decodeObjectForKey:@"_delegate"];
        _soundEnabled       = [aCoder decodeBoolForKey:@"_soundEnabled"];
        _boshService        = [aCoder decodeObjectForKey:@"_boshService"];
        _connection         = [aCoder decodeObjectForKey:@"_connection"];
        _audioTagReceive    = [aCoder decodeObjectForKey:@"_audioTagReceive"];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_JID forKey:@"_JID"];
    [aCoder encodeObject:_password forKey:@"_password"];
    [aCoder encodeObject:_resource forKey:@"_resource"];
    [aCoder encodeBool:_soundEnabled forKey:@"_soundEnabled"];
    [aCoder encodeObject:_boshService forKey:@"_boshService"];
    [aCoder encodeObject:_connection forKey:@"_connection"];
    [aCoder encodeObject:_registredHandlerDict forKey:@"_registredHandlerDict"];
    [aCoder encodeObject:_audioTagReceive forKey:@"_audioTagReceive"];
}
@end



