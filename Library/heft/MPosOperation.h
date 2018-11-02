//
//  MPosOperation.h
//  headstart
//

#import "IHostProcessor.h"

class RequestCommand;
@class iOSConnection;
@protocol IResponseProcessor;

@interface MPosOperation : NSOperation<IHostProcessor>

- (id)initWithRequest:(RequestCommand *)aRequest
           connection:(iOSConnection *)aConnection
     resultsProcessor:(id <IResponseProcessor>)processor
         sharedSecret:(NSString *)aSharedSecret;

+ (void)startRunLoop;
@end
