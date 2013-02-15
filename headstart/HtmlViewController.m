//
//  HtmlViewController.m
//  headstart
//

#import "HtmlViewController.h"
#import "HeftTabBarViewController.h"

@interface HtmlViewController()<UIWebViewDelegate>
@end

@implementation HtmlViewController

+ (id)controllerWithHtmlString:(NSString*)html storyboard:(UIStoryboard*)storyboard{
	HtmlViewController* result = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass(self)];
	result->html = html;
	return result;
}

- (void)viewDidLoad{
    [super viewDidLoad];
	[webView loadHTMLString:html baseURL:nil];
}

/*- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}*/

#pragma mark -
#pragma mark IBAction

- (IBAction)close{
	[(HeftTabBarViewController*)self.view.superview.nextResponder dismissHtmlViewController];
}

/*#pragma mark UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView*)webView{
}*/

@end
