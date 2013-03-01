//
//  HeftTabBarViewController.h
//  headstart
//

#import "../heft/HeftStatusReportPublic.h"

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
- (void)setTransactionStatus:(NSString*)status;
- (void)dismissHtmlViewController;
- (void)dismissTextViewController;
- (void)acceptSign:(BOOL)accepted;
- (void)showHtmlViewControllerWithDetails:(NSArray*)details;

@end
