/*
 * TNStropheGlobals.j
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

#pragma mark -
#pragma mark globals of TNStropheConnection

/*!
    @global
    @group TNStropheConnectionStatus
    Notification sent on connecting
*/
TNStropheConnectionStatusConnecting         = @"TNStropheConnectionStatusConnecting";
/*!
    @global
    @group TNStropheConnectionStatus
    Notification sent when connected
*/
TNStropheConnectionStatusConnected          = @"TNStropheConnectionStatusConnected";
/*!
    @global
    @group TNStropheConnectionStatus
    Notification sent on connection fail
*/
TNStropheConnectionStatusConnectionFailure  = @"TNStropheConnectionStatusConnectionFailure";
/*! @global
    @group TNStropheConnectionStatus
    Notification sent when authenticating

*/
TNStropheConnectionStatusAuthenticating     = @"TNStropheConnectionStatusAuthenticating"
/*!
    @global
    @group TNStropheConnectionStatus
    Notification sent on auth fail
*/
TNStropheConnectionStatusAuthFailure        = @"TNStropheConnectionStatusAuthFailure";

/*!
    @global
    @group TNStropheConnectionStatus
    Notification sent on disconnecting
*/
TNStropheConnectionStatusDisconnecting      = @"TNStropheConnectionStatusDisconnecting";
/*!
    @global
    @group TNStropheConnectionStatus
    Notification sent when disconnected
*/
TNStropheConnectionStatusDisconnected       = @"TNStropheConnectionStatusDisconnected";

/*!
    @global
    @group TNStropheConnectionStatus
    Notification sent when other error occurs
*/
TNStropheConnectionStatusError              = @"TNStropheConnectionStatusError";


#pragma mark -
#pragma mark globals of TNStropheContact

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


#pragma mark -
#pragma mark globals of TNStropheRoster

/*!
    @global
    @group TNStropheRoster
    notification indicates that TNStropheRoster has received the data from the XMPP server
*/
TNStropheRosterRetrievedNotification        = @"TNStropheRosterRetrievedNotification";
/*!
    @global
    @group TNStropheRoster
    notification indicates that a new contact has been added to the TNStropheRoster
*/
TNStropheRosterAddedContactNotification     = @"TNStropheRosterAddedContactNotification";
/*!
    @global
    @group TNStropheRoster
    notification indicates that a new contact has been removed from the TNStropheRoster
*/

TNStropheRosterRemovedContactNotification   = @"TNStropheRosterRemovedContactNotification";
/*!
    @global
    @group TNStropheRoster
    notification indicates that a new group has been added to the TNStropheRoster
*/
TNStropheRosterAddedGroupNotification       = @"TNStropheRosterAddedGroupNotification";

/*!
    @global
    @group TNStropheRoster
    notification indicates that a new group has been added to the TNStropheRoster
*/
TNStropheRosterRemovedGroupNotification     = @"TNStropheRosterRemovedGroupNotification";


#pragma mark -
#pragma mark globals of TNStropheGroup

/*!
    @global
    @group TNStropheGroup
    notification indicates that a group has been renamed
*/
TNStropheGroupRenamedNotification = @"TNStropheGroupRenamed";

/*!
    @global
    @group TNStropheGroup
    notification indicates that a group has been removed
*/
TNStropheGroupRemovedNotification = @"TNStropheGroupRemoved";
