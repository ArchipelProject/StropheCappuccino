/*
 * TNPubSubController.j
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

@import "TNStropheGlobals.j"
@import "TNStropheConnection.j"
@import "TNPubSubNode.j"


/*! @ingroup strophecappuccino
    this is an implementation of a XMPP Publish-Subscribe controller
*/
@implementation TNPubSubController : CPObject
{
    CPArray     _nodes          @accessors(getter=nodes);
    id          _connection;
    CPString    _server         @accessors(property=server);
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
        _connection = aConnection;
        _server     = aPubSubServer;
        _nodes      = [CPArray array];
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

- (void)subscribeToNode:(CPString)aNodeName
{
    var node = [self findOrCreateNodeWithName:aNodeName];
    [node subscribe];
}

@end
