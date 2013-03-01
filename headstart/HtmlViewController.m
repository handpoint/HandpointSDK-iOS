//
//  HtmlViewController.m
//  headstart
//

#import "HtmlViewController.h"
#import "HeftTabBarViewController.h"
#import "XmlViewController.h"

@interface HtmlViewController()<UIWebViewDelegate>
@end

@implementation HtmlViewController{
	__weak IBOutlet UIWebView* webView;
	__weak IBOutlet UIButton* closeButton;
	__weak IBOutlet UIButton* signButton;
	__weak IBOutlet UIButton* declineButton;
    __weak IBOutlet UIButton* showInfoButton;
	NSString* html;
    NSDictionary* xmlInfo;
}

+ (id)controllerWithDetails:(NSArray*)details storyboard:(UIStoryboard*)storyboard{
	HtmlViewController* result = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass(self)];
	result->html = details[0];
	result->xmlInfo = details.count > 1 ? details[1] : nil;
    
	return result;
}

- (void)setSignMode{
	closeButton.hidden = YES;
	showInfoButton.hidden = YES;
	signButton.hidden = NO;
	declineButton.hidden = NO;
    
}

- (void)viewDidLoad{
    [super viewDidLoad];
    [webView loadHTMLString:html baseURL:nil];
    if (xmlInfo)
        [self setSignMode];
}

/*- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}*/

#pragma mark -
#pragma mark Segue

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showXml"])
    {
        XmlViewController* controller = (XmlViewController*) segue.destinationViewController;
        controller.xmlInfo = xmlInfo;
    }
}

#pragma mark -
#pragma mark IBAction

- (IBAction)close{
	[(HeftTabBarViewController*)self.view.superview.nextResponder dismissHtmlViewController];
}

- (IBAction)sign:(UIButton*)sender{
	[(HeftTabBarViewController*)self.view.superview.nextResponder acceptSign:sender == signButton];
}

/*#pragma mark UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView*)webView{
}*/

@end
