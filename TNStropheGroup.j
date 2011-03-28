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
    CPArray         _contacts       @accessors(getter=contacts);
    CPString        _name           @accessors(getter=name);
    TNStropheGroup  _parentGroup    @accessors(property=parentGroup);
}

+ (TNStropheGroup)stropheGroupWithName:(CPString)aName
{
    return [[TNStropheGroup alloc] initWithName:aName];
}

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

- (CPString)description
{
    return _name;
}

- (void)changeName:(CPString)aName
{
    for (var i = 0; i < [self contactCount]; i++)
    {
        var contact = [[self content] objectAtIndex:i],
            groups  = [[contact groups] copy];
        [groups removeObject:self];
        [groups addObject:[TNStropheGroup stropheGroupWithName:aName]];
        [contact setGroups:groups];
    }

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheGroupRenamedNotification object:self];
}

- (void)addContact:(TNStropheContact)aContact
{
    if (![aContact isKindOfClass:TNStropheContact])
        [CPException raise:"Invalid Object" reason:"addContact only supports to add TNStropheContacts"];

    [[aContact groups] addObject:self];
    [_contacts addObject:aContact];
}

- (void)removeContact:(TNStropheContact)aContact
{
    [[aContact groups] removeObject:self];
    [_contacts removeObject:aContact];
}

- (void)addSubGroup:(TNStropheGroup)aGroup
{
    if (![aGroup isKindOfClass:TNStropheGroup])
        [CPException raise:"Invalid Object" reason:"addSubGroup only supports to add TNStropheGroups"];

    [aGroup setParentGroup:self];
    [_subGroups addObject:aGroup];
}

- (void)removeSubGroups
{
    for (var i = 0; i < [self subGroupsCount]; i++)
    {
        var subGroup = [[self subGroups] objectAtIndex:i];
        [self removeSubGroup:subGroup];
    }

    _subGroups = [CPArray array];
}

- (void)removeSubGroup:(TNStropheGroup)aGroup
{
    if (![_subGroups containsObject:aGroup])
        return;

    [aGroup setParentGroup:nil];
    [aGroup removeSubGroups];

    [_subGroups removeObject:aGroup];
}

- (int)subGroupsCount
{
    return [_subGroups count];
}

- (int)contactCount
{
    return [_contacts count];
}

- (int)count
{
    return [self subGroupsCount] + [self contactCount];
}

- (TNStropheGroup)subGroupWithName:(CPString)aName
{
    for (var i = 0; i < [self subGroupsCount]; i++)
        if ([[[_subGroups objectAtIndex:i] name] uppercaseString] == [aName uppercaseString])
            return [_subGroups objectAtIndex:i];
    return nil;
}

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

- (CPArray)content
{
    return [_subGroups arrayByAddingObjectsFromArray:_contacts];
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
    return path.reverse().join("::");
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
