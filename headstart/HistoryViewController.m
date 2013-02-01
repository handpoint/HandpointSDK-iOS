//
//  HistoryViewController.m
//  headstart
//

#import "HistoryViewController.h"
#import "HistoryCell.h"
#import "HeftTabBarViewController.h"

#import "../heft/HeftStatusReport.h"
#import "../heft/HeftClient.h"

@interface Transaction : NSObject<NSCoding>
@property(nonatomic, strong) NSString* date;
@property(nonatomic, assign) int amount;
@property(nonatomic, strong) NSString* currency;
@property(nonatomic, strong) NSString* amountString;
@property(nonatomic, strong) NSString* type;
@property(nonatomic, strong) NSString* transactionId;
@property(nonatomic, strong) NSString* receipt;
@property(nonatomic, assign) BOOL voided;
@end

static NSString* const kTransactionDateKey = @"date";
static NSString* const kTransactionAmountKey = @"amount";
static NSString* const kTransactionCurrencyKey = @"currency";
static NSString* const kTransactionAmountStringKey = @"amount_s";
static NSString* const kTransactionTypeKey = @"type";
static NSString* const kTransactionIdKey = @"id";
static NSString* const kTransactionReceiptKey = @"receipt";
static NSString* const kTransactionVoidKey = @"void";

@implementation Transaction

@synthesize date, amount, currency, amountString, type, transactionId, receipt, voided;

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder{
	[aCoder encodeObject:date forKey:kTransactionDateKey];
	[aCoder encodeInt:amount forKey:kTransactionAmountKey];
	[aCoder encodeObject:currency forKey:kTransactionCurrencyKey];
	[aCoder encodeObject:amountString forKey:kTransactionAmountStringKey];
	[aCoder encodeObject:type forKey:kTransactionTypeKey];
	[aCoder encodeObject:transactionId forKey:kTransactionIdKey];
	[aCoder encodeObject:receipt forKey:kTransactionReceiptKey];
	[aCoder encodeBool:voided forKey:kTransactionVoidKey];
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super init]){
		date = [aDecoder decodeObjectForKey:kTransactionDateKey];
		amount = [aDecoder decodeIntegerForKey:kTransactionAmountKey];
		currency = [aDecoder decodeObjectForKey:kTransactionCurrencyKey];
		amountString = [aDecoder decodeObjectForKey:kTransactionAmountStringKey];
		type = [aDecoder decodeObjectForKey:kTransactionTypeKey];
		transactionId = [aDecoder decodeObjectForKey:kTransactionIdKey];
		receipt = [aDecoder decodeObjectForKey:kTransactionReceiptKey];
		voided = [aDecoder decodeBoolForKey:kTransactionVoidKey];
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

- (void)addNewTransaction:(FinanceResponseInfo*)info{
	NSDictionary* xml = info.xml;
	LOG(@"%@", xml);
	
	NSString* type = xml[@"TransactionType"];

	if([type isEqualToString:@"SALE"] || [type isEqualToString:@"REFUND"]){
		NSString* currency = xml[@"Currency"];
		NSString* amount = nil;
		if(currency){
			amount = [((NSString*)currencySymbol[currency]) stringByAppendingString:xml[@"RequestedAmount"]];
			Assert([amount length] > 2);
			amount = [amount stringByReplacingCharactersInRange:NSMakeRange([amount length] - 2, 0) withString:@"."];
			currency = [@"0" stringByAppendingString:currency];
		}
		
		NSString* date = xml[@"EFTTimestamp"];
		
		Transaction* transaction = [Transaction new];
		transaction.date = date;
		transaction.amount = info.authorisedAmount;
		transaction.currency = currency;
		transaction.amountString = amount;
		transaction.transactionId = info.transactionId;
		transaction.type = type;
		[transactions addObject:transaction];
	}
	else if ([type hasPrefix:@"VOID"]){
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
	if(!transaction.voided){
		[mainController.heftClient saleVoidWithAmount:transaction.amount currency:transaction.currency cardholder:YES transaction:transaction.transactionId];
		[mainController showTransactionViewController:eTransactionVoid];
	}
}

@end
