/*
 * TNStrophePrivateStorage.j
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

@import "TNStropheConnection.j"


TNStrophePrivateStorageGetErrorNotification = @"TNStrophePrivateStorageGetErrorNotification";
TNStrophePrivateStorageSetErrorNotification = @"TNStrophePrivateStorageSetErrorNotification";
TNStrophePrivateStorageSetNotification      = @"TNStrophePrivateStorageSetNotification";


function stripHTMLCharCode(str)
{
    str = str.replace(/&amp;/g, '&');
    str = str.replace(/&nbsp;/g, ' ');
    str = str.replace(/&quote;/g, '\"');
    str = str.replace(/&apos;/g, '\'');
    str = str.replace(/&lt;/g, '<');
    str = str.replace(/&gt;/g, '>');
    str = str.replace(/&agrave;/g, 'à');
    str = str.replace(/&ccedil;/g, 'ç');
    str = str.replace(/&egrave;/g, 'è');
    str = str.replace(/&eacute;/g, 'é');
    str = str.replace(/&ecirc;/g, 'ê');
    return str;
}

/*! @ingroup strophecappuccino
    This class allows to store random objects in XMPP private storage
*/
@implementation TNStrophePrivateStorage : CPObject
{
    CPString            _namespace  @accessors(property=namespace);
    TNStropheConnection _connection @accessors(property=connection);
}


#pragma mark -
#pragma mark Initialization

/*! return an initialized TNStrophePrivateStorage with given connection and namespace
    @param aConnection the TNStropheConnection
    @param aNamespace the namespace of the storage
    @return a new TNStrophePrivateStorage
*/
+ (TNStropheConnection)strophePrivateStorageWithConnection:(TNStropheConnection)aConnection namespace:(CPString)aNamespace
{
    return [[TNStrophePrivateStorage alloc] initWithConnection:aConnection namespace:aNamespace];
}

/*! initialize TNStrophePrivateStorage with given connection and namespace
    @param aConnection the TNStropheConnection
    @param aNamespace the namespace of the storage
    @return a new TNStrophePrivateStorage
*/
- (TNStropheConnection)initWithConnection:(TNStropheConnection)aConnection namespace:(CPString)aNamespace
{
    if (self = [super init])
    {
        _connection = aConnection;
        _namespace  = aNamespace
    }

    return self;
}


#pragma mark -
#pragma mark Storage

/*! set the given object for the given key
    @param anObject the obect to store
    @param aKey the associated key
*/
- (void)setObject:(id)anObject forKey:(CPString)aKey
{
    var data        = [CPKeyedArchiver archivedDataWithRootObject:anObject],
        uid         = [_connection getUniqueId],
        stanza      = [TNStropheStanza iqWithAttributes:{@"id": uid, @"type": @"set"}],
        params      = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];

    [stanza addChildWithName:@"query" andAttributes:{@"xmlns": Strophe.NS.PRIVATE_STORAGE}];
    [stanza addChildWithName:aKey andAttributes:{@"xmlns": _namespace}];
    [stanza addTextNode:[data rawString]];
    [_connection registerSelector:@selector(_didSetObject:object:) ofObject:self withDict:params userInfo:anObject];
    [_connection send:stanza];
}

/*! @ignore
    called when the storage is sucessfull
    @params aStanza the stanza containing the result
    @params anObject the object that has been set
*/
- (BOOL)_didSetObject:(TNStropheStanza)aStanza object:(id)anObject
{
    if ([aStanza type] == @"result")
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStrophePrivateStorageSetNotification object:self userInfo:anObject];
    else
        [[CPNotificationCenter defaultCenter] postNotificationName:TNStrophePrivateStorageSetErrorNotification object:self userInfo:aStanza];

    return NO;
}

/*! get the object associated to the given key. This message will send to target
    @param aKey the key
    @param aTarget the target that will receive the message containing the object
    @param aSelector the message that will be send to the target
*/
- (id)objectForKey:(CPString)aKey target:(id)aTarget selector:(SEL)aSelector
{
    var uid         = [_connection getUniqueId],
        stanza      = [TNStropheStanza iqWithAttributes:{@"id": uid, @"type": @"get"}],
        params      = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"],
        listener    = {@"target": aTarget, @"selector": aSelector, @"key": aKey};

    [stanza addChildWithName:@"query" andAttributes:{@"xmlns": Strophe.NS.PRIVATE_STORAGE}];
    [stanza addChildWithName:aKey andAttributes:{@"xmlns": _namespace}];
    [_connection registerSelector:@selector(_didReceiveObject:userInfo:) ofObject:self withDict:params userInfo:listener];
    [_connection send:stanza];
}

/*! @ignore
    called when the object is retreived
    @params aStanza the stanza containing the result
    @params listener internal
*/
- (BOOL)_didReceiveObject:(TNStropheStanza)aStanza userInfo:(id)listener
{
    if ([aStanza type] == @"result")
    {
        var dataString = [[aStanza firstChildWithName:listener.key] text];

        // check if a an LPCrashReporter is here.
        // and if yes deactive it during parsing
        // data
        try
        {
            if (dataString)
                var obj =  [CPKeyedUnarchiver unarchiveObjectWithData:[CPData dataWithRawString:stripHTMLCharCode(dataString)]];
        }
        catch(ex)
        {
            [[CPNotificationCenter defaultCenter] postNotificationName:TNStrophePrivateStorageGetErrorNotification object:self userInfo:ex];
        }
    }

    [listener.target performSelector:listener.selector withObject:aStanza withObject:obj];

    return NO;
}

@end