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



/*! @ingroup strophecappuccino
    this is an implementation of a basic XMPP Roster
*/
@implementation TNStropheRoster : CPObject 
{
    CPMutableArray          contacts        @accessors;
    CPMutableArray          groups          @accessors;
    id                      delegate        @accessors;
    
    TNStropheConnection     _connection     @accessors(getter=connection);
}

/*! initialize a roster with a valid TNStropheConnection

    @return initialized instance of TNStropheRoster
*/
- (id)initWithConnection:(TNStropheConnection)aConnection 
{
    if (self = [super init])
    {
        _connection= aConnection;
        [self setContacts:[[CPMutableArray alloc] init]];
        [self setGroups:[[CPMutableArray alloc] init]];

        var params = [[CPDictionary alloc] init];
        [params setValue:@"presence" forKey:@"name"];
        [params setValue:@"subscribe" forKey:@"type"];
        [params setValue:[_connection jid] forKey:@"to"];
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
    if ([[self delegate] respondsToSelector:@selector(didReceiveSubscriptionRequest:)])
        [[self delegate] performSelector:@selector(didReceiveSubscriptionRequest:) withObject:requestStanza];
    
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
        var item = [items objectAtIndex:i];
        
        if ([item valueForAttribute:@"name"])
            var nickname = [item valueForAttribute:@"name"];
        
        var theJid = [item valueForAttribute:@"jid"];
        
        if (![self doesRosterContainsJID:theJid])
        {
            var theGroup = ([item firstChildWithName:@"group"] != null) ? [[item firstChildWithName:@"group"] text] : "General";
            [self addGroupIfNotExists:theGroup];

        	var contact = [TNStropheContact contactWithConnection:_connection jid:theJid group:theGroup];
            [contact setNickname:nickname];
            
            [contact getVCard];
            [contact getStatus];
            [contact getMessages];
           	[[self contacts] addObject:contact];
        }
    	
    }
    
    [center postNotificationName:TNStropheRosterRetrievedNotification object:self];
    
    return NO;
}

/*! return a TNStropheContact object according to the given JID
    @param aJid CPString containing the JID
    @return TNStropheContact the contact with the given JID
*/
- (TNStropheContact)getContactFromJID:(CPString)aJid
{
    //@each (var contact in [self contacts])
    for(var i = 0; i < [[self contacts] count]; i++)
    {
        var contact = [[self contacts] objectAtIndex:i];
        if ([contact jid] == aJid)
            return contact;
    }
    
    return nil; 
}

/*! check if roster contains a contact with a given JID
    @param aJid the JID to search
    @return YES is JID is in roster, NO otherwise
*/
- (BOOL)doesRosterContainsJID:(CPString)aJid
{
    //@each (var contact in [self contacts])
    for(var i = 0; i < [[self contacts] count]; i++)
    {
        var contact = [[self contacts] objectAtIndex:i];
        
        if ([[contact jid] lowercaseString] == [aJid lowercaseString])
            return YES;
    }
    return NO;
}

/*! add a new contact to the roster with given information
    @param aJid the jid of the new contact
    @param aName the nickname of the new contact. If nil, it will be the JID
    @param aGroup the group of the new contact. if nil, it will be "General"
    @return the new TNStropheContact
*/
- (TNStropheContact)addContact:(CPString)aJid withName:(CPString)aName inGroup:(CPString)aGroup
{
    if ([self doesRosterContainsJID:aJid] == YES)
        return;

    if (!aGroup)
           aGroup = "General";
    
    var uid     = [_connection getUniqueId];
    var addReq  = [TNStropheStanza iqWithAttributes:{"type": "set", "id": uid}];
    
    [addReq addChildName:@"query" withAttributes: {'xmlns':Strophe.NS.ROSTER}];
    [addReq addChildName:@"item" withAttributes:{"jid": aJid, "name": aName}];
    [addReq addChildName:@"group" withAttributes:nil];
    [addReq addTextNode:aGroup];
    
    [_connection send:addReq];
    
    var contact = [TNStropheContact contactWithConnection:_connection jid:aJid group:aGroup];
    [contact setNickname:aName];
    [contact getVCard];
    [contact getStatus];
    [contact getMessages];
    [[self addGroupIfNotExists:aGroup]]
   	[[self contacts] addObject:contact];
   	
   	var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNStropheRosterAddedContactNotification object:contact];
    
    return contact;
}

/*! remove a contact from the roster according to its JID
    
    @param aJid the JID of the contact to remove
*/
- (void)removeContact:(CPString)aJid 
{
    var contact = [self getContactFromJID:aJid];
    if (contact) 
    {
        [[self contacts] removeObject:contact];
        
        var uid         = [_connection getUniqueId];
        var removeReq   = [TNStropheStanza iqWithAttributes:{"type": "set", "id": uid}];
        
        [removeReq addChildName:@"query" withAttributes: {'xmlns':Strophe.NS.ROSTER}];
        [removeReq addChildName:@"item" withAttributes:{'jid': aJid, 'subscription': 'remove'}];
        
        [_connection send:removeReq];
        
        var center = [CPNotificationCenter defaultCenter];
        [center postNotificationName:TNStropheRosterRemovedContactNotification object:contact];
    }
}

/*! changes the nickname of the contact with the given JID
    @param aName the new nickname
    @param aJid the JID of the contact to change the nickname
*/
- (void)changeNickname:(CPString)aName forJID:(CPString)aJid
{
    var contact = [self getContactFromJID:aJid];
    [contact changeNickname:aName];
}

/*! changes the group of the contact with the given JID
    @param aGroup the new group
    @param aJid the JID of the contact to change the nickname
*/
- (void) changeGroup:(CPString)aGroup forJID:(CPString)aJid
{
    var contact = [self getContactFromJID:aJid];
    [contact changeGroup:aGroup];
}


/*! return TNStropheGroup object according to the given name
    @param aGroupName the group name
    @return TNStropheGroup the group. nil if group doesn't exist
*/
- (TNStropheGroup)getGroupFromName:(CPString)aGroupName
{
    //@each (var group in [self groups])
    for(var i = 0; i < [[self groups] count]; i++)
    {
        var group = [[self groups] objectAtIndex:i];
        
        if ([group name] == aGroupName)
        return group;
    }
    return nil;
}

/*! checks if group with given name exist in roster
    @param aGroup the group name
    @return YES if group is in roster, NO otherwise 
*/
- (BOOL)doesRosterContainsGroup:(CPString)aGroup
{
    //@each (var group in [self groups])
    for(var i = 0; i < [[self groups] count]; i++)
    {
        var group = [[self groups] objectAtIndex:i];
        
        if ([group name] == aGroup)
            return YES;
    }   
    return NO;
}

/*! add a group to the roster with given name
    @param aGroupName the name of the new group
    @return TNStropheGroup object representing the new group
*/
- (TNStropheGroup)addGroup:(CPString)groupName
{
    var newGroup = [[TNStropheGroup alloc] init];

    [newGroup setName:groupName];
    [[self groups] addObject:newGroup];
    
    var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNStropheRosterAddedGroupNotification object:newGroup];
    
    return newGroup;
}

/*! add a group to the roster with given name only if it doesn't exist.
    @param aGroupName the name of the new group
    @return TNStropheGroup object representing the new group
*/
- (TNStropheGroup)addGroupIfNotExists:(CPString)groupName
{
    if (![self doesRosterContainsGroup:groupName])
        return [self addGroup:groupName];
    return nil;
}

/*! NOT IMPLEMENTED
    remove a group from the roster with given name
    @param aGroupName the name of the group to remove
    @return YES if group has been removed, NO otherwise
*/
- (BOOL)removeGroup:(CPString)aGroupName
{
    // TODO
}

/*! returns a CPArray containung all the TNStropheContact in a given group
    @param TNStropheGroup aGroup object
    @return CPArray containing all TNStropheContact in group
*/
- (CPArray)getContactsInGroup:(TNStropheGroup)aGroup
{
    var ret = [[CPArray alloc] init];

    //@each (var contact in [self contacts])
    for(var i = 0; i < [[self contacts] count]; i++)
    {
        var contact = [[self contacts] objectAtIndex:i];
        
        if ([contact group] == aGroup)
            [ret addObject:contact];
    }
    return ret;
}


/*! subscribe to the given JID and add in into the roster if needed
    @param aJid the JID to subscribe
*/
- (void)authorizeJID:(CPString)aJid 
{
    var contact = [self getContactFromJID:aJid];
    
    if (!contact)
    {
        var name = aJid.split('@')[0];
        
        // this is stupid to put this here.
        // But I have to put it somewhere before integration in archipel at more
        // judicious place
        //
        // var exp = new RegExp("[01234567890abcdef]{6}\-[01234567890abcdef]{4}\-[01234567890abcdef]{4}\-[01234567890abcdef]{4}\-[01234567890abcdef]{12}" , "gi")
        // alert(exp.test("579e6e34-dRa9-ecdd-e417-6b2e24e7bce4"));
        
        contact = [self addContact:aJid withName:name inGroup:@"General"];        
    }
    
    [contact subscribe];
}

/*! unsubscribe to the given JID
    @param aJid the JID to unsubscribe
*/
- (void)unauthorizeJID:(CPString)aJid
{
    var contact = [self getContactFromJID:aJid];
    [contact unsubscribe];
}

/*! ask subscribtion to the given JID
    @param aJid the JID to ask subscribtion
*/
- (void)askAuthorizationTo:(CPString)aJid
{
    var contact = [self getContactFromJID:aJid];
    [contact askSubscription];
}

/*! answer to a pending subscription request.
    @param TNStropheStanza the subscription request
    @param theAnswer if YES contact is subscribed and added to the roster. If NO, the subscription request is declined
*/
- (void)answerAuthorizationRequest:(id)aStanza answer:(BOOL)theAnswer
{
    var requester = [aStanza getFrom];
    
    if (theAnswer == YES)
    {
        [self authorizeJID:requester];
        [self askAuthorizationTo:requester];
    }
    else
        [self unauthorizeJID:requester];
    
    if (![self doesRosterContainsJID:requester])
        [self addContact:requester withName:requester inGroup:nil]; 
        
}


/*! sent disconnect message to the TNStropheConnection of the roster
*/
- (void)disconnect
{
    [_connection disconnect];
}
@end
