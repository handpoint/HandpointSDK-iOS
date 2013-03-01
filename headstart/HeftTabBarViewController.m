//
//  HeftTabBarViewController.m
//  headstart
//

#import "HeftTabBarViewController.h"
//#import "ScanViewController.h"
//#import "NumPadViewController.h"
#import "HistoryViewController.h"
//#import "SettingsViewController.h"
#import "TransactionViewController.h"
#import "HtmlViewController.h"
#import "TextViewController.h"

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
	HtmlViewController* htmlViewController;
	TextViewController* textViewController;
	UIAlertView* signAlert;
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

- (void)showViewController:(UIViewController*)viewController{
	[self addFadeTransition];
	[self.view addSubview:viewController.view];
}

- (void)dismissViewController:(UIViewController*)viewController{
	[self addFadeTransition];
	[viewController.view removeFromSuperview];
}

- (void)showTransactionViewController:(eTransactionType)type{
	transactionViewController = [TransactionViewController transactionWithType:type storyboard:self.storyboard];
	[self showViewController:transactionViewController];
}

- (void)dismissTransactionViewController{
	[self dismissViewController:transactionViewController];
	transactionViewController = nil;
}

- (void)setTransactionStatus:(NSString*)status{
	[transactionViewController setStatusMessage:status];
}

- (void)showHtmlViewControllerWithDetails:(NSArray*)details  {
	htmlViewController = [HtmlViewController controllerWithDetails:details storyboard:self.storyboard];
    
	[self showViewController:htmlViewController];
}

- (void)dismissHtmlViewController{
	[self dismissViewController:htmlViewController];
	htmlViewController = nil;
}

- (void)showTextViewControllerWithString:(NSString*)text{
	textViewController = [TextViewController controllerWithString:text storyboard:self.storyboard];
	[self showViewController:textViewController];
}

- (void)dismissTextViewController{
	[self dismissViewController:textViewController];
	textViewController = nil;
}

- (void)acceptSign:(BOOL)accepted{
	[heftClient acceptSignature:accepted];
	[self dismissHtmlViewController];
}

/*#pragma mark property

- (void)setHeftClient:(id<HeftClient>)aHeftClient{
	if(heftClient != aHeftClient){
		heftClient = aHeftClient;
		NumPadViewController* phoneViewController = self.viewControllers[eNumPadTab];
		Assert([phoneViewController isKindOfClass:[NumPadViewController class]]);
		[phoneViewController updateOnHeftClient:heftClient != nil];

		SettingsViewController* settingsViewController = self.viewControllers[eSettingsTab];
		Assert([settingsViewController isKindOfClass:[SettingsViewController class]]);
		[settingsViewController updateOnHeftClient:heftClient != nil];
		
		HistoryViewController* historyViewController = self.viewControllers[eHistoryTab];
		Assert([historyViewController isKindOfClass:[HistoryViewController class]]);
		[historyViewController updateOnHeftClient:heftClient != nil];

		if(heftClient)
			self.selectedIndex = eNumPadTab;
	}
}*/

#pragma mark HeftStatusReportDelegate

- (void)didConnect:(id<HeftClient>)client{
	self.heftClient = client;

	for(id vc in self.viewControllers)
		[vc updateOnHeftClient:heftClient != nil];

	if(heftClient)
		self.selectedIndex = eNumPadTab;
}

- (void)responseStatus:(id<ResponseInfo>)info{
	LOG(@"responseStatus:%@", info.xml);
	[self setTransactionStatus:info.status];
	[transactionViewController allowCancel:[info.xml[@"CancelAllowed"] boolValue]];
}

- (void)responseError:(id<ResponseInfo>)info{
	LOG(@"responseError:%@", info.status);
	[transactionViewController setStatusMessage:info.status];
	[self performSelector:@selector(dismissTransactionViewController) withObject:nil afterDelay:2.];
}

- (void)responseFinanceStatus:(id<FinanceResponseInfo>)info{
	LOG(@"responseFinanceStatus:%@", info.status);
	[transactionViewController setStatusMessage:info.status];
	[self performSelector:@selector(dismissTransactionViewController) withObject:nil afterDelay:2.];
	
	NSString* receipt = info.customerReceipt;
        if(receipt.length)
        [self performSelector:@selector(showHtmlViewControllerWithDetails:) withObject:@[receipt, info.xml] afterDelay:2.3];
    
        if(info.statusCode == EFT_PP_STATUS_SUCCESS){
		self.selectedIndex = eHistoryTab;
		
		HistoryViewController* historyViewController = self.viewControllers[eHistoryTab];
		Assert([historyViewController isKindOfClass:[HistoryViewController class]]);
		[historyViewController addNewTransaction:info];
	}
}

- (void)responseLogInfo:(id<LogInfo>)info{
	LOG(@"responseLogInfo:%@", info.status);
	[info.log writeToFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"mped_log.txt"] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	[self dismissTransactionViewController];
	[self showTextViewControllerWithString:info.log];
}

- (void)requestSignature:(NSString*)receipt{
     LOG(@"requestSignature:");
     [self showHtmlViewControllerWithDetails:@[receipt]];
}

- (void)cancelSignature{
	LOG(@"cancelSignature");
	[self dismissHtmlViewController];
	[signAlert dismissWithClickedButtonIndex:1 animated:YES];
}

@end
