/*  
 * TNImage.j
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


@implementation TNBase64Image : CPImage
{
    CPString    _baseEncoded64Data  @accessors(setter=setBaseEncoded64Data:);
    CPString    _contentType        @accessors(setter=setContentType:);
}

+ (TNBase64Image)base64ImageWithContentType:(CPString)aContentType andData:(CPString)someBase64Data 
{
    var img = [[TNBase64Image alloc] init];
    
    [img setBaseEncoded64Data:someBase64Data];
    [img setContentType:aContentType];
    
    [img load];
    
    return img;
}

- (void)load
{
    if (_loadStatus == CPImageLoadStatusLoading || _loadStatus == CPImageLoadStatusCompleted)
        return;

    var data    = @"data:" + _contentType + @";base64," + _baseEncoded64Data;
    
    _loadStatus = CPImageLoadStatusLoading;
    _image      = new Image();
    _filename   = data;
    _image.src  = data;

    [self _imageDidLoad];
}

@end