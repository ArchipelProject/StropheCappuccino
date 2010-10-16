/*  
 * StropheCappuccino.j
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
@import "TNStropheStanza.j"
@import "TNStropheGroup.j"
@import "TNStropheConnection.j"
@import "TNStropheContact.j"
@import "TNStropheRoster.j"
@import "TNPubSubNode.j"
@import "TNPubSubController.j"
@import "TNBase64Image.j"

[TNStropheConnection addNamespaceWithName:@"CAPS" value:@"http://jabber.org/protocol/caps"];
[TNStropheConnection addNamespaceWithName:@"PUBSUB" value:@"http://jabber.org/protocol/pubsub"];
[TNStropheConnection addNamespaceWithName:@"PUBSUB_EVENT" value:@"http://jabber.org/protocol/pubsub#event"];
[TNStropheConnection addNamespaceWithName:@"PUBSUB_OWNER" value:@"http://jabber.org/protocol/pubsub#owner"];
[TNStropheConnection addNamespaceWithName:@"PUBSUB_NODE_CONFIG" value:@"http://jabber.org/protocol/pubsub#node_config"];
[TNStropheConnection addNamespaceWithName:@"PUBSUB_NOTIFY" value:@"http://jabber.org/protocol/pubsub+notify"];
[TNStropheConnection addNamespaceWithName:@"PUBSUB_SUBSCRIBE OPTIONS" value:@"http://jabber.org/protocol/pubsub#subscribe_options"];
[TNStropheConnection addNamespaceWithName:@"DELAY" value:@"urn:xmpp:delay"];
[TNStropheConnection addNamespaceWithName:@"X_DATA" value:@"jabber:x:data"];

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
