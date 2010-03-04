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
TNStropheContactNicknameUpdatedNotification = @"TNStropheContactNicknameUpdatedNotification";
TNStropheContactGroupUpdatedNotification    = @"TNStropheContactGroupUpdatedNotification";
TNStropheContactPresenceUpdatedNotification = @"TNStropheContactPresenceUpdatedNotification";
TNStropheContactMessageReceivedNotification = @"TNStropheContactMessageReceivedNotification";
TNStropheContactMessageTreatedNotification  = @"TNStropheContactMessageTreatedNotification";
TNStropheContactMessageSentNotification     = @"TNStropheContactMessageSentNotification";

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
    
    CPImage             _imageOffline;
    CPImage             _imageOnline;
    CPImage             _imageAway;
    CPImage             _imageNewMessage;
    CPImage             _imageNewMessage;
    CPImage             _statusReminder;
}

+ (TNStropheContact)contactWithConnection:(TNStropheConnection)aConnection jid:(CPString)aJid group:(CPString)aGroup
{
    var contact = [[TNStropheContact alloc] initWithConnection:aConnection];
    [contact setGroup:aGroup];
	[contact setJid:aJid];
	[contact setNodeName:aJid.split('@')[0]];
	[contact setNickname:aJid.split('@')[0]];
	[contact setResource:aJid.split('/')[1]];
	[contact setDomain: aJid.split('/')[0].split('@')[1]];
	
    return contact;
}

- (id)initWithConnection:(TNStropheConnection)aConnection
{
    if (self = [super init])
    {
        var bundle = [CPBundle bundleForClass:[self class]];

        _imageOffline       = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Offline.png"]];
        _imageOnline        = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Available.png"]];
        _imageBusy          = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Away.png"]];
        _imageAway          = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Idle.png"]];
        _imageDND           = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Blocked.png"]];
        _imageNewMessage    = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"NewMessage.png"]];
        
        [self setType:@"contact"];
        [self setValue:_imageOffline forKeyPath:@"statusIcon"];
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
    [params setValue:{"matchBare": YES} forKey:@"options"];
    
    [connection registerSelector:@selector(didReceivedStatus:) ofObject:self withDict:params];
    [[self connection] send:probe];
}

- (BOOL)didReceivedStatus:(id)aStanza
{   
    var bundle          = [CPBundle bundleForClass:self];
    var fromJID         = [aStanza getFrom];
    var resource        = [aStanza getFromResource];
    var presenceType    = [aStanza getType];
    
    [self setFullJID:fromJID];
    [self setResource:resource];
    

    if (presenceType == "unavailable") 
    {   
        [self setValue:TNStropheContactStatusOffline forKey:@"status"];
        [self setValue:_imageOffline forKeyPath:@"statusIcon"];
        _statusReminder = _imageOffline;
    }
    else
    {
        [self setValue:TNStropheContactStatusOnline forKey:@"status"];
        [self setValue:_imageOnline forKeyPath:@"statusIcon"];
        _statusReminder = _imageOnline;
        
        show = [aStanza firstChildWithName:@"show"];
        if (show)
        {
            var textValue = [show text];
            if (textValue == TNStropheContactStatusBusy) 
            {
                [self setValue:TNStropheContactStatusBusy forKey:@"status"];
                [self setValue:_imageBusy forKeyPath:@"statusIcon"];
                _statusReminder = _imageBusy;
            }
            else if (textValue == TNStropheContactStatusAway) 
            {
                [self setValue:TNStropheContactStatusAway forKey:@"status"];
                [self setValue:_imageAway forKeyPath:@"statusIcon"];
                _statusReminder = _imageAway;
            }
            else if (textValue == TNStropheContactStatusDND) 
            {
                [self setValue:TNStropheContactStatusDND forKey:@"status"];
                [self setValue:_imageDND forKeyPath:@"statusIcon"];
                _statusReminder = _imageDND;
            }
        }
    }
    
    [self getVCard];
    
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
    [connection send:vcard_stanza];
}

- (BOOL)didReceivedVCard:(id)aStanza
{
    var vCard   = [aStanza firstChildWithName:@"vCard"];
    
    if (vCard)
    {
        [self setVCard:vCard];
    }
    
    return NO;
}

- (void)getMessages
{
    var params = [[CPDictionary alloc] init];

    [params setValue:@"message" forKey:@"name"];
    [params setValue:[self jid] forKey:@"from"];
    [params setValue:{"matchBare": YES} forKey:@"options"];
    
    [[self connection] registerSelector:@selector(didReceivedMessage:) ofObject:self withDict:params];
}

- (BOOL)didReceivedMessage:(id)aStanza
{
    var center      = [CPNotificationCenter defaultCenter];
    var userInfo    = [CPDictionary dictionaryWithObjectsAndKeys:aStanza, @"stanza"];
    
    [[self messagesQueue] addObject:aStanza];
    
    [self setStatusIcon:_imageNewMessage];
    
    [center postNotificationName:TNStropheContactMessageReceivedNotification object:self userInfo:userInfo];

    [[self connection] playReceivedSound];

    return YES;
}

- (void)sendMessage:(CPString)aMessage
{
    var uid             = [connection getUniqueId];
    var messageStanza   = [TNStropheStanza messageWithAttributes:{"to":  [self jid], "from": [[self connection] jid], "type": "chat"}];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];;
    
    [messageStanza addChildName:@"body"];
    [messageStanza addTextNode:aMessage];
    
    [[self connection] registerSelector:@selector(didSentMessage:) ofObject:self withDict:params];
    [[self connection] send:messageStanza];
}

- (BOOL)didSentMessage:(id)aStanza
{
    var center      = [CPNotificationCenter defaultCenter];
    var userInfo    = [CPDictionary dictionaryWithObjectsAndKeys:aStanza, @"stanza"];
    
    [center postNotificationName:TNStropheContactMessageSentNotification object:self userInfo:userInfo];
    
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

    [[self connection] send:stanza];
   
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
    
    [[self connection] send:stanza];
    
    var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNStropheContactGroupUpdatedNotification object:self];
}

- (TNStropheStanza)popMessagesQueue
{
    if ([[self messagesQueue] count] == 0)
        return Nil;
        
    var lastMessage = [[self messagesQueue] objectAtIndex:0];
    var center = [CPNotificationCenter defaultCenter];
    
    
    [self setStatusIcon:_statusReminder];
    
    [[self messagesQueue] removeObjectAtIndex:0];
    
    [center postNotificationName:TNStropheContactMessageTreatedNotification object:self];
    
    return lastMessage;
}

- (void)freeMessagesQueue
{
    var center = [CPNotificationCenter defaultCenter];


    [self setStatusIcon:_statusReminder];
    
    [[self messagesQueue] removeAllObjects];
    
    [center postNotificationName:TNStropheContactMessageTreatedNotification object:self];
}


@end