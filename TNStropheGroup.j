/*
 * TNStropheGroup.j
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
@import "TNStropheGlobals.j"


/*! @ingroup strophecappuccino
    this is an implementation of a basic XMPP Group.
*/
@implementation TNStropheGroup : CPObject
{
    CPArray         _subGroups      @accessors(getter=subGroups);
    CPArray         _contacts       @accessors(property=contacts);
    CPString        _name           @accessors(property=name);
    TNStropheGroup  _parentGroup    @accessors(property=parentGroup);
}

#pragma mark -
#pragma mark Initialization

/*! alloc and initialize a group with given name
    @param aName the name of the group
    @return a new TNStropheGroup
*/
+ (TNStropheGroup)stropheGroupWithName:(CPString)aName
{
    return [[TNStropheGroup alloc] initWithName:aName];
}

/*! initialize a group with given name
    @param aName the name of the group
    @return a new TNStropheGroup
*/
- (TNStropheGroup)initWithName:(CPString)aName
{
    if (self = [super init])
    {
        _contacts       = [CPArray array];
        _subGroups      = [CPArray array];
        _name           = aName;
        _parentGroup    = nil;
    }

    return self;
}


#pragma mark -
#pragma mark Overides

/*! return the group name as description
*/
- (CPString)description
{
    return _name;
}


#pragma mark -
#pragma mark Contacts

/*! return the contact with given jid
    @param aJID the TNStropheJID
    @param matchBare if YES, will use bareEquals, otherwise will use fullEquals
*/
- (TNStropheContact)contactWithJID:(TNStropheJID)aJID matchBare:(BOOL)matchBare
{
    for (var i = 0; i < [_contacts count]; i++)
    {
        if (matchBare)
        {
            if ([[[_contacts objectAtIndex:i] JID] bareEquals:aJID])
                return [_contacts objectAtIndex:i];
        }
        else
        {
            if ([[[_contacts objectAtIndex:i] JID] fullEquals:aJID])
                return [_contacts objectAtIndex:i];
        }
    }

    return nil;
}


#pragma mark -
#pragma mark Subgroups

/*! add another group as subgroup
    @param aGroup the other group
*/
- (void)addSubGroup:(TNStropheGroup)aGroup
{
    if (![aGroup isKindOfClass:TNStropheGroup])
        [CPException raise:"Invalid Object" reason:"addSubGroup only supports to add TNStropheGroups"];

    [aGroup setParentGroup:self];
    [_subGroups addObject:aGroup];
}

/*! remove the given subgroup
    @param aGroup the group to remove
*/
- (void)removeSubGroup:(TNStropheGroup)aGroup
{
    if (![_subGroups containsObject:aGroup])
        return;

    [aGroup setParentGroup:nil];
    [_subGroups removeObject:aGroup];
}

/*! remove all subgroups
*/
- (void)removeSubGroups
{
    for (var i = 0; i < [self subGroupsCount]; i++)
    {
        var subGroup = [[self subGroups] objectAtIndex:i];
        [self removeSubGroup:subGroup];
    }

    [_subGroups removeAllObjects];
}

- (void)flushAllSubGroups
{
    for (var i = 0; i < [self subGroupsCount]; i++)
    {
        var subGroup = [[self subGroups] objectAtIndex:i];
        [subGroups flushAllSubGroups];
        [self removeSubGroup:subGroup];
    }

    [_contacts removeAllObjects];
    [_subGroups removeAllObjects];
}

/*! return the subgroup with given name
    @param aName the name of the subgroup
*/
- (TNStropheGroup)subGroupWithName:(CPString)aName
{
    for (var i = 0; i < [self subGroupsCount]; i++)
        if ([[[_subGroups objectAtIndex:i] name] uppercaseString] == [aName uppercaseString])
            return [_subGroups objectAtIndex:i];
    return nil;
}

/*! format the path for the given group
    @param aGroup the group to format the path
    @returna the path of the group
*/
- (CPString)path
{
    var path = [[self name]],
        currentGroup = self;

    while (currentGroup)
    {
        currentGroup = [currentGroup parentGroup];
        if (currentGroup)
            [path addObject:[[currentGroup name] uppercaseString]];
    }
    return path.reverse().join(TNStropheRosterRosterDelimiter);
}


#pragma mark -
#pragma mark Counting

/*! return the number of groups
    @return the number of groups
*/
- (int)subGroupsCount
{
    return [_subGroups count];
}

/*! return the number of contacts
    @return the number of contacts
*/
- (int)contactCount
{
    return [_contacts count];
}

/*! return the number of entries
    @return the number of entries
*/
- (int)count
{
    return [self subGroupsCount] + [self contactCount];
}


- (CPArray)content
{
    return [_subGroups.sort() arrayByAddingObjectsFromArray:_contacts.sort()];
}


@end

@implementation TNStropheGroup (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _contacts       = [aCoder decodeObjectForKey:@"_contacts"];
        _name           = [aCoder decodeObjectForKey:@"_name"];
        _parentGroup    = [aCoder decodeObjectForKey:@"_parentGroup"];
        _subGroups      = [aCoder decodeObjectForKey:@"_subGroups"];
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_contacts forKey:@"_contacts"];
    [aCoder encodeObject:_name forKey:@"_name"];
    [aCoder encodeObject:_parentGroup forKey:@"_parentGroup"];
    [aCoder encodeObject:_subGroups forKey:@"_subGroups"];
}

@end
