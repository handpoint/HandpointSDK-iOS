//
//  PhoneViewController
//  headstart
//

#import "NumPadViewController.h"
#import "HeftTabBarViewController.h"

#import "../heft/HeftClient.h"

extern NSString* const kUserCurrencyKey;
extern NSString* const kRefundKey;
extern NSString* const currencyDidChangedNotification;
extern NSString* currency[];

NSString* currencySymbol[] = {@"₤", @"$", @"€"};

@implementation NumPadViewController{
	__weak IBOutlet UIButton* saleButton;
	__weak IBOutlet UIButton* refundButton;
	__weak IBOutlet UITextField* amount;
	HeftTabBarViewController* __weak mainController;
	NSMutableString* amountString;
	BOOL amountUsed;
	int currentCurrencyIndex;
}

//@synthesize heftClient;

- (id)initWithCoder:(NSCoder *)aDecoder{
	if(self = [super initWithCoder:aDecoder]){
		mainController = (HeftTabBarViewController*)self.parentViewController;
		amountString = [NSMutableString new];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currencyDidChanged:) name:currencyDidChangedNotification object:nil];
	}
	return self;
}

- (void)dealloc{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)formatAmountString{
	const unichar padding[] = {L'0', L'0', L'0'};
	int length = dim(padding) - [amountString length];
	NSMutableString* text = nil;
	if(length < 0)
		text = [amountString mutableCopy];
	else{
		text = [NSMutableString stringWithCharacters:padding length:length];
		[text appendString:amountString];
	}
	[text insertString:@"." atIndex:[text length] - 2];
	[text insertString:currencySymbol[currentCurrencyIndex] atIndex:0];
	amount.text = text;
}

- (void)viewDidLoad{
    [super viewDidLoad];
	[self currencyDidChanged:nil];
}

- (void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	
	[self updateOnHeftClient:mainController.heftClient != nil];

	BOOL refund = [[NSUserDefaults standardUserDefaults] boolForKey:kRefundKey];
	saleButton.hidden = refund;
	refundButton.hidden = !refund;
}

/*- (void)didReceiveMemoryWarning
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

- (void)currencyDidChanged:(NSNotification*)notification{
	currentCurrencyIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kUserCurrencyKey];
	[self formatAmountString];
}

- (void)updateOnHeftClient:(BOOL)fOn{
	saleButton.enabled = fOn;
	refundButton.enabled = fOn;
}

#pragma mark IBAction

- (IBAction)sale{
	[mainController.heftClient saleWithAmount:[amountString intValue] currency:currency[[[NSUserDefaults standardUserDefaults] integerForKey:kUserCurrencyKey]] cardholder:YES];
	[mainController showTransactionViewController:eTransactionSale];
	amountUsed = YES;
}

- (IBAction)refund{
	[mainController.heftClient refundWithAmount:[amountString intValue] currency:currency[[[NSUserDefaults standardUserDefaults] integerForKey:kUserCurrencyKey]] cardholder:YES];
	[mainController showTransactionViewController:eTransactionRefund];
	amountUsed = YES;
}

- (void)resetAmountIfNeeded{
	if(amountUsed){
		[amountString setString:@""];
		amountUsed = NO;
	}
}

- (IBAction)digit:(UIButton*)sender{
	[self resetAmountIfNeeded];

	[amountString appendFormat:@"%d", sender.tag];
	[self formatAmountString];
}

- (IBAction)zeros{
	[self resetAmountIfNeeded];
	
	if([amountString length]){
		[amountString appendString:@"00"];
		[self formatAmountString];
	}
}

- (IBAction)clearDigit{
	[self resetAmountIfNeeded];
	
	int newLength = [amountString length] - 1;
	if(newLength >= 0){
		[amountString deleteCharactersInRange:NSMakeRange(newLength, 1)];
		[self formatAmountString];
	}
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
	[textField resignFirstResponder];
	return YES;
}

@end
