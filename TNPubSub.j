/*
 * TNPubSub.j
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

@import "TNStropheConnection.j"
@import "PubSub/TNPubSubNode.j"
@import "PubSub/TNPubSubController.j"

[TNStropheConnection addNamespaceWithName:@"PUBSUB" value:@"http://jabber.org/protocol/pubsub"];
[TNStropheConnection addNamespaceWithName:@"PUBSUB_EVENT" value:@"http://jabber.org/protocol/pubsub#event"];
[TNStropheConnection addNamespaceWithName:@"PUBSUB_OWNER" value:@"http://jabber.org/protocol/pubsub#owner"];
[TNStropheConnection addNamespaceWithName:@"PUBSUB_NODE_CONFIG" value:@"http://jabber.org/protocol/pubsub#node_config"];
[TNStropheConnection addNamespaceWithName:@"PUBSUB_NOTIFY" value:@"http://jabber.org/protocol/pubsub+notify"];
[TNStropheConnection addNamespaceWithName:@"PUBSUB_SUBSCRIBE OPTIONS" value:@"http://jabber.org/protocol/pubsub#subscribe_options"];
