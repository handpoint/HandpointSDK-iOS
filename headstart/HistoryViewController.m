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

- (id)initWith;

@end

@implementation Transaction

@synthesize date, amount, currency, amountString, type, transactionId, receipt;

- (id)initWith{
	if(self = [super init]){
		
	}
	return self;
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder{
	[aCoder encodeObject:date];
	[aCoder encodeInt:amount forKey:@"amount"];
	[aCoder encodeObject:currency];
	[aCoder encodeObject:amountString];
	[aCoder encodeObject:type];
	[aCoder encodeObject:transactionId];
	[aCoder encodeObject:receipt];
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super init]){
		date = [aDecoder decodeObject];
		amount = [aDecoder decodeIntegerForKey:@"amount"];
		currency = [aDecoder decodeObject];
		amountString = [aDecoder decodeObject];
		type = [aDecoder decodeObject];
		transactionId = [aDecoder decodeObject];
		receipt = [aDecoder decodeObject];
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

/*- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}*/

- (void)addNewTransaction:(FinanceResponseInfo*)info{
	NSDictionary* xml = info.xml;
	LOG(@"%@", xml);

	NSString* currency = xml[@"Currency"];
	int amountInt = 0;
	NSString* amount = nil;
	if(currency){
		amountInt = [xml[@"TotalAmount"] intValue];
		amount = [((NSString*)currencySymbol[currency]) stringByAppendingString:xml[@"TotalAmount"]];
		Assert([amount length] > 2);
		amount = [amount stringByReplacingCharactersInRange:NSMakeRange([amount length] - 2, 0) withString:@"."];
		currency = [@"0" stringByAppendingString:currency];
	}

	NSString* date = xml[@"EFTTimestamp"];
	NSString* transactionId = xml[@"TransactionID"];
	NSString* type = xml[@"TransactionType"];
	
	Transaction* tr = [Transaction new];
	tr.date = date;
	tr.amount = amountInt;
	tr.currency = currency;
	tr.amountString = amount;
	tr.transactionId = transactionId;
	tr.type = type;
	[transactions addObject:tr];
	
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
	
	return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	int row = indexPath.row;
	Transaction* transaction = transactions[row];
	[mainController.heftClient saleVoidWithAmount:transaction.amount currency:transaction.currency cardholder:YES transaction:transaction.transactionId];
}

@end
