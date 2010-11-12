/*
 * TNXMLNode.j
 *
 * Copyright (C) 2010  Antoine Mercadal <antoine.mercadal@inframonde.eu>
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


/*! @ingroup strophecappuccino
    This is an implementation of a really basic XML node in Cappuccino
*/
@implementation TNXMLNode : CPObject
{
    XMLDocument _xmlDocument;
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
- (TNXMLNode)initWithNode:(TNXMLNode)aNode
{
    if (self = [self init])
    {
        _xmlNode = aNode;
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
        if (window.ActiveXObject)
        {
            _xmlDocument = new ActiveXObject("Microsoft.XMLDOM");
            _xmlDocument.appendChild(doc.createElement('strophe'));
        }
        else
            _xmlDocument = document.implementation.createDocument('strophe', 'jabber:client', null);

        _xmlNode = _xmlDocument.createElement(aName)

        if (attributes)
        {
            if (!attributes.isa)
                attributes = [CPDictionary dictionaryWithJSObject:attributes];
            for (var i = 0; i < [[attributes allKeys] count]; i++)
            {
                var attribute = [[attributes allKeys] objectAtIndex:i],
                    value = [attributes valueForKey:attribute];
                _xmlNode.setAttribute(attribute, value);
            }
        }
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
    _xmlNode.appendChild(_xmlDocument.importNode([aNode xmlNode], true));
}

/*! Add text value to the current seletected node
    @param aText name of the new tag
*/
- (void)addTextNode:(CPString)aText
{
    _xmlNode.appendChild(_xmlDocument.createTextNode(aText));
}

/*! get the text node value
    @return CPString of the content of node
*/
- (CPString)text
{
    return _xmlNode.data;
}

/*! return a DOM Element of the TNXMLNode
    @return an DOM Element
*/
- (id)tree
{
    return _xmlNode;
}

/*! Move the pointer to the parent of the current node
*/
- (BOOL)up
{
    if (_xmlNode
        && _xmlNode.parentNode
        && _xmlNode.parentNode.nodeType == 1)
    {
        _xmlNode = _xmlNode.parentNode;
        return YES;
    }
    return NO;
}

/*! convert the TNXMLNode into its string representation
    @return string representation of the TNXMLNode
*/
- (CPString)stringValue
{
    if (!_xmlNode)
        return null;

    var result,
        nodeName = _xmlNode.nodeName,
        i,
        child;

    if (_xmlNode.getAttribute("_realname"))
        nodeName = _xmlNode.getAttribute("_realname");

    result = "<" + nodeName;
    for (i = 0; i < _xmlNode.attributes.length; i++)
        if(_xmlNode.attributes[i].nodeName != "_realname")
            result += " " + _xmlNode.attributes[i].nodeName.toLowerCase() + "='" + _xmlNode.attributes[i].value + "'";
            // result += " " + _xmlNode.attributes[i].nodeName.toLowerCase() + "='" + _xmlNode.attributes[i].value.replace(/&/g, "&amp;").replace(/\'/g, "&apos;").replace(/</g, "&lt;") + "'";

    if (_xmlNode.childNodes.length > 0)
    {
        result += ">";
        for (i = 0; i < _xmlNode.childNodes.length; i++)
        {
            child = _xmlNode.childNodes[i];
            if (child.nodeType == Strophe.ElementType.NORMAL)
                result += Strophe.serialize(child);
            else if (child.nodeType == Strophe.ElementType.TEXT)
                result += child.nodeValue;
        }
        result += "</" + nodeName + ">";
    }
    else
        result += "/>";

    return result;
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
    return _xmlNode.getAttribute(anAttribute);
}

/*! allow to set a value for a given attribute
    @param aValue the value
    @param anAttribute the attribute name
*/
- (void)setValue:(CPString)aValue forAttribute:(CPString)anAttribute
{
    _xmlNode.setAttribute(anAttribute, aValue);
}

/*! return the name of the current node
    @return CPString containing the name of the current node
*/
- (CPString)name
{
    return _xmlNode.tagName;
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
    var newElem = _xmlDocument.createElement(aTagName);

    _xmlNode.appendChild(newElem);
    _xmlNode = newElem;

    if (attributes)
    {
        if (!attributes.isa)
            attributes = [CPDictionary dictionaryWithJSObject:attributes];

        for (var i = 0; i < [[attributes allKeys] count]; i++)
        {
            var attribute = [[attributes allKeys] objectAtIndex:i],
                value = [attributes valueForKey:attribute];
            _xmlNode.setAttribute(attribute, value);
        }
    }
}

/*! Add a child to the current seletected node
    This will move the stanza object pointer to the child node
    @param aTagName name of the new tag
*/
- (void)addChildWithName:(CPString)aTagName
{
    [self addChildWithName:aTagName andAttributes:[CPDictionary dictionary]];
}

/*! get an CPArray of TNXMLNode with matching tag name
    @param aName the name tags should match
    @return CPArray of TNXMLNode
*/
- (CPArray)childrenWithName:(CPString)aName
{
    var nodes       = [CPArray array],
        elements    = _xmlNode.getElementsByTagName(aName);

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
        elements    = _xmlNode.childNodes;

    for (var i = 0; i < elements.length; i++)
        if ((aName === nil) || (aName && elements [i].tagName == aName))
            [nodes addObject:[TNXMLNode nodeWithXMLNode:elements[i]]]

    return nodes;
}

/*! get the first TNXMLNode that matching tag name
    @param aName the name tags should match
    @return the first matching TNXMLNode
*/
- (TNXMLNode)firstChildWithName:(CPString)aName
{
    var elements = _xmlNode.getElementsByTagName(aName);

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