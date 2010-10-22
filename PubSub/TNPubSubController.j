/*
 * TNPubSubController.j
 *
 * Copyright (C) 2010 Ben Langfeld <ben@langfeld.me>
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

@import "../TNStropheGlobals.j"
@import "../TNStropheConnection.j"
@import "TNPubSubNode.j"


/*! @ingroup strophecappuccino
    this is an implementation of a XMPP Publish-Subscribe controller
*/
@implementation TNPubSubController : CPObject
{
    CPArray         _nodes                  @accessors(getter=nodes);
    id              _connection;
    CPString        _server                 @accessors(property=server);
    CPDictionary    _subscriptionBatches;
}

#pragma mark -
#pragma mark Class methods

/*! create and initialize and return a new TNPubSubController
    @param  aConnection the TNStropheConnection to use to communicate
    @param  aPubSubServer a pubsubserver. if nil, it will be pubsub. + domain of [_connection JID]
    @return initialized TNPubSubController
*/
+ (TNPubSubNode)pubSubControllerWithConnection:(TNStropheConnection)aConnection pubSubServer:(CPString)aPubSubServer
{
    return [[TNPubSubController alloc] initWithConnection:aConnection pubSubServer:aPubSubServer];
}


#pragma mark -
#pragma mark Initialization

/*! initialize and return a new TNPubSubController
    @param  aConnection the TNStropheConnection to use to communicate
    @param  aPubSubServer a pubsubserver. if nil, it will be pubsub. + domain of [_connection JID]
    @return initialized TNPubSubController
*/
- (TNPubSubNode)initWithConnection:(TNStropheConnection)aConnection pubSubServer:(CPString)aPubSubServer
{
    if (self = [super init])
    {
        _connection             = aConnection;
        _server                 = aPubSubServer;
        _nodes                  = [CPArray array];
        _subscriptionBatches    = [CPDictionary dictionary];
    }

    return self;
}


#pragma mark -
#pragma mark Node Management

- (TNPubSubNode)findOrCreateNodeWithName:(CPString)aNodeName
{
    var node = [self nodeWithName:aNodeName];
    if (!node)
    {
        node = [TNPubSubNode pubSubNodeWithNodeName:aNodeName connection:_connection pubSubServer:_server];
        [_nodes addObject:node];
    }
    return node;
}

- (TNPubSubNode)nodeWithName:(CPString)aNodeName
{
    for (var i = 0; i < [_nodes count]; i++)
    {
        var node = _nodes[i];
        if ([node name] === aNodeName)
            return node;
    }
}

- (TNPubSubNode)subscribeToNode:(CPString)aNodeName
{
    var node = [self findOrCreateNodeWithName:aNodeName];
    [node subscribe];
    return node;
}

/*! batch subscribe to nodes
    @param someNodes an array of node names to subscribe to
        posts TNStrophePubSubBatchSubscribeComplete when all nodes have been subscribed
    @return batchID an ID for this batch used to establish the relevance of completion notification
*/
- (CPString)subscribeToNodes:(CPArray)someNodes
{
    var batchID = [_connection getUniqueId];

    [_subscriptionBatches setValue:someNodes forKey:batchID];

    for (var i = 0; i < [someNodes count]; i++)
    {
        var nodeName    = someNodes[i],
            node        = [self subscribeToNode:nodeName];

        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_monitorBatchSubscriptions:) name:TNStrophePubSubNodeSubscribedNotification object:node];
    }

    return batchID;
}

- (void)_monitorBatchSubscriptions:(CPNotification)aNotification
{
    var node    = [aNotification object],
        batchID = [self _findBatchIdForNode:node],
        batch   = [_subscriptionBatches valueForKey:batchID],
        params  = [CPDictionary dictionaryWithObject:batchID forKey:@"batchID"];

    [batch removeObjectIdenticalTo:[node name]];

    if ([batch count] === 0)
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStrophePubSubBatchSubscribeComplete object:self userInfo:params];
}

- (CPString)_findBatchIdForNode:(TNPubSubNode)aNode
{
    var keys = [_subscriptionBatches allKeys];
    for (var i = 0; i < [keys count]; i++)
    {
        var batchID = keys[i],
            batch   = [_subscriptionBatches valueForKey:batchID];

        if ([batch containsObject:[aNode name]])
            return batchID;
    }
}


#pragma mark -
#pragma mark Subscription Management

- (void)retrieveAllSubscriptions
{
    var uid     = [_connection getUniqueId],
        stanza  = [TNStropheStanza iqWithAttributes:{"type": "get", "to": _server, "id": uid}],
        params  = [CPDictionary dictionaryWithObjectsAndKeys:uid,@"id"];

    [stanza addChildWithName:@"pubsub" andAttributes:{"xmlns": Strophe.NS.PUBSUB}];
    [stanza addChildWithName:@"subscriptions"];

    [_connection registerSelector:@selector(_didRetrieveSubscriptions:) ofObject:self withDict:params];

    [_connection send:stanza];
}

- (BOOL)_didRetrieveSubscriptions:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var subscriptions = [[[aStanza firstChildWithName:@"pubsub"] firstChildWithName:@"subscriptions"] childrenWithName:@"subscription"];

        for (var i = 0; i < [subscriptions count]; i++)
        {
            var subscription    = subscriptions[i],
                nodeName        = [subscription valueForAttribute:@"node"],
                subid           = [subscription valueForAttribute:@"subid"],
                node            = [self findOrCreateNodeWithName:nodeName];

            [node addSubscriptionID:subid];
        }

        [[CPNotificationCenter defaultCenter] postNotificationName:TNStrophePubSubSubscriptionsRetrievedNotification object:self];
    }
    else
        CPLog.error("Cannot retrieve the contents of pubsub node with name: " + _nodeName);

    return NO;
}

- (void)removeAllExistingSubscriptions
{
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(unsubscribeFromAllNodes:) name:TNStrophePubSubSubscriptionsRetrievedNotification object:self];
    [self retrieveAllSubscriptions];
}

- (void)unsubscribeFromAllNodes:(CPNotification)aNotification
{
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_monitorUnsubscriptions:) name:TNStrophePubSubNodeUnsubscribedNotification object:nil];

    if ([_nodes count] < 1)
    {
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStrophePubSubNoOldSubscriptionsLeftNotification object:self];
        return;
    }

    for (var i = 0; i < [_nodes count]; i++)
    {
        [_nodes[i] unsubscribe];
    }
}

- (void)_monitorUnsubscriptions:(CPNotification)aNotification
{
    var numberOfOutstandingSubscriptions = 0;
    for (var i = 0; i < [_nodes count]; i++)
        numberOfOutstandingSubscriptions += [_nodes[i] numberOfSubscriptions];

    if (numberOfOutstandingSubscriptions === 0)
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStrophePubSubNoOldSubscriptionsLeftNotification object:self];
}

@end
