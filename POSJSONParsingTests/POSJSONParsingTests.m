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
    XCTAssertTrue(items.count == 4);
    POSJSONMap *itemValues = [items[0] asMap];
    XCTAssertTrue([[[itemValues extract:@"id"] asString] isEqualToString:@"Open"]);
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

@end
