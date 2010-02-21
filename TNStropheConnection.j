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


/*! this class is a Objective-J Cappuccino wrapper for the Strophe library
*/
@implementation TNStropheConnection: CPObject 
{    
    CPString        jid                     @accessors; 
    CPString        password                @accessors; 
    id              delegate                @accessors; 
    CPString        _boshService;
    id              _connection;

}

// class methods
+ (TNStropheConnection)connectionWithService:(CPString)aService 
{
    return [[TNStropheConnection alloc] initWithService:aService];
}

+ (TNStropheConnection)connectionWithService:(CPString)aService jid:(CPString)aJid password:(CPString)aPassword 
{
    return [[TNStropheConnection alloc] initWithService:aService jid:aJid password:aPassword];
}


// initialization methods
- (id)initWithService:(CPString)aService
{
    if (self = [super init])
    {
        _boshService = aService;   
    }
    
    return self;
}

- (id)initWithService:(CPString)aService jid:(CPString)aJid password:(CPString)aPassword
{
    if (self = [self initWithService:aService])
    {
        [self setJid:aJid];
        [self setPassword:aPassword];
    }
    
    return self;
}


// connection management
- (void)connect
{
    _connection = new Strophe.Connection(_boshService);
    
    _connection.connect([self jid], [self password], function (status) 
    {
        if (status == Strophe.Status.CONNECTING)
        {
            if ([[self delegate] respondsToSelector:@selector(onStropheConnecting:)])
    	        [[self delegate] onStropheConnecting:self];        
        } 
        else if (status == Strophe.Status.CONNFAIL) 
        {
            if ([[self delegate] respondsToSelector:@selector(onStropheConnectFail:)])
    	        [[self delegate] onStropheConnectFail:self];      
        } 
        else if (status == Strophe.Status.DISCONNECTING) 
        {
    	    if ([[self delegate] respondsToSelector:@selector(onStropheDisconnecting:)])
    	        [[self delegate] onStropheDisconnecting:self];   
        } 
        else if (status == Strophe.Status.DISCONNECTED) 
        {
    	    if ([[self delegate] respondsToSelector:@selector(onStropheDisconnected:)])
    	        [[self delegate] onStropheDisconnected:self];
        } 
        else if (status == Strophe.Status.CONNECTED)
        {    
    	    _connection.send($pres().tree());
    	    
    	    if ([[self delegate] respondsToSelector:@selector(onStropheConnected:)])
    	        [[self delegate] onStropheConnected:self];
        }
    });
}

- (void)disconnect 
{
    _connection.disconnect("logout");
}


// Strophe function wrapping 
- (void)send:(id)stanza
{
    _connection.send(stanza);
}

- (void)getUniqueId
{
    return _connection.getUniqueId(null);
}

- (void)getUniqueId:(CPString)prefix
{
    return _connection.getUniqueId(prefix);
}


// handlers
- (void)registerSelector:(SEL)aSelector ofObject:(CPObject)anObject withDict:(id)aDict 
{    
    _connection.addHandler(function(stanza) {
                return [anObject performSelector:aSelector withObject:stanza]; 
            }, 
            [aDict valueForKey:@"namespace"], 
            [aDict valueForKey:@"name"], 
            [aDict valueForKey:@"type"], 
            [aDict valueForKey:@"id"], 
            [aDict valueForKey:@"from"],
            [aDict valueForKey:@"options"]);
}

@end



