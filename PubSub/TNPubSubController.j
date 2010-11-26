 /*
  * TNPubSubController.j
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

@import "../TNStropheGlobals.j"
@import "../TNStropheConnection.j"
@import "TNPubSubNode.j"


/*! @ingroup strophecappuccino
    this is an implementation of a XMPP Publish-Subscribe controller
*/
@implementation TNPubSubController : CPObject
{
    CPArray         _nodes                  @accessors(getter=nodes);
    CPArray         _servers                @accessors(property=servers);
    id              _delegate               @accessors(property=delegate);
    id              _connection;
    CPDictionary    _subscriptionBatches;
    CPDictionary    _unsubscriptionBatches;
    int             _numberOfPromptedServers;
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

/*! create and initialize and return a new TNPubSubController
    @param  aConnection the TNStropheConnection to use to communicate
    @return initialized TNPubSubController
*/
+ (TNPubSubNode)pubSubControllerWithConnection:(TNStropheConnection)aConnection
{
    return [[TNPubSubController alloc] initWithConnection:aConnection pubSubServer:nil];
}


#pragma mark -
#pragma mark Initialization

/*! initialize and return a new TNPubSubController
    @param  aConnection the TNStropheConnection to use to communicate
    @param  aPubSubServer a pubsubserver. if nil, it will be pubsub. + domain of [_connection JID]
    @return initialized TNPubSubController
*/
- (TNPubSubNode)initWithConnection:(TNStropheConnection)aConnection pubSubServer:(TNStropheJID)aPubSubServer
{
    if (self = [super init])
    {
        _connection                 = aConnection;
        _servers                    = [CPArray arrayWithObject:(aPubSubServer || [TNStropheJID stropheJIDWithString:@"pubsub." + [[aConnection JID] domain]])];
        _numberOfPromptedServers    = 0;
        _nodes                      = [CPArray array];
        _subscriptionBatches        = [CPDictionary dictionary];
        _unsubscriptionBatches      = [CPDictionary dictionary];
    }

    return self;
}


#pragma mark -
#pragma mark Notification handlers

/*! notification send when subscribed to a node
    it will call the delegate pubSubController:subscribedToNode:
*/
- (void)_didSubscribeToNode:(CPNotification)aNotification
{
    if (_delegate && [_delegate respondsToSelector:@selector(pubSubController:subscribedToNode:)])
        [_delegate pubSubController:self subscribedToNode:[aNotification object]]
}

/*! notification send when unsubscribed from a node
    it will call the delegate pubSubController:subscribedToNode:
*/
- (void)_didUnsubscribeToNode:(CPNotification)aNotification
{
    if (_delegate && [_delegate respondsToSelector:@selector(pubSubController:unsubscribedFromNode:)])
        [_delegate pubSubController:self unsubscribedFromNode:[aNotification object]]
}

/*! notification send when a batch subscription is done
*/
- (void)_didBatchSubscribe:(CPNotification)aNotification
{
    var node    = [aNotification object],
        batchID = [aNotification useInfo],
        batch   = [_subscriptionBatches valueForKey:batchID],
        params  = [CPDictionary dictionaryWithObject:batchID forKey:@"batchID"];

    [batch removeObjectIdenticalTo:[node name]];

    if ([batch count] === 0)
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStrophePubSubBatchSubscribeComplete object:self userInfo:params];
}

/*! notification send when a batch unsubscription is done
*/
- (void)_didBatchUnsubscribe:(CPNotification)aNotification
{
    var node    = [aNotification object],
        batchID = [aNotification useInfo],
        batch   = [_unsubscriptionBatches valueForKey:batchID],
        params  = [CPDictionary dictionaryWithObject:batchID forKey:@"batchID"];

    [batch removeObjectIdenticalTo:[node name]];

    if ([batch count] === 0)
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStrophePubSubBatchUnsubscribeComplete object:self userInfo:params];
}


#pragma mark -
#pragma mark Utilities

/*! returns YES is server list contains a given server
    @param aServerJID the server to search
    @return YES if aServerJID is already in list
*/
- (BOOL)containsServerJID:(TNStropheJID)aServerJID
{
    for (var i = 0; i < [_servers count]; i++)
        if ([[_servers objectAtIndex:i] node] == [aServerJID node])
            return YES;
    return NO;
}

/*! returns the node with given name, or null if not it not exists
    @param aNodeName the name of the node
    @param aServer the server of the node if nil, will return the first matching node with name
    @return the TNPubSubNode with given name or nil
*/
- (TNPubSubNode)nodeWithName:(CPString)aNodeName server:(TNStropheJID)aServer
{
    for (var i = 0; i < [_nodes count]; i++)
    {
        var node = [_nodes objectAtIndex:i];

        if (([node name] === aNodeName) && (!aServer || [[node server] equals:aServer]))
            return node;
    }

    return nil;
}

/*! returns the node with given name, or null if not it not exists
    @param aNodeName the name of the node
    @return the TNPubSubNode with given name or nil
*/
- (TNPubSubNode)nodeWithName:(CPString)aNodeName
{
    return [self nodeWithName:aNodeName server:nil];
}

/*! returns the node with given name, or initialize a new one if not it not exists
    @param aNodeName the name of the node
    @param aServer the server of the node if nil, will return the first matching node with name
    @return the TNPubSubNode with given name or new one if not found
*/
- (TNPubSubNode)findOrCreateNodeWithName:(CPString)aNodeName server:(TNStropheJID)aServer
{
    var node = [self nodeWithName:aNodeName server:aServer];

    if (![self containsServerJID:aServer])
        [_servers addObject:aServer];

    if (!node)
    {
        node = [TNPubSubNode pubSubNodeWithNodeName:aNodeName connection:_connection pubSubServer:aServer];
        [_nodes addObject:node];
    }
    return node;
}

#pragma mark -
#pragma mark Subscription Management

/*! retrieve all the subscription of the user
    from all given servers
*/
- (void)retrieveSubscriptions
{
    _numberOfPromptedServers = 0;

    for (var i = 0; i < [_servers count]; i++)
    {
        var uid     = [_connection getUniqueId],
            stanza  = [TNStropheStanza iqWithAttributes:{"type": "get", "to": [_servers objectAtIndex:i], "id": uid}],
            params  = [CPDictionary dictionaryWithObjectsAndKeys:uid,@"id"];

        [stanza addChildWithName:@"pubsub" andAttributes:{"xmlns": Strophe.NS.PUBSUB}];
        [stanza addChildWithName:@"subscriptions"];

        [_connection registerSelector:@selector(_didRetrieveSubscriptions:) ofObject:self withDict:params];

        [_connection send:stanza];
    }
}

/*! @ignore
*/
- (BOOL)_didRetrieveSubscriptions:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var subscriptions   = [aStanza childrenWithName:@"subscription"],
            server          = [aStanza from];

        for (var i = 0; i < [subscriptions count]; i++)
        {
            var subscription    = [subscriptions objectAtIndex:i],
                nodeName        = [subscription valueForAttribute:@"node"],
                subid           = [subscription valueForAttribute:@"subid"],
                node            = [self findOrCreateNodeWithName:nodeName server:server];

            [node addSubscriptionID:subid];

            [[CPNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_didSubscribeToNode:)
                                                         name:TNStrophePubSubNodeSubscribedNotification
                                                       object:node];

            [[CPNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_didUnsubscribeToNode:)
                                                         name:TNStrophePubSubNodeUnsubscribedNotification
                                                       object:node];
        }

        _numberOfPromptedServers++;

        if (_numberOfPromptedServers >= [_servers count])
        {
            _numberOfPromptedServers = 0;

            [[CPNotificationCenter defaultCenter] postNotificationName:TNStrophePubSubSubscriptionsRetrievedNotification object:self];
            if (_delegate && [_delegate respondsToSelector:@selector(pubSubController:retrievedSubscriptions:)])
                [_delegate pubSubController:self retrievedSubscriptions:YES];
        }
    }
    else
    {
        if (_delegate && [_delegate respondsToSelector:@selector(pubSubController:retrievedSubscriptions:)])
            [_delegate pubSubController:self retrievedSubscriptions:NO];
        CPLog.error("Cannot retrieve the contents of pubsub node");
        CPLog.error(aStanza);
    }


    return NO;
}

/*! subscribe to a node with given name from given server with given delegate
    @param aNodeName the name of the node to subscribe
    @param aServer the server where is located the node
    @param nodeDelegate the delegate that'll be assigned to the node
*/
- (TNPubSubNode)subscribeToNodeWithName:(CPString)aNodeName server:(TNStropheJID)aServer nodeDelegate:(id)nodeDelegate
{
    var node = [self findOrCreateNodeWithName:aNodeName server:aServer];

    [node setDelegate:nodeDelegate];
    [node subscribe];

    return node;
}

/*! subscribe to a node with given name from given server
    @param aNodeName the name of the node to subscribe
    @param aServer the server where is located the node
*/
- (TNPubSubNode)subscribeToNodeWithName:(CPString)aNodeName server:(TNStropheJID)aServer
{
    return [self subscribeToNodeWithName:aNodeName server:aServer nodeDelegate:nil];
}

/*! batch subscribe to nodes
    @param someNodes a CPDictionnary servers as key, and CPArray of node names as values
    posts TNStrophePubSubBatchSubscribeComplete when all nodes have been subscribed
    @return batchID an ID for this batch used to establish the relevance of completion notification
*/
- (CPString)subscribeToNodesWithNames:(CPDictionary)someNodes nodesDelegate:(id)aDelegate
{
    var batchID = [_connection getUniqueId],
        servers = [someNodes allKeys];

    [_subscriptionBatches setValue:someNodes forKey:batchID];

    for (var k = 0; k < [servers count]; k++)
    {
        var server = [servers objectAtIndex:k],
            nodes = [servers valueForKey:server];

        for (var i = 0; i < [nodes count]; i++)
        {
            var nodeName    = [nodes objectAtIndex:i],
                node        = [self subscribeToNodeWithName:nodeName server:server nodeDelegate:aDelegate];

            [[CPNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_didBatchSubscribe:)
                                                         name:TNStrophePubSubNodeSubscribedNotification
                                                       object:node
                                                     userInfo:batchID];
        }
    }

    return batchID;
}

/*! unsubscribe from a node with given name from given server with given delegate
    @param aNodeName the name of the node to unsubscribe
    @param aServer the server where is located the node
    @param nodeDelegate the delegate that'll be assigned to the node
*/
- (TNPubSubNode)unsubscribeFromNodeWithName:(CPString)aNodeName server:(TNStropheJID)aServer nodeDelegate:(id)nodeDelegate
{
    var node = [self findOrCreateNodeWithName:aNodeName server:aServer];

    [node setDelegate:nodeDelegate];
    [node unsubscribe];

    return node;
}

/*! unsubscribe from a node with given name from given server
    @param aNodeName the name of the node to subscribe
    @param aServer the server where is located the node
*/
- (TNPubSubNode)unsubscribeFromNodeWithName:(CPString)aNodeName server:(TNStropheJID)aServer
{
    return [self unsubscribeFromNodeWithName:aNodeName server:aServer nodeDelegate:nil];
}

/*! batch unsubscribe to nodes
    @param someNodes a CPDictionnary servers as key, and CPArray of node names as values
    posts TNStrophePubSubBatchSubscribeComplete when all nodes have been subscribed
    @return batchID an ID for this batch used to establish the relevance of completion notification
*/
- (CPString)unsubscribeFromNodesWithNames:(CPDictionary)someNodes nodesDelegate:(id)aDelegate
{
    var batchID = [_connection getUniqueId],
        servers = [someNodes allKeys];

    [_unsubscriptionBatches setValue:someNodes forKey:batchID];

    for (var k = 0; k < [servers count]; k++)
    {
        var server = [servers objectAtIndex:k],
            nodes = [servers valueForKey:server];

        for (var i = 0; i < [nodes count]; i++)
        {
            var nodeName    = [nodes objectAtIndex:i],
                node        = [self unsubscribeFromNodeWithName:nodeName server:server nodeDelegate:aDelegate];

            [[CPNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_didBatchUnsubscribe:)
                                                         name:TNStrophePubSubNodeUnsubscribedNotification
                                                       object:node
                                                     userInfo:batchID];
        }
    }

    return batchID;
}

/*! unsubscribe from all nodes
*/
- (void)unsubscribeFromAllNodes
{
    for (var i = 0; i < [_nodes count]; i++)
        [[_nodes objectAtIndex:i] unsubscribe];
}

@end
