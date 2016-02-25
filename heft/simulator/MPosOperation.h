//
//  MPosOperation.h
//  headstart
//

#import <Foundation/Foundation.h>
#import "IHostProcessor.h"

class RequestCommand;
@class HeftConnection;
@protocol IResponseProcessor;

@interface MPosOperation : NSOperation<IHostProcessor>

- (id)initWithRequest:(RequestCommand*)aRequest connection:(HeftConnection*)aConnection resultsProcessor:(id<IResponseProcessor>)aProcessor sharedSecret:(NSData*)aSharedSecret;

@end
