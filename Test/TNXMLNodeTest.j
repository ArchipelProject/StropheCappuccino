/*
 * TNXMLNodeTest.j
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
@import <AppKit/AppKit.j>

@import "../Resources/Strophe/strophe.js"
@import "../Resources/Strophe/sha1.js"
@import "../TNXMLNode.j"


@implementation TNXMLNodeTest : OJTestCase
{
    TNXMLNode   node;
}

- (void)setUp
{
    node = [[TNXMLNode alloc] initWithName:@"testnode" andAttributes:{@"type": "test"}];
}

- (void)testInit
{
    [self assert:[node name] equals:@"testnode"];
    [self assert:[node valueForAttribute:@"type"] equals:@"test"];
}

- (void)testNodeBuilding
{
    [node addChildWithName:@"subnode" andAttributes:{"attr1": "1", "attr2": "2"}];
    [node addTextNode:@"cdata"];

    [self assert:@"testnode" equals:[node name]];
    [self assert:1 equals:[[node children] count]];
    [self assert:@"cdata" equals:[[node firstChildWithName:@"subnode"] text]];
}

- (void)testCopy
{
    [node addChildWithName:@"subnode" andAttributes:{"attr1": "1", "attr2": "2"}];
    [node addTextNode:@"cdata"];

    var node2 = [node copy];

    [node2 addChildWithName:@"subsubnode"];

    [self assert:1 equals:[[node children] count]];
    [self assert:2 equals:[[node2 children] count]];
}

- (void)testNodeBrowsing
{
    [node addChildWithName:@"subnodeA1" andAttributes:{"attr1": "A1"}];
    [node addChildWithName:@"subnodeB1" andAttributes:{"attr1": "B1"}];
    [node addChildWithName:@"subnodeC1" andAttributes:{"attr1": "C1"}];
    [node up];
    [node addChildWithName:@"subnodeB2" andAttributes:{"attr1": "B2"}];
    [node up];
    [node up];
    [node addChildWithName:@"subnodeA2" andAttributes:{"attr1": "A2"}];
    [node up];

    [self assert:"A1" equals:[[node firstChildWithName:@"subnodeA1"] valueForAttribute:@"attr1"]];
    [self assert:2 equals:[[node children] count]];
    [self assert:1 equals:[[[node firstChildWithName:@"subnodeB1"] children] count]];
    [self assert:0 equals:[[[node firstChildWithName:@"subnodeB2"] children] count]];
}

- (void)tearDown
{
}

@end