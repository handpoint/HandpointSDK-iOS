//
//  ResponseParser.h
//  headstart
//

@interface ResponseParser : NSObject<NSXMLParserDelegate>

@property(nonatomic, readonly) NSMutableDictionary* result;

- (id)initWithPath:(NSString*)aNodeName;

@end
