//
//  ResponseParser.h
//  headstart
//

#import <Foundation/Foundation.h>


@interface ResponseParser : NSObject<NSXMLParserDelegate>

@property(nonatomic, readonly) NSMutableDictionary* result;

- (id)initWithPath:(NSString*)aNodeName;

@end
