/*
 * TNStropheMUCRoster.j
 *
 * Copyright (C) 2010 Ben Langfeld <ben@langfeld.me>
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

@import "../TNStropheConnection.j"
@import "../TNStropheStanza.j"
@import "../TNStropheGroup.j"
@import "../TNStropheGlobals.j"
@import "../TNStropheContact.j"



/*! @ingroup strophecappuccino
    this is an implementation of a basic XMPP Multi-User Chat Roster
*/
@implementation TNStropheMUCRoster : CPObject
{
    CPArray                 _contacts       @accessors(getter=contacts);
    CPArray                 _groups         @accessors(getter=groups);
    TNStropheGroup          _visitors       @accessors(getter=visitors);
    TNStropheGroup          _participants   @accessors(getter=participants);
    TNStropheGroup          _moderators     @accessors(getter=moderators);
    TNStropheGroup          _admins         @accessors(getter=admins);
    TNStropheGroup          _owners         @accessors(getter=owners);
    id                      _delegate       @accessors(property=delegate);
    TNStropheConnection     _connection     @accessors(getter=connection);
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

    @return initialized instance of TNStropheRoster
*/
- (id)initWithConnection:(TNStropheConnection)aConnection forRoom:(TNStropheMUCRoom)aRoom
{
    if (self = [super init])
    {
        _connection     = aConnection;
        _room           = aRoom;
        _contacts       = [CPArray array];

        _visitors       = [TNStropheGroup stropheGroupWithName:@"Visitors"];
        _participants   = [TNStropheGroup stropheGroupWithName:@"Participants"];
        _moderators     = [TNStropheGroup stropheGroupWithName:@"Moderators"];
        _admins         = [TNStropheGroup stropheGroupWithName:@"Admins"];
        _owners         = [TNStropheGroup stropheGroupWithName:@"Owners"];

        var params      = [CPDictionary dictionaryWithObjectsAndKeys:@"presence", @"name",
                                                                     [_room roomJID], @"from",
                                                                     {matchBare: true}, @"options"];
        [_connection registerSelector:@selector(_didReceivePresence:) ofObject:self withDict:params];
    }

    return self;
}

/*! sent disconnect message to the TNStropheConnection of the roster
*/
- (void)disconnect
{
    [_connection disconnect];
}


#pragma mark -
#pragma mark Presence

/*! this called when the roster is recieved. Will post TNStropheMUCPresenceRetrievedNotification
    @return YES to keep the selector registered with TNStropheConnection
*/
- (BOOL)_didReceivePresence:(id)aStanza
{
    var contact = [self contactWithJID:[aStanza from]],
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

    if (!contact)
    {
        contact = [self addContact:[aStanza from] withName:[aStanza from].split("/")[1] inGroup:group];
        [contact getStatus];
    }

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
- (TNStropheContact)addContact:(CPString)aJID withName:(CPString)aName inGroup:(TNStropheGroup)aGroup
{
    if ([self containsJID:aJID] == YES)
        return;

    if (!aGroup)
        aGroup = _visitors;

    var contact = [TNStropheContact contactWithConnection:_connection JID:aJID groupName:[aGroup name]];
    [contact setNickname:aName];

    [aGroup addContact:contact];
    [_contacts addObject:contact];

    var userInfo = [CPDictionary dictionaryWithObject:contact forKey:@"contact"];

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheMUCContactJoinedNotification object:self userInfo:userInfo];

    return contact;
}

/*! remove a TNStropheContact from the roster

    @param aJID the JID of the contact to remove
*/
- (void)removeContact:(TNStropheContact)aContact withStatusCode:(CPString)aStatusCode
{
    [_contacts removeObject:aContact];
    [[self groupOfContact:aContact] removeContact:aContact];

    var userInfo = [CPDictionary dictionaryWithObjectAndKeys:aStatusCode, @"statusCode",
                                                             aContact, @"contact"];

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheMUCContactLeftNotification object:self userInfo:userInfo];
}

/*! remove a contact from the roster according to its JID

    @param aJID the JID of the contact to remove
*/
- (void)removeContactWithJID:(CPString)aJID
{
    [self removeContact:[self contactWithJID:aJID]];
}

/*! return a TNStropheContact object according to the given JID
    @param aJID CPString containing the JID
    @return TNStropheContact the contact with the given JID
*/
- (TNStropheContact)contactWithJID:(CPString)aJID
{
    for (var i = 0; i < [_contacts count]; i++)
    {
        var contact = [_contacts objectAtIndex:i];
        if ([contact JID] == aJID)
            return contact;
    }

    return nil;
}

/*! check if roster contains a contact with a given JID
    @param aJID the JID to search
    @return YES is JID is in roster, NO otherwise
*/
- (BOOL)containsJID:(CPString)aJID
{
    //@each (var contact in _contacts)
    for (var i = 0; i < [_contacts count]; i++)
    {
        if ([[[_contacts objectAtIndex:i] JID] lowercaseString] == [aJID lowercaseString])
            return YES;
    }
    return NO;
}

/*! changes the nickname of the contact with the given JID
    @param aName the new nickname
    @param aJID the JID of the contact to change the nickname
*/
- (void)changeNickname:(CPString)aName ofContact:(TNStropheContact)aContact
{
    [aContact changeNickname:aName];
}

/*! changes the nickname of the contact with the given JID
    @param aName the new nickname
    @param aJID the JID of the contact to change the nickname
*/
- (void)changeNickname:(CPString)aName ofContactWithJID:(CPString)aJID
{
    [self changeNickname:aName ofContact:[self contactWithJID:aJID]];
}

/*! return the group of given contact
    @param aContact the contact
    @return TNStropheGroup of the the contact
*/
- (TNStropheGroup)groupOfContact:(TNStropheContact)aContact
{
    for (var i = 0; i < [_groups count]; i++)
    {
        var group = [_groups objectAtIndex:i];
        if ([[group contacts] containsObject:aContact])
            return group;
    }

    return nil;
}

/*! changes the group of the contact with the given JID
    @param aGroup the new group
    @param aJID the JID of the contact to change the nickname
*/
- (void)changeGroup:(TNStropheGroup)newGroup ofContact:(TNStropheContact)aContact
{
    [[self groupOfContact:aContact] removeContact:aContact];

    [newGroup addContact:aContact];
    [aContact changeGroup:newGroup];
}

@end
