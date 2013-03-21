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

NSString* pathToTransactionSign(NSString* transactionId);

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
@property(nonatomic, strong) NSDictionary* xmlInfo;
@property(nonatomic, strong) NSString* voidReceipt;
@property(nonatomic, strong) NSDictionary* voidXmlInfo;
@end

NSString* const kTransactionStatusKey = @"status";
NSString* const kTransactionDateKey = @"date";
NSString* const kTransactionAmountKey = @"amount";
NSString* const kTransactionCurrencyKey = @"currency";
NSString* const kTransactionAmountStringKey = @"amount_s";
NSString* const kTransactionTypeKey = @"type";
NSString* const kTransactionIdKey = @"id";
NSString* const kTransactionCustomerReceiptKey = @"customerReceipt";
NSString* const kTransactionMerchantReceiptKey = @"merchantReceipt";
NSString* const kTransactionVoidKey = @"void";
NSString* const kTransactionInfo = @"xmlInfo";
NSString* const kVoidReceipt = @"voidReciept";
NSString* const kVoidTransactionInfo = @"voidXmlInfo";

@implementation Transaction

@synthesize status, date, amount, currency, amountString, type, transactionId, customerReceipt, merchantReceipt, xmlInfo, voidReceipt, voidXmlInfo;

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
	[aCoder encodeObject:xmlInfo forKey:kTransactionInfo];
	[aCoder encodeObject:voidReceipt forKey:kVoidReceipt];
	[aCoder encodeObject:voidXmlInfo forKey:kVoidTransactionInfo];
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
		xmlInfo = [aDecoder decodeObjectForKey:kTransactionInfo];
		voidReceipt = [aDecoder decodeObjectForKey:kVoidReceipt];
		voidXmlInfo = [aDecoder decodeObjectForKey:kVoidTransactionInfo];
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
	__weak HeftTabBarViewController* mainController;
	NSMutableArray* transactions;
	__weak IBOutlet UIToolbar *toolbar;
	__weak IBOutlet UIBarButtonItem *flexibleSpace;
	NSArray* noToolBarItems;
	NSArray* toolBarItems;
	NSMutableArray* selectedCellsIndexPaths;
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

- (void)viewDidLoad{
	[super viewDidLoad];

	UIBarButtonItem* editButton = self.editButtonItem;
	UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
												   target:self
												   action:@selector(cancelEditing)];
 	noToolBarItems = @[flexibleSpace, editButton];
	toolBarItems = @[cancelButton, flexibleSpace, editButton];
	toolbar.items = noToolBarItems;
}
/*
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

- (void)addNewTransaction:(id<FinanceResponseInfo>)info sign:(UIImage*)sign{
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
		if(sign)
			Verify([UIImagePNGRepresentation(sign) writeToFile:pathToTransactionSign(transaction.transactionId) atomically:YES]);
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
		transaction.voidReceipt = info.customerReceipt;
		transaction.voidXmlInfo = info.xml;
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
	cell.voidLabel.hidden = !transaction.voidReceipt;
	return cell;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete){
		[self deleteSignWithTransactionId:[transactions[indexPath.row] transactionId]];
        [transactions removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[NSKeyedArchiver archiveRootObject:transactions toFile:historyPath()];
    }
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	if(tableView.editing){
        [selectedCellsIndexPaths addObject:indexPath];
	}
	else{
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		int row = indexPath.row;
		Transaction* transaction = transactions[row];
		if(!transaction.voidReceipt && ![transaction.status isEqualToString:@"DECLINED"]){
			if([transaction.type isEqualToString:@"SALE"])
				[mainController.heftClient saleVoidWithAmount:transaction.amount currency:transaction.currency cardholder:YES transaction:transaction.transactionId];
			else if([transaction.type isEqualToString:@"REFUND"])
				[mainController.heftClient refundVoidWithAmount:transaction.amount currency:transaction.currency cardholder:YES transaction:transaction.transactionId];
			else
				return;
			[mainController showTransactionViewController:eTransactionVoid];
		}
	}
}


-(void) tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    [selectedCellsIndexPaths removeObject:indexPath];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    int row = indexPath.row;
	Transaction* transaction = transactions[row];
    
	if (transaction.voidReceipt){
		[mainController showHtmlViewControllerWithDetails:@{kTransactionCustomerReceiptKey:transaction.customerReceipt, kTransactionInfo:transaction.xmlInfo, kVoidReceipt:transaction.voidReceipt, kVoidTransactionInfo:transaction.voidXmlInfo, kTransactionIdKey:transaction.transactionId}];
	}
	else{
		[mainController showHtmlViewControllerWithDetails:@{kTransactionCustomerReceiptKey:transaction.customerReceipt, kTransactionInfo:transaction.xmlInfo, kTransactionIdKey:transaction.transactionId}];
	}
}

- (void)tableView:(UITableView*)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath{
	return;
}

#pragma mark -
#pragma mark IBAction

- (void)setEditing:(BOOL)editing animated:(BOOL)animated{
	if(editing){
		self.tableView.allowsMultipleSelectionDuringEditing = YES;
		[super setEditing:editing animated:animated];
		toolbar.items = toolBarItems;
		selectedCellsIndexPaths = [NSMutableArray array];
	}
	else{
		[selectedCellsIndexPaths sortUsingComparator: ^NSComparisonResult (NSIndexPath* obj1, NSIndexPath* obj2){
			if (obj1.row < obj2.row)
				return NSOrderedDescending;
			else if (obj1.row > obj2.row)
				return NSOrderedAscending;
			else
				return NSOrderedSame;
		}];
        for(NSIndexPath* index in selectedCellsIndexPaths){
			[self deleteSignWithTransactionId:[transactions[index.row] transactionId]];
            [transactions removeObjectAtIndex:index.row];
        }
        [self.tableView deleteRowsAtIndexPaths:selectedCellsIndexPaths withRowAnimation:UITableViewRowAnimationLeft];
        [NSKeyedArchiver archiveRootObject:transactions toFile:historyPath()];
		[self cancelEditing];
    }
}


- (void)cancelEditing{
	[super setEditing:NO animated:YES];
	self.tableView.allowsMultipleSelectionDuringEditing = NO;
	toolbar.items = noToolBarItems;
	selectedCellsIndexPaths = nil;
}

#pragma mark -

-(void) deleteSignWithTransactionId:(NSString*) transactionId{
	Verify([[NSFileManager defaultManager] removeItemAtPath:pathToTransactionSign(transactionId) error:nil]);
}

@end
