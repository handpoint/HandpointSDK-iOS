//
//  TransactionViewController.h
//  headstart
//

@interface TransactionViewController : UIViewController{
	__weak IBOutlet UILabel* statusLabel;
	__weak IBOutlet UIImageView* statusImage;
	__weak IBOutlet UIButton* cancelButton;
}

- (IBAction)cancel;

- (void)setStatusMessage:(NSString*)message;
- (void)allowCancel:(BOOL)fAllowed;

@end
