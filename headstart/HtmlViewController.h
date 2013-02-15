//
//  HtmlViewController.h
//  headstart
//

@interface HtmlViewController : UIViewController{
	__weak IBOutlet UIWebView* webView;
	NSString* html;
}

+ (id)controllerWithHtmlString:(NSString*)html storyboard:(UIStoryboard*)storyboard;

- (IBAction)close;

@end
