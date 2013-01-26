//
//  HeftTabBarViewController.m
//  headstart
//

#import "HeftTabBarViewController.h"
#import "NumPadViewController.h"
#import "HistoryViewController.h"
#import "SettingsViewController.h"
#import "TransactionViewController.h"

#import "../heft/HeftClient.h"
#import "../heft/Shared/api/CmdIds.h"

enum eTab{
	eScanTab
	, eNumPadTab
	, eHistoryTab
	, eSettingsTab
};

@interface TransactionViewController ()
+ (id)transactionWithType:(eTransactionType)type storyboard:(UIStoryboard*)storyboard;
@end

@implementation HeftTabBarViewController{
	TransactionViewController* transactionViewController;
}

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

- (void)addFadeTransition{
	CATransition* transition = [CATransition animation];
	transition.type = kCATransitionFade;
	[self.view.layer addAnimation:transition forKey:nil];
}

- (void)showTransactionViewController:(eTransactionType)type{
	transactionViewController = [TransactionViewController transactionWithType:type storyboard:self.storyboard];

	[self addFadeTransition];
	[self.view addSubview:transactionViewController.view];
}

- (void)dismissTransactionViewController{
	[self addFadeTransition];
	[transactionViewController.view removeFromSuperview];

	transactionViewController = nil;
}

- (void)setTransactionStatus:(NSString*)status{
	[transactionViewController setStatusMessage:status];
}

#pragma mark property

- (void)setHeftClient:(id<HeftClient>)aHeftClient{
	if(heftClient != aHeftClient){
		heftClient = aHeftClient;
		NumPadViewController* phoneViewController = self.viewControllers[eNumPadTab];
		Assert([phoneViewController isKindOfClass:[NumPadViewController class]]);
		[phoneViewController updateOnHeftClient:heftClient != nil];

		SettingsViewController* settingsViewController = self.viewControllers[eSettingsTab];
		Assert([settingsViewController isKindOfClass:[SettingsViewController class]]);
		[settingsViewController updateOnHeftClient:heftClient != nil];

		if(heftClient)
			self.selectedIndex = eNumPadTab;
	}
}

#pragma mark HeftStatusReportDelegate

- (void)responseStatus:(ResponseInfo*)info{
	LOG(@"responseStatus:%@", info.xml);
	[self setTransactionStatus:info.status];
	[transactionViewController allowCancel:[info.xml[@"CancelAllowed"] boolValue]];
}

- (void)responseError:(ResponseInfo*)info{
	LOG(@"responseError:%@", info.status);
	[transactionViewController setStatusMessage:info.status];
	[self performSelector:@selector(dismissTransactionViewController) withObject:nil afterDelay:2.];
}

- (void)responseFinanceStatus:(FinanceResponseInfo*)info{
	LOG(@"responseFinanceStatus:%@", info.status);
	[transactionViewController setStatusMessage:info.status];
	[self performSelector:@selector(dismissTransactionViewController) withObject:nil afterDelay:2.];
	
	if(info.statusCode == EFT_PP_STATUS_SUCCESS){
		self.selectedIndex = eHistoryTab;
		
		HistoryViewController* historyViewController = self.viewControllers[eHistoryTab];
		Assert([historyViewController isKindOfClass:[HistoryViewController class]]);
		[historyViewController addNewTransaction:info];
	}
}

- (void)responseLogInfo:(LogInfo*)info{
	LOG(@"responseLogInfo:%@", info.status);
	[info.log writeToFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"mped_log.txt"] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	[self dismissTransactionViewController];
}

- (void)requestSignature:(NSString*)receipt{
	LOG(@"requestSignature:");
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:@"sign?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
	[alert show];
}

- (void)cancelSignature{
	LOG(@"cancelSignature");
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	[heftClient acceptSignature:buttonIndex != [alertView cancelButtonIndex]];
}

@end
