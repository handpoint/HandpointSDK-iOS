//
//  TextViewController.m
//  headstart
//

#import "TextViewController.h"
#import "HeftTabBarViewController.h"

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
	
	Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
	mailClass = nil;
	if ((!mailClass) || (![mailClass canSendMail]))
	{
		sendLogButton.enabled = NO;
	}
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
-(void)displayComposerSheet
{
	MFMailComposeViewController* mailController = [[MFMailComposeViewController alloc] init];
	mailController.mailComposeDelegate = self;
	
	[mailController setSubject:@"MPED log"];
	
	
	NSString* logFileName = @"mped_log.txt";
	
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* documentsPath = [paths objectAtIndex:0];
	NSString* logFilePath = [documentsPath stringByAppendingPathComponent:logFileName];
	
	NSData* logData = [NSData dataWithContentsOfFile:logFilePath];
	[mailController addAttachmentData:logData mimeType:@"txt/plain" fileName:logFileName];
	
	[self presentViewController:mailController animated:YES completion:nil];
}


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	switch (result)
	{
		case MFMailComposeResultCancelled:
			break;
		case MFMailComposeResultSaved:
			break;
		case MFMailComposeResultSent:
		{
			UIAlertView *reportAlert = [[UIAlertView alloc]initWithTitle:@"Send report"
																 message:@"Log a problem."
																delegate:self
													   cancelButtonTitle:@"Ok"
													   otherButtonTitles:nil, nil];
			[reportAlert show];
		}
			break;
		case MFMailComposeResultFailed:
		{
			UIAlertView *reportAlert = [[UIAlertView alloc]initWithTitle:[error localizedDescription]
																 message:[error localizedRecoverySuggestion]
																delegate:self
													   cancelButtonTitle:@"Ok"
													   otherButtonTitles:nil];
			[reportAlert show];
		}
			break;
		default:
			break;
	}
	[ self dismissViewControllerAnimated:YES completion:nil];
}
@end
