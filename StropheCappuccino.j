/*
 * StropheCappuccino.j
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


@import "Resources/Strophe/strophe.js"
@import "Resources/Strophe/sha1.js"
@import "TNStropheJID.j"
@import "TNStropheStanza.j"
@import "TNStropheGroup.j"
@import "TNStropheIMClient.j"
@import "TNStropheClient.j"
@import "TNStropheConnection.j"
@import "TNStropheContact.j"
@import "TNStropheRoster.j"
@import "TNPubSub.j"
@import "TNStrophePrivateStorage.j"
@import "TNStropheServerAdministration.j"
@import "MUC/TNStropheMUCRoom.j"


[TNStropheClient addNamespaceWithName:@"CAPS" value:@"http://jabber.org/protocol/caps"];
[TNStropheClient addNamespaceWithName:@"DELAY" value:@"urn:xmpp:delay"];
[TNStropheClient addNamespaceWithName:@"X_DATA" value:@"jabber:x:data"];
[TNStropheClient addNamespaceWithName:@"PING" value:@"urn:xmpp:ping"];
[TNStropheClient addNamespaceWithName:@"PRIVATE_STORAGE" value:@"jabber:iq:private"];
[TNStropheClient addNamespaceWithName:@"COMMAND" value:@"http://jabber.org/protocol/commands"];

/*! @mainpage
    StropheCappuccino is distributed under the @ref license "AGPL".

    @htmlonly <pre>@endhtmlonly
    @htmlinclude README
    @htmlonly </pre>@endhtmlonly

    @page license License
    @htmlonly <pre>@endhtmlonly
    @htmlinclude LICENSE
    @htmlonly </pre>@endhtmlonly

    @defgroup strophecappuccino StropheCappuccino
*/
