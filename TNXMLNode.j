/*
 * TNXMLNode.j
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
    This is an implementation of a really basic XML node in Cappuccino
*/
@implementation TNXMLNode : CPObject
{
    XMLElement  _xmlNode     @accessors(readonly, getter=xmlNode);
}

#pragma mark -
#pragma mark Class methods

/*! create an instance of a TNXMLNode from a pure javascript Node
    @param aNode a pure Javascript DOM Element
    @return an instance of TNXMLNode initialized with aNode
*/
+ (TNXMLNode)nodeWithXMLNode:(id)aNode
{
    return [[TNXMLNode alloc] initWithNode:aNode];
}

/*! create an instance of a TNXMLNode from a pure javascript Node
    @param aName the name of the node
    @return an instance of TNXMLNode initialized with aName
*/
+ (TNXMLNode)nodeWithName:(CPString)aName
{
    return [[TNXMLNode alloc] initWithName:aName andAttributes:nil];
}

/*! create an instance of a TNXMLNode from a pure javascript Node
    @param aName the name of the node
    @param someAttributes CPDictionary containing the attributes
    @return an instance of TNXMLNode initialized with aName and attributes
*/
+ (TNXMLNode)nodeWithName:(CPString)aName andAttributes:(CPDictionary)someAttributes
{
    return [[TNXMLNode alloc] initWithName:aName andAttributes:someAttributes];
}

#pragma mark -
#pragma mark Initialization

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

#pragma mark -
#pragma mark Representation & Navigation

/*! copy the current TNXMLNode
    @return a copy of this
*/
- (TNXMLNode)copy
{
    return [TNXMLNode nodeWithXMLNode:Strophe.copyElement([self tree])];
}

/*! append a node to the current node
    @param aNode the dom element to add.
*/
- (void)addNode:(TNXMLNode)aNode
{
    _xmlNode.cnode([aNode tree]);
}

/*! Add text value to the current seletected node
    @param aText name of the new tag
*/
- (void)addTextNode:(CPString)aText
{
    _xmlNode = _xmlNode.t(aText);
}

/*! get the text node value
    @return CPString of the content of node
*/
- (CPString)text
{
    return Strophe.getText([self tree]);
}

/*! return a DOM Element of the TNXMLNode
    @return an DOM Element
*/
- (id)tree
{
    return _xmlNode.tree();
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

/*! convert the TNXMLNode into its string representation
    @return string representation of the TNXMLNode
*/
- (CPString)stringValue
{
    //return Strophe.toString(_xmlNode);
    return Strophe.serialize(_xmlNode);
}

- (CPString)description
{
    return [self stringValue];
}

#pragma mark -
#pragma mark Attributes

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

/*! return the name of the current node
    @return CPString containing the name of the current node
*/
- (CPString)name
{
    return [self tree].tagName;
}

/*! get the xmlns field of the node
    @return xmlns field of node
*/
- (CPString)namespace
{
    return [self valueForAttribute:@"xmlns"];
}

/*! set the xmlns field of the node
    @param the new xmls value
*/
- (void)setNamespace:(CPString)aNamespace
{
    [self setValue:aNamespace forAttribute:@"xmlns"];
}

#pragma mark -
#pragma mark Children

/*! Add a child to the current seletected node
    This will move the stanza object pointer to the child node
    @param aTagName name of the new tag
    @param attributes CPDictionary contains all attributes
*/
- (void)addChildWithName:(CPString)aTagName andAttributes:(CPDictionary)attributes
{
    _xmlNode = _xmlNode.c(aTagName, attributes);
}

/*! Add a child to the current seletected node
    This will move the stanza object pointer to the child node
    @param aTagName name of the new tag
*/
- (void)addChildWithName:(CPString)aTagName
{
    [self addChildWithName:aTagName andAttributes:{}];
}

/*! get an CPArray of TNXMLNode with matching tag name
    @param aName the name tags should match
    @return CPArray of TNXMLNode
*/
- (CPArray)childrenWithName:(CPString)aName
{
    var nodes       = [CPArray array],
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
    var nodes       = [CPArray array],
        elements    = [self tree].childNodes;

    for (var i = 0; i < elements.length; i++)
        if ((aName === nil) || (aName && elements[i].tagName == aName))
            [nodes addObject:[TNXMLNode nodeWithXMLNode:elements[i]]]

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

- (BOOL)containsChildrenWithName:(CPString)aName
{
    return ([self firstChildWithName:aName]) ? YES : NO;
}

@end

@implementation TNXMLNode (CPCoding)

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