/*
 * TNStropheStanza.j
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

@import "TNStropheJID.j"
@import "TNXMLNode.j"

/*! @ingroup strophecappuccino
    this is an implementation of a basic XMPP Stanza
*/
@implementation TNStropheStanza: TNXMLNode

#pragma mark -
#pragma mark Class methods

/*! instanciate a TNStropheStanza from a Pure XML Dom Element
    @param aStanza XML Element
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)stanzaWithStanza:(id)aStanza
{
    return [[TNStropheStanza alloc] initWithNode:aStanza];
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

/*! instanciate a TNStropheStanza
    @param aName the root name
    @param aJID the destination JID
    @param attributes CPDictionary of attributes
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)stanzaWithName:(CPString)aName to:(TNStropheJID)aJID  attributes:(CPDictionary)attributes
{
    return [[TNStropheStanza alloc] initWithName:aName to:aJID attributes:attributes bare:NO];
}

/*! instanciate a TNStropheStanza
    @param aName the root name
    @param aJID the destination JID
    @param attributes CPDictionary of attributes
    @param sendToBareJID if YES send to bare JID
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)stanzaWithName:(CPString)aName to:(TNStropheJID)aJID  attributes:(CPDictionary)attributes bare:(BOOL)sendToBareJID
{
    return [[TNStropheStanza alloc] initWithName:aName to:aJID attributes:attributes bare:sendToBareJID];
}


/*! instanciate a TNStropheStanza with name IQ
    @param attributes CPDictionary of attributes
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)iqWithAttributes:(CPDictionary)attributes
{
    return [TNStropheStanza stanzaWithName:@"iq" andAttributes:attributes];
}

/*! instanciate a TNStropheStanza with name IQ
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)iq
{
    return [TNStropheStanza iqWithAttributes:nil];
}

/*! instanciate a TNStropheStanza with name IQ
    @param aJID the destination JID
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)iqTo:(TNStropheJID)aJID
{
    return [TNStropheStanza iqTo:aJID withAttributes:nil];
}

/*! instanciate a TNStropheStanza with name IQ
    @param aType CPString the type of the query
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)iqWithType:(CPString)aType
{
    return [TNStropheStanza iqWithAttributes:{"type": aType}];
}

/*! instanciate a TNStropheStanza with name IQ
    @param aJID the destination JID
    @param aType CPString the type of the query
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)iqTo:(TNStropheJID)aJID withType:(CPString)aType
{
    return [TNStropheStanza iqTo:aJID withAttributes:{"type": aType}];
}

/*! instanciate a TNStropheStanza with name IQ
    @param aJID the destination JID
    @param attributes CPDictionary of attributes
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)iqTo:(TNStropheJID)aJID withAttributes:(CPDictionary)attributes
{
    return [TNStropheStanza stanzaWithName:@"iq" to:aJID attributes:attributes bare:NO];
}

/*! instanciate a TNStropheStanza with name IQ
    @param aJID the destination JID
    @param attributes CPDictionary of attributes
    @param sendToBareJID if YES send to bare JID
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)iqTo:(TNStropheJID)aJID withAttributes:(CPDictionary)attributes bare:(BOOL)sendToBareJID
{
    return [TNStropheStanza stanzaWithName:@"iq" to:aJID attributes:attributes bare:sendToBareJID];
}

/*! instanciate a TNStropheStanza with name presence
    @param attributes CPDictionary of attributes
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)presenceWithAttributes:(CPDictionary)attributes
{
    return [TNStropheStanza stanzaWithName:@"presence" andAttributes:attributes];
}

/*! instanciate a TNStropheStanza with name presence
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)presence
{
    return [TNStropheStanza presenceWithAttributes:nil];
}

/*! instanciate a TNStropheStanza with name presence
    @param aJID the destination JID
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)presenceTo:(TNStropheJID)aJID
{
    return [TNStropheStanza presenceTo:aJID withAttributes:nil];
}

/*! instanciate a TNStropheStanza with name presence
    @param aJID the destination JID
    @param attributes CPDictionary of attributes
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)presenceTo:(TNStropheJID)aJID withAttributes:(CPDictionary)attributes
{
    return [TNStropheStanza stanzaWithName:@"presence" to:aJID attributes:attributes bare:NO];
}

/*! instanciate a TNStropheStanza with name presence
    @param aJID the destination JID
    @param attributes CPDictionary of attributes
    @param sendToBareJID if YES send to bare JID
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)presenceTo:(TNStropheJID)aJID withAttributes:(CPDictionary)attributes bare:(BOOL)sendToBareJID
{
    return [TNStropheStanza stanzaWithName:@"presence" to:aJID attributes:attributes bare:sendToBareJID];
}

/*! instanciate a TNStropheStanza with name message
    @param attributes CPDictionary of attributes
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)messageWithAttributes:(CPDictionary)attributes
{
    return [TNStropheStanza stanzaWithName:@"message" andAttributes:attributes];
}

/*! instanciate a TNStropheStanza with name message
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)message
{
    return [TNStropheStanza messageWithAttributes:nil];
}

/*! instanciate a TNStropheStanza with name message
    @param aJID the destination JID
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)messageTo:(TNStropheJID)aJID
{
    return [TNStropheStanza messageTo:aJID withAttributes:nil];
}

/*! instanciate a TNStropheStanza with name message
    @param aJID the destination JID
    @param attributes CPDictionary of attributes
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)messageTo:(TNStropheJID)aJID withAttributes:(CPDictionary)attributes
{
    return [TNStropheStanza stanzaWithName:@"message" to:aJID attributes:attributes];
}

/*! instanciate a TNStropheStanza with name message
    @param aJID the destination JID
    @param attributes CPDictionary of attributes
    @param sendToBareJID if YES send to bare JID
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)messageTo:(TNStropheJID)aJID withAttributes:(CPDictionary)attributes bare:(BOOL)sendToBareJID
{
    return [TNStropheStanza stanzaWithName:@"message" to:aJID attributes:attributes bare:sendToBareJID];
}


#pragma mark -
#pragma mark Initialization

- (TNStropheStanza)initWithName:(CPString)aName to:(TNStropheJID)aJID attributes:(CPDictionary)someAttributes bare:(BOOL)sendToBareJID
{
    if (aJID && !someAttributes)
        someAttributes = {};

    if (someAttributes)
    {
        if (someAttributes.isa)
            [someAttributes setValue:((sendToBareJID) ? [aJID bare] : aJID) forKey:"to"];
        else
            someAttributes.to = ((sendToBareJID) ? [aJID bare] : [aJID full]);
    }

    return [super initWithName:aName andAttributes:someAttributes];
}


#pragma mark -
#pragma mark Attributes

/*! get the from field of the stanza
    @return from field of stanza
*/
- (CPString)from
{
    while ([self up]);
    return [TNStropheJID stropheJIDWithString:[self valueForAttribute:@"from"]];
}

/*! set the from field of the stanza
    @param the new from value
*/
- (void)setFrom:(id)aFrom
{
    if ([aFrom class] == CPString)
        aFrom = [TNStropheJID stropheJIDWithString:aFrom];

    while ([self up]);
    [self setValue:[aFrom full] forAttribute:@"from"];
}

/*! get the bare from JID of the stanza
    @return bare from JID of stanza
*/
- (CPString)fromBare
{
    return [[self from] bare];
}

/*! return the the bare user name
    @return from user field of stanza
*/
- (CPString)fromUser
{
    return [[self from] node];
}

/*! get the domain of the form field
    @return domain field of stanza
*/
- (CPString)fromDomain
{
    return [[self from] domain];
}

/*! get the resource part of the from field of the stanza
    @return resource of from field
*/
- (CPString)fromResource
{
    return [[self from] resource];
}

/*! get the to field of the stanza
    @return to field of stanza
*/
- (CPString)to
{
    while ([self up]);
    return [TNStropheJID stropheJIDWithString:[self valueForAttribute:@"to"]];
}

/*! set the to field of the stanza
    @param the new To value
*/
- (void)setTo:(id)aTo
{
    if ([aTo class] == CPString)
        aTo = [TNStropheJID stropheJIDWithString:aTo];

    while ([self up]);
    [self setValue:[aTo full] forAttribute:@"to"];
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

/*! get the time the stanza was sent if it was delayed
    @return delayTime from stanza
*/
- (CPDate)delayTime
{
    if ([self containsChildrenWithName:@"delay"] && [[self firstChildWithName:@"delay"] namespace] == Strophe.NS.DELAY)
    {
        // TODO: Fix this to match non-UTC
        var messageDelay    = [[self firstChildWithName:@"delay"] valueForAttribute:@"stamp"],
            match           = messageDelay.match(new RegExp(/(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})Z/));

        if (!match || match.length != 3)
            [CPException raise:CPInvalidArgumentException
                        reason:"delayTime: the string must be of YYYY-MM-DDTHH:MM:SSZ format"];

        return [[CPDate alloc] initWithString:(match[1] + @" " + match[2] + @" +0000")];
    }

    return [CPDate dateWithTimeIntervalSinceNow:0];
}

@end
