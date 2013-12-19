//
//  TransactionViewController.m
//  headstart
//

#import "TransactionViewController.h"
#import "HeftTabBarViewController.h"
#import "../heft/HeftClient.h"

@interface TransactionViewController ()
@property(nonatomic) eTransactionType type;
@end

@implementation TransactionViewController{
    __weak IBOutlet UILabel* statusLabel;
	__weak IBOutlet UIImageView* statusImage;
	__weak IBOutlet UIButton* cancelButton;
}

@synthesize type;

+ (id)transactionWithType:(eTransactionType)type storyboard:(UIStoryboard*)storyboard{
	TransactionViewController* result = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass(self)];
	result.type = type;
	return result;
}

/*- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc{
}*/

NSString* sufix[eTransactionNum] = {@"dsc", @"sale", @"sale", @"init", @"init", @"init", @"init"};

const int imagesCount[eTransactionNum] = {4, 2, 2, 4, 4, 4};

- (void)viewDidLoad{
    [super viewDidLoad];

	NSMutableArray* images = [NSMutableArray array];
	NSString* path = [NSString stringWithFormat:@"transaction.%@.", sufix[type]];
	for(int i = 0; i < imagesCount[type]; ++i){
		UIImage* image = [UIImage imageNamed:[path stringByAppendingFormat:@"%d.png",i]];
		[images addObject:image];
	}

	statusImage.animationImages = images;
	statusImage.animationDuration = 1;
	[statusImage startAnimating];
    
    [self allowCancel:(type == eTransactionScanner ? TRUE : FALSE)];
    [cancelButton setTitle:(type == eTransactionScanner ? @"Stop Scanner" : @"Cancel") forState:UIControlStateNormal];
	cancelButton.layer.cornerRadius = 10;
}

/*- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}*/

- (void)setStatusMessage:(NSString*)message{
	statusLabel.text = message;
}

- (void)allowCancel:(BOOL)fAllowed{
	cancelButton.hidden = !fAllowed;
}

#pragma mark IBAction

- (IBAction)cancel{

	[((HeftTabBarViewController*)self.view.superview.nextResponder).heftClient cancel];
    if(type == eTransactionScanner)
    {
        [self dismissViewViewController:self];

    }
}

-(void)dismissViewViewController:(UIViewController*)viewController{
    [viewController.view removeFromSuperview];
}
@end
