//
//  SignViewController.h
//  headstart
//

@interface SignViewController : UIViewController
@property (nonatomic, strong) NSString* transactionId;
@property (nonatomic, strong) id target;
@end

NSString* pathToTransactionSign(NSString* transactionId);
