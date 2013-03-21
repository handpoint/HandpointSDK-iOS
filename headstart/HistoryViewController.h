//
//  HistoryViewController.h
//  headstart
//

@protocol FinanceResponseInfo;

@interface HistoryViewController : UITableViewController

- (void)updateOnHeftClient:(BOOL)fOn;
- (void)addNewTransaction:(id<FinanceResponseInfo>)info sign:(UIImage*)sign;

@end
