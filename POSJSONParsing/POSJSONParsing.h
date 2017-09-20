//
//  POSJSONParsing.h
//  POSJSONParsing
//
//  Created by Pavel Osipov on 08.06.15.
//  Copyright (c) 2015 Pavel Osipov. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class POSJSONObject;

/// Represents JSON structure with fields.
@interface POSJSONMap : NSObject

/// @return YES if field with 'key' exists in the map.
- (BOOL)contains:(NSString *)key;

/// @return object at field 'key' or throws NSException if it doesn't exist.
- (POSJSONObject *)extract:(NSString *)key;

/// @return object at field 'key' or nil if it doesn't exist.
- (nullable POSJSONObject *)tryExtract:(NSString *)key;

/// Maps all key-value pairs to other objects.
- (NSArray *)map:(id(^)(NSString *key, POSJSONObject *value))block;

/// The designated initializer.
- (instancetype)initWithData:(NSData *)data;

@end

/// Represents JSON entity.
@interface POSJSONObject : NSObject

/// @return YES if objects represents null JSON value or throws NSException if doesn't.
- (BOOL)isNull;

/// @return NSNumber or throws NSException if object has another type.
- (NSNumber *)asNumber;

/// @return NSString or throws NSException if object has another type.
- (NSString *)asString;

/// @return NSString with length 1 or more or throws NSException if object has another type.
- (NSString *)asNonemptyString;

/// @return NSArray of POSJSONObjects or throws NSException if object has another type.
- (NSArray<POSJSONObject *> *)asArray;

/// @return POSJSONMap or throws NSException if object doesn't represent JSON structure.
- (POSJSONMap *)asMap;

/// @return NSURL or thrown NSException if URL is malformed.
- (NSURL *)asURL;

/// @return NSUUID or throws NSException if object was not created.
- (NSUUID *)asUUID;

/// The designated initializer.
- (instancetype)initWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
