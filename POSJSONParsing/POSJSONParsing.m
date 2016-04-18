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

+ (void)pos_throw:(NSString *)format, ... {
    NSParameterAssert(format);
    va_list args;
    va_start(args, format);
    NSString *reason = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
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
        [NSException pos_throw:@"%@ is not an URL\n%@", _name, _allValues];
    }
    return URL;
}

#pragma mark Private

- (id)p_as:(Class)aClass {
    if (![_value isKindOfClass:aClass]) {
        [NSException pos_throw:@"%@ is not %s but %s in JSON:\n%@",
         _name,
         class_getName(aClass),
         class_getName([_value class]),
         _allValues];
        return nil;
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
        [NSException pos_throw:@"JSON data is nil"];
    }
    NSString *allValues = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSError *error;
    id values = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!values) {
        [NSException pos_throw:@"JSON parsing failed with '%@':\n%@", [error localizedDescription], allValues];
    }
    if (![values isKindOfClass:[NSDictionary class]]) {
        [NSException pos_throw:@"Root JSON object is not a struct:\n%@", allValues];
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
        [NSException pos_throw:@"'%@' doesn't contain object with key '%@' in JSON:\n%@", _name, key, _allValues];
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

@end

NS_ASSUME_NONNULL_END
