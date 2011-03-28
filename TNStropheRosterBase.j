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
    CPArray                 _content        @accessors(getter=content);
    id                      _delegate       @accessors(property=delegate);
    TNStropheConnection     _connection     @accessors(getter=connection);

    // TNStropheGroup          _defaultGroup;
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
        _content        = [CPArray array];
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
    [_content removeAllObjects];
}


#pragma mark -
#pragma mark Contacts

- (CPArray)groupsOfContact:(TNStropheContact)aContact
{
    return [contact groups];
}

/*! remove a TNStropheContact from the roster

    @param aContact the contact to remove
*/
- (void)removeContact:(TNStropheContact)aContact
{
    [[self groupOfContact:aContact] removeContact:aContact];
}

/*! remove a contact from the roster according to its JID

    @param aJID the JID of the contact to remove
*/
- (void)removeContactWithJID:(TNStropheJID)aJID
{
    [self removeContact:[self contactWithJID:aJID]];
}

/*! performs contactWithFullJID and contactWithBareJID
    @param aJID CPString containing the JID
    @return TNStropheContact the contact with the given JID
*/
- (TNStropheContact)contactWithJID:(TNStropheJID)aJID
{
    return [self contactWithFullJID:aJID] || [self contactWithBareJID:aJID];
}

/*! return a TNStropheContact object according to the given full JID
    @param aJID CPString containing the JID
    @return TNStropheContact the contact with the given JID
*/
- (TNStropheContact)contactWithFullJID:(TNStropheJID)aJID
{
    for (var i = 0; i < [_content count]; i++)
    {
        var obj = [_content objectAtIndex:i];
        if ([obj isKindOfClass:TNStropheContact] && [[obj JID] equals:aJID])
            return obj;
    }
    
    var c;
    for (var i = 0; i < [_content count]; i++)
    {
        var obj = [_content objectAtIndex:i];
        if ([obj isKindOfClass:TNStropheGroup])
            if (c = [self _searchContactWithJID:aJID matchBare:NO inGroup:obj])
                return c;
    }
    
    return nil;
}

/*! return a TNStropheContact object according to the given bare JID
    @param aJID CPString containing the JID
    @return TNStropheContact the contact with the given JID
*/
- (TNStropheContact)contactWithBareJID:(TNStropheJID)aJID
{
    for (var i = 0; i < [_content count]; i++)
    {
        var obj = [_content objectAtIndex:i];
        if ([obj isKindOfClass:TNStropheContact] && [[obj JID] bareEquals:aJID])
            return obj;
    }

    var c;
    for (var i = 0; i < [_content count]; i++)
    {
        var obj = [_content objectAtIndex:i];
        if ([obj isKindOfClass:TNStropheGroup])
            if (c = [self _searchContactWithJID:aJID matchBare:YES inGroup:obj])
                return c;
    }
    
    return nil;
}


- (TNStropheContact)_searchContactWithJID:(TNStropheJID)aJID matchBare:(BOOL)matchBare inGroup:(TNStropheGroup)aGroup
{
    var contact = [aGroup contactWithJID:aJID matchBare:matchBare];
    
    if (contact)
        return contact;
    
    for (var i = 0; i < [[aGroup subGroups] count]; i++)
    {
        contact = [self _searchContactWithJID:aJID matchBare:matchBare inGroup:[[aGroup subGroups] objectAtIndex:i]];
        if (contact)
            return contact
    }

    return nil;
}


/*! perform containsFullJID and containsBareJID
    @param aJID the JID to search
*/
- (BOOL)containsJID:(TNStropheJID)aJID
{
    return ([self contactWithBareJID:aJID] || [self contactWithFullJID:aJID]);
}

/*! check if roster contains a contact with a given full JID
    @param aJID the JID to search
    @return YES is JID is in roster, NO otherwise
*/
- (BOOL)containsFullJID:(TNStropheJID)aJID
{
    return ([self contactWithFullJID:aJID]) ? YES : NO;
}

/*! check if roster contains a contact with a given bare JID
    @param aJID the JID to search
    @return YES is JID is in roster, NO otherwise
*/
- (BOOL)containsBareJID:(TNStropheJID)aJID
{
    return ([self contactWithBareJID:aJID]) ? YES : NO;
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

@end
