//
//  POSJSONParsingTests.m
//  POSJSONParsing
//
//  Created by Osipov on 11.06.15.
//  Copyright (c) 2015 Pavel Osipov. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "POSJSONParsing.h"

@interface POSJSONParsingTests : XCTestCase
@property (nonatomic) NSData *data;
@end

@implementation POSJSONParsingTests

- (void)setUp {
    [super setUp];
    NSString *JSON = @"{\"menu\": {"
                      "    \"header\": \"SVG Viewer\","
                      "    \"height\": 500,"
                      "    \"items\": ["
                      "        {\"id\": \"Open\"},"
                      "        {\"id\": \"OpenNew\", \"label\": \"Open New\"},"
                      "        null,"
                      "        {\"id\": \"ZoomIn\", \"label\": \"Zoom In\"},"
                      "        {\"id\": \"BadClose\", \"uuid\": \"da401e4c-590a\"},"
                      "        {\"id\": \"EmptyClose\", \"uuid\": \"\"},"
                      "        {\"id\": \"GoodClose\", \"uuid\": \"da401e4c-590a-4fb3-be63-b984ab12c0a8\"},"
                      "    ]"
                      "}}";
    self.data = [JSON dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)testStringParsing {
    POSJSONMap *values = [[POSJSONMap alloc] initWithData:_data];
    NSString *header = [[[[values extract:@"menu"] asMap] extract:@"header"] asString];
    XCTAssertTrue([@"SVG Viewer" isEqualToString:header]);
}

- (void)testNumberParsing {
    POSJSONMap *values = [[POSJSONMap alloc] initWithData:_data];
    NSNumber *height = [[[[values extract:@"menu"] asMap] extract:@"height"] asNumber];
    XCTAssertTrue([@(500) isEqualToNumber:height]);
}

- (void)testArrayParsing {
    POSJSONMap *values = [[POSJSONMap alloc] initWithData:_data];
    NSArray *items = [[[[values extract:@"menu"] asMap] extract:@"items"] asArray];
    XCTAssertTrue(items.count == 7);
    POSJSONMap *itemValues = [items[0] asMap];
    XCTAssertTrue([[[itemValues extract:@"id"] asString] isEqualToString:@"Open"]);
}

- (void)testUUIDParsing {
    POSJSONMap *values = [[POSJSONMap alloc] initWithData:_data];
    NSArray *items = [[[[values extract:@"menu"] asMap] extract:@"items"] asArray];
    POSJSONMap *badValue = [items[4] asMap];
    XCTAssertTrue([[[badValue extract:@"id"] asString] isEqualToString:@"BadClose"]);
    XCTAssertThrows([[badValue extract:@"uuid"] asUUID]);
    POSJSONMap *emptyValue = [items[5] asMap];
    XCTAssertTrue([[[emptyValue extract:@"id"] asString] isEqualToString:@"EmptyClose"]);
    XCTAssertThrows([[emptyValue extract:@"uuid"] asNonemptyString]);
    XCTAssertThrows([[emptyValue extract:@"uuid"] asUUID]);
    POSJSONMap *goodValue = [items[6] asMap];
    XCTAssertTrue([[[goodValue extract:@"id"] asString] isEqualToString:@"GoodClose"]);
    XCTAssertTrue([[[goodValue extract:@"uuid"] asUUID]
                   isEqual:[[NSUUID alloc] initWithUUIDString:@"da401e4c-590a-4fb3-be63-b984ab12c0a8"]]);
}

- (void)testNullParsing {
    POSJSONMap *values = [[POSJSONMap alloc] initWithData:_data];
    NSArray *items = [[[[values extract:@"menu"] asMap] extract:@"items"] asArray];
    XCTAssertTrue([items[2] isNull]);
}

- (void)testJSONObjectShouldThrowErrorWhenTypesMismatch {
    POSJSONMap *values = [[POSJSONMap alloc] initWithData:_data];
    XCTAssertThrows([[[[values extract:@"menu"] asMap] extract:@"header"] asNumber]);
}

- (void)testJSONMapExtractShouldThrowErrorIfObjectWasNotFound {
    POSJSONMap *values = [[POSJSONMap alloc] initWithData:_data];
    XCTAssertThrows([values extract:@"crap"]);
}

- (void)testJSONMapTryExtractShouldNotThrowErrorIfObjectWasNotFound {
    POSJSONMap *values = [[POSJSONMap alloc] initWithData:_data];
    XCTAssertNil([values tryExtract:@"crap"]);
    XCTAssertNil([[values tryExtract:@"crap"] asNumber]);
}

- (void)testJSONMapShouldThrowsErrorWhenJSONIsMalformed {
    XCTAssertThrows([[POSJSONMap alloc] initWithData:[@"blah\nblah" dataUsingEncoding:NSUTF8StringEncoding]]);
}

- (void)testJSONWithArrayRootObject {
    NSString *JSON = @"[{\"key1\":\"value1\"},{\"key2\":\"value2\"}]";
    POSJSONObject *arrayJSON = [[POSJSONObject alloc] initWithData:[JSON dataUsingEncoding:NSUTF8StringEncoding]];
    NSArray<POSJSONObject *> *values = [arrayJSON asArray];
    XCTAssertTrue(values.count == 2);
    POSJSONMap *firstObject = [values.firstObject asMap];
    XCTAssertEqualObjects([[firstObject extract:@"key1"] asString], @"value1");
}

- (void)testIsNumber {
    NSString *JSON = @"{\"key\":403}";
    POSJSONMap *map = [[POSJSONMap alloc] initWithData:[JSON dataUsingEncoding:NSUTF8StringEncoding]];
    POSJSONObject *node = [map extract:@"key"];
    XCTAssertTrue([node isNumber]);
    XCTAssertFalse([node isString]);
    XCTAssertFalse([node isArray]);
}

- (void)testIsString {
    NSString *JSON = @"{\"key\":\"value\"}";
    POSJSONMap *map = [[POSJSONMap alloc] initWithData:[JSON dataUsingEncoding:NSUTF8StringEncoding]];
    POSJSONObject *node = [map extract:@"key"];
    XCTAssertTrue([node isString]);
    XCTAssertFalse([node isNumber]);
    XCTAssertFalse([node isArray]);
}

- (void)testIsArray {
    NSString *JSON = @"[{\"key1\":\"value1\"},{\"key2\":\"value2\"}]";
    POSJSONObject *JSONObject = [[POSJSONObject alloc] initWithData:[JSON dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertTrue([JSONObject isArray]);
    XCTAssertFalse([JSONObject isString]);
    XCTAssertFalse([JSONObject isNumber]);
}

- (void)testIsMap {
    NSString *JSON = @"{\"key\":{\"key1\": \"value\"}}";
    POSJSONMap *map = [[POSJSONMap alloc] initWithData:[JSON dataUsingEncoding:NSUTF8StringEncoding]];
    POSJSONObject *node = [map extract:@"key"];
    XCTAssertTrue([node isMap]);
    XCTAssertFalse([node isString]);
    XCTAssertFalse([node isNumber]);
    XCTAssertFalse([node isArray]);
}

- (void)testIsURL {
    NSString *JSON = @"{\"key\":\"https://mail.ru\"}";
    POSJSONMap *map = [[POSJSONMap alloc] initWithData:[JSON dataUsingEncoding:NSUTF8StringEncoding]];
    POSJSONObject *node = [map extract:@"key"];
    XCTAssertTrue([node isString]);
    XCTAssertTrue([node isURL]);
    XCTAssertFalse([node isNumber]);
    XCTAssertFalse([node isArray]);
}

- (void)testIsUUID {
    NSString *JSON = @"{\"key\":\"72881a22-38eb-11e9-b210-d663bd873d93\"}";
    POSJSONMap *map = [[POSJSONMap alloc] initWithData:[JSON dataUsingEncoding:NSUTF8StringEncoding]];
    POSJSONObject *node = [map extract:@"key"];
    XCTAssertTrue([node isString]);
    XCTAssertTrue([node isUUID]);
    XCTAssertFalse([node isNumber]);
    XCTAssertFalse([node isArray]);
}

@end
