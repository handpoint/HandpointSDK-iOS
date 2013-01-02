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
	HeftConnection* connection;
	//int maxFrameSize;
	__weak id<IResponseProcessor> processor;
	NSData* sharedSecret;
	NSOutputStream* sendStream;
	NSInputStream* recvStream;
}

- (id)initWithRequest:(RequestCommand*)aRequest connection:(HeftConnection*)aConnection resultsProcessor:(id<IResponseProcessor>)processor sharedSecret:(NSData*)aSharedSecret;

@end
