//
//  HistoryViewController.h
//  headstart
//

@class FinanceResponseInfo;

@interface HistoryViewController : UITableViewController

- (void)updateOnHeftClient:(BOOL)fOn;
- (void)addNewTransaction:(FinanceResponseInfo*)info;

@end
