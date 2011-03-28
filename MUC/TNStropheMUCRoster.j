/*
 * TNStropheMUCRoster.j
 *
 * Copyright (C) 2010 Ben Langfeld <ben@langfeld.me>
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
@import "../TNStropheRosterBase.j"


/*! @ingroup strophecappuccino
    this is an implementation of a basic XMPP Multi-User Chat Roster
*/
@implementation TNStropheMUCRoster : TNStropheRosterBase
{
    TNStropheGroup          _admins         @accessors(getter=admins);
    TNStropheGroup          _moderators     @accessors(getter=moderators);
    TNStropheGroup          _owners         @accessors(getter=owners);
    TNStropheGroup          _participants   @accessors(getter=participants);
    TNStropheGroup          _visitors       @accessors(getter=visitors);
    TNStropheMUCRoom        _room           @accessors(getter=room);
}

#pragma mark -
#pragma mark Class methods

+ (TNStropheMUCRoster)rosterWithConnection:(TNStropheConnection)aConnection forRoom:(TNStropheMUCRoom)aRoom
{
    return [[TNStropheMUCRoster alloc] initWithConnection:aConnection forRoom:aRoom];
}

#pragma mark -
#pragma mark Initialization

/*! initialize a roster with a valid TNStropheConnection

    @return initialized instance of TNStropheMUCRoster
*/
- (id)initWithConnection:(TNStropheConnection)aConnection forRoom:(TNStropheMUCRoom)aRoom
{
    if (self = [super initWithConnection:aConnection])
    {
        _room           = aRoom;

        _visitors       = [TNStropheGroup stropheGroupWithName:@"Visitors"];
        _participants   = [TNStropheGroup stropheGroupWithName:@"Participants"];
        _moderators     = [TNStropheGroup stropheGroupWithName:@"Moderators"];
        _admins         = [TNStropheGroup stropheGroupWithName:@"Admins"];
        _owners         = [TNStropheGroup stropheGroupWithName:@"Owners"];

        var params      = [CPDictionary dictionaryWithObjectsAndKeys:@"presence", @"name",
                                                                     [[_room roomJID] full], @"from",
                                                                     {matchBare: true}, @"options"];
        [_connection registerSelector:@selector(_didReceivePresence:) ofObject:self withDict:params];
    }

    return self;
}


#pragma mark -
#pragma mark Presence

/*! this called when the roster is recieved. Will post TNStropheMUCPresenceRetrievedNotification
    @return YES to keep the selector registered with TNStropheConnection
*/
- (BOOL)_didReceivePresence:(id)aStanza
{
    var contact = [self contactWithFullJID:[aStanza from]],
        data    = [aStanza firstChildWithName:@"x"],
        group;

    if (data && [data namespace] == @"http://jabber.org/protocol/muc#user")
    {
        switch ([[data firstChildWithName:@"item"] valueForAttribute:@"role"])
        {
            case @"visitor":
                group = _visitors;
                break;
            case @"participant":
                group = _participants;
                break;
            case @"moderator":
                group = _moderators;
                break;
        }
    }

    if (contact)
        [contact _didReceivePresence:aStanza];
    else
        contact = [self addContact:[aStanza from] withName:[[aStanza from] resource] inGroup:group];

    if ([aStanza type] === @"unavailable")
    {
        var statusCode;
        if ([data containsChildrenWithName:@"status"])
            statusCode = [[data firstChildWithName:@"status"] valueForAttribute:@"code"];

        [self removeContact:contact withStatusCode:statusCode];
    }

    return YES;
}


#pragma mark -
#pragma mark Contacts

/*! add a new contact to the roster with given information
    @param aJID the JID of the new contact
    @param aName the nickname of the new contact. If nil, it will be the resource of the JID
    @param aGroup the group of the new contact. if nil, it will be _visitors
    @return the new TNStropheContact
*/
- (TNStropheContact)addContact:(TNStropheJID)aJID withName:(CPString)aName inGroup:(TNStropheGroup)aGroup
{
    if ([self containsFullJID:aJID])
        return;

    if (!aGroup)
        aGroup = _visitors;

    var contact = [TNStropheContact contactWithConnection:_connection JID:aJID group:aGroup];
    [contact setNickname:aName];

    [aGroup addContact:contact];
    [self cacheContact:contact];

    var userInfo = [CPDictionary dictionaryWithObject:contact forKey:@"contact"];

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheMUCContactJoinedNotification object:self userInfo:userInfo];

    return contact;
}

/*! remove a TNStropheContact from the roster

    @param aJID the JID of the contact to remove
*/
- (void)removeContact:(TNStropheContact)aContact withStatusCode:(CPString)aStatusCode
{
    [super removeContact:aContact];

    var userInfo = [CPDictionary dictionaryWithObjectsAndKeys:aStatusCode, @"statusCode",
                                                             aContact, @"contact"];

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheMUCContactLeftNotification object:self userInfo:userInfo];
}

/*! return the group of given contact
    @param aContact the contact
    @return TNStropheGroup of the the contact
*/
- (TNStropheGroup)groupOfContact:(TNStropheContact)aContact
{
    var groups = [CPArray arrayWithObjects:_visitors, _participants, _moderators, _admins, _owners];
    for (var i = 0; i < [groups count]; i++)
    {
        var group = [groups objectAtIndex:i];
        if ([[group contacts] containsObject:aContact])
            return group;
    }

    return;
}

@end
