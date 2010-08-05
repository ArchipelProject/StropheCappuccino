/*  
 * TNStropheRoster.j
 *    
 * Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
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

@import "TNStropheConnection.j";
@import "TNStropheStanza.j";
@import "TNStropheGroup.j"
@import "TNStropheContact.j"



/*! 
    @global
    @group TNStropheRoster
    notification indicates that TNStropheRoster has received the data from the XMPP server
*/
TNStropheRosterRetrievedNotification                = @"TNStropheRosterRetrievedNotification";
/*! 
    @global
    @group TNStropheRoster
    notification indicates that a new contact has been added to the TNStropheRoster
*/
TNStropheRosterAddedContactNotification             = @"TNStropheRosterAddedContactNotification";
/*! 
    @global
    @group TNStropheRoster
    notification indicates that a new contact has been removed from the TNStropheRoster
*/

TNStropheRosterRemovedContactNotification           = @"TNStropheRosterRemovedContactNotification";
/*! 
    @global
    @group TNStropheRoster
    notification indicates that a new group has been added to the TNStropheRoster
*/
TNStropheRosterAddedGroupNotification               = @"TNStropheRosterAddedGroupNotification";

/*! 
    @global
    @group TNStropheRoster
    notification indicates that a new group has been added to the TNStropheRoster
*/
TNStropheRosterRemovedGroupNotification               = @"TNStropheRosterRemovedGroupNotification";


/*! @ingroup strophecappuccino
    this is an implementation of a basic XMPP Roster
*/
@implementation TNStropheRoster : CPObject 
{
    CPArray                 _contacts       @accessors(getter=contacts);
    CPArray                 _groups         @accessors(getter=groups);
    id                      _delegate       @accessors(property=delegate);
    TNStropheConnection     _connection     @accessors(getter=connection);
    
    TNStropheGroup          _defaultGroup;

}

/*! initialize a roster with a valid TNStropheConnection

    @return initialized instance of TNStropheRoster
*/
- (id)initWithConnection:(TNStropheConnection)aConnection 
{
    if (self = [super init])
    {
        _connection     = aConnection;
        _contacts       = [CPArray array];
        _groups         = [CPArray array];
        
        _defaultGroup   = [TNStropheGroup stropheGroupWithName:@"General" connection:_connection];
        
        //[_groups addObject:_defaultGroup];
        
        var params = [[CPDictionary alloc] init];
        [params setValue:@"presence" forKey:@"name"];
        [params setValue:@"subscribe" forKey:@"type"];
        [params setValue:[_connection JID] forKey:@"to"];
        [_connection registerSelector:@selector(_didReceiveSubscription:) ofObject:self withDict:params];
    }

    return self;
}

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

/*! ask the server to get the roster of the TNStropheConnection user
*/
- (void)getRoster
{
    var uid         = [_connection getUniqueId:@"roster"];    
    var params      = [[CPDictionary alloc] init];
    var rosteriq    = [TNStropheStanza iqWithAttributes:{'id':uid, 'type':'get'}];
    
    [rosteriq addChildName:@"query" withAttributes:{'xmlns':Strophe.NS.ROSTER}];
    
    [params setValue:@"iq" forKey:@"name"];
    [params setValue:@"result" forKey:@"type"];
    [params setValue:uid forKey:@"id"];
    [_connection registerSelector:@selector(_didRosterReceived:) ofObject:self withDict:params];
    
    [_connection send:rosteriq];
}

/*! this called when the roster is recieved. Will post TNStropheRosterRetrievedNotification
    @return NO to remove the selector registred from TNStropheConnection
*/
- (BOOL)_didRosterReceived:(id)aStanza 
{
    var query   = [aStanza firstChildWithName:@"query"];
    var items   = [query childrenWithName:@"item"];
    var center  = [CPNotificationCenter defaultCenter];
    
    for (var i = 0; i < [items count]; i++)
    {
        var item        = [items objectAtIndex:i];
        var theJID      = [item valueForAttribute:@"jid"];
        var nickname    = theJID;
        
        if ([item valueForAttribute:@"name"])
            nickname = [item valueForAttribute:@"name"];

        if (![self containsJID:theJID])
        {
            var groupName   = ([item firstChildWithName:@"group"] != null) ? [[item firstChildWithName:@"group"] text] : "General";
            var newGroup    = [self groupWithName:groupName orCreate:YES];
            var newContact  = [TNStropheContact contactWithConnection:_connection JID:theJID groupName:groupName];
            
            [_contacts addObject:newContact];
            [newGroup addContact:newContact];
            
            [newContact setNickname:nickname];
            [newContact getVCard];
            [newContact getStatus];
            [newContact getMessages];
        }
    }
    
    [center postNotificationName:TNStropheRosterRetrievedNotification object:self];
    
    return NO;
}








/*! add a group to the roster with given name
    @param aGroupName the name of the new group
    @return TNStropheGroup object representing the new group
*/
- (TNStropheGroup)addGroup:(TNStropheGroup)aGroup
{
    var center      = [CPNotificationCenter defaultCenter];
    
    [_groups addObject:aGroup];
    
    [center postNotificationName:TNStropheRosterAddedGroupNotification object:aGroup];
    
    return aGroup;
}

- (TNStropheGroup)addGroupWithName:(CPString)aGroupName
{
    if (![self containsGroupWithName:aGroupName])
    {
        var newGroup = [TNStropheGroup stropheGroupWithName:aGroupName connection:_connection]
        
        return [self addGroup:newGroup];
    }
    
    return nil;
}

/*! remove a group from the roster with given name
    @param aGroupName the name of the group to remove
    @return YES if group has been removed, NO otherwise
*/
- (void)removeGroup:(TNStropheGroup)aGroup
{
    var center  = [CPNotificationCenter defaultCenter];
    
    [_groups removeObject:aGroup];
    [center postNotificationName:TNStropheRosterRemovedGroupNotification object:aGroup];
}

/*! checks if given TNStropheGroup is in roster
    @param aGroup the group
    @return YES if group is in roster, NO otherwise 
*/
- (BOOL)containsGroup:(TNStropheGroup)aGroup
{
    for(var i = 0; i < [_groups count]; i++)
    {
        var group = [_groups objectAtIndex:i];
        
        if (group == aGroup)
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
    var group = [self groupWithName:aGroupName];
    
    return [self containsGroup:group];
}

/*! return TNStropheGroup object according to the given name
    @param aGroupName the group name
    @return TNStropheGroup the group. nil if group doesn't exist
*/
- (TNStropheGroup)groupWithName:(CPString)aGroupName
{
    for(var i = 0; i < [_groups count]; i++)
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
    
    if ((shouldCreate) && !(newGroup))
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
    
    var uid     = [_connection getUniqueId];
    var addReq  = [TNStropheStanza iqWithAttributes:{"type": "set", "id": uid}];
    
    [addReq addChildName:@"query" withAttributes: {'xmlns':Strophe.NS.ROSTER}];
    [addReq addChildName:@"item" withAttributes:{"JID": aJID, "name": aName}];
    [addReq addChildName:@"group" withAttributes:nil];
    [addReq addTextNode:aGroupName];
    
    [_connection send:addReq];
    
    var contact = [TNStropheContact contactWithConnection:_connection JID:aJID groupName:aGroupName];
    [contact setNickname:aName];
    [contact getVCard];
    [contact getStatus];
    [contact getMessages];
    
    var group  = [self groupWithName:aGroupName orCreate:YES];
    
    [group addContact:contact];
   	[_contacts addObject:contact];
   	
   	var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNStropheRosterAddedContactNotification object:contact];
    
    return contact;
}


/*! remove a TNStropheContact from the roster
    
    @param aJID the JID of the contact to remove
*/
- (void)removeContact:(TNStropheContact)aContact
{
    var group       = [self groupOfContact:aContact];
    var uid         = [_connection getUniqueId];
    var removeReq   = [TNStropheStanza iqWithAttributes:{"type": "set", "id": uid}];
    
    [_contacts removeObject:aContact];
    [group removeContact:aContact];
    
    [removeReq addChildName:@"query" withAttributes: {'xmlns':Strophe.NS.ROSTER}];
    [removeReq addChildName:@"item" withAttributes:{'jid': [aContact JID], 'subscription': 'remove'}];
    
    [_connection send:removeReq];
    
    var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNStropheRosterRemovedContactNotification object:aContact];
}

/*! remove a contact from the roster according to its JID
    
    @param aJID the JID of the contact to remove
*/
- (void)removeContactWithJID:(CPString)aJID 
{
    var contact = [self contactWithJID:aJID];
    
    [self removeContact:contact];
}

/*! return a TNStropheContact object according to the given JID
    @param aJID CPString containing the JID
    @return TNStropheContact the contact with the given JID
*/
- (TNStropheContact)contactWithJID:(CPString)aJID
{
    //@each (var contact in _contacts)
    for(var i = 0; i < [_contacts count]; i++)
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
    for(var i = 0; i < [_contacts count]; i++)
    {
        var contact = [_contacts objectAtIndex:i];
        
        if ([[contact JID] lowercaseString] == [aJID lowercaseString])
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
    var contact = [self contactWithJID:aJID];

    [self changeNickname:aName ofContact:contact];
}

/*! changes the group of the contact with the given JID
    @param aGroup the new group
    @param aJID the JID of the contact to change the nickname
*/
- (void)changeGroup:(TNStropheGroup)newGroup ofContact:(TNStropheContact)aContact
{
    var oldGroup = [self groupOfContact:aContact];
    
    [oldGroup removeContact:aContact];
    
    [newGroup addContact:aContact];
    [aContact changeGroup:newGroup];
}







/*! subscribe to the given JID and add in into the roster if needed
    @param aJID the JID to subscribe
*/
- (void)authorizeJID:(CPString)aJID 
{
    var contact = [self contactWithJID:aJID];
    
    if (!contact)
    {
        var name = aJID.split('@')[0];
                
        contact = [self addContact:aJID withName:name inGroupWithName:@"General"];
    }
    
    [contact subscribe];
}

/*! unsubscribe to the given JID
    @param aJID the JID to unsubscribe
*/
- (void)unauthorizeJID:(CPString)aJID
{
    var contact = [self contactWithJID:aJID];
    [contact unsubscribe];
}

/*! ask subscribtion to the given JID
    @param aJID the JID to ask subscribtion
*/
- (void)askAuthorizationTo:(CPString)aJID
{
    var contact = [self contactWithJID:aJID];
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
        [self addContact:requester withName:requester inGroup:nil]; 
        
}


/*! sent disconnect message to the TNStropheConnection of the roster
*/
- (void)disconnect
{
    [_connection disconnect];
}
@end
