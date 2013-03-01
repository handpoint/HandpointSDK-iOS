//
//  TextViewController.h
//  headstart
//
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface TextViewController : UIViewController<MFMailComposeViewControllerDelegate>{
	__weak IBOutlet UITextView* textView;
	__weak IBOutlet UIButton *sendLogButton;
	NSString* text;
}

+ (id)controllerWithString:(NSString*)text storyboard:(UIStoryboard*)storyboard;

- (IBAction)close;

@end
