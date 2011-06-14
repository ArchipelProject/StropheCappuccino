/*
 * TNStropheContact.j
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
@import "TNStropheGroup.j"
@import "TNStropheConnection.j"
@import "TNBase64Image.j"
@import "TNStropheGlobals.j"


/*! @ingroup strophecappuccino
    this is an implementation of a XMPP Contact
*/
@implementation TNStropheContact: CPObject
{
    CPArray             _groups         @accessors(property=groups);
    CPArray             _messagesQueue  @accessors(property=messagesQueue);
    CPArray             _resources      @accessors(property=resources);
    CPImage             _statusIcon     @accessors(property=statusIcon);
    CPNumber            _numberOfEvents @accessors(property=numberOfEvents);
    CPString            _nickname       @accessors(property=nickname);
    CPString            _nodeName       @accessors(property=nodeName);
    CPString            _subscription   @accessors(property=subscription);
    CPString            _type           @accessors(property=type);
    CPString            _vCard          @accessors(property=vCard);
    CPString            _XMPPShow       @accessors(property=XMPPShow);
    CPString            _XMPPStatus     @accessors(property=XMPPStatus);
    TNBase64Image       _avatar         @accessors(property=avatar);
    TNStropheConnection _connection     @accessors(property=connection);
    TNStropheJID        _JID            @accessors(property=JID);

    BOOL                _isComposing;
    BOOL                _askingVCard;
    CPImage             _imageAway;
    CPImage             _imageNewError;
    CPImage             _imageNewMessage;
    CPImage             _imageOffline;
    CPImage             _imageOnline;
    CPImage             _statusReminder;
}

#pragma mark -
#pragma mark Class methods

/*! create a contact using a given connection, JID and group
    @param aConnection TNStropheConnection to use
    @param aJID the JID of the contact
    @param aGroup the group of the contact

    @return an allocated and initialized TNStropheContact
*/
+ (TNStropheContact)contactWithConnection:(TNStropheConnection)aConnection JID:(CPString)aJID group:(CPString)aGroup
{
    return [[TNStropheContact alloc] initWithConnection:aConnection JID:aJID group:aGroup];
}


#pragma mark -
#pragma mark Initialization

/*! init a TNStropheContact with a given connection
    @param aConnection TNStropheConnection to use
    @return an initialized TNStropheContact
*/
- (id)initWithConnection:(TNStropheConnection)aConnection JID:(TNStropheJID)aJID group:(CPString)aGroup
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
        _XMPPStatus         = @"Offline";
        _connection         = aConnection;
        _messagesQueue      = [CPArray array];
        _numberOfEvents     = 0;
        _isComposing        = NO;
        _askingVCard        = NO;

        _resources          = [CPArray array];

        _JID                = aJID;
        _groups             = [CPArray array];

        if (aGroup)
            [_groups addObject:aGroup];

        if (!_vCard && !_askingVCard)
            [self getVCard];
    }

    return self;
}


#pragma mark -
#pragma mark Status

/*! Processes presence. It populates the status of the contact
    and send notifications
    You should never have to use this method
    @param aStanza the response TNStropheStanza
*/
- (BOOL)_didReceivePresence:(TNStropheStanza)aStanza
{
    var resource        = [aStanza fromResource],
        presenceStatus  = [aStanza firstChildWithName:@"status"];

    if (resource && (typeof(resource) != "undefined") && resource != @"")
    {
        if (![_resources containsObject:resource])
            [_resources addObject:resource];
        [_JID setResource:resource]
    }

    switch ([aStanza type])
    {
        case @"error":
            var errorCode   = [[aStanza firstChildWithName:@"error"] valueForAttribute:@"code"];
            _XMPPShow       = TNStropheContactStatusOffline;
            _XMPPStatus     = @"Error code: " + errorCode;
            _statusIcon     = _imageNewError;
            _statusReminder = _imageNewError;

            return NO;
        case @"unavailable":
            [_resources removeObject:resource];
            CPLogConsole(@"contact become unavailable from resource: " + resource + @". Resources left : " + _resources);

            if ([_resources count] == 0)
            {
                _XMPPShow       = TNStropheContactStatusOffline;
                _statusIcon     = _imageOffline;
                _statusReminder = _imageOffline;

                if (presenceStatus)
                    _XMPPStatus = [presenceStatus text];
                else
                    _XMPPStatus = "Online";
            }
            break;
        case @"subscribe":
            _XMPPStatus = @"Asking subscribtion";
            break;
        case @"subscribed":
            break;
        case @"unsubscribe":
            break;
        case @"unsubscribed":
            _XMPPStatus = @"Unauthorized";
            break;
        default:
            _XMPPShow       = TNStropheContactStatusOnline;
            _statusReminder = _imageOnline;
            _statusIcon     = _imageOnline;

            if ([aStanza firstChildWithName:@"show"])
            {
                _XMPPShow = [[aStanza firstChildWithName:@"show"] text];
                switch (_XMPPShow)
                {
                    case TNStropheContactStatusBusy:
                        _statusIcon     = _imageBusy;
                        _statusReminder = _imageBusy;
                        break;
                    case TNStropheContactStatusAway:
                        _statusIcon     = _imageAway;
                        _statusReminder = _imageAway;
                        break;
                    case TNStropheContactStatusDND:
                        _statusIcon     = _imageDND;
                        _statusReminder = _imageDND;
                        break;
                }
            }

            if (_numberOfEvents > 0)
                _statusIcon = _imageNewMessage

            if (presenceStatus)
                _XMPPStatus = [presenceStatus text];
            else
                _XMPPStatus = "Online";

            if ([aStanza firstChildWithName:@"x"] && [[aStanza firstChildWithName:@"x"] valueForAttribute:@"xmlns"] == @"vcard-temp:x:update")
                [self getVCard];

            break;
    }

    if (!([aStanza firstChildWithName:@"x"] && [[aStanza firstChildWithName:@"x"] valueForAttribute:@"xmlns"] == @"vcard-temp:x:update"))
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheContactPresenceUpdatedNotification object:self];

    return YES;
}

- (void)sendStatus:(CPString)aStatus
{
    var statusStanza = [TNStropheStanza messageTo:_JID withAttributes:{"type": "chat"}];

    [statusStanza addChildWithName:aStatus andAttributes:{"xmlns": "http://jabber.org/protocol/chatstates"}];

    [self sendStanza:statusStanza andRegisterSelector:@selector(_didSendMessage:) ofObject:self];
}

/*! this allows to send "composing" information to a user. This will never send "paused".
    you have to handle a timer if you want to automatically send pause after a while.
*/
- (void)sendComposing
{
    if (_isComposing)
        return;

    [self sendStatus:@"composing"];
    _isComposing = YES;
}

/*! this allows to send "paused" information to a user.
*/
- (void)sendComposePaused
{
    [self sendStatus:@"paused"];

    _isComposing = NO;
}


#pragma mark -
#pragma mark Subscription

/*! subscribe to the contact
*/
- (void)subscribe
{
    [_connection send:[TNStropheStanza presenceTo:_JID withAttributes:{@"type": @"subscribed"} bare:YES]];
}

/*! unsubscribe from the contact
*/
- (void)unsubscribe
{
    [_connection send:[TNStropheStanza presenceTo:_JID withAttributes:{@"type": @"unsubscribed"} bare:YES]];
}

/*! ask subscribtion to the contact
*/
- (void)askSubscription
{
    [_connection send:[TNStropheStanza presenceTo:_JID withAttributes:{@"type": @"subscribe"} bare:YES]];
}

- (void)setSubscription:(CPString)aSubscription
{
    _subcription = aSubscription;
    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheContactSubscriptionUpdatedNotification object:self];
}


#pragma mark -
#pragma mark MetaData

- (CPString)description
{
    return _nickname;
}

/*! probe the contact's vCard
    you should never have to use this message if you are using TNStropheRoster
*/
- (void)getVCard
{
    var uid         = [_connection getUniqueId],
        vcardStanza = [TNStropheStanza iqTo:_JID withAttributes:{@"type": @"get", @"id": uid} bare:YES],
        params      = [CPDictionary dictionaryWithObjectsAndKeys: uid, @"id"];

    [vcardStanza addChildWithName:@"vCard" andAttributes:{@"xmlns": @"vcard-temp"}];

    _askingVCard = YES;

    [_connection registerSelector:@selector(_didReceiveVCard:) ofObject:self withDict:params];
    [_connection send:vcardStanza];
}

/*! executed on getVCard result. Will post TNStropheContactVCardReceivedNotification
    and send notifications. If vCard contains a PHOTO node, it will set the avatar TNBase64Image
    property of the TNStropheContact
    You should never have to use this method
    @param aStanza the response TNStropheStanza
*/
- (BOOL)_didReceiveVCard:(TNStropheStanza)aStanza
{
    var aVCard = [aStanza firstChildWithName:@"vCard"];

    _askingVCard = NO;

    if (aVCard)
    {
        _vCard = aVCard;

        if (!_nickname || (_nickname == [_JID bare]))
        {
            if ([aVCard firstChildWithName:@"FN"])
                _nickname = [[aVCard firstChildWithName:@"FN"] text];
            else
                _nickname = [_JID node]
        }

        var photoNode;
        if (photoNode = [aVCard firstChildWithName:@"PHOTO"])
        {
            var contentType = [[photoNode firstChildWithName:@"TYPE"] text],
                data        = [[photoNode firstChildWithName:@"BINVAL"] text];

            // the delegate will send the TNStropheContactVCardReceivedNotification when image will be ready
            _avatar = [TNBase64Image base64ImageWithContentType:contentType data:data delegate:self];
        }
        else
        {
            _avatar = nil;
            // otherwise we send the notification right now.
            [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheContactVCardReceivedNotification object:self];
        }
    }

    return NO;
}


#pragma mark -
#pragma mark Communicating

- (void)sendStanza:(TNStropheStanza)aStanza
{
    [self sendStanza:aStanza withUserInfo:nil];
}

- (void)sendStanza:(TNStropheStanza)aStanza withUserInfo:(CPDictionary)userInfo
{
    [aStanza setTo:_JID];
    [_connection send:aStanza];

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheContactStanzaSentNotification object:self userInfo:userInfo];
}

/*! send a TNStropheStanza to the contact. From, ant To value are rewritten. This message uses a given stanza id
    in order to use it if you need. You should mostly use the
    You should never have to use the method sendStanza:andRegisterSelector:ofObject: in most of the case

    @param aStanza the TNStropheStanza to send to the contact
    @param aSelector the selector to perform on response
    @param anObject the object receiving the selector
    @param anId the specific stanza ID to use
    @param someUserInfo random information to give to the selector

    @return the associated registration id for the selector
*/
- (id)sendStanza:(TNStropheStanza)aStanza andRegisterSelector:(SEL)aSelector ofObject:(id)anObject withSpecificID:(id)anId userInfo:(id)someUserInfo
{
    var params      = [CPDictionary dictionaryWithObjectsAndKeys:anId, @"id"],
        userInfo    = [CPDictionary dictionaryWithObjectsAndKeys:aStanza, @"stanza", anId, @"id"],
        ret;

    [aStanza setID:anId];

    if (aSelector && !someUserInfo)
        ret = [_connection registerSelector:aSelector ofObject:anObject withDict:params];
    else if (aSelector && someUserInfo)
        ret = [_connection registerSelector:aSelector ofObject:anObject withDict:params userInfo:someUserInfo];

    [self sendStanza:aStanza withUserInfo:userInfo];

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
    return [self sendStanza:aStanza andRegisterSelector:aSelector ofObject:anObject withSpecificID:[_connection getUniqueId] userInfo:nil];
}

/*! send a TNStropheStanza to the contact. From, ant To value are rewritten.

    @param aStanza the TNStropheStanza to send to the contact
    @param aSelector the selector to perform on response
    @param anObject the object receiving the selector
    @param anId the specific stanza ID to use

    @return the associated registration id for the selector
*/
- (id)sendStanza:(TNStropheStanza)aStanza andRegisterSelector:(SEL)aSelector ofObject:(id)anObject withSpecificID:(int)anId
{
    return [self sendStanza:aStanza andRegisterSelector:aSelector ofObject:anObject withSpecificID:anId userInfo:nil];
}

/*! send a TNStropheStanza to the contact. From, ant To value are rewritten.
    @param aStanza the TNStropheStanza to send to the contact
    @param aSelector the selector to perform on response
    @param anObject the object receiving the selector
    @param someUserInfo random information to give to the selector
    @return the associated registration id for the selector
*/
- (id)sendStanza:(TNStropheStanza)aStanza andRegisterSelector:(SEL)aSelector ofObject:(id)anObject userInfo:(id)someUserInfo
{
    return [self sendStanza:aStanza andRegisterSelector:aSelector ofObject:anObject withSpecificID:[_connection getUniqueId] userInfo:someUserInfo];
}


/*! register the contact to listen incoming messages
    you should never have to use this message if you use TNStropheRoster
*/
- (void)getMessages
{
    var params = [CPDictionary dictionaryWithObjectsAndKeys:@"message", @"name",
                                                            [_JID bare], @"from",
                                                            {matchBare: true}, @"options"];

    [_connection registerSelector:@selector(_didReceiveMessage:) ofObject:self withDict:params];
}

/*! message sent when contact listening its message (using getMessages) and send appropriates notifications
    you should never have to use this message.
    @param aStanza the response stanza
    @return YES in order to listen again
*/
- (BOOL)_didReceiveMessage:(id)aStanza
{
    var center      = [CPNotificationCenter defaultCenter],
        userInfo    = [CPDictionary dictionaryWithObjectsAndKeys:aStanza, @"stanza", [CPDate date], @"date"];

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

        _numberOfEvents++;
        [center postNotificationName:TNStropheContactMessageReceivedNotification object:self userInfo:userInfo];
    }

    return YES;
}

/*! send a message to the contact (of type chat)
    @param aMessage CPString containing the message
*/
- (void)sendMessage:(CPString)aMessage
{
    [self sendMessage:aMessage withType:@"chat"];
}

/*! send a message to the contact
    @param aMessage CPString containing the message
    @param aType    CPString containing type
*/
- (void)sendMessage:(CPString)aMessage withType:(CPString)aType
{
    var messageStanza = [TNStropheStanza messageWithAttributes:{@"type":aType}];

    [messageStanza addChildWithName:@"body"];
    [messageStanza addTextNode:aMessage];

    [self sendStanza:messageStanza];
}

/*! return the last TNStropheStanza message in the message queue and remove it form the queue.
    Will post TNStropheContactMessageTreatedNotification.

    @return TNStropheStanza the last message in queue
*/
- (TNStropheStanza)popMessagesQueue
{
    if ([_messagesQueue count] == 0)
        return;

    var message = [_messagesQueue objectAtIndex:0];

    _numberOfEvents--;
    if (_numberOfEvents === 0)
        _statusIcon = _statusReminder;

    [_messagesQueue removeObjectAtIndex:0];

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheContactMessageTreatedNotification object:self];

    return message;
}

/*! purge all message in queue. Will post TNStropheContactMessageTreatedNotification
*/
- (void)freeMessagesQueue
{
    _numberOfEvents = 0;
    _statusIcon     = _statusReminder;

    [_messagesQueue removeAllObjects];

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheContactMessageTreatedNotification object:self];
}


#pragma mark -
#pragma mark Delegates

/*! this method is called when the avatar image is ready.
    @param anImage the image that sent the message
*/
- (void)imageDidLoad:(TNBase64Image)anImage
{
    [anImage setDelegate:nil];
    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheContactVCardReceivedNotification object:self];
}

@end

@implementation TNStropheContact (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _JID            = [aCoder decodeObjectForKey:@"_JID"];
        _nodeName       = [aCoder decodeObjectForKey:@"_nodeName"];
        _groups         = [aCoder decodeObjectForKey:@"_groups"];
        _nickname       = [aCoder decodeObjectForKey:@"_nickname"];
        _XMPPStatus     = [aCoder decodeObjectForKey:@"_XMPPStatus"];
        _resources      = [aCoder decodeObjectForKey:@"_resources"];
        _XMPPShow       = [aCoder decodeObjectForKey:@"_XMPPShow"];
        _statusIcon     = [aCoder decodeObjectForKey:@"_statusIcon"];
        _type           = [aCoder decodeObjectForKey:@"_type"];
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
    [aCoder encodeObject:_groups forKey:@"_groups"];
    [aCoder encodeObject:_nickname forKey:@"_nickname"];
    [aCoder encodeObject:_XMPPStatus forKey:@"_XMPPStatus"];
    [aCoder encodeObject:_XMPPShow forKey:@"_XMPPShow"];
    [aCoder encodeObject:_type forKey:@"_type"];
    [aCoder encodeObject:_statusIcon forKey:@"_statusIcon"];
    [aCoder encodeObject:_messagesQueue forKey:@"_messagesQueue"];
    [aCoder encodeObject:_numberOfEvents forKey:@"_numberOfEvents"];

    if (_resources)
        [aCoder encodeObject:_resources forKey:@"_resources"];

    if (_vCard)
        [aCoder encodeObject:_vCard forKey:@"_vCard"];
}

@end
