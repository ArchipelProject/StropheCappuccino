/*
 * TNStropheRoster.j
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
@import "TNStropheRosterBase.j"

/*! @ingroup strophecappuccino
    this is an implementation of a basic XMPP Roster
*/
@implementation TNStropheRoster : TNStropheRosterBase
{
    CPDictionary    _pendingPresence    @accessors(getter=pendingPresence);
}


#pragma mark -
#pragma mark Class methods

+ (TNStropheRoster)rosterWithConnection:(TNStropheConnection)aConnection
{
    return [[TNStropheRoster alloc] initWithConnection:aConnection];
}


#pragma mark -
#pragma mark Initialization

/*! initialize a roster with a valid TNStropheConnection
    @return initialized instance of TNStropheRoster
*/
- (id)initWithConnection:(TNStropheConnection)aConnection
{
    if (self = [super initWithConnection:aConnection])
    {
        _pendingPresence        = [CPDictionary dictionary];

        var rosterPushParams    = [CPDictionary dictionaryWithObjectsAndKeys:@"iq", @"name", Strophe.NS.ROSTER, @"namespace", @"set", @"type"],
            presenceParams      = [CPDictionary dictionaryWithObjectsAndKeys:@"presence", @"name", [[_connection JID] bare], @"to"];

        [_connection registerSelector:@selector(_didReceiveRosterPush:) ofObject:self withDict:rosterPushParams];
        [_connection registerSelector:@selector(_didReceivePresence:) ofObject:self withDict:presenceParams];
    }

    return self;
}

/*! clear all the content of the roster
*/
- (void)clear
{
    for (var i = 0; i < [_groupCache count]; i++)
    {
        [[_groupCache objectAtIndex:i] flushAllSubGroups];
    }
    [_pendingPresence removeAllObjects];
    [super clear];
}


#pragma mark -
#pragma mark Fetch / Push

/*! ask the server to get the roster of the TNStropheConnection user
*/
- (void)getRoster
{
    var uid                 = [_connection getUniqueIdWithSuffix:@"roster"],
        rosteriq            = [TNStropheStanza iqWithAttributes:{@"id": uid, @"type": @"get"}],
        rosterResultParams  = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [rosteriq addChildWithName:@"query" andAttributes:{'xmlns':Strophe.NS.ROSTER}];
    [_connection registerSelector:@selector(_didReceiveRosterResult:) ofObject:self withDict:rosterResultParams];
    [_connection send:rosteriq];
}

/*! this called when the roster is recieved. Will post TNStropheRosterRetrievedNotification
    @return NO to remove the selector registered from TNStropheConnection
*/
- (BOOL)_didReceiveRosterResult:(id)aStanza
{
    var items = [aStanza childrenWithName:@"item"];

    for (var i = 0; i < [items count]; i++)
    {
        var item            = [items objectAtIndex:i],
            subscription    = [item valueForAttribute:@"subscription"],
            allowedSubs     = [CPArray arrayWithObjects:@"none", @"to", @"from", @"both"];

        if (!subscription || ![allowedSubs containsObject:subscription])
            [item setValue:@"none" forAttribute:@"subscription"];

        [self _addContactFromRosterItem:item];
    }

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheRosterRetrievedNotification object:self];

    return NO;
}

/*! this called when a roster push is recieved. Will post TNStropheRosterPushNotification
    @return YES to keep the selector registered with TNStropheConnection
*/
- (BOOL)_didReceiveRosterPush:(id)aStanza
{
    var item            = [aStanza firstChildWithName:@"item"],
        theJID          = [TNStropheJID stropheJIDWithString:[item valueForAttribute:@"jid"]],
        subscription    = [item valueForAttribute:@"subscription"],
        allowedSubs     = [CPArray arrayWithObjects:@"none", @"to", @"from", @"both", @"remove"],
        response        = [TNStropheStanza iqTo:[aStanza from] withAttributes:{@"id": [aStanza ID], @"type": @"result"}],
        contact;

    /*! A receiving client MUST ignore the stanza unless it has no 'from' attribute (i.e., implicitly from the
        bare JID of the user's account) or it has a 'from' attribute whose value matches the user's bare
        JID <user@domainpart>.
    */
    if ([aStanza from] && (![[aStanza from] bareEquals:[_connection JID]]))
        return;

    /*! TODO: Should only send this if the stuff below has actually been successful
        Otherwise should send appropriate error response
    */
    [_connection send:response];

    if (!subscription || ![allowedSubs containsObject:subscription])
        [item setValue:@"none" forAttribute:@"subscription"];

    if ([self containsJID:theJID])
    {
        contact = [self _updateContactFromRosterItem:item];
    }
    else
    {
        contact = [self _addContactFromRosterItem:item];
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheRosterPushAddedContactNotification object:self userInfo:contact];
    }

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheRosterPushNotification object:self];

    return YES;
}

/*! add a contact into the roster from a item XML node from roster iq
    @param aRosterItem TNXMLNode representing the roster item
    @param return a new TNStropheContact
*/
- (void)_addContactFromRosterItem:(TNXMLNode)aRosterItem
{
    var theJID = [TNStropheJID stropheJIDWithString:[aRosterItem valueForAttribute:@"jid"]];

    if ([theJID bareEquals:[_connection JID]])
        return;

    var contact         = [TNStropheContact contactWithConnection:_connection JID:theJID group:nil],
        nickname        = [aRosterItem valueForAttribute:@"name"] || [theJID node],
        groupNodes      = [aRosterItem childrenWithName:@"group"],
        groups          = [CPArray array],
        queuedPresence  = [_pendingPresence valueForKey:[theJID bare]],
        subscription    = [aRosterItem valueForAttribute:@"subscription"];

    if ([groupNodes count])
    {
        for (var i = 0; i < [groupNodes count]; i++)
        {
            var groupsLine = [[[groupNodes objectAtIndex:i] text] uppercaseString],
                currentGroup = [self groupWithPath:groupsLine orCreate:YES];

            [self addContact:contact inGroup:currentGroup push:NO];
            [groups addObject:currentGroup];
        }
    }
    else
    {
        [_content addObject:contact];
    }

    for (var j = 0; j < [queuedPresence count]; j++)
        [contact _didReceivePresence:[queuedPresence objectAtIndex:j]];

    [contact setNickname:nickname];
    [contact setSubscription:subscription];
    [contact getMessages];

    [self cacheContact:contact];

    return contact;
}

/*! update a contact from a item XML node from roster iq
    @param aRosterItem TNXMLNode representing the roster item
    @param return the updated TNStropheContact
*/
- (void)_updateContactFromRosterItem:(TNXMLNode)aRosterItem
{
    var theJID = [TNStropheJID stropheJIDWithString:[aRosterItem valueForAttribute:@"jid"]];

    if ([theJID bareEquals:[_connection JID]])
        return;

    var contact         = [self contactWithJID:theJID],
        subscription    = [aRosterItem valueForAttribute:@"subscription"];

    if (subscription == @"remove")
    {
        [self uncacheContact:contact];
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheRosterPushRemovedContactNotification object:self userInfo:contact];
        return contact;
    }

    var nickname    = [aRosterItem valueForAttribute:@"name"] || [theJID node],
        groupNodes  = [aRosterItem childrenWithName:@"group"],
        groups      = [CPArray array],
        oldGroups   = [[contact groups] copy];

    if (nickname != [contact nickname])
        [contact setNickname:nickname];

    // flush current groups or from root area
    if ([_content containsObject:contact])
        [_content removeObject:contact];
    for (var i = 0; i < [oldGroups count]; i++)
        [self removeContact:contact fromGroup:[oldGroups objectAtIndex:i] push:NO];

    // readd contact in new groups
    for (var i = 0; i < [groupNodes count]; i++)
    {
        var currentGroupName = [[groupNodes objectAtIndex:i] text],
            currentGroup = [self groupWithPath:currentGroupName orCreate:YES];
        [self addContact:contact inGroup:currentGroup push:NO];
    }

    // if not in any groups, readd contcat in root area
    if ([[contact groups] count] == 0)
        [_content addObject:contact];

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheRosterPushUpdatedContactNotification object:self userInfo:contact];

    return contact;
}

/*! send a roster SET to the XMPP server according to the content of groups and nickname
    @param anObject the target object (an CPArray of TNStropheContact or a TNStropheContact)
*/
- (void)sendRosterSet:(id)anObject
{
    var contents;
    switch ([anObject class])
    {
        case TNStropheContact:
            contents = [CPArray arrayWithObject:anObject];
            break;
        case _CPJavaScriptArray:
        case CPArray:
            contents = anObject;
            break;
        default:
            CPLog.error("sendRosterSet: only accepts TNStropheContact or CPArray. given " + [anObject class]);
            return;
    }

    var stanza = [TNStropheStanza iqWithAttributes:{"type": "set"}];

    [stanza addChildWithName:@"query" andAttributes:{'xmlns':Strophe.NS.ROSTER}];

    for (var i = 0; i < [contents count]; i++)
    {
        var contact = [contents objectAtIndex:i];
        [stanza addChildWithName:@"item" andAttributes:{"JID": [[contact JID] bare], "name": [contact nickname]}];

        for (var j = 0; j < [[contact groups] count]; j++)
        {
            [stanza addChildWithName:@"group"];
            [stanza addTextNode:[[[contact groups] objectAtIndex:j] path]];
            [stanza up];
        }

        [stanza up];
    }
    [_connection send:stanza];
}

/*! send a roster REMOVE to the XMPP server
    @param anObject the target object (an CPArray of TNStropheContact or a TNStropheContact)
*/
- (void)sendRosterUnset:(id)anObject
{
    var contents;
    switch ([anObject class])
    {
        case TNStropheContact:
            contents = [CPArray arrayWithObject:anObject];
            break;
        case _CPJavaScriptArray:
        case CPArray:
            contents = anObject;
            break;
        default:
            CPLog.error("sendRosterUnset: only accepts TNStropheContact or CPArray. given " + [anObject class]);
            return;
    }
    var stanza  = [TNStropheStanza iqWithAttributes:{"type": "set"}];

    [stanza addChildWithName:@"query" andAttributes: {'xmlns':Strophe.NS.ROSTER}];

    for (var j = 0; j < [contents count]; j++)
    {
        var contact = [contents objectAtIndex:j];

        [stanza addChildWithName:@"item" andAttributes:{'jid': [[contact JID] bare], 'subscription': 'remove'}];
        [stanza up];
    }

    [_connection send:stanza];
}


#pragma mark -
#pragma mark Presence

/*! message sent when a presence information received
    send roster:receiveSubscriptionRequest: to the delegate with the stanza as parameter
    @return YES to keep the selector registred in TNStropheConnection
*/
- (BOOL)_didReceivePresence:(TNStropheStanza)aStanza
{
    if ([aStanza type] === @"subscribe")
    {
        if ([_delegate respondsToSelector:@selector(roster:receiveSubscriptionRequest:)])
            [_delegate roster:self receiveSubscriptionRequest:aStanza];
    }
    else
    {
        if ([self containsJID:[aStanza from]])
            [[self contactWithJID:[aStanza from]] _didReceivePresence:aStanza];
        else
        {
            var from = [aStanza fromBare];
            if (![_pendingPresence containsKey:from])
                [_pendingPresence setValue:[CPArray array] forKey:from];
            [[_pendingPresence valueForKey:from] addObject:aStanza];
        }
    }

    return YES;
}


#pragma mark -
#pragma mark Groups

/*! get the group with given path
    @param aPath the path of the group
    @return the TNStropheGroup object or nil
*/
- (TNStropheGroup)groupWithPath:(CPString)aPath
{
    var path = [aPath uppercaseString].split("::"),
        currentGroup = [self rootGroupWithName:path[0]],
        lastGroup = [self _subGroupWithPath:[path copy].splice(1, path.length - 1) relativeTo:currentGroup];
    return ([lastGroup path] == aPath) ? lastGroup : nil;
}

/*! @ignore
*/
- (TNStropheGroup)_subGroupWithPath:(CPArray)aPath relativeTo:(TNStropheGroup)aGroup
{
    var subGroup = [aGroup subGroupWithName:[aPath[0] uppercaseString]];
    if (subGroup)
        return [self _subGroupWithPath:aPath.splice(1, aPath.length - 1) relativeTo:subGroup];
    else
        return aGroup;
}

/*! return the group with given path or create it if it doesn't exists
    @param aPath the path of the group
    @param shouldCreate YES or NO
    @return the group
*/
- (TNStropheGroup)groupWithPath:(CPArray)aPath orCreate:(BOOL)shouldCreate
{
    var group = [self groupWithPath:aPath];
    if (!group && shouldCreate)
    {
        [self addGroupWithPath:aPath];
        group = [self groupWithPath:aPath];
    }

    return group;
}

/*! add a group with given path.
    if a group is missing the given path, it will be created
    @param aPath the path of the group
*/
- (void)addGroupWithPath:(CPString)aPath
{
    var path = [aPath uppercaseString].split("::");

    if ([self groupWithPath:aPath])
        return;

    for (var i = 0; i < [path count]; i++)
    {
        var currentPath = [path copy].splice(0, i + 1).join("::"),
            parentPath = [path copy].splice(0, i).join("::"),
            currentGroup = [self groupWithPath:currentPath],
            parentGroup = [self groupWithPath:parentPath];

        if (!currentGroup)
        {
            var tokens = [currentPath uppercaseString].split("::"),
                groupName = [tokens lastObject],
                currentGroup =  [TNStropheGroup stropheGroupWithName:groupName];

            [_groupCache addObject:currentGroup];

            if (parentGroup)
                [parentGroup addSubGroup:currentGroup];
            else
                [_content addObject:currentGroup];
        }
    }

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheRosterAddedGroupNotification object:[self groupWithPath:aPath]];
}

/*! remove the group at given path. all sub groups of the
    removed groups will also be removed
    @param aPath the path of the group
*/
- (void)removeGroupWithPath:(CPString)aPath
{
    var group = [self groupWithPath:aPath],
        parentGroup = [group parentGroup];

    if (!parentGroup)
    {
        [group removeSubGroups];
        [_content removeObject:group]
    }
    else
    {
        [parentGroup removeSubGroup:group];
    }

    [_groupCache removeObject:group];
    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheRosterRemovedGroupNotification object:group];
}

/*! remove the given group
    @param aGroup the group
*/
- (void)removeGroup:(TNStropheGroup)aGroup
{
    [self removeGroupWithPath:[aGroup path]]
}

/*! return TNStropheGroup object according to the given name
    @param aGroupName the group name
    @return TNStropheGroup the group. nil if group doesn't exist
*/
- (TNStropheGroup)rootGroupWithName:(CPString)aGroupName
{
    for (var i = 0; i < [_content count]; i++)
    {
        if (![[_content objectAtIndex:i] isKindOfClass:TNStropheGroup])
            continue;

        var group = [_content objectAtIndex:i];

        if ([group name] == aGroupName)
            return group;
    }
    return nil;
}


#pragma mark -
#pragma mark Contacts

/*! add a new contact to the roster with given information
    @param aJID the JID of the new contact
    @param aName the nickname of the new contact. If nil, it will be the JID
    @param aGroup the group of the new contact. if nil, it will be "General"
*/
- (void)addContact:(TNStropheJID)aJID withName:(CPString)aName inGroupWithPath:(CPString)aGroupPath
{
    if ([self containsJID:aJID])
        return;

    if (!aName)
        aName = [aJID node];

    var group       = aGroupPath ? [self groupWithPath:aGroupPath orCreate:YES] : nil,
        contact     = [TNStropheContact contactWithConnection:_connection JID:aJID group:group];

    [contact setNickname:aName];
    [self sendRosterSet:contact];
}

/*! remove a TNStropheContact from the roster
    @param aContact the contact to remove
*/
- (void)removeContact:(TNStropheContact)aContact
{
    var groups = [aContact groups];

    if (!groups || [groups count] == 0)
        [_content removeObject:aContact];
    else
        for (var i = 0; i < [groups count]; i++)
            [[[groups objectAtIndex:i] contacts] removeObject:aContact];

    [self sendRosterUnset:aContact];
}

/*! return an array of all contacts in group and all its subgroups
    @param aGroup the target group
    @return CPArray containing all contacts
*/
- (CPArray)getAllContactsTreeFromGroup:(TNStropheGroup)aGroup
{
    var returnArray = [CPArray array];
    return [self _getAllContactsTreeFromGroup:aGroup array:returnArray];
}

/*! @ignore
*/
- (CPArray)_getAllContactsTreeFromGroup:(TNStropheGroup)aGroup array:(CPArray)returnArray
{
    var subgroups = [aGroup subGroups];
    [returnArray addObjectsFromArray:[aGroup contacts]];
    for (var i = 0; i < [aGroup subGroupsCount]; i++)
        returnArray = [self _getAllContactsTreeFromGroup:[[aGroup subGroups] objectAtIndex:i] array:returnArray];
    return returnArray;
}


#pragma mark -
#pragma mark Group assignation

/*! add given given contact in given group
    @param aContact the contact to add
    @param aGroup the destination group
    @param shouldPush if YES, will send a roster set request
*/
- (void)addContact:(TNStropheContact)aContact inGroup:(TNStropheGroup)aGroup push:(BOOL)shouldPush
{
    var groupsOfContact = [aContact groups];

    if ([groupsOfContact containsObject:aGroup])
        return;

    [groupsOfContact addObject:aGroup];
    [[aGroup contacts] addObject:aContact];

    if (shouldPush)
    {
        [self sendRosterSet:aContact];
        [groupsOfContact removeObject:aGroup];
        [[aGroup contacts] removeObject:aContact];
    }

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheContactGroupUpdatedNotification object:aContact];
}

/*! remove given given contact from given group
    @param aContact the contact to remove
    @param aGroup the target group
    @param shouldPush if YES, will send a roster set request
*/
- (void)removeContact:(TNStropheContact)aContact fromGroup:(TNStropheGroup)aGroup push:(BOOL)shouldPush
{
    var groupsOfContact = [aContact groups];

    if (![groupsOfContact containsObject:aGroup])
        return;

    [groupsOfContact removeObject:aGroup];
    [[aGroup contacts] removeObject:aContact];

    if (shouldPush)
    {
        [self sendRosterSet:aContact];
        [groupsOfContact addObject:aGroup];
        [[aGroup contacts] addObject:aContact];
    }

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheContactGroupUpdatedNotification object:aContact];
}

/*! set the groups of the given contact
    @param someGroups array of groups
    @param aContact the target contact
*/
- (void)setGroups:(CPArray)someGroups ofContact:(TNStropheContact)aContact
{
    var groupsOfContact = [aContact groups];

    var oldGroups = [groupsOfContact copy];
    [aContact setGroups:someGroups];
    [self sendRosterSet:aContact];
    [aContact setGroups:oldGroups];
}


#pragma mark -
#pragma mark Edition

/*! this allows to change the given contact nickname.
    Will post TNStropheContactNicknameUpdatedNotification
    @param newNickname the new nickname
    @param aContact the target contact
*/
- (void)changeNickname:(CPString)newNickname ofContact:(TNStropheContact)aContact
{
    var oldNickname = [aContact nickname];
    [aContact setNickname:newNickname];
    [self sendRosterSet:aContact];
    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheContactNicknameUpdatedNotification object:aContact];
    [aContact setNickname:oldNickname];
}

/*! change the name of the given group
    @param aName the new name
    @param aGroup the target group
*/
- (void)changeName:(CPString)aName ofGroup:(TNStropheGroup)aGroup
{
    var affectedContacts = [self getAllContactsTreeFromGroup:aGroup];

    [aGroup setName:[aName uppercaseString]];
    console.warn([self getAllContactsTreeFromGroup:aGroup]);
    [self sendRosterSet:[self getAllContactsTreeFromGroup:aGroup]];
    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheGroupRenamedNotification object:self];
}


#pragma mark -
#pragma mark Subscriptions

/*! subscribe to the given JID
    @param aJID the JID to subscribe
*/
- (void)authorizeJID:(TNStropheJID)aJID
{
    var contact = [self contactWithJID:aJID];

    if (!contact)
        return;

    [contact subscribe];
}

/*! unsubscribe to the given JID
    @param aJID the JID to unsubscribe
*/
- (void)unauthorizeJID:(TNStropheJID)aJID
{
    var contact = [self contactWithJID:aJID];

    if (!contact)
        return;

    [contact unsubscribe];
}

/*! ask subscribtion to the given JID
    @param aJID the JID to ask subscribtion
*/
- (void)askAuthorizationTo:(TNStropheJID)aJID
{
    var contact = [self contactWithJID:aJID];

    if (!contact)
        return;

    [contact askSubscription];
}

/*! answer to a pending subscription request.
    @param TNStropheStanza the subscription request
    @param theAnswer if YES contact is subscribed and added to the roster. If NO, the subscription request is declined
*/
- (void)answerAuthorizationRequest:(id)aStanza answer:(BOOL)theAnswer
{
    var requester = [aStanza from];

    if (theAnswer == YES)
    {
        [self authorizeJID:requester];
        [self askAuthorizationTo:requester];
    }
    else
        [self unauthorizeJID:requester];

    if (![self containsJID:requester])
        [self addContact:requester withName:[requester node] inGroupWithPath:nil];

}

@end
