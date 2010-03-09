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
    This is an implémentation of an XML node 
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
    if (self == [super init])
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
        _xmlNode = new Strophe.Builder(aName, attributes);
    }
    
    return self;
}

/*! Add a children to the current seletected node
    @param aTagName name of the new tag
    @param attributes CPDictionary contains all attributes
*/
- (void)addChildName:(CPString)aTagName withAttributes:(CPDictionary)attributes 
{
    _xmlNode = _xmlNode.c(aTagName, attributes);
}

/*! Add a children to the current seletected node
    @param aTagName name of the new tag
*/
- (void)addChildName:(CPString)aTagName
{
    _xmlNode = _xmlNode.c(aTagName, {});
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
    return _xmlNode.toString();
}

/*! Move the pointer to the parent of the current node
*/
- (void)up
{
    _xmlNode = _xmlNode.up();
}

/*! get value of an attribute of the current node
    @param anAttribute the attribute
    @return the value of anAttribute
*/
- (CPString)valueForAttribute:(CPString)anAttribute
{
    return _xmlNode.getAttribute(anAttribute);
}

/*! get an CPArray of TNXMLNode with matching tag name
    @param aName the name tags should match
    @return CPArray of TNXMLNode
*/
- (CPArray)childrenWithName:(CPString)aName
{
    var nodes   = [[CPArray alloc] init];
    var temp    = _xmlNode.getElementsByTagName(aName);
    
    for (var i = 0; i < temp.length; i++)
        [nodes addObject:[TNXMLNode nodeWithXMLNode:temp[i]]]

    return nodes;
}

/*! get the first TNXMLNode that matching tag name
    @param aName the name tags should match
    @return the first matching TNXMLNode
*/
- (CPArray)firstChildWithName:(CPString)aName
{
    var elements = _xmlNode.getElementsByTagName(aName);

    if (elements && (elements.length >  0)) 
        return [TNXMLNode nodeWithXMLNode:elements[0]];
    else
        return nil;
}

/*! get all the children of the current element
    @return array of TNXMLNode children
*/
- (CPArray)children
{
    var nodes   = [CPArray array];
    var temp    = _xmlNode.childNodes;
    
    for (var i = 0; i < temp.length; i++)
    {
        [nodes addObject:[TNXMLNode nodeWithXMLNode:temp[i]]]
    }
    
    return nodes;
}

/*! return the name of the current node
    @return CPString containing the name of the current node
*/
- (CPString)name
{
    return _xmlNode.tagName;
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
    return $(_xmlNode).text();
}

- (CPString)description
{
    return _xmlNode;
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

/*! instanciate a TNStropheStanza with name presence
    @param attributes CPDictionary of attributes
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)presenceWithAttributes:(CPDictionary)attributes
{
    return [[TNStropheStanza alloc] initWithName:@"presence" andAttributes:attributes];
}

/*! instanciate a TNStropheStanza with name message
    @param attributes CPDictionary of attributes
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)messageWithAttributes:(CPDictionary)attributes
{
    return [[TNStropheStanza alloc] initWithName:@"message" andAttributes:attributes];
}

/*! instanciate a TNStropheStanza from a Pure XML Dom Element
    @param aStanza XML Element
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)stanzaWithStanza:(id)aStanza
{
    return [[TNStropheStanza alloc] initWithNode:aStanza];
}

- (CPString)description
{
    return [self stringValue];
}

/*! get the from field of the stanza
    @return from field of stanza
*/
- (CPString)getFrom
{
    return [self valueForAttribute:@"from"];
}

/*! get the to field of the stanza
    @return to field of stanza
*/
- (CPString)getTo
{
    return [self valueForAttribute:@"to"];
}

/*! get the type field of the stanza
    @return type field of stanza
*/
- (CPString)getType
{
    return [self valueForAttribute:@"type"];
}

/*! get the xmlns field of the stanza
    @return xmlns field of stanza
*/
- (CPString)getNamespace
{
    return [self valueForAttribute:@"xmlns"];
}

/*! get the id field of the stanza
    @return id field of stanza
*/
- (CPString)getID
{
    return [self valueForAttribute:@"id"];
}

/*! get the resource part of the from field of the stanza
    @return resource of from field
*/
-(CPString)getFromResource
{
    if ([[[self getFrom] componentsSeparatedByString:@"/"] count] > 1)
        return [[[self getFrom] componentsSeparatedByString:@"/"] objectAtIndex:1];
    return nil;
}
@end

