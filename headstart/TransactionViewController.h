//
//  TransactionViewController.h
//  headstart
//

@interface TransactionViewController : UIViewController

- (IBAction)cancel;

- (void)setStatusMessage:(NSString*)message;
- (void)allowCancel:(BOOL)fAllowed;

@end
