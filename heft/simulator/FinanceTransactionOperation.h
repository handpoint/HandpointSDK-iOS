//
//  FinanceTransactionOperation.h
//  headstart
//

#import "IHostProcessor.h"

class RequestCommand;
@class HeftConnection;
@protocol IResponseProcessor;

@interface FinanceTransactionOperation : NSOperation<IHostProcessor>

- (id)initWithRequest:(RequestCommand*)aRequest connection:(HeftConnection*)aConnection resultsProcessor:(id<IResponseProcessor>)aProcessor sharedSecret:(NSData*)aSharedSecret;

@end
