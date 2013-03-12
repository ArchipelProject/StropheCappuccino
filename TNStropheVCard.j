/*
 * TNStropheVCard.j
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
@import <AppKit/CPImage.j>

@import "TNXMLNode.j"


@implementation TNStropheVCard : CPObject
{
    CPString    _fullName           @accessors(property=fullName);
    CPString    _organizationName   @accessors(property=organizationName);
    CPString    _organizationUnit   @accessors(property=organizationUnit);
    CPString    _userID             @accessors(property=userID);
    CPString    _locality           @accessors(property=locality);
    CPString    _categories         @accessors(property=categories);
    CPString    _type               @accessors(property=type);
    CPString    _role               @accessors(property=role);
    CPString    _title              @accessors(property=title);
    CPImage     _photo              @accessors(property=photo);
}


#pragma mark -
#pragma mark Initialization

- (void)initWithXMLNode:(TNXMLNode)aNode
{
    if (self = [super init])
    {
        _fullName         = [[aNode firstChildWithName:@"FN"] text];
        _organizationName = [[aNode firstChildWithName:@"ORGNAME"] text];
        _organizationUnit = [[aNode firstChildWithName:@"ORGUNIT"] text];
        _userID           = [[aNode firstChildWithName:@"USERID"] text];
        _locality         = [[aNode firstChildWithName:@"LOCALITY"] text];
        _categories       = [[aNode firstChildWithName:@"CATEGORIES"] text];
        _type             = [[aNode firstChildWithName:@"TYPE"] text];
        _role             = [[aNode firstChildWithName:@"ROLE"] text];
        _title            = [[aNode firstChildWithName:@"TITLE"] text];

        var photoNode;
        if (photoNode = [aNode firstChildWithName:@"PHOTO"])
        {
            var data = [[photoNode firstChildWithName:@"BINVAL"] text];
            _photo = [[CPImage alloc] initWithData:[CPData dataWithBase64:data]];
        }
    }

    return self;
}


#pragma mark -
#pragma mark VCard generation

- (TNXMLNode)XMLNode
{
    var node = [TNXMLNode nodeWithName:@"vCard" andAttributes:{@"xmlns": @"vcard-temp"}];

    if (_fullName)
    {
        [node addChildWithName:@"FN"];
        [node addTextNode:_fullName];
        [node up];
    }
    if (_title)
    {
        [node addChildWithName:@"TITLE"];
        [node addTextNode:_title];
        [node up];
    }
    if (_organizationName)
    {
        [node addChildWithName:@"ORGNAME"];
        [node addTextNode:_organizationName];
        [node up];
    }
    if (_organizationUnit)
    {
        [node addChildWithName:@"ORGUNIT"];
        [node addTextNode:_organizationUnit];
        [node up];
    }
    if (_userID)
    {
        [node addChildWithName:@"USERID"];
        [node addTextNode:_userID];
        [node up];
    }
    if (_locality)
    {
        [node addChildWithName:@"LOCALITY"];
        [node addTextNode:_locality];
        [node up];
    }
    if (_categories)
    {
        [node addChildWithName:@"CATEGORIES"];
        [node addTextNode:_categories];
        [node up];
    }
    if (_type)
    {
        [node addChildWithName:@"TYPE"];
        [node addTextNode:_type];
        [node up];
    }
    if (_role)
    {
        [node addChildWithName:@"ROLE"];
        [node addTextNode:_role];
        [node up];
    }

    if (_photo)
    {
        [node addChildWithName:@"PHOTO"];
        [node addChildWithName:@"BINVAL"];
        [node addTextNode:[[_photo data] base64]];
        [node up];
        [node up];
    }

    return node;
}

@end


@implementation TNStropheVCard (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
         _fullName         = [aCoder decodeObjectForKey:@"_fullName"];
         _organizationName = [aCoder decodeObjectForKey:@"_organizationName"];
         _organizationUnit = [aCoder decodeObjectForKey:@"_organizationUnit"];
         _userID           = [aCoder decodeObjectForKey:@"_userID"];
         _locality         = [aCoder decodeObjectForKey:@"_locality"];
         _categories       = [aCoder decodeObjectForKey:@"_categories"];
         _type             = [aCoder decodeObjectForKey:@"_type"];
         _role             = [aCoder decodeObjectForKey:@"_role"];
         _title            = [aCoder decodeObjectForKey:@"_title"];
         _photo            = [aCoder decodeObjectForKey:@"_photo"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_fullName forKey:@"_fullName"];
    [aCoder encodeObject:_organizationName forKey:@"_organizationName"];
    [aCoder encodeObject:_organizationUnit forKey:@"_organizationUnit"];
    [aCoder encodeObject:_userID forKey:@"_userID"];
    [aCoder encodeObject:_locality forKey:@"_locality"];
    [aCoder encodeObject:_categories forKey:@"_categories"];
    [aCoder encodeObject:_type forKey:@"_type"];
    [aCoder encodeObject:_role forKey:@"_role"];
    [aCoder encodeObject:_title forKey:@"_title"];
    [aCoder encodeObject:_photo forKey:@"_photo"];
}

@end
