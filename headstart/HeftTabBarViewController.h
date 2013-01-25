//
//  HeftTabBarViewController.h
//  headstart
//

#import "../heft/HeftStatusReport.h"

@protocol HeftClient;

typedef enum{
	eTransactionDiscovery
	, eTransactionSale
	, eTransactionRefund
	, eTransactionVoid
	, eTransactionFinInit
	, eTransactionGetLog
	, eTransactionNum
} eTransactionType;

@interface HeftTabBarViewController : UITabBarController<HeftStatusReportDelegate>

@property(nonatomic, strong) id<HeftClient> heftClient;

- (void)showTransactionViewController:(eTransactionType)type;
- (void)dismissTransactionViewController;
- (void)setTransactionStatus:(NSString*)status;

@end
