/*
 * TNBase64Image.j
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
    this is a subclass of CPImage that allows to create a CPImage from a image
    encoded in a base64 CPString.
*/
@implementation TNBase64Image : CPImage
{
    CPString    _base64EncodedData  @accessors(setter=setBase64EncodedData:);
    CPString    _contentType        @accessors(setter=setContentType:);
}

/*! create the TNBase64Image from the base64 string using a given content-type
    @param aContentType the content type to use (for example "image/png")
    @param someBase64Data the CPString containing the encoded image in base64
    @return a initialized and loaded TNBase64Image
*/
+ (TNBase64Image)base64ImageWithContentType:(CPString)aContentType andData:(CPString)someBase64Data
{
    var img = [[TNBase64Image alloc] init];

    [img setBase64EncodedData:someBase64Data];
    [img setContentType:aContentType];

    [img load];

    return img;
}

+ (TNBase64Image)base64ImageWithContentType:(CPString)aContentType data:(CPString)someBase64Data delegate:(id)aDelegate
{
    var img = [[TNBase64Image alloc] init];

    [img setBase64EncodedData:someBase64Data];
    [img setContentType:aContentType];
    [img setDelegate:aDelegate];

    [img load];

    return img;
}

/*! override the CPImage load message.
*/
- (void)load
{
    if (_base64EncodedData)
    {
        if (_loadStatus == CPImageLoadStatusLoading || _loadStatus == CPImageLoadStatusCompleted)
            return;

        var data    = @"data:" + _contentType + @";base64," + _base64EncodedData;

        _loadStatus = CPImageLoadStatusLoading;
        _image      = new Image();
        _image.onload = function(e){
            [self _imageDidLoad];
        };
        _filename   = data;
        _image.src  = data;
    }
    else
        [super load];
}


- (CPString)base64EncodedData
{
    var canvas = document.createElement("canvas"),
        ctx = canvas.getContext("2d");

    canvas.width = _image.width,
    canvas.height = _image.height;

    ctx.drawImage(_image, 0, 0);

    var dataURL = canvas.toDataURL("image/png");

    return dataURL.replace(/^data:image\/(png|jpg);base64,/, "");
}

@end