//
//  POSJSONParsing.m
//  POSJSONParsing
//
//  Created by Pavel Osipov on 08.06.15.
//  Copyright (c) 2015 Pavel Osipov. All rights reserved.
//

#import "POSJSONParsing.h"
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSException (POSJSONParsing)
@end

@implementation NSException (POSJSONParsing)

+ (NSException *)pos_exceptionWithFormat:(NSString *)format, ... {
    NSParameterAssert(format);
    va_list args;
    va_start(args, format);
    NSString *reason = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    return [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
}

@end

@interface POSJSONMap (Private)
- (instancetype)initWithName:(NSString *)name values:(NSDictionary *)values allValues:(NSString *)allValues;
@end

#pragma mark -

@interface POSJSONObject ()
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) id value;
@property (nonatomic, readonly) NSString *allValues;
@end

@implementation POSJSONObject

- (instancetype)initWithName:(NSString *)name value:(id)value allValues:(NSString *)allValues {
    NSParameterAssert(name);
    NSParameterAssert(value);
    NSParameterAssert(allValues);
    if (self = [super init]) {
        _name = name;
        _value = value;
        _allValues = allValues;
    }
    return self;
}

- (BOOL)isNull {
    return [_value isKindOfClass:[NSNull class]];
}

- (NSNumber *)asNumber {
    return [self p_as:[NSNumber class]];
}

- (NSString *)asString {
    return [self p_as:[NSString class]];
}

- (NSString *)asNonemptyString {
    NSString *value = [self asString];
    if (value.length == 0) {
        @throw [NSException pos_exceptionWithFormat:@"%@ is empty in JSON:\n%@", _name, _allValues];
    }
    return value;
}

- (NSArray *)asArray {
    NSMutableArray *values = [NSMutableArray new];
    [[self p_as:[NSArray class]] enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop) {
        [values addObject:[[POSJSONObject alloc] initWithName:[NSString stringWithFormat:@"%@[%@]", _name, @(idx)]
                                                        value:element
                                                    allValues:_allValues]];
    }];
    return values;
}

- (POSJSONMap *)asMap {
    return [[POSJSONMap alloc] initWithName:_name
                                     values:[self p_as:[NSDictionary class]]
                                  allValues:_allValues];
}

- (NSURL *)asURL {
    NSURL *URL = [NSURL URLWithString:[self asString]];
    if (!URL) {
        @throw [NSException pos_exceptionWithFormat:@"%@ is not an URL\n%@", _name, _allValues];
    }
    return URL;
}

- (NSUUID *)asUUID {
    NSUUID *value = [[NSUUID alloc] initWithUUIDString:[self asNonemptyString]];
    if (!value) {
        @throw [NSException pos_exceptionWithFormat:@"%@ is not an valid UUID\n%@", _name, _allValues];
    }
    return value;
}

#pragma mark Private

- (id)p_as:(Class)aClass {
    if (![_value isKindOfClass:aClass]) {
        @throw [NSException pos_exceptionWithFormat:@"%@ is not %s but %s in JSON:\n%@",
                _name,
                class_getName(aClass),
                class_getName([_value class]),
                _allValues];
    }
    return _value;
}


@end

#pragma mark -

@interface POSJSONMap ()
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSDictionary *values;
@property (nonatomic, readonly) NSString *allValues;
@end

@implementation POSJSONMap

- (instancetype)init {
    @throw [NSException
            exceptionWithName:NSInternalInconsistencyException
            reason:[NSString stringWithFormat:@"Unexpected deadly init invokation '%@', use %@ instead.",
                    NSStringFromSelector(_cmd),
                    NSStringFromSelector(@selector(initWithData:))]
            userInfo:nil];
}

- (instancetype)initWithData:(NSData *)data {
    if (!data) {
        @throw [NSException pos_exceptionWithFormat:@"JSON data is nil"];
    }
    NSString *allValues = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSError *error;
    id values = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!values) {
        @throw [NSException pos_exceptionWithFormat:@"JSON parsing failed with '%@':\n%@",
                [error localizedDescription], allValues];
    }
    if (![values isKindOfClass:[NSDictionary class]]) {
        @throw [NSException pos_exceptionWithFormat:@"Root JSON object is not a struct:\n%@", allValues];
    }
    return [self initWithName:@"root" values:values allValues:allValues];
}

- (instancetype)initWithName:(NSString *)name values:(NSDictionary *)values allValues:(NSString *)allValues {
    NSParameterAssert(name);
    NSParameterAssert(values);
    NSParameterAssert(allValues);
    if (self = [super init]) {
        _name = name;
        _values = values;
        _allValues = allValues;
    }
    return self;
}

- (BOOL)contains:(NSString *)key {
    return _values[key] != nil;
}

- (POSJSONObject *)extract:(NSString *)key {
    id value = _values[key];
    if (!value) {
        @throw [NSException pos_exceptionWithFormat:@"'%@' doesn't contain object with key '%@' in JSON:\n%@",
                _name, key, _allValues];
    }
    return [[POSJSONObject alloc] initWithName:[NSString stringWithFormat:@"%@.%@", _name, key]
                                         value:value
                                     allValues:_allValues];
}

- (nullable POSJSONObject *)tryExtract:(NSString *)key {
    id value = _values[key];
    if (!value) {
        return nil;
    }
    return [[POSJSONObject alloc] initWithName:[NSString stringWithFormat:@"%@.%@", _name, key]
                                         value:value
                                     allValues:_allValues];
}

- (NSArray *)map:(id (^)(NSString *key, POSJSONObject *value))block {
    NSParameterAssert(block);
    NSMutableArray *mappedValues = [[NSMutableArray alloc] initWithCapacity:_values.count];
    [_values enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        [mappedValues addObject:block(key, [[POSJSONObject alloc]
                                            initWithName:[key description]
                                            value:value
                                            allValues:_allValues])];
    }];
    return mappedValues;
}

#pragma mark NSObject

- (NSString *)description {
    if (!_allValues) {
        return [super description];
    }
    return [NSString stringWithFormat:@"%@: %@=%@", super.description, _name, _values];
}

@end

NS_ASSUME_NONNULL_END
