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

@import "TNStropheRosterBase.j"

/*! @ingroup strophecappuccino
    this is an implementation of a basic XMPP Roster
*/
@implementation TNStropheRoster : TNStropheRosterBase
{
    CPArray _groups @accessors(getter=groups);
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
        _groups = [CPArray array];

        var params = [CPDictionary dictionaryWithObjectsAndKeys:@"presence", @"name",
                                                                @"subscribe", @"type",
                                                                [_connection JID],@"to"];
        [_connection registerSelector:@selector(_didReceiveSubscription:) ofObject:self withDict:params];
    }

    return self;
}


#pragma mark -
#pragma mark Fetch

/*! ask the server to get the roster of the TNStropheConnection user
*/
- (void)getRoster
{
    var uid         = [_connection getUniqueIdWithSuffix:@"roster"],
        params      = [CPDictionary dictionary],
        rosteriq    = [TNStropheStanza iqWithAttributes:{'id':uid, 'type':'get'}];

    [rosteriq addChildWithName:@"query" andAttributes:{'xmlns':Strophe.NS.ROSTER}];

    [params setValue:@"iq" forKey:@"name"];
    [params setValue:@"result" forKey:@"type"];
    [params setValue:uid forKey:@"id"];
    [_connection registerSelector:@selector(_didReceiveRoster:) ofObject:self withDict:params];

    [_connection send:rosteriq];
}

/*! this called when the roster is recieved. Will post TNStropheRosterRetrievedNotification
    @return NO to remove the selector registred from TNStropheConnection
*/
- (BOOL)_didReceiveRoster:(id)aStanza
{
    var query   = [aStanza firstChildWithName:@"query"],
        items   = [query childrenWithName:@"item"];

    for (var i = 0; i < [items count]; i++)
    {
        var item        = [items objectAtIndex:i],
            theJID      = [item valueForAttribute:@"jid"],
            nickname    = theJID;

        if ([item valueForAttribute:@"name"])
            nickname = [item valueForAttribute:@"name"];

        if (![self containsJID:theJID])
        {
            var groupName   = ([item firstChildWithName:@"group"] != null) ? [[item firstChildWithName:@"group"] text] : "General",
                newGroup    = [self groupWithName:groupName orCreate:YES],
                newContact  = [TNStropheContact contactWithConnection:_connection JID:theJID groupName:groupName];

            [_contacts addObject:newContact];
            [newGroup addContact:newContact];

            [newContact setNickname:nickname];
            [newContact getStatus];
            [newContact getMessages];
            [newContact getVCard];
        }
    }

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheRosterRetrievedNotification object:self];

    return NO;
}


#pragma mark -
#pragma mark Groups

/*! add a group to the roster with given name
    @param aGroupName the name of the new group
    @return TNStropheGroup object representing the new group
*/
- (TNStropheGroup)addGroup:(TNStropheGroup)aGroup
{
    [_groups addObject:aGroup];

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheRosterAddedGroupNotification object:aGroup];

    return aGroup;
}

- (TNStropheGroup)addGroupWithName:(CPString)aGroupName
{
    if ([self containsGroupWithName:aGroupName])
        return nil;

    return [self addGroup:[TNStropheGroup stropheGroupWithName:aGroupName]];
}

/*! remove a group from the roster with given name
    @param aGroupName the name of the group to remove
    @return YES if group has been removed, NO otherwise
*/
- (void)removeGroup:(TNStropheGroup)aGroup
{
    [_groups removeObject:aGroup];
    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheRosterRemovedGroupNotification object:aGroup];
}

/*! checks if given TNStropheGroup is in roster
    @param aGroup the group
    @return YES if group is in roster, NO otherwise
*/
- (BOOL)containsGroup:(TNStropheGroup)aGroup
{
    for (var i = 0; i < [_groups count]; i++)
    {
        if ([_groups objectAtIndex:i] == aGroup)
            return YES;
    }
    return NO;
}

/*! checks if group with given name exist in roster
    @param aGroup the group name
    @return YES if group is in roster, NO otherwise
*/
- (BOOL)containsGroupWithName:(CPString)aGroupName
{
    return [self containsGroup:[self groupWithName:aGroupName]];
}

/*! return TNStropheGroup object according to the given name
    @param aGroupName the group name
    @return TNStropheGroup the group. nil if group doesn't exist
*/
- (TNStropheGroup)groupWithName:(CPString)aGroupName
{
    for (var i = 0; i < [_groups count]; i++)
    {
        var group = [_groups objectAtIndex:i];

        if ([group name] == aGroupName)
            return group;
    }
    return nil;
}

/*! return or create and return a TNStropheGroup with aGroupName
    @param aGroupName CPstring of the name
    @return a TNStropheGroup;
*/
- (TNStropheGroup)groupWithName:(CPString)aGroupName orCreate:(BOOL)shouldCreate
{
    var newGroup = [self groupWithName:aGroupName];

    if (shouldCreate && !newGroup)
        return [self addGroupWithName:aGroupName];

    return newGroup;
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

#pragma mark -
#pragma mark Contacts

/*! add a new contact to the roster with given information
    @param aJID the JID of the new contact
    @param aName the nickname of the new contact. If nil, it will be the JID
    @param aGroup the group of the new contact. if nil, it will be "General"
    @return the new TNStropheContact
*/
- (TNStropheContact)addContact:(CPString)aJID withName:(CPString)aName inGroupWithName:(CPString)aGroupName
{
    if ([self containsJID:aJID] == YES)
        return;

    if (!aGroupName)
        aGroupName = @"General";

    var addReq = [TNStropheStanza iqWithAttributes:{"type": "set", "id": [_connection getUniqueId]}];

    [addReq addChildWithName:@"query" andAttributes: {'xmlns':Strophe.NS.ROSTER}];
    [addReq addChildWithName:@"item" andAttributes:{"JID": aJID, "name": aName}];
    [addReq addChildWithName:@"group" andAttributes:nil];
    [addReq addTextNode:aGroupName];

    [_connection send:addReq];

    var contact = [TNStropheContact contactWithConnection:_connection JID:aJID groupName:aGroupName];
    [contact setNickname:aName];
    [contact getVCard];
    [contact getStatus];
    [contact getMessages];

    [[self groupWithName:aGroupName orCreate:YES] addContact:contact];
    [_contacts addObject:contact];

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheRosterAddedContactNotification object:contact];

    return contact;
}

/*! remove a TNStropheContact from the roster

    @param aContact the contact to remove
*/
- (void)removeContact:(TNStropheContact)aContact
{
    [super removeContact:aContact];

    var removeReq = [TNStropheStanza iqWithAttributes:{"type": "set", "id": [_connection getUniqueId]}];

    [removeReq addChildWithName:@"query" andAttributes: {'xmlns':Strophe.NS.ROSTER}];
    [removeReq addChildWithName:@"item" andAttributes:{'jid': [aContact JID], 'subscription': 'remove'}];

    [_connection send:removeReq];

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheRosterRemovedContactNotification object:aContact];
}


#pragma mark -
#pragma mark Subscriptions

/*! message sent when a presence information received
    send didReceiveSubscriptionRequest: to the delegate with the stanza as parameter

    @return YES to keep the selector registred in TNStropheConnection
*/
- (BOOL)_didReceiveSubscription:(id)requestStanza
{
    if ([_delegate respondsToSelector:@selector(didReceiveSubscriptionRequest:)])
        [_delegate performSelector:@selector(didReceiveSubscriptionRequest:) withObject:requestStanza];

    return YES;
}

/*! subscribe to the given JID and add in into the roster if needed
    @param aJID the JID to subscribe
*/
- (void)authorizeJID:(CPString)aJID
{
    var contact = [self contactWithJID:aJID];

    if (!contact)
        contact = [self addContact:aJID withName:aJID.split('@')[0] inGroupWithName:@"General"];

    [contact subscribe];
}

/*! unsubscribe to the given JID
    @param aJID the JID to unsubscribe
*/
- (void)unauthorizeJID:(CPString)aJID
{
    [[self contactWithJID:aJID] unsubscribe];
}

/*! ask subscribtion to the given JID
    @param aJID the JID to ask subscribtion
*/
- (void)askAuthorizationTo:(CPString)aJID
{
    [[self contactWithJID:aJID] askSubscription];
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
        [self addContact:requester withName:requester inGroupWithName:nil];
}

@end
