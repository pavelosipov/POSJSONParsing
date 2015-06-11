//
//  POSJSONParsing.h
//  POSJSONParsing
//
//  Created by Pavel Osipov on 08.06.15.
//  Copyright (c) 2015 Pavel Osipov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class POSJSONObject;

/// Represents JSON structure with fields.
@interface POSJSONMap : NSObject

/// @return YES if field with 'key' exists in the map.
- (BOOL)contains:(NSString *)key;

/// @return object at field 'key' or throws NSException if it doesn't exist.
- (POSJSONObject *)extract:(NSString *)key;

/// @return object at field 'key' or nil if it doesn't exist.
- (POSJSONObject *)tryExtract:(NSString *)key;

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

/// @return NSArray of POSJSONObjects or throws NSException if object has another type.
- (NSArray *)asArray;

/// @return POSJSONMap or throws NSException if object doesn't represent JSON structure.
- (POSJSONMap *)asMap;

@end