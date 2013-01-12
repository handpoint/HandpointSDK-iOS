//
//  FinanceTransactionOperation.h
//  headstart
//

#import "IHostProcessor.h"

class RequestCommand;
@class HeftConnection;
@protocol IResponseProcessor;

@interface FinanceTransactionOperation : NSOperation<IHostProcessor>{
	RequestCommand*	pRequestCommand;
	__weak id<IResponseProcessor> processor;
}

- (id)initWithRequest:(RequestCommand*)aRequest connection:(HeftConnection*)aConnection resultsProcessor:(id<IResponseProcessor>)aProcessor sharedSecret:(NSData*)aSharedSecret;

@end
