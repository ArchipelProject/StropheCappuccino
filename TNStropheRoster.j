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
    CPArray _groups             @accessors(getter=groups);
    CPArray _pendingPresence    @accessors(getter=pendingPresence);
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
        _groups             = [CPArray array];
        _pendingPresence    = [CPArray array];
    }

    return self;
}

- (void)clear
{
    [_groups removeAllObjects];
    [_pendingPresence removeAllObjects];
    [super clear];
}


#pragma mark -
#pragma mark Fetch

/*! add a contact into the roster from a item XML node from roster iq
    @param aRosterItem TNXMLNode representing the roster item
    @param return a new TNStropheContact
*/
- (void)_addContactFromRosterItem:(TNXMLNode)aRosterItem
{
    var theJID = [TNStropheJID stropheJIDWithString:[aRosterItem valueForAttribute:@"jid"]];

    if ([self containsJID:theJID])
    {
        CPLog.warn("Cannot add: roster already contains " + theJID)
        return;
    }

    if ([theJID bareEquals:[_connection JID]])
    {
        CPLog.warn("Cannot add: jid is the current account JID " + theJID)
        return;
    }

    var nickname        = [aRosterItem valueForAttribute:@"name"] || [theJID node],
        groupName       = ([aRosterItem firstChildWithName:@"group"] != null) ? [[aRosterItem firstChildWithName:@"group"] text] : "General",
        newGroup        = [self groupWithName:groupName orCreate:YES],
        newContact      = [TNStropheContact contactWithConnection:_connection JID:theJID groupName:groupName],
        queuedPresence  = [self pendingPresenceForJID:theJID];

    [_contacts addObject:newContact];
    [newGroup addContact:newContact];

    for (var j = 0; j < [queuedPresence count]; j++)
        [newContact _didReceivePresence:[queuedPresence objectAtIndex:j]];

    [newContact setNickname:nickname];
    [newContact getMessages];
    [newContact setSubscription:[aRosterItem valueForAttribute:@"subscription"]];

    return newContact;
}

/*! remove a contact from the roster from a item XML node from roster iq
    @param aRosterItem TNXMLNode representing the roster item
*/
- (void)_removeContactFromRosterItem:(TNXMLNode)aRosterItem
{
    var theJID  = [TNStropheJID stropheJIDWithString:[aRosterItem valueForAttribute:@"jid"]];

    if (![self containsJID:theJID])
    {
        CPLog.warn("Cannot remove: roster do not contains " + theJID)
        return;
    }

    var contact = [self contactWithJID:theJID],
        group   = [self groupOfContact:contact];

    [group removeContact:contact];
    [_contacts removeObject:contact];

    if ([[group contacts] count] === 0)
        [self removeGroup:group];
}


/*! ask the server to get the roster of the TNStropheConnection user
*/
- (void)getRoster
{
    var uid             = [_connection getUniqueIdWithSuffix:@"roster"],
        rosteriq        = [TNStropheStanza iqWithAttributes:{@"id": uid, @"type": @"get"}],
        rosterParams    = [CPDictionary dictionaryWithObjectsAndKeys:@"iq", @"name", Strophe.NS.ROSTER, @"namespace"],
        presenceParams  = [CPDictionary dictionaryWithObjectsAndKeys:@"presence", @"name", [[_connection JID] bare], @"to"];

    [rosteriq addChildWithName:@"query" andAttributes:{'xmlns':Strophe.NS.ROSTER}];

    [_connection registerSelector:@selector(_didReceivePresence:) ofObject:self withDict:presenceParams];
    [_connection registerSelector:@selector(_didReceiveRoster:) ofObject:self withDict:rosterParams];

    [_connection send:rosteriq];
}

/*! this called when the roster is recieved. Will post TNStropheRosterRetrievedNotification
    @return NO to remove the selector registred from TNStropheConnection
*/
- (BOOL)_didReceiveRoster:(id)aStanza
{
    var items = [aStanza childrenWithName:@"item"];

    if ([aStanza type] === @"result")
    {
        for (var i = 0; i < [items count]; i++)
            [self _addContactFromRosterItem:[items objectAtIndex:i]];

        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheRosterRetrievedNotification object:self];
    }
    else if ([aStanza type] === @"set")
    {
        for (var i = 0; i < [items count]; i++)
        {
            var item            = [items objectAtIndex:i],
                theJID          = [TNStropheJID stropheJIDWithString:[item valueForAttribute:@"jid"]],
                subscription    = [item valueForAttribute:@"subscription"],
                contact;

            if (subscription === @"remove")
            {
                contact = [self contactWithJID:theJID];
                [self _removeContactFromRosterItem:item];
                [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheRosterPushRemovedContactNotification object:self userInfo:contact];
            }
            else if (subscription === @"both")
            {
                contact = [self _addContactFromRosterItem:item];
                [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheRosterPushAddedContactNotification object:self userInfo:contact];
            }
        }
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheRosterPushNotification object:self];
    }

    return YES;
}

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
            [_pendingPresence addObject:aStanza];
    }

    return YES;
}

/*! TODO: use a dictionnary for pending presence
*/
- (CPArray)pendingPresenceForJID:(TNStropheJID)aJID
{
    var temp = [CPArray array];
    for (var i = 0; i < [_pendingPresence count]; i++)
    {
        var presence = [_pendingPresence objectAtIndex:i];
        if ([[presence from] bareEquals:aJID])
            [temp addObject:presence];
    }
    return temp;
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
        return;

    return [self addGroup:[TNStropheGroup stropheGroupWithName:aGroupName]];
}

/*! remove a group from the roster with given name
    @param aGroupName the name of the group to remove
    @return YES if group has been removed, NO otherwise
*/
- (void)removeGroup:(TNStropheGroup)aGroup
{
    for (var i = 0; i < [aGroup count]; i++)
        [self changeGroup:_defaultGroup ofContact:[[aGroup contacts] objectAtIndex:i]];
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
    return;
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

    return;
}

#pragma mark -
#pragma mark Contacts

/*! add a new contact to the roster with given information
    @param aJID the JID of the new contact
    @param aName the nickname of the new contact. If nil, it will be the JID
    @param aGroup the group of the new contact. if nil, it will be "General"
*/
- (void)addContact:(TNStropheJID)aJID withName:(CPString)aName inGroupWithName:(CPString)aGroupName
{
    if ([self containsJID:aJID] == YES)
        return;

    if (!aName)
      aName = [aJID node];

    if (!aGroupName)
        aGroupName = @"General";

    var uid         = [_connection getUniqueId],
        addReq      = [TNStropheStanza iqWithAttributes:{"type": "set", "id": uid}],
        params      = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [addReq addChildWithName:@"query" andAttributes: {'xmlns':Strophe.NS.ROSTER}];
    [addReq addChildWithName:@"item" andAttributes:{"JID": [aJID full], "name": aName}];
    [addReq addChildWithName:@"group" andAttributes:nil];
    [addReq addTextNode:aGroupName];

    [_connection registerSelector:@selector(_didAddContact:userInfo:) ofObject:self withDict:params userInfo:aJID];

    [_connection send:addReq];
}

- (BOOL)_didAddContact:(TNStropheStanza)aStanza userInfo:(TNStropheJID)theJID
{
    if ([aStanza type] === @"result")
        CPLog.debug("Contact with JID " + theJID + " was added to roster!");
    else
        CPLog.error("Error adding contact with JID " + theJID + " to roster!");

    return NO;
}

/*! remove a TNStropheContact from the roster

    @param aContact the contact to remove
*/
- (void)removeContact:(TNStropheContact)aContact
{
    [super removeContact:aContact];

    var uid         = [_connection getUniqueIdWithSuffix:@"roster"],
        removeReq   = [TNStropheStanza iqWithAttributes:{"type": "set", "id": uid}];
        params      = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [removeReq addChildWithName:@"query" andAttributes: {'xmlns':Strophe.NS.ROSTER}];
    [removeReq addChildWithName:@"item" andAttributes:{'jid': [[aContact JID] bare], 'subscription': 'remove'}];

    [_connection registerSelector:@selector(_didRemoveContact:userInfo:) ofObject:self withDict:params userInfo:aContact];

    [_connection send:removeReq];
}

- (BOOL)_didRemoveContact:(TNStropheStanza)aStanza userInfo:(TNStropheContact)theContact
{
    if ([aStanza type] === @"result")
        CPLog.debug("Contact was removed from roster!");
    else
    {
        CPLog.error("Error removing contact from roster!");
        CPLog.error(theContact);
    }

    return NO;
}


/*! remove a contact from the roster according to its JID

    @param aJID the JID of the contact to remove
*/
- (void)removeContactWithJID:(TNStropheJID)aJID
{
    [self removeContact:[self contactWithJID:aJID]];
}



#pragma mark -
#pragma mark Subscriptions

/*! subscribe to the given JID and add in into the roster if needed
    @param aJID the JID to subscribe
*/
- (void)authorizeJID:(TNStropheJID)aJID
{
    var contact = [self contactWithJID:aJID];

    if (!contact)
        contact = [self addContact:aJID withName:[aJID node] inGroupWithName:@"General"];

    [contact subscribe];
}

/*! unsubscribe to the given JID
    @param aJID the JID to unsubscribe
*/
- (void)unauthorizeJID:(TNStropheJID)aJID
{
    [[self contactWithJID:aJID] unsubscribe];
}

/*! ask subscribtion to the given JID
    @param aJID the JID to ask subscribtion
*/
- (void)askAuthorizationTo:(TNStropheJID)aJID
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
        [self addContact:requester withName:[requester node] inGroupWithName:nil];

}

@end
