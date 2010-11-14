/*
 * TNStropheRosterBase.j
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
@import "TNStropheConnection.j";
@import "TNStropheStanza.j";
@import "TNStropheGroup.j"
@import "TNStropheContact.j"
@import "TNStropheGlobals.j"

/*! @ingroup strophecappuccino
    this is an implementation of the functionality shared between real rosters and MUC memberships
*/
@implementation TNStropheRosterBase : CPObject
{
    CPArray                 _contacts       @accessors(getter=contacts);
    id                      _delegate       @accessors(property=delegate);
    TNStropheConnection     _connection     @accessors(getter=connection);

    TNStropheGroup          _defaultGroup;
}

#pragma mark -
#pragma mark Class methods

+ (TNStropheRosterBase)rosterWithConnection:(TNStropheConnection)aConnection
{
    return [[TNStropheRosterBase alloc] initWithConnection:aConnection];
}

#pragma mark -
#pragma mark Initialization

/*! initialize a roster with a valid TNStropheConnection

    @return initialized instance of TNStropheRosterBase
*/
- (id)initWithConnection:(TNStropheConnection)aConnection
{
    if (self = [super init])
    {
        _connection     = aConnection;
        _contacts       = [CPArray array];

        _defaultGroup   = [TNStropheGroup stropheGroupWithName:@"General"];
    }

    return self;
}

/*! sent disconnect message to the TNStropheConnection of the roster
*/
- (void)disconnect
{
    [_connection disconnect];
}

- (void)clear
{
    [_contacts removeAllObjects];
}


#pragma mark -
#pragma mark Contacts

- (TNStropheGroup)groupOfContact:(TNStropheContact)aContact
{
    CPLog.error('TNStropheRosterBase groupOfContact must be implemented in sub-classes.');
    return;
}

/*! remove a TNStropheContact from the roster

    @param aContact the contact to remove
*/
- (void)removeContact:(TNStropheContact)aContact
{
    [_contacts removeObject:aContact];
    [[self groupOfContact:aContact] removeContact:aContact];
}

/*! remove a contact from the roster according to its JID

    @param aJID the JID of the contact to remove
*/
- (void)removeContactWithJID:(TNStropheJID)aJID
{
    [self removeContact:[self contactWithJID:aJID]];
}

/*! return a TNStropheContact object according to the given JID
    @param aJID CPString containing the JID
    @return TNStropheContact the contact with the given JID
*/
- (TNStropheContact)contactWithJID:(TNStropheJID)aJID
{
    for (var i = 0; i < [_contacts count]; i++)
    {
        var contact = [_contacts objectAtIndex:i];
        if ([[contact JID] equals:aJID])
            return contact;
    }

    for (var i = 0; i < [_contacts count]; i++)
    {
        var contact = [_contacts objectAtIndex:i];
        if ([[contact JID] bareEquals:aJID])
            return contact;
    }

    return nil;
}

/*! return the first TNStropheContact matching to the given bare JID
    @param aJID CPString containing the JID
    @return TNStropheContact the contact with the given JID
*/
- (TNStropheContact)firstContactWithBareJID:(TNStropheJID)aJID
{
    for (var i = 0; i < [_contacts count]; i++)
    {
        var contact = [_contacts objectAtIndex:i];
        if ([[contact JID] bareEquals:aJID])
            return contact;
    }

    return nil;
}

/*! check if roster contains a contact with a given JID
    @param aJID the JID to search
    @return YES is JID is in roster, NO otherwise
*/
- (BOOL)containsJID:(TNStropheJID)aJID
{
    for (var i = 0; i < [_contacts count]; i++)
    {
        if ([[[_contacts objectAtIndex:i] JID] equals:aJID])
            return YES;
    }

    for (var i = 0; i < [_contacts count]; i++)
    {
        if ([[[_contacts objectAtIndex:i] JID] bareEquals:aJID])
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
- (void)changeNickname:(CPString)aName ofContactWithJID:(TNStropheJID)aJID
{
    [self changeNickname:aName ofContact:[self contactWithJID:aJID]];
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
