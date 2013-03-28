//
//  TextViewController.h
//  headstart
//

#import <MessageUI/MessageUI.h>

@interface TextViewController : UIViewController<MFMailComposeViewControllerDelegate>

+ (id)controllerWithString:(NSString*)text storyboard:(UIStoryboard*)storyboard;

@end
