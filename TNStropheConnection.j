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
TNStropheConnectionStatusFailure          = @"TNStropheConnectionStatusFailure";
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
    
    #TNStropheConnectionStatusFailure
*/
@implementation TNStropheConnection: CPObject 
{    
    CPString        jid                     @accessors(); 
    CPString        password                @accessors(); 
    id              delegate                @accessors();
    
    CPString        _boshService;
    id              _connection;
    CPDictionary    _registredHandlerDict;
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
    @param aJid a JID to connect to the XMPP server
    @param aPassword the password associated to the JID
    
    @return a valid TNStropheConnection
*/
+ (TNStropheConnection)connectionWithService:(CPString)aService jid:(CPString)aJid password:(CPString)aPassword 
{
    return [[TNStropheConnection alloc] initWithService:aService jid:aJid password:aPassword];
}


/*! initialize the TNStropheConnection

    @param aService a url of a bosh service (MUST be complete url with http://)
*/
- (id)initWithService:(CPString)aService
{
    if (self = [super init])
    {
        _boshService = aService;
        _registredHandlerDict = [[CPDictionary alloc] init];
    }
    
    return self;
}

/*! initialize the TNStropheConnection

    @param aService a url of a bosh service (MUST be complete url with http://)
    @param aJid a JID to connect to the XMPP server
    @param aPassword the password associated to the JID
*/
- (id)initWithService:(CPString)aService jid:(CPString)aJid password:(CPString)aPassword
{
    if (self = [self initWithService:aService])
    {
        [self setJid:aJid];
        [self setPassword:aPassword];
    }
    
    return self;
}


/*! connect to the XMPP Bosh Service. on different events, messages are sent to delegate and notification are sent

*/
- (void)connect
{   
    _connection = new Strophe.Connection(_boshService);
    _connection.connect([self jid], [self password], function (status) 
    {
        var center = [CPNotificationCenter defaultCenter];
        
        if (status == Strophe.Status.CONNECTING)
        {
            if ([[self delegate] respondsToSelector:@selector(onStropheConnecting:)])
    	        [[self delegate] onStropheConnecting:self];
    	    
    	    [center postNotification:TNStropheConnectionStatusConnecting]; 
        } 
        else if (status == Strophe.Status.CONNFAIL) 
        {
            if ([[self delegate] respondsToSelector:@selector(onStropheConnectFail:)])
    	        [[self delegate] onStropheConnectFail:self];
    	    
    	    [center postNotification:TNStropheConnectionStatusFailure];
        } 
        else if (status == Strophe.Status.DISCONNECTING) 
        {
    	    if ([[self delegate] respondsToSelector:@selector(onStropheDisconnecting:)])
    	        [[self delegate] onStropheDisconnecting:self];
    	        
    	    [center postNotification:TNStropheConnectionStatusDisconnecting];
        } 
        else if (status == Strophe.Status.DISCONNECTED) 
        {
    	    if ([[self delegate] respondsToSelector:@selector(onStropheDisconnected:)])
    	        [[self delegate] onStropheDisconnected:self];
    	        
    	    [center postNotification:TNStropheConnectionStatusDisconnected];
        } 
        else if (status == Strophe.Status.CONNECTED)
        {    
    	    _connection.send($pres().tree());
    	    
    	    if ([[self delegate] respondsToSelector:@selector(onStropheConnected:)])
    	        [[self delegate] onStropheConnected:self];
    	        
            [center postNotification:TNStropheConnectionStatusConnected];
        }
    });
}

/*! this disconnect the XMPP connection
*/
- (void)disconnect 
{
    _connection.disconnect("logout");
}


/*! send a TNStropheStanza object
    
    @param aStanza: the stanza to send
*/
- (void)send:(TNStropheStanza)aStanza
{
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


/*! allows to register a selector for beeing fired on XMPP events, according to the content of a dictonnary parameter.
    The dictionnary should contains zero to many of the followings :
     - <b>namespace</b>: the namespace of the stanza
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
                return [anObject performSelector:aSelector withObject:[TNStropheStanza stanzaWithStanza:stanza]]; 
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
                return [anObject performSelector:aSelector withObject:[TNStropheStanza stanzaWithStanza:stanza]]; 
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
    _connection.deleteHandler(handlerId)
}

/*! delete an registred timed selector
    
    @param aHandlerId the handler id to remove
*/
- (void)deleteRegistredTimedSelector:(id)aTimedHandlerId
{
    _connection.deleteTimedHandler(aTimedHandlerId)
}

@end



