/*
 * TNStropheIMClient.j
 *
 * Copyright (C) 2010  Ben Langfeld <ben@langfeld.me>
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

@import "TNStropheConnection.j"
@import "TNStropheJID.j"
@import "TNStropheStanza.j"
@import "Resources/Strophe/sha1.js"
@import "TNStropheGlobals.j"
@import "TNStropheRoster.j"
@import "TNStropheClient.j"


@implementation TNStropheIMClient : TNStropheClient
{
    TNStropheRoster _roster @accessors(getter=roster);
}

#pragma mark -
#pragma mark Class methods

/*! instantiate a TNStropheIMClient object

    @param aService a url of a bosh service (MUST be complete url with http://)

    @return a valid TNStropheIMClient
*/
+ (TNStropheIMClient)IMClientWithService:(CPString)aService
{
    return [[TNStropheIMClient alloc] initWithService:aService];
}

/*! instantiate a TNStropheIMClient object

    @param aService a url of a bosh service (MUST be complete url with http://)
    @param aRosterClass the specific roster class to use (optional, defaults to TNStropheRoster)

    @return a valid TNStropheIMClient
*/
+ (TNStropheIMClient)IMClientWithService:(CPString)aService rosterClass:(id)aRosterClass
{
    return [[TNStropheIMClient alloc] initWithService:aService rosterClass:aRosterClass];
}

/*! instantiate a TNStropheIMClient object

    @param aService a url of a bosh service (MUST be complete url with http://)
    @param aJID a JID to connect to the XMPP server
    @param aPassword the password associated to the JID

    @return a valid TNStropheIMClient
*/
+ (TNStropheIMClient)IMClientWithService:(CPString)aService JID:(TNStropheJID)aJID password:(CPString)aPassword
{
    return [[TNStropheIMClient alloc] initWithService:aService JID:aJID password:aPassword];
}

/*! instantiate a TNStropheIMClient object

    @param aService a url of a bosh service (MUST be complete url with http://)
    @param aJID a JID to connect to the XMPP server
    @param aPassword the password associated to the JID
    @param aRosterClass the specific roster class to use (optional, defaults to TNStropheRoster)

    @return a valid TNStropheIMClient
*/
+ (TNStropheIMClient)IMClientWithService:(CPString)aService JID:(TNStropheJID)aJID password:(CPString)aPassword rosterClass:(id)aRosterClass
{
    return [[TNStropheIMClient alloc] initWithService:aService JID:aJID password:aPassword rosterClass:aRosterClass];
}


#pragma mark -
#pragma mark Initialization

/*! initialize the TNStropheIMClient

    @param aService a url of a bosh service (MUST be complete url with http://)
    @param aRosterClass the specific roster class to use (optional, defaults to TNStropheRoster)
*/
- (id)initWithService:(CPString)aService rosterClass:(id)aRosterClass
{
    if (self = [super initWithService:aService])
    {
        if (!aRosterClass)
            aRosterClass = TNStropheRoster;
        _roster = [aRosterClass rosterWithConnection:_connection];
    }

    return self;
}

/*! initialize the TNStropheIMClient

    @param aService a url of a bosh service (MUST be complete url with http://)
    @param aJID a JID to connect to the XMPP server
    @param aPassword the password associated to the JID
    @param aRosterClass the specific roster class to use (optional, defaults to TNStropheRoster)
*/
- (id)initWithService:(CPString)aService JID:(TNStropheJID)aJID password:(CPString)aPassword rosterClass:(id)aRosterClass
{
    if (self = [self initWithService:aService rosterClass:aRosterClass])
    {
        _JID        = aJID;
        _password   = aPassword;

        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didReceiveSubGroupDelimiter:) name:TNStropheRosterSubGroupDelimiterReceived object:nil];
    }

    return self;
}

#pragma mark -
#pragma mark Notification handler

/*! called when the roster's subgroup delimiter has been defined
    @param aNotification the notification that triggers the message
*/
- (void)_didReceiveSubGroupDelimiter:(CPNotification)aNotification
{
    [_roster getRoster];
}

#pragma mark -
#pragma mark Connection


- (void)onStropheConnected:(TNStropheConnection)aConnection
{
    /*! Upon authenticating with a server and binding a resource (thus becoming a connected resource as
        defined in [XMPP‑CORE]), a client SHOULD request the roster before sending initial presence
    */
    [_roster getSubGroupDelimiter];

    [super onStropheConnected:aConnection];
}

- (void)onStropheConnectFail:(TNStropheConnection)aConnection
{
    [_roster clear];
    [super onStropheConnectFail:aConnection];
}

- (void)onStropheDisconnected:(TNStropheConnection)aConnection
{
    [_roster clear];
    [super onStropheDisconnected:aConnection];
}

- (void)onStropheError:(TNStropheConnection)aConnection
{
    [_roster clear];
    [super onStropheError:aConnection];
}

@end

@implementation TNStropheClient (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _roster = [aCoder decodeObjectForKey:@"_roster"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_roster forKey:@"_roster"];
}

@end
