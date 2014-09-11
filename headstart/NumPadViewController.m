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
UIPickerView *pickerView;

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
    __weak IBOutlet UITextField *monthsTextfield;
    UIActionSheet *monthsSelector;
	HeftTabBarViewController* __weak mainController;
	NSMutableString* amountString;
	BOOL amountUsed;
	int currentCurrencyIndex;
    NSArray *availableMonths;
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
    availableMonths = [NSArray arrayWithObjects:@"", @"03", @"06", @"12", @"18", @"24", @"30", @"36", @"42", @"48", @"54", @"60", nil];
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
- (IBAction)startScan {
	//[mainController.heftClient enableScanner];
	//[mainController.heftClient enableScanner:[multiScan isOn]];
	//[mainController.heftClient enableScanner:[multiScan isOn] buttonMode:[buttonMode isOn]];
	//[mainController.heftClient enableScanner:[multiScan isOn] buttonMode:[buttonMode isOn] timeoutSeconds:100];
	//[mainController.heftClient enableScannerWithMultiScan:[multiScan isOn]];
	//[mainController.heftClient enableScannerWithMultiScan:[multiScan isOn] buttonMode:[buttonMode isOn] timeoutSeconds:100];
    [mainController.heftClient enableScannerWithMultiScan:[multiScan isOn] buttonMode:[buttonMode isOn]];
    [mainController showTransactionViewController:eTransactionScanner];
}

- (IBAction)stopScan {
    [mainController.heftClient disableScanner];
    //[mainController dismissTransactionViewController];
}

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

-(void)createMonthsSelector{
    
    monthsSelector = [[UIActionSheet alloc] initWithTitle:@"Select months" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Ok", nil];
    
    
    CGRect pickerFrame = CGRectMake(10,40,300,0);
    
    UIPickerView *monthsPickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
    monthsPickerView.showsSelectionIndicator = YES;
    monthsPickerView.dataSource = self;
    monthsPickerView.delegate = self;
    [monthsSelector addSubview:monthsPickerView];
    
    CGRect pickerRect = monthsPickerView.bounds;
    pickerRect.origin.y = -100;
    monthsPickerView.bounds = pickerRect;

}

- (IBAction)showMonthsSelector:(id)sender {

    if (pickerView == nil) {
        pickerView=[[UIPickerView alloc] initWithFrame:CGRectMake(190,20,150,150)];
        pickerView.transform = CGAffineTransformMakeScale(0.75f, 0.75f);
        pickerView.delegate = self;
        pickerView.dataSource = self;
        pickerView.showsSelectionIndicator = YES;
        pickerView.backgroundColor = [UIColor clearColor];
        pickerView.hidden = YES;
        [self.view addSubview:pickerView];
    }
    if (![monthsTextfield.text isEqual: @""])
    {
        int selectedRow = [availableMonths indexOfObject:monthsTextfield.text];
        [pickerView selectRow:selectedRow inComponent:0 animated:YES];
    }
    if([pickerView isHidden]) {
        [pickerView setHidden:NO];
    }
    else {
        [pickerView setHidden:YES];
    }

//    if(monthsSelector == nil)
//    {
//        [self createMonthsSelector];
//    }
//    
//    [monthsSelector showInView:self.view];
//    [monthsSelector setBounds:CGRectMake(0,0,320, 500)];
    
}
#pragma mark UITextFieldDelegate

- (void)viewDidUnload {
    monthsTextfield = nil;
    [super viewDidUnload];
}

#pragma mark UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
	int count = [availableMonths count];
	return count ? count : 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (availableMonths!=nil) {
        return [availableMonths objectAtIndex:row];//assuming the array contains strings..
    }
    return @"";//or nil, depending how protective you are
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    monthsTextfield.text = [availableMonths objectAtIndex:row];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == monthsSelector.firstOtherButtonIndex){
        // set text to the selected item in picker.. how can I access picker?? monthsTextfield.text =;
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return NO;
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return NO;
}
@end
