/*
 * TNStropheJID.j
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

TNStropheJIDExceptionJID = @"TNStropheJIDExceptionJID";


/*! @ingroup strophecappuccino
    This class represents a XMPP JID
*/
@implementation TNStropheJID : CPObject
{
    CPString    _node       @accessors(property=node);
    CPString    _domain     @accessors(property=domain);
    CPString    _resource   @accessors(property=resource);
    BOOL        _isServer   @accessors(getter=isServer);
}

#pragma mark -
#pragma mark Class methods

/*! return a new TNStropheJID
    @param aNode the node part of the JID
    @param aDomain the domain part of the JID
    @param aResource the resource part of the JID
*/
+ (TNStropheJID)stropheJIDWithNode:(CPString)aNode domain:(CPString)aDomain resource:(CPString)aResource
{
    return [[TNStropheJID alloc] initWithNode:aNode domain:aDomain resource:aResource];
}

/*! return a new TNStropheJID
    @param aNode the node part of the JID
    @param aDomain the domain part of the JID
    @param aResource the resource part of the JID
*/
+ (TNStropheJID)stropheJIDWithNode:(CPString)aNode domain:(CPString)aDomain
{
    return [[TNStropheJID alloc] initWithNode:aNode domain:aDomain];
}

/*! return a new TNStropheJID
    @param aNode the node part of the JID
    @param aDomain the domain part of the JID
    @param aResource the resource part of the JID
*/
+ (TNStropheJID)stropheJIDWithString:(CPString)aStringJID
{
    return [[TNStropheJID alloc] initWithString:aStringJID];
}


#pragma mark -
#pragma mark Initialization

/*! return a new TNStropheJID
    @param aNode the node part of the JID
    @param aDomain the domain part of the JID
    @param aResource the resource part of the JID
*/

- (TNStropheJID)initWithNode:(CPString)aNode domain:(CPString)aDomain resource:(CPString)aResource
{
    if (self = [super init])
    {
        _node       = aNode;
        _domain     = aDomain;
        _resource   = aResource;
        _isServer   = (!aDomain && !aResource);
    }

    return self;
}

/*! return a new TNStropheJID
    @param aNode the node part of the JID
    @param aDomain the domain part of the JID
*/
- (TNStropheJID)initWithNode:(CPString)aNode domain:(CPString)aDomain
{
    return [self initWithNode:aNode domain:aDomain resource:nil];
}

/*! return a new TNStropheJID
    @param aNode the node part of the JID
    @param aDomain the domain part of the JID
*/
- (TNStropheJID)initWithString:(CPString)aStringJID
{
    var node = aStringJID.split("@")[0],
        domain,
        resource;

    if (aStringJID.indexOf("@") != -1) //this is a server
    {
        domain = aStringJID.split("@")[1].split("/")[0],
        resource = aStringJID.split("/")[1];
    }

    if (!node)
        [CPException raise:TNStropheJIDExceptionJID reason:aStringJID + @" is not a valid JID"];

    return [self initWithNode:node domain:domain resource:resource];
}


#pragma mark -
#pragma mark Setters and Getters

/*! return the bare JID (node@domain)
    @return CPString containing the bare JID
*/
- (CPString)bare
{
    if (_domain)
        return _node + @"@" + _domain;
    else
        return _node;
}

/*! set the bare JID from the string.
    resource, if any remains the same
    @param aBareJID CPString containing the bare JID
*/
- (void)setBare:(CPString)aBareJID
{
    var node = aBareJID.split("@")[0],
        domain = aBareJID.split("@")[1].split("/")[0];

    if (!node || !domain)
        [CPException raise:TNStropheJIDExceptionJID reason:aBareJID + @" is not a valid JID"];

    _node = node;
    _domain = domain;
}

/*! return the full JID (node@domain/resource)
    @return CPString containing the full JID
*/
- (CPString)full
{
    if (_resource)
        return [self bare] + "/" + _resource;
    else
        return [self bare];
}

/*! set the full JID from the string.
    @param aFullJID CPString containing the full JID
*/
- (void)setFull:(CPString)aFullJID
{
    [self setBare:aFullJID];

    var resource = aFullJID.split("/")[1];

    if (!resource)
        [CPException raise:TNStropheJIDExceptionJID reason:aFullJID + @" is not a valid JID"];

    _resource = resource;
}

/*! description method
    @return CPString containing the full JID
*/
- (CPString)description
{
    return [self stringValue];
}

/*! string value method
    @return CPString containing the full JID
*/
- (CPString)stringValue
{
    return [self full];
}

/*! convenient method
*/
- (CPString)uppercaseString
{
    return [[self stringValue] uppercaseString];
}

/*! convenient method
*/
- (CPString)lowercaseString
{
    return [[self stringValue] lowercaseString];
}

#pragma mark -
#pragma mark Operations

/*! check if given TNStropheJID is equals to self
    @param anotherJID the TNStropheJID to compare
*/
- (BOOL)equals:(TNStropheJID)anotherJID
{
    return [self fullEquals:anotherJID];
}

/*! check if given TNStropheJID fullJID is equals to self
    @param anotherJID the TNStropheJID to compare
*/
- (BOOL)fullEquals:(TNStropheJID)anotherJID
{
    return ([self bareEquals:anotherJID] && ([[anotherJID resource] uppercaseString] === [[self resource] uppercaseString]))
}

/*! check if given TNStropheJID's node and domain is equals to self
    @param anotherJID the TNStropheJID to compare
*/
- (BOOL)bareEquals:(TNStropheJID)anotherJID
{
    return (([[anotherJID node] uppercaseString] === [[self node] uppercaseString]) && ([[anotherJID domain] uppercaseString] === [[self domain] uppercaseString]));
}

/*! compare rthe JID with another (using the full JID)
    @param another the JID to compare with
*/
- (CPComparisonResult)compare:(TNStropheJID)anotherJID
{
    var stringRepA = [self stringValue],
        stringRepB = [anotherJID stringValue];

    return [stringRepA compare:stringRepB];
}

@end


@implementation TNStropheJID (CPCodingCompliance)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
        _node       = [aCoder decodeObjectForKey:@"_node"];
        _domain     = [aCoder decodeObjectForKey:@"_domain"];
        _resource   = [aCoder decodeObjectForKey:@"_resource"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_node forKey:@"_node"];

    if (_domain)
        [aCoder encodeObject:_domain forKey:@"_domain"];

    if (_resource)
        [aCoder encodeObject:_resource forKey:@"_resource"];
}

@end