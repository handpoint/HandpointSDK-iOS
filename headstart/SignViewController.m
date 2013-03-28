//
//  SignViewController.m
//  headstart
//

#import "SignViewController.h"
#import "SignView.h"

NSString* pathToTransactionSign(NSString* transactionId){
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", transactionId]];
}

@implementation SignViewController{
	__weak IBOutlet SignView* signView;
	__weak IBOutlet UIImageView *imageSignView;
	__weak IBOutlet UIButton *doneSignButton;
	__weak IBOutlet UIButton *cancelSignButton;
	__weak IBOutlet UIButton *closeButton;
}

@synthesize transactionId, target;

- (void)viewDidLoad{
	[super viewDidLoad];
	[self performSelectorOnMainThread:@selector(asyncDidLoad) withObject:nil waitUntilDone:NO];
}

- (void)asyncDidLoad{
	if(transactionId){
		signView.userInteractionEnabled = NO;
		doneSignButton.hidden = YES;
		cancelSignButton.hidden = YES;
		closeButton.hidden = NO;
		imageSignView.image = [UIImage imageWithContentsOfFile:pathToTransactionSign(transactionId)];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
	return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

- (NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskLandscape;
}

#pragma mark -
#pragma IBAction

- (IBAction)cancelSign:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doneSign:(UIButton *)sender {
	UIImage* image = signView.image;
	[self dismissViewControllerAnimated:YES completion:^{
		[target  performSelector:@selector(setSignImage:) withObject:image];
	}];
}

@end

