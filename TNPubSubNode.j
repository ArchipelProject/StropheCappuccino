/*
 * TNPubSubNode.j
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
    this is an implementation of a XMPP Publish-Subscribe node
*/
@implementation TNPubSubNode : CPObject
{
    CPArray                 _content        @accessors(getter=content);
    id                      _delegate       @accessors(property=delegate);
    CPString                _nodeName;
    CPString                _pubSubServer;
    TNStropheConnection     _connection;
    id                      _eventSelectorID;
}

#pragma mark -
#pragma mark Class methods

+ (void)registerSelector:(SEL)aSelector ofObject:(id)anObject forPubSubEventWithConnection:(TNStropheConnection)aConnection
{
    var params = [CPDictionary dictionaryWithObjectsAndKeys:@"message", @"name",
                                                            @"headline", @"type",
                                                            {"matchBare": YES}, @"options",
                                                            @"http://jabber.org/protocol/pubsub#event", @"namespace"];

    return [aConnection registerSelector:aSelector ofObject:anObject withDict:params];
}

#pragma mark -
#pragma mark Initialization

/*! create and initialize and return a new TNPubSubNode
    @param  aNodeName the name of the pubsub node
    @param  aConnection the TNStropheConnection to use to communicate
    @param aPubSubServer a pubsubserver. if nil, it will be pubsub. + domain of [_connection JID]
    @return initialized TNPubSubNode
*/
+ (TNPubSubNode)pubSubNodeWithNodeName:(CPString)aNodeName connection:(TNStropheConnection)aConnection pubSubServer:(CPString)aPubSubServer
{
    var pubsub = [[TNPubSubNode alloc] initWithNodeName:aNodeName connection:aConnection pubSubServer:aPubSubServer];

    return pubsub;
}

/*! initialize and return a new TNPubSubNode
    @param  aNodeName the name of the pubsub node
    @param  aConnection the TNStropheConnection to use to communicate
    @param aPubSubServer a pubsubserver. if nil, it will be pubsub. + domain of [_connection JID]
    @return initialized TNPubSubNode
*/
- (TNPubSubNode)initWithNodeName:(CPString)aNodeName connection:(TNStropheConnection)aConnection pubSubServer:(CPString)aPubSubServer
{
    if (self = [super init])
    {
        _nodeName           = aNodeName;
        _connection         = aConnection;
        _pubSubServer       = aPubSubServer ? aPubSubServer : [_connection JID].split("@")[1].split("/")[0];
        _content            = nil;
        _eventSelectorID    = nil;
    }

    return self;
}


#pragma mark -
#pragma mark Node Management

/*! recover the content of the PubSub node from the server and call _didRecoverPubSubNode selector
    You should use this method to populate the content property
*/
- (void)recover
{
    var uid     = [_connection getUniqueId],
        stanza  = [TNStropheStanza iq],
        params  = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [stanza setTo:_pubSubServer];
    [stanza setType:@"get"];
    [stanza setID:uid];

    [stanza addChildWithName:@"pubsub" andAttributes:{@"xmlns": "http://jabber.org/protocol/pubsub"}];
    [stanza addChildWithName:@"items" andAttributes:{@"node": _nodeName}];

    [_connection registerSelector:@selector(_didRecoverPubSubNode:) ofObject:self withDict:params];
    [_connection send:stanza];
}

/*! send TNStrophePubSubNodeRecoveredNotification if everything is ok
    @param aStanza TNStropheStanza contaning the response of the server
    @return NO in order to unregister the selector from connection
*/
- (BOOL)_didRecoverPubSubNode:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        _content = [aStanza childrenWithName:@"item"];
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStrophePubSubNodeRecoveredNotification object:self];
    }
    else
        CPLog.error("Cannot recover the pubsub node with name: " + _nodeName);

    return NO;
}

/*! ask server to create the pubsub node and call _didCreatePubSubNode selector
*/
- (void)create
{
    var uid     = [_connection getUniqueId],
        stanza  = [TNStropheStanza iq],
        params  = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [stanza setTo:_pubSubServer];
    [stanza setType:@"set"];
    [stanza setID:uid];

    [stanza addChildWithName:@"pubsub" andAttributes:{@"xmlns": "http://jabber.org/protocol/pubsub"}];
    [stanza addChildWithName:@"create" andAttributes:{@"node": _nodeName}];

    [_connection registerSelector:@selector(_didCreatePubSubNode:) ofObject:self withDict:params];
    [_connection send:stanza];
}

/*! send TNStrophePubSubNodeCreatedNotification if everything is OK
    @param aStanza TNStropheStanza contaning the response of the server
    @return NO in order to unregister the selector from connection
*/
- (BOOL)_didCreatePubSubNode:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStrophePubSubNodeCreatedNotification object:self];
    else
        CPLog.error("Cannot create the pubsub node with name: " + _nodeName);

    return NO;
}

/*! ask the server to delete the pubsub node
*/
- (void)delete
{
    var uid     = [_connection getUniqueId],
        stanza  = [TNStropheStanza iq],
        params  = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [stanza setTo:_pubSubServer];
    [stanza setType:@"set"];
    [stanza setID:uid];

    [stanza addChildWithName:@"pubsub" andAttributes:{@"xmlns": "http://jabber.org/protocol/pubsub#owner"}];
    [stanza addChildWithName:@"delete" andAttributes:{@"node": _nodeName}];

    [_connection registerSelector:@selector(didDeletePubSubNode:) ofObject:self withDict:params];
    [_connection send:stanza];
}

/*! send TNStrophePubSubNodeDeleted if everything is OK
    @param aStanza TNStropheStanza contaning the response of the server
    @return NO in order to unregister the selector from connection
*/
- (BOOL)_didCreatePubSubNode:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStrophePubSubNodeDeletedNotification object:self];
    else
        CPLog.error("Cannot delete the pubsub node with name: " + _nodeName);

    return NO;
}

/*! configure the pubsub node with given directory. This dictionary can be for example

    [CPDictionary dictionaryWithObjectsAndKeys:1, TNStrophePubSubVarDeliverNotification,
                                               10, TNStrophePubSubVarMaxItems,
                                               0, TNStrophePubSubVarPurgeOffline];
    See XEP-0060 for more information about configuring a PubSubNode.

    @param aDictionary CPDictionary containing the configuration of the node
*/
- (void)configureWithDict:(CPDictionary)aDictionary
{
    var uid     = [_connection getUniqueId],
        stanza  = [TNStropheStanza iq],
        params  = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [stanza setTo:_pubSubServer];
    [stanza setType:@"set"];
    [stanza setID:uid];

    [stanza addChildWithName:@"pubsub" andAttributes:{@"xmlns": "http://jabber.org/protocol/pubsub#owner"}];
    [stanza addChildWithName:@"configure" andAttributes:{@"node": _nodeName}];
    [stanza addChildWithName:@"x" andAttributes:{@"xmlns": "jabber:x:data", @"type": @"submit"}];
    [stanza addChildWithName:@"field" andAttributes:{@"var": @"FORM_TYPE", @"type": @"hidden"}];
    [stanza addChildWithName:@"value"];
    [stanza addTextNode:@"http://jabber.org/protocol/pubsub#node_config"];
    [stanza up];
    [stanza up];

    for (var i = 0; i < [[aDictionary allKeys] count]; i++)
    {
        var key     = [[aDictionary allKeys] objectAtIndex:i],
            value   = [aDictionary objectForKey:key];

        [stanza addChildWithName:@"field" andAttributes:{@"var": key}];

        if ([value class] == CPArray)
        {
            for (var j = 0; j < [value count]; j++)
            {
                [stanza addChildWithName:@"value"];
                [stanza addTextNode:@"" + [value objectAtIndex:j] + @""];
                [stanza up];
            }
        }
        else
        {
            [stanza addChildWithName:@"value"];
            [stanza addTextNode:@"" + value + @""];
            [stanza up];
        }
        [stanza up];
    }

    [_connection registerSelector:@selector(_didConfigurePubSubNode:) ofObject:self withDict:params];
    [_connection send:stanza];
}

/*! send TNStrophePubSubNodeConfiguredNotification if everything is OK
    @param aStanza TNStropheStanza contaning the response of the server
    @return NO in order to unregister the selector from connection
*/
- (BOOL)_didConfigurePubSubNode:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStrophePubSubNodeConfiguredNotification object:self];
    else
        CPLog.error("Cannot configure the pubsub node with name: " + _nodeName);

    return NO;
}


#pragma mark -
#pragma mark Item management

/*! Ask the server to publish a new item containing the content of the given TNXMLNode
    @params anItem TNXMLNode containing the content of the item
*/
- (void)publishItem:(TNXMLNode)anItem
{
    var uid     = [_connection getUniqueId],
        stanza  = [TNStropheStanza iq],
        params  = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [stanza setTo:_pubSubServer];
    [stanza setType:@"set"];
    [stanza setID:uid];

    [stanza addChildWithName:@"pubsub" andAttributes:{@"xmlns": "http://jabber.org/protocol/pubsub"}];
    [stanza addChildWithName:@"publish" andAttributes:{@"node": _nodeName}];
    [stanza addChildWithName:@"item"];
    [stanza addNode:anItem];

    [_connection registerSelector:@selector(_didPublishPubSubItem:) ofObject:self withDict:params];
    [_connection send:stanza];
}

/*! will recover the content of node if everything is OK
    @param aStanza TNStropheStanza contaning the response of the server
    @return NO in order to unregister the selector from connection
*/
- (BOOL)_didPublishPubSubItem:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didUpdateContentAfterPublishing:) name:TNStrophePubSubNodeRecoveredNotification object:self];
        [self recover];
    }
    else
        CPLog.error("Cannot publish the pubsub item in node with name: " + _nodeName);

    return NO;
}

/*! send TNStrophePubSubItemPublishedNotification if everything is OK
    @param aNotification CPNotification given by [TNPubSubNode recover]
*/
- (void)_didUpdateContentAfterPublishing:(CPNotification)aNotification
{
    [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStrophePubSubNodeRecoveredNotification object:self];
    [[CPNotificationCenter defaultCenter] postNotificationName:TNStrophePubSubItemPublishedNotification object:self];
}


/*! Ask the server to retract (remove) a new item according to the given ID
    @params anID CPString containing the ID of the item to retract
*/
- (void)retractItemWithID:(CPString)anID
{
    var uid     = [_connection getUniqueId],
        stanza  = [TNStropheStanza iq],
        params  = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [stanza setTo:_pubSubServer];
    [stanza setType:@"set"];
    [stanza setID:uid];

    [stanza addChildWithName:@"pubsub" andAttributes:{@"xmlns": "http://jabber.org/protocol/pubsub"}];
    [stanza addChildWithName:@"retract" andAttributes:{@"node": _nodeName}];
    [stanza addChildWithName:@"item" andAttributes:{@"id": anID}];

    [_connection registerSelector:@selector(_didRetractPubSubItem:) ofObject:self withDict:params];
    [_connection send:stanza];
}

/*! will recover the content of node if everything is OK
    @param aStanza TNStropheStanza contaning the response of the server
    @return NO in order to unregister the selector from connection
*/
- (BOOL)_didRetractPubSubItem:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didUpdateContentAfterRetracting:) name:TNStrophePubSubNodeRecoveredNotification object:self];
        [self recover];
    }
    else
        CPLog.error("Cannot remove the pubsub item in node with name: " + _nodeName);

    return NO;
}

/*! send TNStrophePubSubItemRetractedNotification if everything is OK
    @param aNotification CPNotification given by [TNPubSubNode recover]
*/
- (void)_didUpdateContentAfterRetracting:(CPNotification)aNotification
{
    [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStrophePubSubNodeRecoveredNotification object:self];
    [[CPNotificationCenter defaultCenter] postNotificationName:TNStrophePubSubItemRetractedNotification object:self];
}


#pragma mark -
#pragma mark Subscription Management

/*! Ask the server to subscribe to the node in order to recieve event.
*/
- (void)subscribe
{
    var uid    = [_connection getUniqueId],
        stanza = [TNStropheStanza iq],
        params = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [stanza setType:@"set"];
    [stanza setID:uid];
    [stanza setTo:_pubSubServer];

    [stanza addChildWithName:@"pubsub" andAttributes:{@"xmlns": @"http://jabber.org/protocol/pubsub"}];
    [stanza addChildWithName:@"subscribe" andAttributes:{@"node": _nodeName, @"jid": [_connection JID]}];

    [_connection registerSelector:@selector(_didSubscribe:) ofObject:self withDict:params]
    [_connection send:stanza];
}

/*! send TNStrophePubSubNodeSubscribedNotification if everything is OK and register __didReceiveEvent:
    that will eventually call the delegate selector pubsubNode:receivedEvent: when an event is recieved
    @param aStanza TNStropheStanza contaning the response of the server
    @return NO in order to unregister the selector from connection
*/
- (BOOL)_didSubscribe:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var params = [CPDictionary dictionaryWithObjectsAndKeys:@"message", @"name",
                                                                @"http://jabber.org/protocol/pubsub#event", @"namespace",
                                                                @"headline", @"type"];

        [[CPNotificationCenter defaultCenter] postNotificationName:TNStrophePubSubNodeSubscribedNotification object:self];

        _eventSelectorID = [_connection registerSelector:@selector(_didReceiveEvent:) ofObject:self withDict:params];
    }
    else
        CPLog.error("Cannot subscribe the pubsub node with name: " + _nodeName);

    return NO;
}

/*! Ask the server to unsubscribe from the node in order to recieve event.
*/
- (void)unsubscribe
{
    var uid    = [_connection getUniqueId],
        stanza = [TNStropheStanza iq],
        params = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [stanza setType:@"set"];
    [stanza setID:uid];
    [stanza setTo:_pubSubServer];

    [stanza addChildWithName:@"pubsub" andAttributes:{"xmlns": "http://jabber.org/protocol/pubsub"}];
    [stanza addChildWithName:@"unsubscribe" andAttributes:{"node": _nodeName, "jid": [_connection JID]}];

    [_connection registerSelector:@selector(_didUnsubscribe:) ofObject:self withDict:params];
    [_connection send:stanza];
}

/*! send TNStrophePubSubNodeUnsubscribedNotification if everything is OK and unregister __didReceiveEvent:
    @param aStanza TNStropheStanza contaning the response of the server
    @return NO in order to unregister the selector from connection
*/
- (BOOL)_didUnsubscribe:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStrophePubSubNodeUnsubscribedNotification object:self];
        if (_eventSelectorID)
        {
            [_connection deleteRegisteredSelector:_eventSelectorID];
            _eventSelectorID = nil;
        }
    }
    else
        CPLog.error("Cannot unsubscribe the pubsub node with name: " + _nodeName);

    return NO;
}


#pragma mark -
#pragma mark Event Management

/*! this message is send when a new pubsub event is recieved. It will call the delegate
    pubsubNode:receivedEvent: if any selector and send TNStrophePubSubNodeEventNotification notification
    @param aStanza TNStropheStanza contaning the response of the server
    @return NO in order to unregister the selector from connection
*/
- (BOOL)_didReceiveEvent:(TNStropheStanza)aStanza
{
    if (_delegate && [_delegate respondsToSelector:@selector(pubsubNode:receivedEvent:)])
        [_delegate pubsubNode:self receivedEvent:aStanza];

    [[CPNotificationCenter defaultCenter] postNotificationName:TNStrophePubSubNodeEventNotification object:self];

    return YES;
}

@end
