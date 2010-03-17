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

/*! 
    @global
    @group TNStropheContactStatus
    Status away
*/
TNStropheContactStatusAway       = @"away";
/*! 
    @global
    @group TNStropheContactStatus
    Status Busy
*/
TNStropheContactStatusBusy       = @"xa";
/*! 
    @global
    @group TNStropheContactStatus
    Status Do Not Disturb
*/
TNStropheContactStatusDND        = @"dnd";
/*! 
    @global
    @group TNStropheContactStatus
    Status offline
*/
TNStropheContactStatusOffline    = @"offline";
/*! 
    @global
    @group TNStropheContactStatus
    Status online
*/
TNStropheContactStatusOnline     = @"online";


/*! 
    @global
    @group TNStropheContact
    notification sent when nickname of contact has been updated
*/
TNStropheContactNicknameUpdatedNotification = @"TNStropheContactNicknameUpdatedNotification";
/*! 
    @global
    @group TNStropheContact
    notification sent when group of contact have been updated
*/
TNStropheContactGroupUpdatedNotification    = @"TNStropheContactGroupUpdatedNotification";
/*! 
    @global
    @group TNStropheContact
    notification sent when presence status of contact has been updated
*/
TNStropheContactPresenceUpdatedNotification = @"TNStropheContactPresenceUpdatedNotification";
/*! 
    @global
    @group TNStropheContact
    notification sent when contact receive a message
*/
TNStropheContactMessageReceivedNotification = @"TNStropheContactMessageReceivedNotification";
/*! 
    @global
    @group TNStropheContact
    notification sent when all messages in messages queue have been treated
*/
TNStropheContactMessageTreatedNotification  = @"TNStropheContactMessageTreatedNotification";
/*! 
    @global
    @group TNStropheContact
    notification sent when message have been sent to the contact
*/
TNStropheContactMessageSentNotification     = @"TNStropheContactMessageSentNotification";
/*! 
    @global
    @group TNStropheContact
    notification sent when stanza have been sent to the contact
*/
TNStropheContactStanzaSentNotification      = @"TNStropheContactStanzaSentNotification"


/*! 
    @global
    @group TNStropheContactMessage
    notification sent when contact is composing a message
*/
TNStropheContactMessageComposing            = @"TNStropheContactMessageComposing";
/*! 
    @global
    @group TNStropheContactMessage
    notification sent when contact stops composing a message
*/
TNStropheContactMessagePaused               = @"TNStropheContactMessagePaused";
/*! 
    @global
    @group TNStropheContactMessage
    notification sent when chat with contact is active
*/
TNStropheContactMessageActive               = @"TNStropheContactMessageActive";
/*! 
    @global
    @group TNStropheContactMessage
    notification sent when chat with contact is unactive
*/
TNStropheContactMessageInactive             = @"TNStropheContactMessageInactive";
/*! 
    @global
    @group TNStropheContactMessage
    notification sent when contact leave chat (close window most of the time)
*/
TNStropheContactMessageGone                 = @"TNStropheContactMessageGone";



/*! @ingroup strophecappuccino
    this is an implementation of a XMPP Contact
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
    CPNumber            numberOfEvents  @accessors;
    TNStropheConnection connection      @accessors;
    
    CPImage             _imageOffline;
    CPImage             _imageOnline;
    CPImage             _imageAway;
    CPImage             _imageNewMessage;
    CPImage             _imageNewMessage;
    CPImage             _statusReminder;
    BOOL                _isComposing;
    
}

/*! create a contact using a given connection, jid and group
    @param aConnection TNStropheConnection to use
    @param aJid the jid of the contact
    @param aGroup the group of the contact
    
    @return an allocated and initialized TNStropheContact
*/
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

/*! init a TNStropheContact with a given connection
    @param aConnection TNStropheConnection to use
    
    @return an initialized TNStropheContact
*/
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
        [self setStatusIcon:_imageOffline];
        [self setStatus:TNStropheContactStatusOffline];

        [self setConnection:aConnection];
        [self setMessagesQueue:[[CPArray alloc] init]];
        [self setNumberOfEvents:0];
        
        _isComposing = NO;
    }
    
    return self;
}

- (CPString)description
{
    return [self nickname];
}

/*! probe the contact about its status
    You should never have to use this message
*/
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

/*! executed on getStatus result. It populates the status of the contact
    and send notifications
    You should never have to use this method
    @param aStanza the response TNStropheStanza
*/
- (BOOL)didReceivedStatus:(TNStropheStanza)aStanza
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

/*! probe the contact's vCard
    you should never have to use this message
*/
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

/*! executed on getVCard result
    and send notifications
    You should never have to use this method
    @param aStanza the response TNStropheStanza
*/
- (BOOL)didReceivedVCard:(TNStropheStanza)aStanza
{
    var vCard   = [aStanza firstChildWithName:@"vCard"];
    
    if (vCard)
    {
        [self setVCard:vCard];
    }
    
    return NO;
}

/*! send a TNStropheStanza to the contact. From, ant To value are rewritten. This message uses a given stanza id
    in order to use it if you need. You should mostly use the 
    You should never have to use the method sendStanza:andRegisterSelector:ofObject: in most of the case
    
    @param aStanza the TNStropheStanza to send to the contact
    @param aSelector the selector to perform on response
    @param anObject the object receiving the selector
    @param anId the specific stanza ID to use
    
    @return the associated registration id for the selector
*/
- (id)sendStanza:(TNStropheStanza)aStanza andRegisterSelector:(SEL)aSelector ofObject:(id)anObject withSpecificID:(id)anId
{
    var uid     = anId
    var params  = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];;
    var ret     = nil;
    
    [aStanza setTo:[self fullJID]];
    [aStanza setID:uid];
    
    if (aSelector)
    {
        ret = [[self connection] registerSelector:aSelector ofObject:anObject withDict:params];
    }
    
    [[self connection] send:aStanza];

    return ret;
}

/*! send a TNStropheStanza to the contact. From, ant To value are rewritten.
    
    @param aStanza the TNStropheStanza to send to the contact
    @param aSelector the selector to perform on response
    @param anObject the object receiving the selector
    
    @return the associated registration id for the selector
*/
- (id)sendStanza:(TNStropheStanza)aStanza andRegisterSelector:(SEL)aSelector ofObject:(id)anObject
{
    var uid         = [[self connection] getUniqueId];
    var center      = [CPNotificationCenter defaultCenter];
    var userInfo    = [CPDictionary dictionaryWithObjectsAndKeys:aStanza, @"stanza"];
    
    var ret = [self sendStanza:aStanza andRegisterSelector:aSelector ofObject:anObject withSpecificID:uid]
    
    [center postNotificationName:TNStropheContactStanzaSentNotification object:self userInfo:userInfo];
    
    return ret
}

/*! register the contact to listen incoming messages
    you should never have to use this message if you use TNStropheRoster
*/
- (void)getMessages
{
    var params = [[CPDictionary alloc] init];

    [params setValue:@"message" forKey:@"name"];
    [params setValue:[self jid] forKey:@"from"];
    [params setValue:{"matchBare": YES} forKey:@"options"];
    
    [[self connection] registerSelector:@selector(_didReceivedMessage:) ofObject:self withDict:params];
}

/*! message sent when contact listening its message (using getMessages) and send appropriates notifications
    you should never have to use this message.
    
    @param aStanza the response stanza
    
    @return YES in order to listen again
*/
- (BOOL)_didReceivedMessage:(id)aStanza
{
    var center      = [CPNotificationCenter defaultCenter];
    var userInfo    = [CPDictionary dictionaryWithObjectsAndKeys:aStanza, @"stanza", [CPDate date], @"date"];

    if ([aStanza containsChildrenWithName:@"composing"])
        [center postNotificationName:TNStropheContactMessageComposing object:self userInfo:userInfo];
    
    if ([aStanza containsChildrenWithName:@"paused"])
        [center postNotificationName:TNStropheContactMessagePaused object:self userInfo:userInfo];
        
    if ([aStanza containsChildrenWithName:@"active"])
        [center postNotificationName:TNStropheContactMessageActive object:self userInfo:userInfo];
    
    if ([aStanza containsChildrenWithName:@"inactive"])
        [center postNotificationName:TNStropheContactMessageInactive object:self userInfo:userInfo];
    
    if ([aStanza containsChildrenWithName:@"gone"])
        [center postNotificationName:TNStropheContactMessageGone object:self userInfo:userInfo];

    if ([aStanza containsChildrenWithName:@"body"])
    {
        [self setStatusIcon:_imageNewMessage];
        [[self messagesQueue] addObject:aStanza];
        [[self connection] playReceivedSound];
        
        numberOfEvents++;
        [center postNotificationName:TNStropheContactMessageReceivedNotification object:self userInfo:userInfo];
    }
    
    return YES;
}


/*! send a message to the contact
    @param aMessage CPString containing the message
*/
- (void)sendMessage:(CPString)aMessage
{
    var uid             = [connection getUniqueId];
    var messageStanza   = [TNStropheStanza messageWithAttributes:{"to":  [self jid], "from": [[self connection] jid], "type": "chat"}];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];;
    
    [messageStanza addChildName:@"body"];
    [messageStanza addTextNode:aMessage];
    
    [[self connection] registerSelector:@selector(_didSentMessage:) ofObject:self withDict:params];
    [[self connection] send:messageStanza];
}

/*! message sent when a message has been sent. It posts appropriate notification with userInfo
    containing the stanza under the key "stanza"
    you should never use this message
    
    @param aStanza the response stanza
    
    @return NO to remove the registering of the selector
*/
- (BOOL)_didSentMessage:(id)aStanza
{
    var center      = [CPNotificationCenter defaultCenter];
    var userInfo    = [CPDictionary dictionaryWithObjectsAndKeys:aStanza, @"stanza"];
    
    [center postNotificationName:TNStropheContactMessageSentNotification object:self userInfo:userInfo];
    
    return NO;
}

/*! this allows to send "composing" information to a user. This will never send "paused".
    you have to handle a timer if you want to automatically send pause after a while.
*/
- (void)sendComposing
{
    if (!_isComposing)
    {
        var uid             = [connection getUniqueId];
        var composingStanza = [TNStropheStanza messageWithAttributes:{"to":  [self jid], "from": [[self connection] jid], "type": "chat"}];
        var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];;


        [composingStanza addChildName:@"composing" withAttributes:{"xmlns": "http://jabber.org/protocol/chatstates"}];

        [[self connection] registerSelector:@selector(_didSentMessage:) ofObject:self withDict:params];
        [[self connection] send:composingStanza];
        _isComposing = YES;
    }
}

/*! this allows to send "paused" information to a user.
*/
- (void)sendComposePaused
{
    var uid             = [connection getUniqueId];
    var pausedStanza   = [TNStropheStanza messageWithAttributes:{"to":  [self jid], "from": [[self connection] jid], "type": "chat"}];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];;
    
    [pausedStanza addChildName:@"paused" withAttributes:{"xmlns": "http://jabber.org/protocol/chatstates"}];
    
    [[self connection] registerSelector:@selector(_didSentMessage:) ofObject:self withDict:params];
    [[self connection] send:pausedStanza];

    _isComposing = NO;
}

/*! this allows to change the contact nickname. Will post TNStropheContactNicknameUpdatedNotification
    @param newNickname the new nickname
*/
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

/*! this allows to change the group of the contact. Will post TNStropheContactGroupUpdatedNotification
*/
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

/*! return the last TNStropheStanza message in the message queue and remove it form the queue.
    Will post TNStropheContactMessageTreatedNotification.
    
    @return TNStropheStanza the last message in queue
*/
- (TNStropheStanza)popMessagesQueue
{
    if ([[self messagesQueue] count] == 0)
        return Nil;
        
    var lastMessage = [[self messagesQueue] objectAtIndex:0];
    var center = [CPNotificationCenter defaultCenter];
    numberOfEvents--;
    
    [self setStatusIcon:_statusReminder];
    
    [[self messagesQueue] removeObjectAtIndex:0];
    
    [center postNotificationName:TNStropheContactMessageTreatedNotification object:self];
    
    return lastMessage;
}

/*! purge all message in queue. Will post TNStropheContactMessageTreatedNotification
*/
- (void)freeMessagesQueue
{
    var center = [CPNotificationCenter defaultCenter];
    numberOfEvents = 0;

    [self setStatusIcon:_statusReminder];
    
    [[self messagesQueue] removeAllObjects];
    
    [center postNotificationName:TNStropheContactMessageTreatedNotification object:self];
}

/*! subscribe to the contact
*/
- (void)subscribe
{
    var resp = [TNStropheStanza presenceWithAttributes:{"from": [[self connection] jid], "type": "subscribed", "to": [self jid]}];
    [[self connection] send:resp];
}

/*! unsubscribe from the contact
*/
- (void)unsubscribe
{
    var resp = [TNStropheStanza presenceWithAttributes:{"from": [[self connection] jid], "type": "unsubscribed", "to": [self jid]}];
    [[self connection] send:resp];
}

/*! ask subscribtion to the contact
*/
- (void)askSubscription
{
    var auth    = [TNStropheStanza presenceWithAttributes:{"type": "subscribe", "to": [self jid]}];   
    [[self connection] send:auth];
}

@end



@implementation TNStropheContact (codingCompliant)
{
    
}
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    
    if (self)
    {
        //[self setConnection:[aCoder decodeObjectForKey:@"connection"]];
        [self setJid:[aCoder decodeObjectForKey:@"jid"]];
        [self setNodeName:[aCoder decodeObjectForKey:@"nodeName"]];
        [self setDomain:[aCoder decodeObjectForKey:@"domain"]];
        [self setNickname:[aCoder decodeObjectForKey:@"nickname"]];

        
        [self setResource:[aCoder decodeObjectForKey:@"resource"]];
            
        [self setStatus:[aCoder decodeObjectForKey:@"status"]];
        [self setStatusIcon:[aCoder decodeObjectForKey:@"statusIcon"]];
        [self setGroup:[aCoder decodeObjectForKey:@"group"]];
        [self setType:[aCoder decodeObjectForKey:@"type"]];
        
        
        [self setFullJID:[aCoder decodeObjectForKey:@"fullJID"]];
        
        
        [self setVCard:[aCoder decodeObjectForKey:@"vCard"]];

        [self setMessageQueue:[aCoder decodeObjectForKey:@"messagesQueue"]];
        [self setNumberOfEvents:[aCoder decodeObjectForKey:@"numberOfEvents"]];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    // if ([super respondsToSelector:@selector(encodeWithCoder:)])
    //     [super encodeWithCoder:aCoder];
    
    //[aCoder encodeObject:connection forKey:@"connection"];
    [aCoder encodeObject:jid forKey:@"jid"];
    [aCoder encodeObject:nodeName forKey:@"nodeName"];
    [aCoder encodeObject:domain forKey:@"domain"];
    [aCoder encodeObject:nickname forKey:@"nickname"];
    if ([self resource])
        [aCoder encodeObject:resource forKey:@"resource"];
    [aCoder encodeObject:status forKey:@"status"];
    [aCoder encodeObject:group forKey:@"group"];
    [aCoder encodeObject:type forKey:@"type"];
    
    if ([self fullJID])
        [aCoder encodeObject:fullJID forKey:@"fullJID"];
    
    if ([self vCard])
        [aCoder encodeObject:vCard forKey:@"vCard"];
        
    [aCoder encodeObject:statusIcon forKey:@"statusIcon"];
    [aCoder encodeObject:messagesQueue forKey:@"messagesQueue"];
    [aCoder encodeObject:numberOfEvents forKey:@"numberOfEvents"];
}
@end

@end