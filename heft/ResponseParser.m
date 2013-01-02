//
//  ResponseParser.m
//  headstart
//

#import "ResponseParser.h"

@implementation ResponseParser

@synthesize result;

- (id)initWithPath:(NSString*)aNodeName{
	if(self = [super init]){
		nodeName = aNodeName;
		result = [NSMutableDictionary new];
	}
	return self;
}

#pragma mark NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
	if(key){
		[result setObject:string forKey:key];
		key = nil;
	}
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if(inScope)
		key = elementName;
	else
		inScope = [elementName isEqualToString:nodeName];
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
	if(inScope)
		inScope = ![elementName isEqualToString:nodeName];
}

@end
