//
//  TextViewController.m
//  headstart
//

#import "TextViewController.h"
#import "HeftTabBarViewController.h"

extern NSString* kMpedLogName;

NSString* kEmailSubject = @"MPED log";

/*@interface TextViewController()<UITextViewDelegate>
@end*/

@implementation TextViewController

+ (id)controllerWithString:(NSString*)text storyboard:(UIStoryboard*)storyboard{
	TextViewController* result = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass(self)];
	result->text = text;
	return result;
}

- (void)viewDidLoad{
    [super viewDidLoad];
	textView.text = text;
	sendLogButton.enabled = [MFMailComposeViewController canSendMail];
}

#pragma mark -
#pragma mark IBAction

- (IBAction)close{
	[(HeftTabBarViewController*)self.view.superview.nextResponder dismissTextViewController];
}

- (IBAction)sendLog:(UIButton *)sender {
	[self displayComposerSheet];
}

#pragma mark -
#pragma mark Compose Mail

// Displays an email composition interface inside the application. Populates all the Mail fields.
-(void)displayComposerSheet{
	MFMailComposeViewController* mailController = [MFMailComposeViewController new];
	mailController.mailComposeDelegate = self;
	
	[mailController setSubject:kEmailSubject];
	
	
	NSString* logFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
							 stringByAppendingPathComponent:kMpedLogName];
	[mailController addAttachmentData:[NSData dataWithContentsOfFile:logFilePath] mimeType:@"txt/plain" fileName:kMpedLogName];
	
	[self presentViewController:mailController animated:YES completion:nil];
}


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error{
	switch(result){
		case MFMailComposeResultSaved:
		case MFMailComposeResultSent:{
			UIAlertView *reportAlert = [[UIAlertView alloc]initWithTitle:kEmailSubject
																 message:@"Log is in the Outbox"
																delegate:self
													   cancelButtonTitle:@"OK"
													   otherButtonTitles:nil];
			[reportAlert show];
			break;
		}
		case MFMailComposeResultFailed:{
			UIAlertView *reportAlert = [[UIAlertView alloc]initWithTitle:kEmailSubject
																 message:[error localizedDescription]
																delegate:self
													   cancelButtonTitle:@"OK"
													   otherButtonTitles:nil];
			[reportAlert show];
			break;
		}
		default:;
	}
	[self dismissViewControllerAnimated:YES completion:nil];
}
@end
