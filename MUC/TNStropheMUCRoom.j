/*
 * TNStropheMUCRoom.j
 *
 * Copyright (C) 2010 Ben Langfeld <ben@langfeld.me>
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

@import "../TNStropheConnection.j"
@import "../TNStropheJID.j"
@import "../TNStropheStanza.j"
@import "TNStropheMUCRoster.j"


TNStropheMUCConversationWasUpdatedNotification      = @"TNStropheMUCConversationWasUpdatedNotification";
TNStropheMUCDataReceivedNotification                = @"TNStropheMUCDataReceivedNotification";
TNStropheMUCPrivateMessageWasReceivedNotification   = @"TNStropheMUCPrivateMessageWasReceivedNotification";
TNStropheMUCRosterWasUpdatedNotification            = @"TNStropheMUCRosterWasUpdatedNotification";
TNStropheMUCSubjectWasUpdatedNotification           = @"TNStropheMUCSubjectWasUpdatedNotification";


/*! @ingroup strophecappuccino
    this is an implementation of an XMPP multi-user chat room
*/
@implementation TNStropheMUCRoom : CPObject
{
    CPArray                 _messages           @accessors(getter=messages);
    CPString                _subject            @accessors(getter=subject);
    id                      _delegate           @accessors(property=delegate);
    TNStropheJID            _roomJID            @accessors(getter=roomJID);
    TNStropheMUCRoster      _roster             @accessors(getter=roster);

    CPArray                 _handlerIDs;
    TNStropheConnection     _connection;
}

#pragma mark -
#pragma mark Initialization

/*! create and initialize and return a new TNStropheMUCRoom
    @param  aRoom the name of the room
    @param  aService the service
    @param aConnection a valid open TNStropheConnection
    @param aNick the wanted nick
    @return initialized TNStropheMUCRoom
*/
+ (TNStropheMUCRoom)joinRoom:(CPString)aRoom onService:(CPString)aService usingConnection:(TNStropheConnection)aConnection withNick:(CPString)aNick
{
    return [[TNStropheMUCRoom alloc] initWithRoom:aRoom
                                 onService:aService
                           usingConnection:aConnection
                                  withNick:aNick];
}

/*! create and initialize and return a new TNStropheMUCRoom
    @param  aRoom the name of the room
    @param  aService the service
    @param aConnection a valid open TNStropheConnection
    @param aNick the wanted nick
    @return initialized TNStropheMUCRoom
*/
- (id)initWithRoom:(CPString)aRoom onService:(CPString)aService usingConnection:(TNStropheConnection)aConnection withNick:(CPString)aNick
{
    if (self = [super init])
    {
        _connection     = aConnection;
        _roomJID        = [TNStropheJID stropheJIDWithNode:aRoom domain:aService resource:aNick];
        _handlerIDs     = [CPArray array];
        _messages       = [CPArray array];
        _roster         = [TNStropheMUCRoster rosterWithConnection:_connection forRoom:self];
    }
    return self;
}


#pragma mark -
#pragma mark Membership

- (TNStropheStanza)directedPresence
{
    return [TNStropheStanza presenceTo:_roomJID];
}

- (void)join
{
    // Handle messages sent to room
    var messageParams   = [CPDictionary dictionaryWithObjectsAndKeys:@"message", @"name",
                                                                     [_roomJID full], @"from",
                                                                     @"groupchat", @"type",
                                                                     {matchBare: true}, @"options"],
        messageHandler  = [_connection registerSelector:@selector(receiveMessage:) ofObject:self withDict:messageParams];
    [_handlerIDs addObject:messageHandler];

    // Handle private messages from room roster
    var pmParams    = [CPDictionary dictionaryWithObjectsAndKeys:@"message", @"name",
                                                                [_roomJID full], @"from",
                                                                 @"chat", @"type",
                                                                 {matchBare: true}, @"options"],
        pmHandler   = [_connection registerSelector:@selector(receivePrivateMessage:) ofObject:self withDict:pmParams];
    [_handlerIDs addObject:pmHandler];

    [_connection send:[self directedPresence]];
}

- (void)leave
{
    // Send directed unavailable presence
    var leavePresence = [self directedPresence];
    [leavePresence setType:@"unavailable"];
    [_connection send:leavePresence];

    // Remove room handlers
    for (var i = 0; i < [_handlerIDs count]; i++)
        [_connection deleteRegisteredSelector:[_handlerIDs objectAtIndex:i]];
}


#pragma mark -
#pragma mark Content

- (void)setSubject:(CPString)aSubject
{
    var message = [TNStropheStanza message];
    [message setType:@"groupchat"];
    [message addChildWithName:@"subject"];
    [message addTextNode:aSubject];

    [self sendStanzaToRoom:message];
}

- (void)sayToRoom:(CPString)aMessage
{
    var message = [TNStropheStanza message];
    [message setType:@"groupchat"];
    [message addChildWithName:@"body"];
    [message addTextNode:aMessage];

    [self sendStanzaToRoom:message];
}

- (void)sendStanzaToRoom:(TNStropheStanza)aStanza
{
    [aStanza setTo:[_roomJID bare]];
    [_connection send:aStanza];
}

- (BOOL)receiveMessage:(TNStropheStanza)aStanza
{
    if ([aStanza containsChildrenWithName:@"subject"])
    {
        _subject = [[aStanza firstChildWithName:@"subject"] text];

        if (_delegate && [_delegate respondsToSelector:@selector(mucRoom:receivedNewSubject:)])
            [_delegate mucRoom:self receivedNewSubject:_subject];

        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheMUCSubjectWasUpdatedNotification object:self userInfo:aStanza];
    }

    if ([aStanza containsChildrenWithName:@"body"])
    {
        var body    = [[aStanza firstChildWithName:@"body"] text],
            contact = [_roster contactWithJID:[aStanza from]];

        if (!contact)
        {
            [_roster addContact:[aStanza from] withName:[[aStanza from] resource] inGroup:[_roster visitors]];
            contact = [_roster contactWithJID:[aStanza from]];
        }

        var message = [CPDictionary dictionaryWithObjectsAndKeys:body, @"body",
                                                                 contact, @"from",
                                                                 [aStanza delayTime], @"time"];
        [_messages addObject:message];

        if (_delegate && [_delegate respondsToSelector:@selector(mucRoom:receivedMessage:)])
            [_delegate mucRoom:self receivedMessage:message];

        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheMUCConversationWasUpdatedNotification object:self userInfo:aStanza];
    }

    var otherChildren = [aStanza children];
    [otherChildren removeObjectsInArray:[aStanza childrenWithName:@"body"]];
    [otherChildren removeObjectsInArray:[aStanza childrenWithName:@"subject"]];

    if ([otherChildren count] > 0)
    {
        if (_delegate && [_delegate respondsToSelector:@selector(mucRoom:receivedData:)])
            [_delegate mucRoom:self receivedData:aStanza];

        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheMUCDataReceivedNotification object:self userInfo:aStanza];
    }

    return YES;
}

- (BOOL)receivePrivateMessage:(TNStropheStanza)aMessage
{
    // TODO: Handle receiving private messages

    return YES;
}

@end
