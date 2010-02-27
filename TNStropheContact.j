/*  
 * TNStropheContact.j
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

@import "TNStropheGroup.j"
@import "TNStropheConnection.j"

// Presence status
TNStropheContactStatusAway       = @"away";
TNStropheContactStatusBusy       = @"xa";
TNStropheContactStatusDND        = @"dnd";
TNStropheContactStatusOffline    = @"offline";
TNStropheContactStatusOnline     = @"online";

// Contact updates notification
TNStropheContactNicknameUpdatedNotification  = @"TNStropheContactNicknameUpdatedNotification";
TNStropheContactGroupUpdatedNotification     = @"TNStropheContactGroupUpdatedNotification";
TNStropheContactPresenceUpdatedNotification  = @"TNStropheContactPresenceUpdatedNotification";
TNStropheContactMessageReceivedNotification  = @"TNStropheContactMessageReceivedNotification";
TNStropheContactMessageSentNotification      = @"TNStropheContactMessageSentNotification";

/*! @ingroup strophecappuccino
    this is an implementation of a basic XMPP Contact
*/
@implementation TNStropheContact: CPObject
{
    CPString            jid             @accessors;
    CPString            nodeName        @accessors;
    CPString            domain          @accessors;
    CPString            nickname        @accessors;
    CPString            resource        @accessors;
    CPString            status          @accessors;
    CPString            group           @accessors;
    CPString            type            @accessors;
    CPString            fullJID         @accessors;
    CPString            vCard           @accessors;
    CPImage             statusIcon      @accessors;
    CPArray             messagesQueue   @accessors;
    TNStropheConnection connection      @accessors;
}

+ (TNStropheContact)contactWithConnection:(TNStropheConnection)aConnection jid:(CPString)aJid group:(CPString)aGroup
{
    var contact = [[TNStropheContact alloc] initWithConnection:aConnection];
    [contact setGroup:aGroup];
	[contact setJid:aJid];
	[contact setNodeName:aJid.split('@')[0]];
	[contact setNickname:aJid.split('@')[0]];
	[contact setResource: aJid.split('/')[1]];
	[contact setDomain: aJid.split('/')[0].split('@')[1]];
	
    return contact;
}

- (id)initWithConnection:(TNStropheConnection)aConnection
{
    if (self = [super init])
    {
        var bundle = [CPBundle bundleForClass:[self class]];
        
        [self setType:@"contact"];
        [self setStatusIcon:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"StatusIcons/Offline.png"] size:CGSizeMake(16, 16)]];
        [self setValue:[bundle pathForResource:@"StatusIcons/Offline.png"] forKeyPath:@"statusIcon.filename"];
        [self setStatus:TNStropheContactStatusOffline];

        [self setConnection:aConnection];
        [self setMessagesQueue:[[CPArray alloc] init]];
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
    
    [connection registerSelector:@selector(didReceivedStatus:) ofObject:self withDict:params];
    
    [[self connection] send:[probe stanza]];
}

- (BOOL)didReceivedStatus:(id)aStanza
{
    // update resource
    [self setFullJID:aStanza.getAttribute("from")];
    [self setResource:aStanza.getAttribute("from").split('/')[1]];
    
    var bundle = [CPBundle bundleForClass:self];
    
    if (aStanza.getAttribute("type") == "unavailable") 
    {   
        [self setValue:TNStropheContactStatusOffline forKey:@"status"];
        [self setValue:[bundle pathForResource:@"StatusIcons/Offline.png"] forKeyPath:@"statusIcon.filename"];
    }
    else
    {
        show = aStanza.getElementsByTagName("show")[0];

        [self setValue:TNStropheContactStatusOnline forKey:@"status"];
        [self setValue:[bundle pathForResource:@"StatusIcons/Available.png"] forKeyPath:@"statusIcon.filename"];

        if (show)
        {
            if ($(show).text() == TNStropheContactStatusBusy) 
            {
                [self setValue:TNStropheContactStatusBusy forKey:@"status"];
                [self setValue:[bundle pathForResource:@"StatusIcons/Away.png"] forKeyPath:@"statusIcon.filename"];
            }
            else if ($(show).text() == TNStropheContactStatusAway) 
            {
                [self setValue:TNStropheContactStatusAway forKey:@"status"];
                [self setValue:[bundle pathForResource:@"StatusIcons/Idle.png"] forKeyPath:@"statusIcon.filename"];
            }
            else if ($(show).text() == TNStropheContactStatusDND) 
            {
                [self setValue:TNStropheContactStatusDND forKey:@"status"];
                [self setValue:[bundle pathForResource:@"StatusIcons/Blocked.png"] forKeyPath:@"statusIcon.filename"];
            }
        }
    }

    var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNStropheContactPresenceUpdatedNotification object:self];
    
    return YES;
}

- (void)getVCard
{
    var uid = [connection getUniqueId];
    var vcard_stanza = [TNStropheStanza stanzaWithName:@"iq" andAttributes:{"from": [connection jid], "to": [self jid], "type": "get", "id": uid}];
    [vcard_stanza addChildName:@"vCard" withAttributes:{'xmlns': "vcard-temp"}];
    
    var params = [[CPDictionary alloc] init];
    [params setValue:uid forKey:@"id"];

    [connection registerSelector:@selector(didReceivedVCard:) ofObject:self withDict:params];
    [connection send:[vcard_stanza tree]];
}

- (BOOL)didReceivedVCard:(id)aStanza
{
    var vCard = aStanza.getElementsByTagName("vCard");
    
    if (vCard)
    {
        [self setVCard:vCard[0]];
    }
    
    
    return NO;
}

- (void)getMessages
{
    var params = [[CPDictionary alloc] init];

    [params setValue:@"message" forKey:@"name"];
    [params setValue:[self jid] forKey:@"from"];
    [params setValue:{"matchBare": true} forKey:@"options"];
    
    [[self connection] registerSelector:@selector(didReceivedMessage:) ofObject:self withDict:params];
}

- (BOOL)didReceivedMessage:(id)aStanza
{
    var stanza = [[TNStropheStanza alloc] initFromStropheStanza:aStanza];
    var center = [CPNotificationCenter defaultCenter];
    
    [center postNotificationName:TNStropheContactMessageReceivedNotification object:stanza];
    [[self messagesQueue] addObject:stanza];
    
    return YES;
}

- (void)sendMessage:(CPString)aMessage
{
    var uid             = [connection getUniqueId];
    var messageStanza   = [TNStropheStanza messageWithAttributes:{"to":  [self fullJID], "from": [[self connection] jid], "type": "chat"}];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];;
    
    [messageStanza addChildName:@"body"];
    [messageStanza addTextNode:aMessage];
    
    [[self connection] registerSelector:@selector(didSentMessage:) ofObject:self withDict:params];
    [[self connection] send:[messageStanza tree]];
}

- (BOOL)didSentMessage:(id)aStanza
{
    var stanza = [[TNStropheStanza alloc] initFromStropheStanza:aStanza];
    var center = [CPNotificationCenter defaultCenter];
    
    [center postNotificationName:TNStropheContactMessageSentNotification object:stanza];
    
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
    [center postNotificationName:TNStropheContactNicknameUpdatedNotification object:self];
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
    [center postNotificationName:TNStropheContactGroupUpdatedNotification object:self];
}

- (TNStropheStanza)popMessagesQueue
{
    var lastMessage = [[self messagesQueue] lastObject];
    
    [[self messagesQueue] removeLastObject];
    
    return lastMessage;
}

- (void)freeMessageQueue
{
    [[self messagesQueue] removeAllObjects];
}


@end