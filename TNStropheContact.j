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
@import "TNBase64Image.j"

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
    notification sent when contact receive its vCard
*/
TNStropheContactVCardReceivedNotification = @"TNStropheContactVCardReceivedNotification";
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
    CPArray             _messagesQueue  @accessors(property=messagesQueue);
    CPImage             _statusIcon     @accessors(property=statusIcon);
    CPNumber            _numberOfEvents @accessors(property=numberOfEvents);
    CPString            _domain         @accessors(property=domain);
    CPString            _fullJID        @accessors(property=fullJID);
    CPString            _groupName      @accessors(property=groupName);
    CPString            _JID            @accessors(property=JID);
    CPString            _nickname       @accessors(property=nickname);
    CPString            _nodeName       @accessors(property=nodeName);
    CPArray             _resources      @accessors(property=resources);
    CPString            _XMPPStatus     @accessors(property=XMPPStatus);
    CPString            _XMPPShow       @accessors(property=XMPPShow);
    CPString            _type           @accessors(property=type);
    CPString            _vCard          @accessors(property=vCard);
    TNBase64Image       _avatar         @accessors(property=avatar);
    TNStropheConnection _connection     @accessors(property=connection);
    
    CPImage             _imageOffline;
    CPImage             _imageOnline;
    CPImage             _imageAway;
    CPImage             _imageNewMessage;
    CPImage             _imageNewMessage;
    CPImage             _statusReminder;
    CPImage             _imageNewError;
    BOOL                _isComposing;
    
}

/*! create a contact using a given connection, JID and group
    @param aConnection TNStropheConnection to use
    @param aJID the JID of the contact
    @param aGroup the group of the contact
    
    @return an allocated and initialized TNStropheContact
*/
+ (TNStropheContact)contactWithConnection:(TNStropheConnection)aConnection JID:(CPString)aJID groupName:(CPString)aGroupName
{
    var contact = [[TNStropheContact alloc] initWithConnection:aConnection];
    [contact setJID:aJID];
    [contact setGroupName:aGroupName];
    [contact setNodeName:aJID.split('@')[0]];
    [contact setNickname:aJID.split('@')[0]];
    [contact setDomain: aJID.split('/')[0].split('@')[1]];
    
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
        _imageNewError      = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Error.png"]];
        
        _type               = @"contact";
        _statusIcon         = _imageOffline;
        _XMPPShow           = TNStropheContactStatusOffline;
        _connection         = aConnection;
        _messagesQueue      = [[CPArray alloc] init];
        _numberOfEvents     = 0;
        _isComposing        = NO;
        
        _resources = [CPArray array];
    }
    
    return self;
}

- (CPString)description
{
    return _nickname;
}

/*! probe the contact about its status
    You should never have to use this message if you are using TNStropheRoster
*/
- (void)getStatus
{
    var probe   = [TNStropheStanza presenceWithAttributes:{"from": [_connection JID], "type": "probe", "to": _JID}];
    var params  = [[CPDictionary alloc] init];
    
    [params setValue:@"presence" forKey:@"name"];
    [params setValue:_JID forKey:@"from"];
    [params setValue:{"matchBare": YES} forKey:@"options"];
    
    [_connection registerSelector:@selector(didReceivedStatus:) ofObject:self withDict:params];
    [_connection send:probe];
}

/*! executed on getStatus result. It populates the status of the contact
    and send notifications
    You should never have to use this method
    @param aStanza the response TNStropheStanza
*/
- (BOOL)didReceivedStatus:(TNStropheStanza)aStanza
{
    var center          = [CPNotificationCenter defaultCenter];
    var bundle          = [CPBundle bundleForClass:self];
    var fromJID         = [aStanza from];
    var resource        = [aStanza fromResource];
    var presenceType    = [aStanza type];
    
    _fullJID = fromJID;
    
    if (resource && (resource != @"") && ![_resources containsObject:resource])
        [_resources addObject:resource];
    
    if (presenceType == "error")
    {
        errorCode       = [[aStanza firstChildWithName:@"error"] valueForAttribute:@"code"];
        _XMPPShow       = TNStropheContactStatusOffline;
        _XMPPStatus     ="Error code: " + errorCode;
        _statusIcon     = _imageNewError;
        _statusReminder = _imageNewError;
        
        [center postNotificationName:TNStropheContactPresenceUpdatedNotification object:self];
        
        return NO;
    }
    if (presenceType == "unavailable")
    {
        
        [_resources removeObject:resource];
        CPLogConsole("contact become unavailable from resource: "+resource+". Resources left : " + _resources )
        
        if ([_resources count] == 0)
        {
            _XMPPShow       = TNStropheContactStatusOffline;
            _statusIcon     = _imageOffline;
            _statusReminder = _imageOffline;
            
            var presenceShow = [aStanza firstChildWithName:@"status"];
            if (presenceShow)
                _XMPPStatus = [presenceShow text];
        }
    }
    else if ((presenceType == "subscribe"))
    {
        _XMPPStatus = "Asking subscribtion"
    }
    else if ((presenceType == "subscribed"))
    {
        // ouaaah
    }
    else if (presenceType == "unsubscribe")
    {
        // kajfds
    }
    else if (presenceType == "unsubscribed")
    {
        _XMPPStatus = "Unauthorized";
    }
    else
    {
        _XMPPShow       = TNStropheContactStatusOnline;
        _statusIcon     = _imageOnline;
        _statusReminder = _imageOnline;
        
        _XMPPStatus = [aStanza firstChildWithName:@"show"];
        if (_XMPPStatus)
        {
            var textValue = [_XMPPStatus text];
            if (textValue == TNStropheContactStatusBusy) 
            {
                _XMPPShow       = TNStropheContactStatusBusy;
                _statusIcon     = _imageBusy
                _statusReminder = _imageBusy;
            }
            else if (textValue == TNStropheContactStatusAway) 
            {
                _XMPPShow       = TNStropheContactStatusAway;
                _statusIcon     = _imageAway
                _statusReminder = _imageAway;
            }
            else if (textValue == TNStropheContactStatusDND) 
            {
                _XMPPShow       = TNStropheContactStatusDND;
                _statusIcon     = _imageDND;
                _statusReminder = _imageDND;
            }
        }
        
        var presenceShow = [aStanza firstChildWithName:@"status"];
        if (presenceShow)
            _XMPPStatus = [presenceShow text];
        
        if ([aStanza firstChildWithName:@"x"] && [[aStanza firstChildWithName:@"x"] valueForAttribute:@"xmlns"] == @"vcard-temp:x:update")
            [self getVCard];
    }
    
    [center postNotificationName:TNStropheContactPresenceUpdatedNotification object:self];
    
    return YES;
}


/*! probe the contact's vCard
    you should never have to use this message if you are using TNStropheRoster
*/
- (void)getVCard
{
    var uid             = [_connection getUniqueId];
    var vcardStanza    = [TNStropheStanza iqWithAttributes:{"from": [_connection JID], "to": _JID, "type": "get", "id": uid}];
    
    [vcardStanza addChildName:@"vCard" withAttributes:{'xmlns': "vcard-temp"}];
    
    var params = [[CPDictionary alloc] init];
    [params setValue:_JID forKey:@"from"];
    [params setValue:uid forKey:@"id"];
    [params setValue:{"matchBare": YES} forKey:@"options"];

    [_connection registerSelector:@selector(didReceiveVCard:) ofObject:self withDict:params];
    [_connection send:vcardStanza];
}

/*! executed on getVCard result. Will post TNStropheContactVCardReceivedNotification
    and send notifications. If vCard contains a PHOTO node, it will set the avatar TNBase64Image
    property of the TNStropheContact
    You should never have to use this method
    @param aStanza the response TNStropheStanza
*/
- (BOOL)didReceiveVCard:(TNStropheStanza)aStanza
{
    var aVCard   = [aStanza firstChildWithName:@"vCard"];
    
    if (aVCard)
    {
        var center  = [CPNotificationCenter defaultCenter];
        var photoNode;
        
        _vCard = aVCard;
        
        if (photoNode = [aVCard firstChildWithName:@"PHOTO"])
        {
            var contentType = [[photoNode firstChildWithName:@"TYPE"] text];
            var data        = [[photoNode firstChildWithName:@"BINVAL"] text];
            
            _avatar = [TNBase64Image base64ImageWithContentType:contentType andData:data];
        }
        
        var name;
        if ((_nickname == _nodeName) && ([aVCard firstChildWithName:@"NAME"]))
        {
            _nickname = [[aVCard firstChildWithName:@"NAME"] text]
        }
        
        [center postNotificationName:TNStropheContactVCardReceivedNotification object:self];
    }
    
    return YES;
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
    
    
    var lastKnownResource = (_fullJID) ? _fullJID.split("/")[1] : nil;
    
    if (_fullJID && ![_resources containsObject:lastKnownResource])
        _fullJID = _fullJID.split("/")[0] + "/" + [_resources lastObject];
        
    [aStanza setTo:_fullJID];
    [aStanza setID:uid];
    
    if (aSelector)
    {
        ret = [_connection registerSelector:aSelector ofObject:anObject withDict:params];
    }
    
    [_connection send:aStanza];

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
    var uid         = [_connection getUniqueId];
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
    [params setValue:_JID forKey:@"from"];
    [params setValue:{"matchBare": YES} forKey:@"options"];
    
    [_connection registerSelector:@selector(_didReceivedMessage:) ofObject:self withDict:params];
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
        _statusIcon = _imageNewMessage;
        [_messagesQueue addObject:aStanza];
        [_connection playReceivedSound];
        
        _numberOfEvents++;
        [center postNotificationName:TNStropheContactMessageReceivedNotification object:self userInfo:userInfo];
    }
    
    return YES;
}


/*! send a message to the contact
    @param aMessage CPString containing the message
*/
- (void)sendMessage:(CPString)aMessage
{
    var uid             = [_connection getUniqueId];
    var messageStanza   = [TNStropheStanza messageWithAttributes:{"to":  _JID, "from": [_connection JID], "type": "chat"}];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];;
    
    [messageStanza addChildName:@"body"];
    [messageStanza addTextNode:aMessage];
    
    [_connection registerSelector:@selector(_didSentMessage:) ofObject:self withDict:params];
    [_connection send:messageStanza];
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
        var uid             = [_connection getUniqueId];
        var composingStanza = [TNStropheStanza messageWithAttributes:{"to": _JID, "from": [_connection JID], "type": "chat"}];
        var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];;


        [composingStanza addChildName:@"composing" withAttributes:{"xmlns": "http://jabber.org/protocol/chatstates"}];

        [_connection registerSelector:@selector(_didSentMessage:) ofObject:self withDict:params];
        [_connection send:composingStanza];
        _isComposing = YES;
    }
}

/*! this allows to send "paused" information to a user.
*/
- (void)sendComposePaused
{
    var uid             = [_connection getUniqueId];
    var pausedStanza   = [TNStropheStanza messageWithAttributes:{"to": _JID, "from": [_connection JID], "type": "chat"}];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];;
    
    [pausedStanza addChildName:@"paused" withAttributes:{"xmlns": "http://jabber.org/protocol/chatstates"}];
    
    [_connection registerSelector:@selector(_didSentMessage:) ofObject:self withDict:params];
    [_connection send:pausedStanza];

    _isComposing = NO;
}

/*! this allows to change the contact nickname. Will post TNStropheContactNicknameUpdatedNotification
    @param newNickname the new nickname
*/
- (void)changeNickname:(CPString)newNickname
{
    _nickname = newNickname;
    
    var stanza = [TNStropheStanza iqWithAttributes:{"type": "set"}];
    [stanza addChildName:@"query" withAttributes: {'xmlns':Strophe.NS.ROSTER}];
    [stanza addChildName:@"item" withAttributes:{"JID": _JID, "name": _nickname}];
    [stanza addChildName:@"group" withAttributes:nil];
    [stanza addTextNode:_groupName];

    [_connection send:stanza];
   
    var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNStropheContactNicknameUpdatedNotification object:self];
}

/*! this allows to change the group of the contact. Will post TNStropheContactGroupUpdatedNotification
*/
- (void)changeGroup:(TNStropheGroup)newGroup
{
    var stanza = [TNStropheStanza iqWithAttributes:{"type": "set"}];
    [stanza addChildName:@"query" withAttributes: {'xmlns':Strophe.NS.ROSTER}];
    [stanza addChildName:@"item" withAttributes:{"JID": _JID, "name": _nickname}];
    [stanza addChildName:@"group" withAttributes:nil];
    [stanza addTextNode:[newGroup name]];
    
    [_connection send:stanza];
    
    _groupName = [newGroup name];
    
    var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNStropheContactGroupUpdatedNotification object:self];
}

- (void)changeGroupName:(CPString)aNewName
{
    var center = [CPNotificationCenter defaultCenter];
    var stanza = [TNStropheStanza iqWithAttributes:{"type": "set"}];
    
    [stanza addChildName:@"query" withAttributes: {'xmlns':Strophe.NS.ROSTER}];
    [stanza addChildName:@"item" withAttributes:{"JID": _JID, "name": _nickname}];
    [stanza addChildName:@"group" withAttributes:nil];
    [stanza addTextNode:aNewName];
    
    [_connection send:stanza];
    
    _groupName = aNewName;
    
    [center postNotificationName:TNStropheContactGroupUpdatedNotification object:self];
}

/*! return the last TNStropheStanza message in the message queue and remove it form the queue.
    Will post TNStropheContactMessageTreatedNotification.
    
    @return TNStropheStanza the last message in queue
*/
- (TNStropheStanza)popMessagesQueue
{
    if ([_messagesQueue count] == 0)
        return Nil;
        
    var lastMessage = [_messagesQueue objectAtIndex:0];
    var center = [CPNotificationCenter defaultCenter];

    _numberOfEvents--;
    _statusIcon = _statusReminder;
    
    [_messagesQueue removeObjectAtIndex:0];
    
    [center postNotificationName:TNStropheContactMessageTreatedNotification object:self];
    
    return lastMessage;
}

/*! purge all message in queue. Will post TNStropheContactMessageTreatedNotification
*/
- (void)freeMessagesQueue
{
    var center = [CPNotificationCenter defaultCenter];

    _numberOfEvents = 0;
    _statusIcon = _statusReminder;
    
    [_messagesQueue removeAllObjects];
    
    [center postNotificationName:TNStropheContactMessageTreatedNotification object:self];
}

/*! subscribe to the contact
*/
- (void)subscribe
{
    var resp = [TNStropheStanza presenceWithAttributes:{"from": [_connection JID], "type": "subscribed", "to": _JID}];
    [_connection send:resp];
}

/*! unsubscribe from the contact
*/
- (void)unsubscribe
{
    var resp = [TNStropheStanza presenceWithAttributes:{"from": [_connection JID], "type": "unsubscribed", "to": _JID}];
    [_connection send:resp];
}

/*! ask subscribtion to the contact
*/
- (void)askSubscription
{
    var auth    = [TNStropheStanza presenceWithAttributes:{"type": "subscribe", "to": _JID}];   
    [_connection send:auth];
}

@end



@implementation TNStropheContact (codingCompliant)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    
    if (self)
    {
        _JID            = [aCoder decodeObjectForKey:@"_JID"];
        _nodeName       = [aCoder decodeObjectForKey:@"_nodeName"];
        _domain         = [aCoder decodeObjectForKey:@"_domain"];
        _groupName      = [aCoder decodeObjectForKey:@"_groupName"];
        _nickname       = [aCoder decodeObjectForKey:@"_nickname"];
        _XMPPStatus     = [aCoder decodeObjectForKey:@"_XMPPStatus"];
        _resources      = [aCoder decodeObjectForKey:@"_resources"];
        _XMPPShow       = [aCoder decodeObjectForKey:@"_XMPPShow"];
        _statusIcon     = [aCoder decodeObjectForKey:@"_statusIcon"];
        _type           = [aCoder decodeObjectForKey:@"_type"];
        _fullJID        = [aCoder decodeObjectForKey:@"_fullJID"];
        _vCard          = [aCoder decodeObjectForKey:@"_vCard"];
        _messageQueue   = [aCoder decodeObjectForKey:@"_messagesQueue"];
        _numberOfEvents = [aCoder decodeObjectForKey:@"_numberOfEvents"];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_JID forKey:@"_JID"];
    [aCoder encodeObject:_nodeName forKey:@"_nodeName"];
    [aCoder encodeObject:_groupName forKey:@"_groupName"];
    [aCoder encodeObject:_domain forKey:@"_domain"];
    [aCoder encodeObject:_nickname forKey:@"_nickname"];
    [aCoder encodeObject:_XMPPStatus forKey:@"_XMPPStatus"];
    [aCoder encodeObject:_XMPPShow forKey:@"_XMPPShow"];
    [aCoder encodeObject:_type forKey:@"_type"];
    [aCoder encodeObject:_statusIcon forKey:@"_statusIcon"];
    [aCoder encodeObject:_messagesQueue forKey:@"_messagesQueue"];
    [aCoder encodeObject:_numberOfEvents forKey:@"_numberOfEvents"];

    if (_resources)
        [aCoder encodeObject:_resources forKey:@"_resources"];
    
    if (_fullJID)
        [aCoder encodeObject:_fullJID forKey:@"_fullJID"];
    if (_vCard)
        [aCoder encodeObject:_vCard forKey:@"_vCard"];
}
@end