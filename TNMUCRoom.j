/*
 * TNMUCRoom.j
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

@import "TNStropheGlobals.j";
@import "TNStropheConnection.j";
@import "TNStropheStanza.j";



/*! @ingroup strophecappuccino
    this is an implementation of an XMPP multi-user chat room
*/
@implementation TNMUCRoom : CPObject
{
    CPString                _roomName           @accessors(getter=name);
    CPString                _service            @accessors(getter=service);
    CPString                _nick               @accessors(getter=nick);
    CPString                _subject            @accessors(getter=subject);
    CPArray                 _messages           @accessors(getter=messages);
    CPArray                 _roster             @accessors(getter=roster);

    TNStropheConnection     _connection;
    CPArray                 _handlerIDs;
}

#pragma mark -
#pragma mark Initialization

/*! create and initialize and return a new TNPubSubNode
    @param  aNodeName the name of the pubsub node
    @param  aConnection the TNStropheConnection to use to communicate
    @param aPubSubServer a pubsubserver. if nil, it will be pubsub. + domain of [_connection JID]
    @return initialized TNPubSubNode
*/
+ (XMPPMUCSession)joinRoom:(CPString)aRoom onService:(CPString)aService usingConnection:(TNStropheConnection)aConnection withNick:(CPString)aNick
{
    return [[TNMUCRoom alloc] initWithRoom:aRoom
                                 onService:aService
                           usingConnection:aConnection
                                  withNick:aNick];
}

/*! initialize and return a new TNPubSubNode
    @param  aNodeName the name of the pubsub node
    @param  aConnection the TNStropheConnection to use to communicate
    @param aPubSubServer a pubsubserver. if nil, it will be pubsub. + domain of [_connection JID]
    @return initialized TNPubSubNode
*/
- (id)initWithRoom:(CPString)aRoom onService:(CPString)aService usingConnection:(TNStropheConnection)aConnection withNick:(CPString)aNick
{
    self = [super init];
    if (self)
    {
        _roomName       = aRoom;
        _service        = aService;
        _connection     = aConnection;
        _nick           = aNick;
        _handlerIDs     = [CPArray array];
        _messages       = [CPArray array];
        _roster         = [CPArray array];
    }
    return self;
}


#pragma mark -
#pragma mark Membership

- (CPString)roomJID
{
    return _roomName + @"@" + _service;
}

// Includes own nick as resource
- (CPString)ownRoomJID
{
    return [self roomJID] + @"/" + _nick;
}

- (TNStropheStanza)directedPresence
{
    return [TNStropheStanza presenceWithAttributes:{"to": [self ownRoomJID]}];
}

- (void)join
{
    // Handle room roster
    var rosterParams    = [CPDictionary dictionaryWithObjectsAndKeys:@"presence",@"name",
                                                                     [self roomJID],@"from",
                                                                     @"unavailable",@"type",
                                                                     {matchBare: true},@"options"],
        rosterHandler   = [_connection registerSelector:@selector(presenceReceived:) ofObject:self withDict:rosterParams];
    [_handlerIDs addObject:rosterHandler];

    // Handle messages sent to room
    var messageParams   = [CPDictionary dictionaryWithObjectsAndKeys:@"message",@"name",
                                                                     [self roomJID],@"from",
                                                                     @"groupchat",@"type",
                                                                     {matchBare: true},@"options"],
        messageHandler  = [_connection registerSelector:@selector(receiveMessage:) ofObject:self withDict:messageParams];
    [_handlerIDs addObject:messageHandler];

    // Handle private messages from room roster
    var pmParams    = [CPDictionary dictionaryWithObjectsAndKeys:@"message",@"name",
                                                                 [self roomJID],@"from",
                                                                 @"chat",@"type",
                                                                 {matchBare: true},@"options"],
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
    for (int i = 0; i < [_handlerIds count]; i++)
        [_connection deleteRegisteredSelector:handlerIDs[i]];
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
    [aStanza setTo:[self roomJID]];
    [_connection send:aStanza];
}

- (BOOL)receiveMessage:(TNStropheStanza)aMessage
{
    if ([aMessage containsChildrenWithName:@"subject"])
    {
        _subject = [[aMessage firstChildWithName:@"subject"] text];

        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheMUCSubjectWasUpdatedNotification object:self];
    }

    if ([aMessage containsChildrenWithName:@"body"])
    {
        var body    = [[aMessage firstChildWithName:@"body"] text],
            message = [CPDictionary dictionaryWithObjectsAndKeys:body,@"body",
                                                                 [aMessage fromResource],@"from",
                                                                 [aMessage delayTime],@"time"];
        [_messages addObject:message];

        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheMUCConversationWasUpdatedNotification object:self];
    }

    return YES;
}

- (BOOL)receivePrivateMessage:(TNStropheStanza)aMessage
{
    // TODO: Handle receiving private messages

    return YES;
}


#pragma mark -
#pragma mark Roster

- (BOOL)presenceReceived:(TNStropheStanza)aPresence
{
    var nick        = [aPresence fromResource],
        meta        = [aPresence firstChildWithName:@"x"],
        affiliation = [[meta firstChildWithName:@"item"] valueForAttribute:@"affiliation"],
        role        = [[meta firstChildWithName:@"item"] valueForAttribute:@"role"],
        statusCode  = [[meta firstChildWithName:@"status"] valueForAttribute:@"code"];

    if ([meta namespace] != @"http://jabber.org/protocol/muc#user")
    {
        CPLog.error("MUC received presence with incorect meta-data namespace");
        return NO;
    }

    // TODO: Remove user from roster

    // TODO: Add user back into roster with correct meta-data
    if ([aPresence type] === @"unavailable")
    {
        // TODO: Assert nature (voluntary?)
        switch (statusCode)
        {
            case @"307":
            // User was temporarily kicked from room
            break;
            default:
            // Leaving was voluntary
        }
    }

    [roster addObject:nick];

    [[CPNotificationCenter defaultCenter] postNotificationName:XMPPMUCRosterWasUpdatedNotification object:self];

    return YES;
}

@end
