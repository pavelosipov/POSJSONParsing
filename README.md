<h1>Wrapper around NSJSONSerialization
Tiny wrapper around NSJSONSerialization to parse JSON. Its major features are:

* Detailed error reporting.
* Error handling is based on throwing exceptions instead of "if hell".
* Type checking.
* Fluent API.

<h3>Example</h3>

```objc
@interface Menu : NSObject
@property (nonatomic) NSString *header;
@property (nonatomic) NSNumber *height;
@property (nonatomic) NSNumber *width;
@end

@implementation Menu

+ (POSJSONMap *)exmpleJSON {
    return [[POSJSONMap alloc] initWithData:[
        @"{\"menu\": {"
        "    \"header\": \"SVG Viewer\","
        "    \"height\": 500,"
        "    \"items\": ["
        "        {\"id\": \"Open\"},"
        "        {\"id\": \"OpenNew\", \"label\": \"Open New\"},"
        "        null,"
        "        {\"id\": \"ZoomIn\", \"label\": \"Zoom In\"},"
        "    ]"
        "}}"
        dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (Menu *)parseMenu:(NSError **)error {
    @try {
        POSJSONMap *JSON = [self exmpleJSON];
        Menu *menu = [Menu new];
        // mandatory parameters
        menu.header = [[JSON extract:@"header"] asString];
        menu.height = [[JSON extract:@"height"] asNumber];
        // optional parameters
        menu.width = [[JSON tryExtract:@"width"] asNumber];
        return menu;
    }
    @catch (NSException *exception) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.example"
                                         code:0
                                     userInfo:@{ NSLocalizedDescriptionKey: [exception reason] }];
        }
        return nil;
    }
}

@end
```

If to replace in the example above `[[JSON tryExtract:@"width"] asNumber]` with
`[[JSON extract:@"width"] asNumber]` exception with the following reason will be thrown:
```
'root.menu' doesn't contain object with key 'width' in JSON:
{
	"menu": {
		"header": "SVG Viewer",
		"height": 500,
		"items": [
			{"id": "Open"},
			{"id": "OpenNew", "label": "Open New"},
			null,
			{"id": "ZoomIn", "label": "Zoom In"},
		]
	}
}
```

<h3>Remarks</h3>

As we know NSException and ARC are not best friends. At the same time usually JSON is a contract
between your app and some remote service. If everithing is OK then will be no exceptions at all,
in other case there is some kind of contract violation and you have more serious problems than
some leaked objects during malformed JSON parsing. For example NSKeyedArchiever notifies clients
about errors in the same manner during archive unpacking.

Enjoy!