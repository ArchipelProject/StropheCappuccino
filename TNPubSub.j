@import "PubSub/TNPubSubNode.j"
@import "PubSub/TNPubSubController.j"

[TNStropheConnection addNamespaceWithName:@"PUBSUB" value:@"http://jabber.org/protocol/pubsub"];
[TNStropheConnection addNamespaceWithName:@"PUBSUB_EVENT" value:@"http://jabber.org/protocol/pubsub#event"];
[TNStropheConnection addNamespaceWithName:@"PUBSUB_OWNER" value:@"http://jabber.org/protocol/pubsub#owner"];
[TNStropheConnection addNamespaceWithName:@"PUBSUB_NODE_CONFIG" value:@"http://jabber.org/protocol/pubsub#node_config"];
[TNStropheConnection addNamespaceWithName:@"PUBSUB_NOTIFY" value:@"http://jabber.org/protocol/pubsub+notify"];
[TNStropheConnection addNamespaceWithName:@"PUBSUB_SUBSCRIBE OPTIONS" value:@"http://jabber.org/protocol/pubsub#subscribe_options"];