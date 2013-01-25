//
//  HistoryViewController.h
//  headstart
//

@class FinanceResponseInfo;

@interface HistoryViewController : UITableViewController

- (void)addNewTransaction:(FinanceResponseInfo*)info;

@end
