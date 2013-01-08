/*
 * TNStropheServerAdministration.j
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

@import "Resources/Strophe/strophe.js"
@import "Resources/Strophe/sha1.js"
@import "TNStropheConnection.j"


TNStropheServerAdministrationGetConnectedUserNotification       = @"TNStropheServerAdministrationGetConnectedUserNotification";
TNStropheServerAdministrationGetRegisteredUserNotification      = @"TNStropheServerAdministrationGetRegisteredUserNotification";
TNStropheServerAdministrationRegisterUserNotification           = @"TNStropheServerAdministrationRegisterUserNotification";
TNStropheServerAdministrationSendAnnouncementNotification       = @"TNStropheServerAdministrationSendAnnouncementNotification";
TNStropheServerAdministrationSetUserEnabledNotification         = @"TNStropheServerAdministrationSetUserEnabledNotification";
TNStropheServerAdministrationUnregisterUserNotification         = @"TNStropheServerAdministrationUnregisterUserNotification";


/*! @ingroup strophecappuccino
    This class allows to manage XMPP server using XMPP
*/
@implementation TNStropheServerAdministration : CPObject
{
    TNStropheConnection     _connection     @accessors(property=connection);
    TNStropheJID            _server         @accessors(property=server);
    id                      _delegate       @accessors(property=delegate);
}

#pragma mark -
#pragma mark Initialization

/*! initialize a new TNStropheServerAdminstration
    @param aConnection a TNStropheConnection
    @param aServer the target XMPP server
*/
- (void)initWithConnection:(TNStropheConnection)aConnection server:(TNStropheJID)aServer
{
    if (self = [super init])
    {
        _connection = aConnection;
        _server     = aServer
    }

    return self;
}


#pragma mark -
#pragma mark Utilities

/*! factor sending basic commands
    @param anAction the action to send
    @param aSelector the selector to trigger
*/
- (void)sendAction:(CPString)anAction selector:(SEL)aSelector
{
    var uid         = [_connection getUniqueId],
        stanza      = [TNStropheStanza iqWithAttributes:{@"id": uid, @"type": @"set"}],
        params      = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [stanza setTo:_server];
    [stanza addChildWithName:@"command" andAttributes:{
        @"xmlns": Strophe.NS.COMMAND,
        @"action": @"execute",
        @"node": anAction}];

    [_connection registerSelector:aSelector ofObject:self withDict:params];
    [_connection send:stanza];
}


#pragma mark -
#pragma mark Announcement

/*! send a message to all connected users
    @param anAnnouncement the body of the message
    @param aSubject the subject of the message
*/
- (void)sendAnnouncement:(CPString)anAnnouncement subject:(CPString)aSubject
{
    var uid         = [_connection getUniqueId],
        stanza      = [TNStropheStanza iqWithAttributes:{@"id": uid, @"type": @"set"}],
        params      = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [stanza setTo:_server];
    [stanza addChildWithName:@"command" andAttributes:{
        @"xmlns": Strophe.NS.COMMAND,
        @"node": @"http://jabber.org/protocol/admin#announce"}];

    [stanza addChildWithName:@"x" andAttributes:{@"xmlns": @"jabber:x:data", @"type": @"submit"}];

    [stanza addChildWithName:@"field" andAttributes:{@"type": @"hidden", @"var": @"FORM_TYPE"}];
    [stanza addChildWithName:@"value"];
    [stanza addTextNode:@"http://jabber.org/protocol/admin"];
    [stanza up];
    [stanza up];
    if (aSubject)
    {
        [stanza addChildWithName:@"field" andAttributes:{@"var": @"subject"}];
        [stanza addChildWithName:@"value"];
        [stanza addTextNode:aSubject];
        [stanza up];
        [stanza up];
    }
    [stanza addChildWithName:@"field" andAttributes:{@"var": @"body"}];
    [stanza addChildWithName:@"value"];
    [stanza addTextNode:anAnnouncement];

    [_connection registerSelector:_didSendAnnouncement ofObject:self withDict:params];
    [_connection send:stanza];
}

/*! @ignore
*/
- (void)_didSendAnnouncement:(TNStropheStanza)aStanza
{
    if (_delegate && [_delegate respondsToSelector:@selector(serverAdmin:didSendAnnouncement:)])
        [_delegate serverAdmin:self didSendAnnouncement:aStanza];
    else
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheServerAdministrationSendAnnouncementNotification object:self userInfo:aStanza];
}


#pragma mark -
#pragma mark Users

/*! get all the registred users
    NOT IMPLEMENTED IN EJABBERD
*/
- (void)registeredUsers
{
    [self sendAction:@"http://jabber.org/protocol/admin#get-registered-users-list" selector:@selector(_didGetRegisteredUsers:)]
}

/*! @ignore
*/
- (void)_didGetRegisteredUsers:(TNStropheStanza)aStanza
{
    if (_delegate && [_delegate respondsToSelector:@selector(serverAdmin:didGetRegisteredUsers:)])
        [_delegate serverAdmin:self didGetRegisteredUsers:aStanza];
    else
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheServerAdministrationGetRegisteredUserNotification object:self userInfo:aStanza];
}

/*! get all the connected users
    NOT IMPLEMENTED IN EJABBERD
*/
- (void)connectedUsers
{
    [self sendAction:@"http://jabber.org/protocol/admin#get-online-users-list" selector:@selector(_didGetConnectedUsers:)]
}

/*! @ignore
*/
- (void)_didGetConnectedUsers:(TNStropheStanza)aStanza
{
    if (_delegate && [_delegate respondsToSelector:@selector(serverAdmin:didGetConnectedUsers:)])
        [_delegate serverAdmin:self didGetConnectedUsers:aStanza];
    else
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheServerAdministrationGetConnectedUserNotification object:self userInfo:aStanza];
}

/*! add a user to the server
    @param aJID the JID of the new user
    @param aPassword the password
    @param aName the given name
    @param aSurname the surname
    @param anEmail the email
*/
- (void)registerUser:(TNStropheJID)aJID  password:(CPString)aPassword name:(CPString)aName surname:(CPString)aSurname email:(CPString)anEmail
{
    var uid         = [_connection getUniqueId],
        stanza      = [TNStropheStanza iqWithAttributes:{@"id": uid, @"type": @"set"}],
        params      = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [stanza setTo:_server];
    [stanza addChildWithName:@"command" andAttributes:{
        @"xmlns": Strophe.NS.COMMAND,
        @"node": @"http://jabber.org/protocol/admin#add-user"}];

    [stanza addChildWithName:@"x" andAttributes:{@"xmlns": @"jabber:x:data", @"type": @"submit"}];

    [stanza addChildWithName:@"field" andAttributes:{@"type": @"hidden", @"var": @"FORM_TYPE"}];
    [stanza addChildWithName:@"value"];
    [stanza addTextNode:@"http://jabber.org/protocol/admin"];
    [stanza up];
    [stanza up];

    [stanza addChildWithName:@"field" andAttributes:{@"var": @"accountjid"}];
    [stanza addChildWithName:@"value"];
    [stanza addTextNode:[aJID bare]];
    [stanza up];
    [stanza up];

    [stanza addChildWithName:@"field" andAttributes:{@"var": @"password"}];
    [stanza addChildWithName:@"value"];
    [stanza addTextNode:aPassword];
    [stanza up];
    [stanza up];

    [stanza addChildWithName:@"field" andAttributes:{@"var": @"password-verify"}];
    [stanza addChildWithName:@"value"];
    [stanza addTextNode:aPassword];
    [stanza up];
    [stanza up];

    [stanza addChildWithName:@"field" andAttributes:{@"var": @"email"}];
    [stanza addChildWithName:@"value"];
    [stanza addTextNode:anEmail];
    [stanza up];
    [stanza up];

    [stanza addChildWithName:@"field" andAttributes:{@"var": @"given_name"}];
    [stanza addChildWithName:@"value"];
    [stanza addTextNode:aName];
    [stanza up];
    [stanza up];

    [stanza addChildWithName:@"field" andAttributes:{@"var": @"surname"}];
    [stanza addChildWithName:@"value"];
    [stanza addTextNode:aSurname];
    [stanza up];
    [stanza up];

    [_connection registerSelector:@selector(_didRegisterUser:) ofObject:self withDict:params];
    [_connection send:stanza];
}

/*! @ignore
*/
- (void)_didRegisterUser:(TNStropheStanza)aStanza
{
    if (_delegate && [_delegate respondsToSelector:@selector(serverAdmin:didRegisterUser:)])
        [_delegate serverAdmin:self didRegisterUser:aStanza];
    else
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheServerAdministrationRegisterUserNotification object:self userInfo:aStanza];
}

/*! remove a user from the server
    @param someJIDs array of TNStropheJID to remove
*/
- (void)unregisterUsers:(CPArray)someJIDs
{
    var uid         = [_connection getUniqueId],
        stanza      = [TNStropheStanza iqWithAttributes:{@"id": uid, @"type": @"set"}],
        params      = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [stanza setTo:_server];
    [stanza addChildWithName:@"command" andAttributes:{
        @"xmlns": Strophe.NS.COMMAND,
        @"node": @"http://jabber.org/protocol/admin#delete-user"}];

    [stanza addChildWithName:@"x" andAttributes:{@"xmlns": @"jabber:x:data", @"type": @"submit"}];

    [stanza addChildWithName:@"field" andAttributes:{@"type": @"hidden", @"var": @"FORM_TYPE"}];
    [stanza addChildWithName:@"value"];
    [stanza addTextNode:@"http://jabber.org/protocol/admin"];
    [stanza up];
    [stanza up];

    [stanza addChildWithName:@"field" andAttributes:{@"var": @"accountjids"}];
    for (var i = 0; i < [someJIDs count]; i++)
    {
        [stanza addChildWithName:@"value"];
        [stanza addTextNode:[[someJIDs objectAtIndex:i] bare]];
        [stanza up];
    }
    [stanza up];

    [_connection registerSelector:@selector(_didUnregisterUser:) ofObject:self withDict:params];
    [_connection send:stanza];
}

/*! @ignore
*/
- (void)_didUnregisterUser:(TNStropheStanza)aStanza
{
    if (_delegate && [_delegate respondsToSelector:@selector(serverAdmin:didUnregisterUser:)])
        [_delegate serverAdmin:self didUnregisterUser:aStanza];
    else
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheServerAdministrationUnregisterUserNotification object:self userInfo:aStanza];
}

/*! set if user's account should be enabled or disabled
    @param someJIDs array of target TNStropheJID
    @param shouldEnable enable or disable the accounts
*/
- (void)setUsers:(CPArray)someJIDs enabled:(BOOL)shouldEnable
{
    var uid         = [_connection getUniqueId],
        stanza      = [TNStropheStanza iqWithAttributes:{@"id": uid, @"type": @"set"}],
        params      = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"],
        node        = (shouldEnable) ? @"http://jabber.org/protocol/admin#reenable-user" : @"http://jabber.org/protocol/admin#disable-user";

    [stanza setTo:_server];
    [stanza addChildWithName:@"command" andAttributes:{
        @"xmlns": Strophe.NS.COMMAND,
        @"node": node}];

    [stanza addChildWithName:@"x" andAttributes:{@"xmlns": @"jabber:x:data", @"type": @"submit"}];

    [stanza addChildWithName:@"field" andAttributes:{@"type": @"hidden", @"var": @"FORM_TYPE"}];
    [stanza addChildWithName:@"value"];
    [stanza addTextNode:@"http://jabber.org/protocol/admin"];
    [stanza up];
    [stanza up];

    [stanza addChildWithName:@"field" andAttributes:{@"var": @"accountjids"}];
    for (var i = 0; i < [someJIDs count]; i++)
    {
        [stanza addChildWithName:@"value"];
        [stanza addTextNode:[[someJIDs objectAtIndex:i] bare]];
        [stanza up];
    }
    [stanza up];

    [_connection registerSelector:@selector(_didEnableUsers:) ofObject:self withDict:params];
    [_connection send:stanza];
}

/*! @ignore
*/
- (void)_didEnableUsers:(TNStropheStanza)aStanza
{
    if (_delegate && [_delegate respondsToSelector:@selector(serverAdmin:didEnableUsers:)])
        [_delegate serverAdmin:self didEnableUsers:aStanza];
    else
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheServerAdministrationSetUserEnabledNotification object:self userInfo:aStanza];
}

@end


/*! Subclass of TNStropheServerAdministration that handles
    the ejabberd way to get registred users
*/
@implementation TNStropheEjabberdAdministration : TNStropheServerAdministration

/*! get all the rgistered users
    ONLY WITH EJABBERD
*/
- (void)registredUsers
{
    var uid         = [_connection getUniqueId],
        stanza      = [TNStropheStanza iqWithAttributes:{@"id": uid, @"type": @"get"}],
        params      = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [stanza setTo:_server];
    [stanza addChildWithName:@"query" andAttributes:{
        @"xmlns": @"http://jabber.org/protocol/disco#items",
        @"node": @"all users"}];

    [_connection registerSelector:@selector(_didGetRegisteredUsers:) ofObject:self withDict:params];
    [_connection send:stanza];
}

- (void)_didGetRegisteredUsers:(TNStropheStanza)aStanza
{
    if ([aStanza type] != @"result")
        [CPException raise:@"error" reason:@"stanza error"];

    var users = [CPArray array],
        items = [aStanza childrenWithName:@"item"];

    for (var i = 0; i < [items count]; i++)
        [users addObject:[TNStropheJID stropheJIDWithString:[[items objectAtIndex:i] valueForAttribute:@"jid"]]];

    if (_delegate && [_delegate respondsToSelector:@selector(serverAdmin:didGetRegisteredUsers:)])
        [_delegate serverAdmin:self didGetRegisteredUsers:users];
    else
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStropheServerAdministrationGetRegisteredUserNotification object:self userInfo:users];
}


@end
