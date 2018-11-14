//
//  MPosOperation.h
//  headstart
//

#import "IHostProcessor.h"

class RequestCommand;
@class HeftConnection;
@protocol xIResponseProcessor;

@interface MPosOperation : NSOperation<IHostProcessor>

- (id)initWithRequest:(RequestCommand *)aRequest
           connection:(HeftConnection *)aConnection
     resultsProcessor:(id <IResponseProcessor>)processor
         sharedSecret:(NSString *)aSharedSecret;

+ (void)startRunLoop;
@end
