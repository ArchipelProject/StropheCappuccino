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
    XMLElement  _xmlNode;
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
@end




/*! @ingroup strophecappuccino
    this is an implementation of a basic XMPP Stanza
*/
@implementation TNStropheStanza: TNXMLNode
{   
    id          _stanza     @accessors(readonly, getter=stanza);
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
    return [[TNStropheStanza alloc] initWithStanza:aStanza];
}

- (id)initWithName:(CPString)aName andAttributes:(CPDictionary)attributes
{
    if (self = [super init])
    {
        _stanza = new Strophe.Builder(aName, attributes);
        _xmlNode = _stanza.tree();
    }
    
    return self;
}

- (id)initWithStanza:(id)aStanza
{    
    if (self = [super init])
    {
        _stanza = aStanza;
        _xmlNode = aStanza;
    }

    return self;
}

- (void)addChildName:(CPString)aTagName withAttributes:(CPDictionary)attributes 
{
    _stanza = _stanza.c(aTagName, attributes);
    _xmlNode = _stanza.tree();
}

- (void)addChildName:(CPString)aTagName
{
    _stanza = _stanza.c(aTagName, {});
    _xmlNode = _stanza.tree();
}

- (void)addTextNode:(CPString)aText
{
    _stanza = _stanza.t(aText);
    _xmlNode = _stanza.tree();
}

- (id)tree
{
    return _stanza.tree();
}

- (CPString)stringValue
{
    return _stanza.toString();
}

- (void)up
{
    _stanza = _stanza.up();
}

- (CPString)getType
{
    return _stanza.getAttribute("type");
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

// - (CPString)getValueForAttribute:(CPString)anAttribute
// {
//     var node = [TNXMLNode nodeWithXMLNode:_stanza.tree()];
//     
//     return [node getValueForAttribute:]
// }
// 
// - (CPArray)getChildrenWithName:(CPString)aName
// {
//     return _stanza.getElementsByTagName(aName);
// }
// 
// - (CPArray)getFirstChildWithName:(CPString)aName
// {
//     var elements = _stanza.getElementsByTagName(aName);
//     
//     return (elements.length >  0) ? _stanza.getElementsByTagName(aName)[0] : nil;
// }
@end

