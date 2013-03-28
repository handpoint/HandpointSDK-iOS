//
//  HistoryViewController.h
//  headstart
//

#import "TabBarItemProtocol.h"

@protocol FinanceResponseInfo;

@interface HistoryViewController : UITableViewController<TabBarItemProtocol>

- (void)addNewTransaction:(id<FinanceResponseInfo>)info sign:(UIImage*)sign;

@end
