//
//  MpedDevice.h
//  headstart
//

#import "HeftClient.h"

@class HeftConnection;
@protocol HeftStatusReportDelegate;

@interface MpedDevice : NSObject<HeftClient>{
	HeftConnection* connection;
	NSOperationQueue* queue;
	//NSObject<HeftClientDelegate>* delegate;
	NSData* sharedSecret;
	__weak NSObject<HeftStatusReportDelegate>* delegate;
	NSConditionLock* signLock;
	BOOL signatureIsOk;
}

- (id)initWithConnection:(HeftConnection*)aConnection sharedSecret:(NSData*)aSharedSecret delegate:(NSObject<HeftStatusReportDelegate>*)aDelegate;

@end
