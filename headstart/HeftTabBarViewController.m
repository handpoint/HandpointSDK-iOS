//
//  HeftTabBarViewController.m
//  headstart
//

#import "HeftTabBarViewController.h"
#import "PhoneViewController.h"

#import "../heft/HeftClient.h"

@implementation HeftTabBarViewController

@synthesize heftClient;

/*- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
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
	if(heftClient != aHeftClient){
		heftClient = aHeftClient;
		PhoneViewController* phoneViewController = self.viewControllers[1];
		Assert([phoneViewController isKindOfClass:[PhoneViewController class]]);
		phoneViewController.heftClient = heftClient;
	}
}

#pragma mark HeftStatusReportDelegate

- (void)responseStatus:(ResponseInfo*)info{
	NSLog(@"responseStatus:");
}

- (void)responseFinanceStatus:(FinanceResponseInfo*)info{
	NSLog(@"responseFinanceStatus:");
}

- (void)responseLogInfo:(LogInfo*)info{
	NSLog(@"responseLogInfo:");
}

- (void)requestSignature:(NSString*)receipt{
	NSLog(@"requestSignature:");
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:@"sign?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
	[alert show];
}

- (void)cancelSignature{
	NSLog(@"cancelSignature");
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	[heftClient acceptSignature:buttonIndex != [alertView cancelButtonIndex]];
}

@end
