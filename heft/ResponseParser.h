//
//  ResponseParser.h
//  headstart
//

@interface ResponseParser : NSObject<NSXMLParserDelegate>{
	NSString* nodeName;
	BOOL inScope;
	NSString* key;
}

@property(nonatomic, readonly) NSMutableDictionary* result;

- (id)initWithPath:(NSString*)aNodeName;

@end
