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

/*! @ingroup strophecappuccino
    This is an implementation of an XML node
*/
@implementation TNXMLNode : CPObject
{
    XMLElement  _xmlNode     @accessors(readonly, getter=xmlNode);
}

/*! create an instance of a TNXMLNode from a pure javascript Node
    @param aNode a pure Javascript DOM Element
    @return an instance of TNXMLNode initialized with aNode
*/
+ (TNXMLNode)nodeWithXMLNode:(id)aNode
{
    return [[TNXMLNode alloc] initWithNode:aNode];
}

/*! initialize an instance of a TNXMLNode from a pure javascript Node
    @param aNode a pure Javascript DOM Element
    @return an instance of TNXMLNode initialized with aNode
*/
- (TNXMLNode)initWithNode:(id)aNode
{
    if (self = [super init])
    {
        if ((aNode.c) && (aNode.c) != undefined)
        {
            _xmlNode = aNode;
        }
        else
        {
            _xmlNode = new Strophe.Builder('msg');
            _xmlNode.nodeTree = aNode;
            _xmlNode.node = aNode;
        }
    }

    return self;
}

/*! initialize an instance of a TNXMLNode with root node and attributes
    @param aName name of the root tag
    @param attributes CPDictionary contains all attributes
    @return an instance of TNXMLNode initialized
*/
- (TNXMLNode)initWithName:(CPString)aName andAttributes:(CPDictionary)attributes
{
    if (self = [super init])
    {
        _xmlNode = new Strophe.Builder(aName, attributes);
    }

    return self;
}

/*! copy the current TNXMLNode
    @return a copy of this
*/
- (TNXMLNode)copy
{
    return [TNXMLNode nodeWithXMLNode:Strophe.copyElement([self tree])];
}

/*! Add a child to the current seletected node
    This will move the stanza object pointer to the child node
    @param aTagName name of the new tag
    @param attributes CPDictionary contains all attributes
*/
- (void)addChildWithName:(CPString)aTagName andAttributes:(CPDictionary)attributes
{
    _xmlNode = _xmlNode.c(aTagName, attributes);
}

- (void)addChildName:(CPString)aTagName andAttributes:(CPDictionary)attributes
{
    [self addChildWithName:aTagName andAttributes:attributes];
}

/*! Add a child to the current seletected node
    This will move the stanza object pointer to the child node
    @param aTagName name of the new tag
*/
- (void)addChildWithName:(CPString)aTagName
{
    [self addChildWithName:aTagName andAttributes:{}]
}

- (void)addChildName:(CPString)aTagName
{
    [self addChildWithName:aTagName];
}

/*! append a node to the current node
    @param aNode the dom element to add.
*/
- (void)addNode:(DOMElement)aNode
{
    _xmlNode.cnode(aNode)
}

/*! Add text value to the current seletected node
    @param aText name of the new tag
*/
- (void)addTextNode:(CPString)aText
{
    _xmlNode = _xmlNode.t(aText);
}

/*! return a DOM Element of the TNXMLNode
    @return an DOM Element
*/
- (id)tree
{
    return _xmlNode.tree();
}

/*! convert the TNXMLNode into its string representation
    @return string representation of the TNXMLNode
*/
- (CPString)stringValue
{
    //return Strophe.toString(_xmlNode);
    return Strophe.serialize(_xmlNode);
}

/*! Move the pointer to the parent of the current node
*/
- (BOOL)up
{
    if (_xmlNode.node && _xmlNode.node.parentNode)
    {
        ret = _xmlNode.up();
        return YES;
    }
    return NO;
}

/*! get value of an attribute of the current node
    @param anAttribute the attribute
    @return the value of anAttribute
*/
- (CPString)valueForAttribute:(CPString)anAttribute
{
    return [self tree].getAttribute(anAttribute);
}

/*! allow to set a value for a given attribute
    @param aValue the value
    @param anAttribute the attribute name
*/
- (void)setValue:(CPString)aValue forAttribute:(CPString)anAttribute
{
    var attr = {};

    attr[anAttribute] = aValue;

    _xmlNode.attrs(attr);
}

/*! get an CPArray of TNXMLNode with matching tag name
    @param aName the name tags should match
    @return CPArray of TNXMLNode
*/
- (CPArray)childrenWithName:(CPString)aName
{
    var nodes       = [[CPArray alloc] init],
        elements    = [self tree].getElementsByTagName(aName);

    for (var i = 0; i < elements.length; i++)
        [nodes addObject:[TNXMLNode nodeWithXMLNode:elements[i]]]

    return nodes;
}

/*! return all direct children wth given name.
    @param aName the name tags should match
    @return CPArray of TNXMLNode
*/
- (CPArray)ownChildrenWithName:(CPString)aName
{
    var nodes       = [[CPArray alloc] init],
        elements    = [self tree].childNodes;

    for (var i = 0; i < elements.length; i++)
    {
        if (aName && elements[i].tagName == aName)
            [nodes addObject:[TNXMLNode nodeWithXMLNode:elements[i]]]
    }

    return nodes;
}

/*! get the first TNXMLNode that matching tag name
    @param aName the name tags should match
    @return the first matching TNXMLNode
*/
- (TNXMLNode)firstChildWithName:(CPString)aName
{
    var elements = [self tree].getElementsByTagName(aName);

    if (elements && (elements.length > 0))
        return [TNXMLNode nodeWithXMLNode:elements[0]];
    else
        return nil;
}

/*! get all the children of the current element
    @return array of TNXMLNode children
*/
- (CPArray)children
{
    return [self ownChildrenWithName:nil];
}

/*! return the name of the current node
    @return CPString containing the name of the current node
*/
- (CPString)name
{
    return [self tree].tagName;
}

- (BOOL)containsChildrenWithName:(CPString)aName
{
    return ([self firstChildWithName:aName]) ? YES : NO;
}

/*! get the text node value
    @return CPString of the content of node
*/
- (CPString)text
{
    return Strophe.getText([self tree]);
}

- (CPString)description
{
    return [self stringValue];
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
       // _xmlNode = [aCoder decodeObjectForKey:@"_xmlNode"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    // if ([super respondsToSelector:@selector(encodeWithCoder:)])
    //     [super encodeWithCoder:aCoder];

    //[aCoder encodeObject:_xmlNode forKey:@"_xmlNode"];
}
@end

/*! @ingroup strophecappuccino
    this is an implementation of a basic XMPP Stanza
*/
@implementation TNStropheStanza: TNXMLNode
{
}

/*! instanciate a TNStropheStanza
    @param aName the root name
    @param attributes CPDictionary of attributes
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)stanzaWithName:(CPString)aName andAttributes:(CPDictionary)attributes
{
    return [[TNStropheStanza alloc] initWithName:aName andAttributes:attributes];
}

/*! instanciate a TNStropheStanza with name IQ
    @param attributes CPDictionary of attributes
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)iqWithAttributes:(CPDictionary)attributes
{
    return [[TNStropheStanza alloc] initWithName:@"iq" andAttributes:attributes];
}

/*! instanciate a TNStropheStanza with name IQ
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)iq
{
    return [[TNStropheStanza alloc] initWithName:@"iq" andAttributes:nil];
}

/*! instanciate a TNStropheStanza with name IQ
    @param aType CPString the type of the query
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)iqWithType:(CPString)aType
{
    return [[TNStropheStanza alloc] initWithName:@"iq" andAttributes:{"type": aType}];
}

/*! instanciate a TNStropheStanza with name presence
    @param attributes CPDictionary of attributes
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)presenceWithAttributes:(CPDictionary)attributes
{
    return [[TNStropheStanza alloc] initWithName:@"presence" andAttributes:attributes];
}

/*! instanciate a TNStropheStanza with name presence
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)presence
{
    return [[TNStropheStanza alloc] initWithName:@"presence" andAttributes:nil];
}

/*! instanciate a TNStropheStanza with name message
    @param attributes CPDictionary of attributes
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)messageWithAttributes:(CPDictionary)attributes
{
    return [[TNStropheStanza alloc] initWithName:@"message" andAttributes:attributes];
}

/*! instanciate a TNStropheStanza with name message
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)message
{
    return [[TNStropheStanza alloc] initWithName:@"message" andAttributes:nil];
}

/*! instanciate a TNStropheStanza from a Pure XML Dom Element
    @param aStanza XML Element
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)stanzaWithStanza:(id)aStanza
{
    return [[TNStropheStanza alloc] initWithNode:aStanza];
}

/*! get the from field of the stanza
    @return from field of stanza
*/
- (CPString)from
{
    while ([self up]);
    return [self valueForAttribute:@"from"];
}

/*! set the from field of the stanza
    @param the new from value
*/
- (void)setFrom:(CPString)aFrom
{
    while ([self up]);
    [self setValue:aFrom forAttribute:@"from"];
}

/*! get the bare from JID of the stanza
    @return bare from JID of stanza
*/
- (CPString)fromBare
{
    return [self from].split("/")[0];
}

/*! return the the bare user name
    @return from user field of stanza
*/
- (CPString)fromUser
{
    return [self from].split("/")[0].split("@")[0];
}

/*! get the domain of the form field
    @return domain field of stanza
*/
- (CPString)fromDomain
{
    return [self from].split("@")[1].split("/")[0]
}

/*! get the resource part of the from field of the stanza
    @return resource of from field
*/
- (CPString)fromResource
{
    if ([[[self from] componentsSeparatedByString:@"/"] count] > 1)
        return [[[self from] componentsSeparatedByString:@"/"] objectAtIndex:1];
    return nil;
}

/*! get the to field of the stanza
    @return to field of stanza
*/
- (CPString)to
{
    while ([self up]);
    return [self valueForAttribute:@"to"];
}

/*! set the to field of the stanza
    @param the new To value
*/
- (void)setTo:(CPString)aTo
{
    while ([self up]);
    [self setValue:aTo forAttribute:@"to"];
}

/*! get the type field of the stanza
    @return type field of stanza
*/
- (CPString)type
{
    return [self valueForAttribute:@"type"];
}

/*! set the type field of the stanza
    @param the new type value
*/
- (void)setType:(CPString)aType
{
    [self setValue:aType forAttribute:@"type"];
}

/*! get the xmlns field of the stanza
    @return xmlns field of stanza
*/
- (CPString)namespace
{
    return [self valueForAttribute:@"xmlns"];
}

/*! set the xmlns field of the stanza
    @param the new xmls value
*/
- (void)setNamespace:(CPString)aNamespace
{
    [self setValue:aNamespace forAttribute:@"xmlns"];
}

/*! get the id field of the stanza
    @return id field of stanza
*/
- (CPString)ID
{
    return [self valueForAttribute:@"id"];
}

/*! set the id field of the stanza
    @param the new id value
*/
- (void)setID:(CPString)anID
{
    while ([self up]);
    [self setValue:anID forAttribute:@"id"];
}

@end
