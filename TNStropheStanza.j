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
@import "TNXMLNode.j"

/*! @ingroup strophecappuccino
    this is an implementation of a basic XMPP Stanza
*/
@implementation TNStropheStanza: TNXMLNode

#pragma mark -
#pragma mark Class methods

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
    @param aType CPString the type of the query
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)iqWithType:(CPString)aType
{
    return [TNStropheStanza iqWithAttributes:{"type": aType}];
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

/*! instanciate a TNStropheStanza from a Pure XML Dom Element
    @param aStanza XML Element
    @return instance of TNStropheStanza
*/
+ (TNStropheStanza)stanzaWithStanza:(id)aStanza
{
    return [[TNStropheStanza alloc] initWithNode:aStanza];
}

#pragma mark -
#pragma mark Attributes

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
