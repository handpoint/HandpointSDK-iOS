//
//  HistoryViewController.m
//  headstart
//

#import "HistoryViewController.h"
#import "HistoryCell.h"
#import "HeftTabBarViewController.h"

#import "../heft/HeftStatusReportPublic.h"
#import "../heft/HeftClient.h"

extern NSMutableString* formatAmountString(NSString* currency, NSString* amountString);

@interface Transaction : NSObject<NSCoding>
@property(nonatomic, strong) NSString* status;
@property(nonatomic, strong) NSString* date;
@property(nonatomic, assign) int amount;
@property(nonatomic, strong) NSString* currency;
@property(nonatomic, strong) NSString* amountString;
@property(nonatomic, strong) NSString* type;
@property(nonatomic, strong) NSString* transactionId;
@property(nonatomic, strong) NSString* customerReceipt;
@property(nonatomic, strong) NSString* merchantReceipt;
@property(nonatomic, assign) BOOL voided;
@property(nonatomic, strong) NSDictionary* xmlInfo;
@end

static NSString* const kTransactionStatusKey = @"status";
static NSString* const kTransactionDateKey = @"date";
static NSString* const kTransactionAmountKey = @"amount";
static NSString* const kTransactionCurrencyKey = @"currency";
static NSString* const kTransactionAmountStringKey = @"amount_s";
static NSString* const kTransactionTypeKey = @"type";
static NSString* const kTransactionIdKey = @"id";
static NSString* const kTransactionCustomerReceiptKey = @"customerReceipt";
static NSString* const kTransactionMerchantReceiptKey = @"merchantReceipt";
static NSString* const kTransactionVoidKey = @"void";
static NSString* const kTransactionInfo = @"xmlInfo";

@implementation Transaction

@synthesize status, date, amount, currency, amountString, type, transactionId, customerReceipt, merchantReceipt, voided, xmlInfo;

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder{
	[aCoder encodeObject:status forKey:kTransactionStatusKey];
	[aCoder encodeObject:date forKey:kTransactionDateKey];
	[aCoder encodeInt:amount forKey:kTransactionAmountKey];
	[aCoder encodeObject:currency forKey:kTransactionCurrencyKey];
	[aCoder encodeObject:amountString forKey:kTransactionAmountStringKey];
	[aCoder encodeObject:type forKey:kTransactionTypeKey];
	[aCoder encodeObject:transactionId forKey:kTransactionIdKey];
	[aCoder encodeObject:customerReceipt forKey:kTransactionCustomerReceiptKey];
	[aCoder encodeObject:merchantReceipt forKey:kTransactionMerchantReceiptKey];
	[aCoder encodeBool:voided forKey:kTransactionVoidKey];
	[aCoder encodeObject:xmlInfo forKey:kTransactionInfo];
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super init]){
		status = [aDecoder decodeObjectForKey:kTransactionStatusKey];
		date = [aDecoder decodeObjectForKey:kTransactionDateKey];
		amount = [aDecoder decodeIntegerForKey:kTransactionAmountKey];
		currency = [aDecoder decodeObjectForKey:kTransactionCurrencyKey];
		amountString = [aDecoder decodeObjectForKey:kTransactionAmountStringKey];
		type = [aDecoder decodeObjectForKey:kTransactionTypeKey];
		transactionId = [aDecoder decodeObjectForKey:kTransactionIdKey];
		customerReceipt = [aDecoder decodeObjectForKey:kTransactionCustomerReceiptKey];
		merchantReceipt = [aDecoder decodeObjectForKey:kTransactionMerchantReceiptKey];
		voided = [aDecoder decodeBoolForKey:kTransactionVoidKey];
		xmlInfo = [aDecoder decodeObjectForKey:kTransactionInfo];
    }
    return self;
}

@end

static NSDictionary* currencySymbol;
static NSString* const historyFileName = @"history";

NSString* historyPath(){
	return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:historyFileName];
}

@implementation HistoryViewController{
	HeftTabBarViewController* __weak mainController;
	NSMutableArray* transactions;
}

+ (void)initialize{
	if(self == [HistoryViewController class]){
		currencySymbol = @{@"826":@"₤", @"840":@"$", @"978":@"€"};
	}
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super initWithCoder:aDecoder]){
		mainController = (HeftTabBarViewController*)self.parentViewController;

		transactions = [NSKeyedUnarchiver unarchiveObjectWithFile:historyPath()];
		if(!transactions)
			transactions = [NSMutableArray new];
    }
    return self;
}

/*- (void)viewDidLoad{
	[super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}*/

- (void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	
	[self updateOnHeftClient:mainController.heftClient != nil];
}

- (void)updateOnHeftClient:(BOOL)fOn{
	self.tableView.allowsSelection = fOn;
}

- (void)addNewTransaction:(id<FinanceResponseInfo>)info{
	NSDictionary* xml = info.xml;
	LOG(@"%@", xml);
	
	NSString* type = xml[@"TransactionType"];

	if([type isEqualToString:@"SALE"] || [type isEqualToString:@"REFUND"]){
		NSString* currency = xml[@"Currency"];
		NSString* amount = nil;
		if(currency){
			amount = xml[@"RequestedAmount"];
			Assert([amount length]);
			amount = formatAmountString(currencySymbol[currency], amount);
			currency = [@"0" stringByAppendingString:currency];
		}
		
		NSString* date = xml[@"EFTTimestamp"];
		
		Transaction* transaction = [Transaction new];
		transaction.status = info.status;
		transaction.date = date;
		transaction.amount = info.authorisedAmount;
		transaction.currency = currency;
		transaction.amountString = amount;
		transaction.transactionId = info.transactionId;
		transaction.type = type;
		transaction.customerReceipt = info.customerReceipt;
		transaction.merchantReceipt = info.merchantReceipt;
		transaction.xmlInfo = info.xml;
		[transactions addObject:transaction];
	}
	else if ([type hasPrefix:@"VOID"]){
		if([info.status isEqualToString:@"DECLINED"])
			return;
		NSString* transactionId = xml[@"OriginalEFTTransactionID"];
		int index = [transactions indexOfObjectPassingTest:^(Transaction* obj, NSUInteger idx, BOOL *stop){
			if([obj.transactionId isEqualToString:transactionId])
				*stop = YES;
			return *stop;
		}];
		Assert(index != NSNotFound);
		Transaction* transaction = transactions[index];
		transaction.voided = YES;
	}
	
	[NSKeyedArchiver archiveRootObject:transactions toFile:historyPath()];
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return [transactions count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	static NSString* const kCellIdentifier = @"HistoryCell";
	
	HistoryCell* cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
	
	int row = indexPath.row;
	Transaction* transaction = transactions[row];
	cell.dateLabel.text = transaction.date;
	cell.amountLabel.text = transaction.amountString;
	cell.typeLabel.text = transaction.type;
	cell.voidLabel.hidden = !transaction.voided;
	
	return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	int row = indexPath.row;
	Transaction* transaction = transactions[row];
	if(!transaction.voided && ![transaction.status isEqualToString:@"DECLINED"]){
		if([transaction.type isEqualToString:@"SALE"])
			[mainController.heftClient saleVoidWithAmount:transaction.amount currency:transaction.currency cardholder:YES transaction:transaction.transactionId];
		else if([transaction.type isEqualToString:@"REFUND"])
			[mainController.heftClient refundVoidWithAmount:transaction.amount currency:transaction.currency cardholder:YES transaction:transaction.transactionId];
		else
			return;
		[mainController showTransactionViewController:eTransactionVoid];
	}
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    int row = indexPath.row;
	Transaction* transaction = transactions[row];
    
    NSDictionary* cellInfo = transaction.xmlInfo;
    
    if (cellInfo)
    {
        [mainController showHtmlViewControllerWithDetails:@[transaction.customerReceipt, cellInfo]];
    }
}

@end
