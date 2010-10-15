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
@import "TNStropheGlobals.j"


/*! @ingroup strophecappuccino
    this is an implementation of a XMPP Contact
*/
@implementation TNStropheContact: CPObject
{
    CPArray             _messagesQueue  @accessors(property=messagesQueue);
    CPArray             _resources      @accessors(property=resources);
    CPImage             _statusIcon     @accessors(property=statusIcon);
    CPNumber            _numberOfEvents @accessors(property=numberOfEvents);
    CPString            _domain         @accessors(property=domain);
    CPString            _fullJID        @accessors(property=fullJID);
    CPString            _groupName      @accessors(property=groupName);
    CPString            _JID            @accessors(property=JID);
    CPString            _nickname       @accessors(property=nickname);
    CPString            _nodeName       @accessors(property=nodeName);
    CPString            _type           @accessors(property=type);
    CPString            _vCard          @accessors(property=vCard);
    CPString            _XMPPShow       @accessors(property=XMPPShow);
    CPString            _XMPPStatus     @accessors(property=XMPPStatus);
    TNBase64Image       _avatar         @accessors(property=avatar);
    TNStropheConnection _connection     @accessors(property=connection);

    BOOL                _isComposing;
    CPImage             _imageAway;
    CPImage             _imageNewError;
    CPImage             _imageNewMessage;
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
+ (TNStropheContact)contactWithConnection:(TNStropheConnection)aConnection JID:(CPString)aJID groupName:(CPString)aGroupName
{
    return [[TNStropheContact alloc] initWithConnection:aConnection JID:aJID groupName:aGroupName];
}

#pragma mark -
#pragma mark Initialization

/*! init a TNStropheContact with a given connection
    @param aConnection TNStropheConnection to use

    @return an initialized TNStropheContact
*/
- (id)initWithConnection:(TNStropheConnection)aConnection JID:(CPString)aJID groupName:(CPString)aGroupName
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
        _messagesQueue      = [CPArray array];
        _numberOfEvents     = 0;
        _isComposing        = NO;

        _resources          = [CPArray array];

        _JID                = aJID;
        _groupName          = aGroupName;
        _nodeName           = aJID.split('@')[0];
        _nickname           = aJID.split('@')[0];
        _domain             = aJID.split('/')[0].split('@')[1];
    }

    return self;
}


#pragma mark -
#pragma mark Status

/*! probe the contact about its status
    You should never have to use this message if you are using TNStropheRoster
*/
- (void)getStatus
{
    var probe   = [TNStropheStanza presenceWithAttributes:{@"type": @"probe", @"to": _JID}],
        params  = [CPDictionary dictionary];

    [params setValue:@"presence" forKey:@"name"];
    [params setValue:_JID forKey:@"from"];
    [params setValue:{@"matchBare": YES} forKey:@"options"];

    [_connection registerSelector:@selector(didReceiveStatus:) ofObject:self withDict:params];
    [_connection send:probe];
}

/*! executed on getStatus result. It populates the status of the contact
    and send notifications
    You should never have to use this method
    @param aStanza the response TNStropheStanza
*/
- (BOOL)didReceiveStatus:(TNStropheStanza)aStanza
{

    var resource = [aStanza fromResource],
        presenceShow = [aStanza firstChildWithName:@"status"];

    _fullJID = [aStanza from];

    if (resource && (resource != @"") && ![_resources containsObject:resource])
        [_resources addObject:resource];

    switch ([aStanza type])
    {
        case @"error":
            errorCode       = [[aStanza firstChildWithName:@"error"] valueForAttribute:@"code"];
            _XMPPShow       = TNStropheContactStatusOffline;
            _XMPPStatus     = @"Error code: " + errorCode;
            _statusIcon     = _imageNewError;
            _statusReminder = _imageNewError;

            [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheContactPresenceUpdatedNotification object:self];

            return NO;
        case @"unavailable":
            [_resources removeObject:resource];
            CPLogConsole(@"contact become unavailable from resource: " + resource + @". Resources left : " + _resources )

            if ([_resources count] == 0)
            {
                _XMPPShow       = TNStropheContactStatusOffline;
                _statusIcon     = _imageOffline;
                _statusReminder = _imageOffline;

                if (presenceShow)
                    _XMPPStatus = [presenceShow text];
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
            _statusIcon     = _imageOnline;
            _statusReminder = _imageOnline;

            _XMPPStatus = [aStanza firstChildWithName:@"show"];
            if (_XMPPStatus)
            {
                switch ([_XMPPStatus text])
                {
                    case TNStropheContactStatusBusy:
                        _XMPPShow       = TNStropheContactStatusBusy;
                        _statusIcon     = _imageBusy
                        _statusReminder = _imageBusy;
                        break;
                    case TNStropheContactStatusAway:
                        _XMPPShow       = TNStropheContactStatusAway;
                        _statusIcon     = _imageAway
                        _statusReminder = _imageAway;
                        break;
                    case TNStropheContactStatusDND:
                        _XMPPShow       = TNStropheContactStatusDND;
                        _statusIcon     = _imageDND;
                        _statusReminder = _imageDND;
                        break;
                }
            }

            if (presenceShow)
                _XMPPStatus = [presenceShow text];

            if ([aStanza firstChildWithName:@"x"] && [[aStanza firstChildWithName:@"x"] valueForAttribute:@"xmlns"] == @"vcard-temp:x:update")
                [self getVCard];
            break;
    }

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheContactPresenceUpdatedNotification object:self];

    return YES;
}

- (void)sendStatus:(CPString)aStatus
{
    var statusStanza = [TNStropheStanza messageWithAttributes:{"to": _JID, "from": [_connection JID], "type": "chat"}];

    [statusStanza addChildWithName:aStatus andAttributes:{"xmlns": "http://jabber.org/protocol/chatstates"}];

    [self sendStanza:statusStanza andRegisterSelector:@selector(_didSendMessage:) ofObject:self];
}

/*! this allows to send "composing" information to a user. This will never send "paused".
    you have to handle a timer if you want to automatically send pause after a while.
*/
- (void)sendComposing
{
    if (!_isComposing)
    {
        [self sendStatus:@"composing"];
        _isComposing = YES;
    }
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
    var resp = [TNStropheStanza presenceWithAttributes:{@"from": [_connection JID], @"type": @"subscribed", @"to": _JID}];
    [_connection send:resp];
}

/*! unsubscribe from the contact
*/
- (void)unsubscribe
{
    var resp = [TNStropheStanza presenceWithAttributes:{@"from": [_connection JID], @"type": @"unsubscribed", @"to": _JID}];
    [_connection send:resp];
}

/*! ask subscribtion to the contact
*/
- (void)askSubscription
{
    var auth = [TNStropheStanza presenceWithAttributes:{@"type": @"subscribe", @"to": _JID}];
    [_connection send:auth];
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
        vcardStanza = [TNStropheStanza iqWithAttributes:{@"from": [_connection JID], @"to": _JID, @"type": @"get", @"id": uid}];

    [vcardStanza addChildWithName:@"vCard" andAttributes:{@"xmlns": @"vcard-temp"}];

    var params = [CPDictionary dictionary];
    [params setValue:_JID forKey:@"from"];
    [params setValue:uid forKey:@"id"];
    [params setValue:{@"matchBare": YES} forKey:@"options"];

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
    var aVCard = [aStanza firstChildWithName:@"vCard"];

    if (aVCard)
    {
        _vCard = aVCard;

        var photoNode;
        if (photoNode = [aVCard firstChildWithName:@"PHOTO"])
        {
            var contentType = [[photoNode firstChildWithName:@"TYPE"] text],
                data        = [[photoNode firstChildWithName:@"BINVAL"] text];

            _avatar = [TNBase64Image base64ImageWithContentType:contentType andData:data];
        }

        if ((_nickname == _nodeName) && ([aVCard firstChildWithName:@"NAME"]))
            _nickname = [[aVCard firstChildWithName:@"NAME"] text];

        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheContactVCardReceivedNotification object:self];
    }

    return YES;
}

/*! this allows to change the contact nickname. Will post TNStropheContactNicknameUpdatedNotification
    @param newNickname the new nickname
*/
- (void)changeNickname:(CPString)newNickname
{
    _nickname = newNickname;

    var stanza = [TNStropheStanza iqWithAttributes:{"type": "set"}];
    [stanza addChildWithName:@"query" andAttributes: {'xmlns':Strophe.NS.ROSTER}];
    [stanza addChildWithName:@"item" andAttributes:{"JID": _JID, "name": _nickname}];
    [stanza addChildWithName:@"group" andAttributes:nil];
    [stanza addTextNode:_groupName];

    [_connection send:stanza];

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheContactNicknameUpdatedNotification object:self];
}

/*! this allows to change the group of the contact. Will post TNStropheContactGroupUpdatedNotification
*/
- (void)changeGroup:(TNStropheGroup)newGroup
{
    var stanza = [TNStropheStanza iqWithAttributes:{"type": "set"}];
    [stanza addChildWithName:@"query" andAttributes: {'xmlns':Strophe.NS.ROSTER}];
    [stanza addChildWithName:@"item" andAttributes:{"JID": _JID, "name": _nickname}];
    [stanza addChildWithName:@"group" andAttributes:nil];
    [stanza addTextNode:[newGroup name]];

    [_connection send:stanza];

    _groupName = [newGroup name];

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheContactGroupUpdatedNotification object:self];
}

- (void)changeGroupName:(CPString)aNewName
{
    var stanza = [TNStropheStanza iqWithAttributes:{"type": "set"}];

    [stanza addChildWithName:@"query" andAttributes: {'xmlns':Strophe.NS.ROSTER}];
    [stanza addChildWithName:@"item" andAttributes:{"JID": _JID, "name": _nickname}];
    [stanza addChildWithName:@"group" andAttributes:nil];
    [stanza addTextNode:aNewName];

    [_connection send:stanza];

    _groupName = aNewName;

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheContactGroupUpdatedNotification object:self];
}


#pragma mark -
#pragma mark Communicating

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
    var params              = [CPDictionary dictionaryWithObjectsAndKeys:anId, @"id"],
        ret                 = nil,
        lastKnownResource   = (_fullJID) ? _fullJID.split(@"/")[1] : nil,
        userInfo            = [CPDictionary dictionaryWithObjectsAndKeys:aStanza, @"stanza", anId, @"id"];

    if (_fullJID && ![_resources containsObject:lastKnownResource])
        _fullJID = _fullJID.split("/")[0] + @"/" + [_resources lastObject];

    [aStanza setTo:(_fullJID) ? _fullJID : _JID];
    [aStanza setID:anId];

    if (aSelector)
        ret = [_connection registerSelector:aSelector ofObject:anObject withDict:params];

    [_connection send:aStanza];

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheContactStanzaSentNotification object:self userInfo:userInfo];

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
    return [self sendStanza:aStanza andRegisterSelector:aSelector ofObject:anObject withSpecificID:[_connection getUniqueId]];
}

/*! register the contact to listen incoming messages
    you should never have to use this message if you use TNStropheRoster
*/
- (void)getMessages
{
    var params = [CPDictionary dictionary];

    [params setValue:@"message" forKey:@"name"];
    [params setValue:_JID forKey:@"from"];
    [params setValue:{@"matchBare": YES} forKey:@"options"];

    [_connection registerSelector:@selector(_didReceivedMessage:) ofObject:self withDict:params];
}

/*! message sent when contact listening its message (using getMessages) and send appropriates notifications
    you should never have to use this message.

    @param aStanza the response stanza

    @return YES in order to listen again
*/
- (BOOL)_didReceivedMessage:(id)aStanza
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
        [_connection playReceivedSound];

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
    var messageStanza = [TNStropheStanza messageWithAttributes:{@"to":  _JID, @"from": [_connection JID], @"type":aType}];

    [messageStanza addChildWithName:@"body"];
    [messageStanza addTextNode:aMessage];

    [self sendStanza:messageStanza andRegisterSelector:@selector(_didSendMessage:) ofObject:self];
}

/*! message sent when a message has been sent. It posts appropriate notification with userInfo
    containing the stanza under the key "stanza"
    you should never use this message

    @param aStanza the response stanza

    @return NO to remove the registering of the selector
*/
- (BOOL)_didSendMessage:(id)aStanza
{
    var userInfo = [CPDictionary dictionaryWithObjectsAndKeys:aStanza, @"stanza"];

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheContactMessageSentNotification object:self userInfo:userInfo];

    return NO;
}

/*! return the last TNStropheStanza message in the message queue and remove it form the queue.
    Will post TNStropheContactMessageTreatedNotification.

    @return TNStropheStanza the last message in queue
*/
- (TNStropheStanza)popMessagesQueue
{
    if ([_messagesQueue count] == 0)
        return Nil;

    var message = [_messagesQueue objectAtIndex:0];

    _numberOfEvents--;
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
    _statusIcon = _statusReminder;

    [_messagesQueue removeAllObjects];

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheContactMessageTreatedNotification object:self];
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
