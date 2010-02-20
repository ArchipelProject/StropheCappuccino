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
@import <AppKit/AppKit.j>

@import "TNStropheConnection.j";
@import "TNStropheStanza.j";

TNStropheRosterStatusAway       = @"away";
TNStropheRosterStatusBusy       = @"xa";
TNStropheRosterStatusDND        = @"dnd";
TNStropheRosterStatusOffline    = @"offline";
TNStropheRosterStatusOnline     = @"online";


TNStropheContactNicknameUpdated         = @"TNStropheContactNicknameUpdated";
TNStropheContactGroupUpdated            = @"TNStropheContactGroupUpdated";
TNStropheContactPresenceUpdated         = @"TNStropheContactPresenceUpdated";

TNStropheRosterAskRetrieving            = @"TNStropheRosterAskRetrieving";
TNStropheRosterRetrieved                = @"TNStropheRosterRetrieved";
TNStropheRosterAddedContact             = @"TNStropheRosterAddedContact";
TNStropheRosterRemovedContact           = @"TNStropheRosterRemovedContact";
TNStropheRosterAddedGroup               = @"TNStropheRosterAddedGroup";

@implementation TNStropheRosterGroup: CPObject 
{
    CPArray     entries     @accessors;
    CPString    name        @accessors;
    CPString    type        @accessors;
}

- (id)init
{
    if (self = [super init])
    {
        [self setType:@"group"];
        [self setEntries:[[CPArray alloc] init]];
    }
    
    return self;
}

- (CPString)description
{
    return [self name];
}

@end




// this is the implementation of an contact in roster
@implementation TNStropheRosterEntry: CPObject
{
    CPString            jid             @accessors;
    CPString            domain          @accessors;
    CPString            nickname        @accessors;
    CPString            resource        @accessors;
    CPString            status          @accessors;
    CPImage             statusIcon      @accessors;
    CPString            group           @accessors;
    CPString            type            @accessors;
    CPString            fullJID         @accessors;
    CPString            vCard           @accessors;
    TNStropheConnection connection      @accessors;
}

+ (TNStropheRosterEntry)rosterEntryWithConnection:(TNStropheConnection)aConnection jid:(CPString)aJid group:(CPString)aGroup
{
    var entry = [[TNStropheRosterEntry alloc] initWithConnection:aConnection];
    [entry setGroup:aGroup];
	[entry setJid:aJid];
	[entry setNickname:aJid.split('@')[0]];
	[entry setResource: aJid.split('/')[1]];
	[entry setDomain: aJid.split('/')[0].split('@')[1]];
    return entry;
}

- (id)initWithConnection:(TNStropheConnection)aConnection
{
    if (self = [super init])
    {
        [self setType:@"contact"];
        [self setStatusIcon:[[CPImage alloc] initWithContentsOfFile:@"Resources/StatusIcons/Offline.jpg" size:CGSizeMake(16, 16)]];
        [self setValue:@"Resources/StatusIcons/Offline.png" forKeyPath:@"statusIcon.filename"];
        [self setStatus:TNStropheRosterStatusOffline];

        [self setConnection:aConnection]   
    }
    
    return self;
}

- (CPString)description
{
    return [self nickname];
}

- (void)getStatus
{
    var probe = [TNStropheStanza presenceWithAttributes:{"from": [connection jid], "type": "probe", "to": [self jid]}];
    var params = [[CPDictionary alloc] init];
    
    [params setValue:@"presence" forKey:@"name"];
    [params setValue:[self jid] forKey:@"from"];
    [params setValue:{"matchBare": true} forKey:@"options"];
    
    [connection registerSelector:@selector(handleStatusResponse:) ofObject:self withDict:params];
    
    [[self connection] send:[probe stanza]];
}

- (BOOL)handleStatusResponse:(id)aStanza
{
    // update resource
    [self setFullJID:aStanza.getAttribute("from")];
    [self setResource:aStanza.getAttribute("from").split('/')[1]];
    
    if (aStanza.getAttribute("type") == "unavailable") 
    {   
        [self setValue:TNStropheRosterStatusOffline forKey:@"status"];
        [self setValue:@"Resources/StatusIcons/Offline.png" forKeyPath:@"statusIcon.filename"];
    }
    else
    {
        show = aStanza.getElementsByTagName("show")[0];

        [self setValue:TNStropheRosterStatusOnline forKey:@"status"];
        [self setValue:@"Resources/StatusIcons/Available.png" forKeyPath:@"statusIcon.filename"];

        if (show)
        {
            if ($(show).text() == TNStropheRosterStatusBusy) 
            {
                [self setValue:TNStropheRosterStatusBusy forKey:@"status"];
                [self setValue:@"Resources/StatusIcons/Away.png" forKeyPath:@"statusIcon.filename"];
            }
            else if ($(show).text() == TNStropheRosterStatusAway) 
            {
                [self setValue:TNStropheRosterStatusAway forKey:@"status"];
                [self setValue:@"Resources/StatusIcons/Idle.png" forKeyPath:@"statusIcon.filename"];
            }
            else if ($(show).text() == TNStropheRosterStatusDND) 
            {
                [self setValue:TNStropheRosterStatusDND forKey:@"status"];
                [self setValue:@"Resources/StatusIcons/Blocked.png" forKeyPath:@"statusIcon.filename"];
            }
        }
    }

    var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNStropheContactPresenceUpdated object:self];
    
    return YES;
}

- (void)getVCard
{
    var uid = [connection getUniqueId];
    var vcard_stanza = [TNStropheStanza stanzaWithName:@"iq" andAttributes:{"from": [connection jid], "to": [self jid], "type": "get", "id": uid}];
    [vcard_stanza addChildName:@"vCard" withAttributes:{'xmlns': "vcard-temp"}];
    
    var params = [[CPDictionary alloc] init];
    [params setValue:uid forKey:@"id"];

    [connection registerSelector:@selector(handleVCardResponse:) ofObject:self withDict:params];
    [connection send:[vcard_stanza tree]];
}

- (BOOL)handleVCardResponse:(id)aStanza
{
    var vCard = aStanza.getElementsByTagName("vCard");
    
    if (vCard)
    {
        [self setVCard:vCard[0]];
    }
    
    
    return NO;
}

- (void)changeNickname:(CPString)newNickname
{
    [self setNickname:newNickname];
    
    var stanza = [TNStropheStanza iqWithAttributes:{"type": "set"}];
    [stanza addChildName:@"query" withAttributes: {'xmlns':Strophe.NS.ROSTER}];
    [stanza addChildName:@"item" withAttributes:{"jid": [self jid], "name": newNickname}];
    [stanza addChildName:@"group" withAttributes:nil];
    [stanza addTextNode:[self group]];

    [[self connection] send:[stanza tree]];
   
    var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNStropheContactNicknameUpdated object:self];
}

- (void)changeGroup:(CPString)newGroupName
{
    [self setGroup:newGroupName];
    
    var stanza = [TNStropheStanza iqWithAttributes:{"type": "set"}];
    [stanza addChildName:@"query" withAttributes: {'xmlns':Strophe.NS.ROSTER}];
    [stanza addChildName:@"item" withAttributes:{"jid": [self jid], "name": [self nickname]}];
    [stanza addChildName:@"group" withAttributes:nil];
    [stanza addTextNode:newGroupName];
    
    [[self connection] send:[stanza tree]];
    
    var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNStropheContactGroupUpdated object:self];
}

@end




// this is an implementation of a basic XMPP Roster
@implementation TNStropheRoster : CPObject 
{
    CPMutableArray          entries         @accessors;
    CPMutableArray          groups          @accessors;
    id                      delegate        @accessors;
    
    TNStropheConnection     _connection;
}

// instance methods
- (id)initWithConnection:(TNStropheConnection)aConnection 
{
    if (self = [super init])
    {
        _connection= aConnection;
        [self setEntries:[[CPMutableArray alloc] init]];
        [self setGroups:[[CPMutableArray alloc] init]];

        var params = [[CPDictionary alloc] init];
        [params setValue:@"presence" forKey:@"name"];
        [params setValue:@"subscribe" forKey:@"type"];
        [params setValue:[_connection jid] forKey:@"to"];
        [_connection registerSelector:@selector(presenceSubscriptionRequestHandler:) ofObject:self withDict:params];
    }

    return self;
}

- (BOOL)presenceSubscriptionRequestHandler:(id)requestStanza 
{
    if ([[self delegate] respondsToSelector:@selector(didReceiveSubscriptionRequest:)])
        [[self delegate] performSelector:@selector(didReceiveSubscriptionRequest:) withObject:requestStanza];

    return YES;
}

- (CPArray)getRoster
{
    var uid         = [_connection getUniqueId:@"roster"];    
    var params      = [[CPDictionary alloc] init];
    var rosteriq    = [TNStropheStanza iqWithAttributes:{'id':uid, 'type':'get'}];
    
    [rosteriq addChildName:@"query" withAttributes:{'xmlns':Strophe.NS.ROSTER}];
    
    [params setValue:@"iq" forKey:@"name"];
    [params setValue:@"result" forKey:@"type"];
    [params setValue:uid forKey:@"id"];
    [_connection registerSelector:@selector(_didRosterReceived:) ofObject:self withDict:params];
    
    [_connection send:[rosteriq tree]];
}

- (BOOL)_didRosterReceived:(id) aStanza 
{
    var query = aStanza.getElementsByTagName('query')[0];
    var items = query.getElementsByTagName('item');
    var i;
    
    for (i = 0; i < items.length; i++)
    {
        if (items[i].getAttribute('name'))
            var nickname = items[i].getAttribute('name');
        
        if (![self doesRosterContainsJID:items[i].getAttribute('jid')])
        {
            var theGroup = (items[i].getElementsByTagName('group')[0] != null) ? $(items[i].getElementsByTagName('group')[0]).text() : "General";
            [self addGroupIfNotExists:theGroup];

        	var tnEntry = [TNStropheRosterEntry rosterEntryWithConnection:_connection jid:items[i].getAttribute('jid') group:theGroup];
            [tnEntry setNickname:nickname];

            [tnEntry getStatus];
            [tnEntry getVCard];
           	[[self entries] addObject:tnEntry];
        }
    	
    }
    
    //announce complete roster retrieved
    var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNStropheRosterRetrieved object:self];
    
    return YES;
}


// Contact management
- (TNStropheRosterEntry) getContactFromJID:(CPString)aJid
{
    
    for (i = 0; i < [[self entries] count]; i++) {
        //console.log("matching " + aJid +  " with " + [[[self entries] objectAtIndex:i] jid])
        if ([[[self entries] objectAtIndex:i] jid] == aJid)
            return [[self entries] objectAtIndex:i];
    }
    
    return nil; 
}

- (BOOL)doesRosterContainsJID:(CPString)aJid
{
    for (i = 0; i < [[self entries] count]; i++)
        if ([[[self entries] objectAtIndex:i] jid] == aJid)
            return YES;
    return NO;
}

- (void)addContact:(CPString)aJid withName:(CPString)aName inGroup:(CPString)aGroup
{
    if ([self doesRosterContainsJID:aJid] == YES)
        return;

    if (!aGroup)
           aGroup = "General";
    
    var uid = [_connection getUniqueId];
    var params = [[CPDictionary alloc] init];
    var addReq = [TNStropheStanza iqWithAttributes:{"type": "set", "id": uid}];
    
    [addReq addChildName:@"query" withAttributes: {'xmlns':Strophe.NS.ROSTER}];
    [addReq addChildName:@"item" withAttributes:{"jid": aJid, "name": aName}];
    [addReq addChildName:@"group" withAttributes:nil];
    [addReq addTextNode:aGroup];
    
    [_connection send:[addReq tree]];
    
    var tnEntry = [TNStropheRosterEntry rosterEntryWithConnection:_connection jid:aJid group:aGroup];
    [tnEntry setNickname:aName];
    [tnEntry getStatus];
    [tnEntry getVCard];
    
    [[self addGroupIfNotExists:aGroup]]
   	[[self entries] addObject:tnEntry];
   	
    var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNStropheRosterAddedContact object:tnEntry];
}

- (BOOL)removeContact:(CPString)aJid 
{
    var entry = [self getContactFromJID:aJid];
    if (entry) 
    {
        [[self entries] removeObject:entry];
        
        var uid = [_connection getUniqueId];
        var params = [[CPDictionary alloc] init];
        var removeReq = [TNStropheStanza iqWithAttributes:{"type": "set", "id": uid}];
        
        [removeReq addChildName:@"query" withAttributes: {'xmlns':Strophe.NS.ROSTER}];
        [removeReq addChildName:@"item" withAttributes:{'jid': aJid, 'subscription':"remove" }];
        
        [_connection send:[removeReq tree]];
        
        var center = [CPNotificationCenter defaultCenter];
        [center postNotificationName:TNStropheRosterRemovedContact object:entry];
    }
    
    return NO;
}

- (void)changeNickname:(CPString)aName forJID:(CPString)aJid
{
    var contact = [self getContactFromJID:aJid];
    [contact changeNickname:aName];
}

- (void) changeGroup:(CPString)aGroup forJID:(CPString)aJid
{
    
    var contact = [self getContactFromJID:aJid];
    [contact changeGroup:aGroup];
}


// group management
- (TNStropheRosterGroup)getGroupFromName:(CPString)aGroupName
{
    for (i = 0; i < [[self groups] count]; i++) {
        if ([[[self groups] objectAtIndex:i] name] == aGroupName)
        return [[self groups] objectAtIndex:i];
    }
    return nil;
}

- (BOOL)doesRosterContainsGroup:(CPString)aGroup
{
    var i;
    
    for (i = 0; i < [[self groups] count]; i++)
        if ([[self groups][i] name] == aGroup)
            return YES;
            
    return NO;
}

- (TNStropheRosterGroup) addGroup:(CPString)groupName
{
    var newGroup = [[TNStropheRosterGroup alloc] init];

    [newGroup setName:groupName];
    [[self groups] addObject:newGroup];
    
    var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNStropheRosterAddedGroup object:newGroup];
    
    return newGroup;
}

- (TNStropheRosterGroup) addGroupIfNotExists:(CPString)groupName
{
    if (![self doesRosterContainsGroup:groupName])
        return [self addGroup:groupName];
    return nil;
}

- (BOOL)removeGroup:(CPString)aGroupName
{
    // TODO
}

- (CPArray)getEntriesInGroup:(TNStropheRosterGroup)aGroup
{
    var ret = [[CPArray alloc] init];
    var i;
    
    for (i = 0; i < [[self entries] count]; i++)
    {
        if ([[[self entries] objectAtIndex:i] group] == aGroup)
            [ret addObject:[[self entries] objectAtIndex:i]];
    }
    return ret;
}


// Authorizations management
- (void)authorizeJID:(CPString)aJid 
{
    var resp = [TNStropheStanza presenceWithAttributes:{"from": [_connection jid], "type": "subscribed", "to": aJid}];
    [_connection send:[resp stanza]];
}

- (void)unauthorizeJID:(CPString)aJid
{
    var resp = [TNStropheStanza presenceWithAttributes:{"from": [_connection jid], "type": "unsubscribed", "to": aJid}];
    [_connection send:[resp stanza]];
}

- (void)askAuthorizationTo:(CPString)aJid
{
    var auth = [TNStropheStanza presenceWithAttributes:{"from": [_connection jid], "type": "subscribe", "to": aJid}];
    [_connection send:[auth stanza]];
}

- (void)answerAuthorizationRequest:(id)aStanza answer:(BOOL)theAnswer
{
    var requester = aStanza.getAttribute("from");
    
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


// disconnection
- (void) disconnect
{
    [_connection disconnect];
}
@end
