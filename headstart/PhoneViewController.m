//
//  PhoneViewController
//  headstart
//

#import "PhoneViewController.h"
#import "../heft/HeftClient.h"

@implementation PhoneViewController

@synthesize heftClient;

- (void)viewDidLoad{
    [super viewDidLoad];
	saleButton.hidden = !heftClient;
}

/*- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
	return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (NSUInteger)supportedInterfaceOrientations{
	return UIInterfaceOrientationMaskPortrait;
}

#pragma mark property

- (void)setHeftClient:(id<HeftClient>)aHeftClient{
	heftClient = aHeftClient;
	saleButton.hidden = !heftClient;
}

#pragma mark IBAction

- (IBAction)sale{
	[heftClient saleWithAmount:[amount.text intValue] currency:@"GBP" cardholder:YES];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
	[textField resignFirstResponder];
	return YES;
}

@end
