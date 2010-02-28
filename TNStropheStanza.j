/*  
 * TNStropheStanza.j
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


@implementation TNXMLNode : CPObject
{
    XMLElement  _xmlNode     @accessors(readonly, getter=xmlNode);
}

+ (TNXMLNode)nodeWithXMLNode:(id)aNode
{
    return [[TNXMLNode alloc] initWithNode:aNode];
}

- (void)initWithNode:(id)aNode
{
    if (self == [super init])
    {
        _xmlNode = aNode;
    }
    
    return self;
}

- (id)initWithName:(CPString)aName andAttributes:(CPDictionary)attributes
{
    if (self = [super init])
    {
        _xmlNode = new Strophe.Builder(aName, attributes);
    }
    
    return self;
}

- (void)addChildName:(CPString)aTagName withAttributes:(CPDictionary)attributes 
{
    _xmlNode = _xmlNode.c(aTagName, attributes);
}

- (void)addChildName:(CPString)aTagName
{
    _xmlNode = _xmlNode.c(aTagName, {});
}

- (void)addTextNode:(CPString)aText
{
    _xmlNode = _xmlNode.t(aText);
}

- (id)tree
{
    return _xmlNode.tree();
}

- (CPString)stringValue
{
    return _xmlNode.toString();
}

- (void)up
{
    _xmlNode = _xmlNode.up();
}


- (CPString)getValueForAttribute:(CPString)anAttribute
{
    return _xmlNode.getAttribute(anAttribute);
}

- (CPArray)getChildrenWithName:(CPString)aName
{
    var nodes   = [[CPArray alloc] init];
    var temp    = _xmlNode.getElementsByTagName(aName);
    
    for (var i = 0; i < temp.length; i++)
        [nodes addObject:[TNXMLNode nodeWithXMLNode:temp[i]]]

    return nodes;
}

- (CPArray)getFirstChildWithName:(CPString)aName
{
    var elements = _xmlNode.getElementsByTagName(aName);

    if (elements.length >  0) 
        return [TNXMLNode nodeWithXMLNode:elements[0]];
    else
        return nil;
}

- (CPString)text
{
    return $(_xmlNode).text();
}

- (CPString)description
{
    return _xmlNode;
}
@end




/*! @ingroup strophecappuccino
    this is an implementation of a basic XMPP Stanza
*/
@implementation TNStropheStanza: TNXMLNode
{   
}

+ (TNStropheStanza)stanzaWithName:(CPString)aName andAttributes:(CPDictionary)attributes
{
    return [[TNStropheStanza alloc] initWithName:aName andAttributes:attributes];
}

+ (TNStropheStanza)iqWithAttributes:(CPDictionary)attributes
{
    return [[TNStropheStanza alloc] initWithName:@"iq" andAttributes:attributes];
}

+ (TNStropheStanza)presenceWithAttributes:(CPDictionary)attributes
{
    return [[TNStropheStanza alloc] initWithName:@"presence" andAttributes:attributes];
}

+ (TNStropheStanza)messageWithAttributes:(CPDictionary)attributes
{
    return [[TNStropheStanza alloc] initWithName:@"message" andAttributes:attributes];
}

+ (TNStropheStanza)stanzaWithStanza:(id)aStanza
{
    return [[TNStropheStanza alloc] initWithNode:aStanza];
}


- (CPString)getType
{
    return [self getValueForAttribute:@"type"];
}

- (CPString)description
{
    return [self stringValue];
}

- (CPString)getFrom
{
    return [self getValueForAttribute:@"from"];
}

- (CPString)getTo
{
    return [self getValueForAttribute:@"to"];
}

- (CPString)getType
{
    return [self getValueForAttribute:@"type"];
}

- (CPString)getNamespace
{
    return [self getValueForAttribute:@"xmlns"];
}

- (CPString)getID
{
    return [self getValueForAttribute:@"id"];
}

-(CPString)getFromResource
{
    return [[[self getFrom] componentsSeparatedByString:@"/"] objectAtIndex:1];
}
@end

