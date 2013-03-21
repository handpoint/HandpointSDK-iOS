//
//  HtmlViewController.m
//  headstart
//

#import "HtmlViewController.h"
#import "HeftTabBarViewController.h"
#import "XmlViewController.h"
#import "SignViewController.h"

NSString* const kReceiptTypeKey = @"CheckType";

extern const NSString* kTransactionCustomerReceiptKey ;
extern const NSString* kTransactionInfo;
extern const NSString* kVoidReceipt;
extern const NSString* kVoidTransactionInfo;
extern const NSString* kTransactionIdKey;

@interface HtmlViewController()<UIWebViewDelegate>
@end

@implementation HtmlViewController{
	__weak IBOutlet UIWebView* webView;
	__weak IBOutlet UIButton* closeButton;
	__weak IBOutlet UIButton* signButton;
	__weak IBOutlet UIButton* declineButton;
	__weak IBOutlet UIButton* showInfoButton;
	__weak IBOutlet UISwitch* receiptTypeSwitch;
	__weak IBOutlet UILabel* switchLabel;
	__weak IBOutlet UIButton* showSignButton;
	NSString* html;
	NSDictionary* xmlInfo;
	NSString* voidHtml;
	NSDictionary* voidXmlInfo;
	NSString* transactionId;
}

+ (id)controllerWithDetails:(NSDictionary*)details storyboard:(UIStoryboard*)storyboard{
	HtmlViewController* result = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass(self)];
	result->html = details[kTransactionCustomerReceiptKey];
	result->xmlInfo = details[kTransactionInfo];
	result->voidHtml = details[kVoidReceipt];
	result->voidXmlInfo = details[kVoidTransactionInfo];
	result->transactionId = details[kTransactionIdKey];
	return result;
}

- (void)viewDidLoad{
	[super viewDidLoad];

	if(voidHtml){
		receiptTypeSwitch.hidden = NO;
		switchLabel.hidden = NO;
	}
	receiptTypeSwitch.on =[[NSUserDefaults standardUserDefaults] boolForKey:kReceiptTypeKey];
	[self reloadWebView];
	
	if(xmlInfo){
		if(!transactionId || ![[NSFileManager defaultManager] fileExistsAtPath: pathToTransactionSign(transactionId)])
			showSignButton.enabled = NO;
	}
	else
		[self setSignMode];
}

/*- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}*/

- (void)setSignMode{
	closeButton.hidden = YES;
	showInfoButton.hidden = YES;
	showSignButton.hidden = YES;
	signButton.hidden = NO;
	declineButton.hidden = NO;
}

#pragma mark -
#pragma mark Segue

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showXml"])
    {
        XmlViewController* controller = (XmlViewController*) segue.destinationViewController;
		if(receiptTypeSwitch.on && voidXmlInfo)
			controller.xmlInfo = voidXmlInfo;
		else
			controller.xmlInfo = xmlInfo;
    }
}

#pragma mark -
#pragma mark IBAction

- (IBAction)close{
	[(HeftTabBarViewController*)self.view.superview.nextResponder dismissHtmlViewController];
}

- (IBAction)decline:(UIButton*)sender{
	[(HeftTabBarViewController*)self.view.superview.nextResponder acceptSign:nil];
}

- (IBAction)receiptTypeChanged:(UISwitch *)sender {
	[[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:kReceiptTypeKey];
	[self reloadWebView];
}

- (IBAction)ShowSign:(UIButton *)sender {
	SignViewController* controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SignViewController"];
	controller.target = self;
	if(showSignButton == sender)
		controller.transactionId = transactionId;
	[[UIApplication sharedApplication].delegate.window.rootViewController presentModalViewController:controller animated:YES];
}

/*#pragma mark UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView*)webView{
}*/

#pragma mark -
- (void)reloadWebView{
	if (voidHtml && receiptTypeSwitch.on)
		[webView loadHTMLString:voidHtml baseURL:nil];
	else
		[webView loadHTMLString:html baseURL:nil];
}

- (void)setSignImage:(UIImage*)image{
	[(HeftTabBarViewController*)self.view.superview.nextResponder acceptSign:image];

}
@end
