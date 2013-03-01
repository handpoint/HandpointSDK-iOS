//
//  SettingsViewController.m
//  headstart
//

#import "SettingsViewController.h"
#import "HeftTabBarViewController.h"

#import "../heft/HeftClient.h"

NSString* const kUserCurrencyKey = @"UserCurrency";
NSString* const kRefundKey = @"Refund";
NSString* const kLogLevel = @"LogLevel";
NSString* const currencyDidChangedNotification = @"currencyDidChangedNotification";

NSString* currency[] = {@"GBP", @"USD", @"EUR"};

@implementation SettingsViewController{
	HeftTabBarViewController* __weak mainController;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
	if(self = [super initWithCoder:aDecoder]){
		mainController = (HeftTabBarViewController*)self.parentViewController;
	}
	return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
	[self updateOnHeftClient:mainController.heftClient != nil];
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	currentCurrency = [defaults integerForKey:kUserCurrencyKey];
	refundSwitch.on = [defaults boolForKey:kRefundKey];
	logLevelControl.selectedSegmentIndex = [defaults integerForKey: kLogLevel];
}

/*- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}*/

- (void)updateOnHeftClient:(BOOL)fOn{
	finInitButton.enabled = fOn;
	getLogsButton.enabled = fOn;
}

#pragma mark -
#pragma mark IBAction

- (IBAction)refundChanged:(UISwitch*)sender{
	[[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:kRefundKey];
}

- (IBAction)financeInit:(UIButton*)sender{
	[mainController.heftClient financeInit];
	[mainController showTransactionViewController:eTransactionFinInit];
}

- (IBAction)getLogs:(UIButton*)sender{
	[mainController.heftClient logGetInfo];
	[mainController showTransactionViewController:eTransactionGetLog];
	[mainController setTransactionStatus:@"Getting logs"];
}

- (IBAction)controlSegmentChange:(UISegmentedControl *)sender {
	[[NSUserDefaults standardUserDefaults] setInteger:logLevelControl.selectedSegmentIndex forKey: kLogLevel];
	[mainController.heftClient logSetLevel:logLevelControl.selectedSegmentIndex];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return dim(currency);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	NSString* const kCellIdentifier = @"CurrencyCell";
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
	
	int row = indexPath.row;
	cell.textLabel.text = currency[row];
	cell.accessoryType = row == currentCurrency ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	
	return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:currentCurrency inSection:0]].accessoryType = UITableViewCellAccessoryNone;
	currentCurrency = indexPath.row;
	[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:currentCurrency inSection:0]].accessoryType = UITableViewCellAccessoryCheckmark;
	
	[[NSUserDefaults standardUserDefaults] setInteger:currentCurrency forKey:kUserCurrencyKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:currencyDidChangedNotification object:self];
}
@end
