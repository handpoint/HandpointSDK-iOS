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

NSMutableString* formatAmountString(NSString* currency, NSString* amountString){
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
	[text insertString:currency atIndex:0];
	return text;
}

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
	amount.text = formatAmountString(currencySymbol[currentCurrencyIndex], amountString);
}

#pragma mark TabBarItemProtocol

- (void)updateOnHeftClient:(BOOL)fOn{
	saleButton.enabled = fOn;
	refundButton.enabled = fOn;
}

#pragma mark IBAction

- (IBAction)sale{
	int iAmount = [amountString intValue];
	if(!iAmount)
		return;
	[mainController.heftClient saleWithAmount:iAmount currency:currency[[[NSUserDefaults standardUserDefaults] integerForKey:kUserCurrencyKey]] cardholder:YES];
	[mainController showTransactionViewController:eTransactionSale];
	amountUsed = YES;
}

- (IBAction)refund{
	int iAmount = [amountString intValue];
	if(!iAmount)
		return;
	[mainController.heftClient refundWithAmount:iAmount currency:currency[[[NSUserDefaults standardUserDefaults] integerForKey:kUserCurrencyKey]] cardholder:YES];
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

	int digit = sender.tag;
	if(digit || [amountString length]){
		[amountString appendFormat:@"%d", digit];
		amount.text = formatAmountString(currencySymbol[currentCurrencyIndex], amountString);
	}
}

- (IBAction)zeros{
	[self resetAmountIfNeeded];
	
	if([amountString length]){
		[amountString appendString:@"00"];
		amount.text = formatAmountString(currencySymbol[currentCurrencyIndex], amountString);
	}
}

- (IBAction)clearDigit{
	[self resetAmountIfNeeded];
	
	int newLength = [amountString length] - 1;
	if(newLength >= 0){
		[amountString deleteCharactersInRange:NSMakeRange(newLength, 1)];
		amount.text = formatAmountString(currencySymbol[currentCurrencyIndex], amountString);
	}
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
	[textField resignFirstResponder];
	return YES;
}

@end
