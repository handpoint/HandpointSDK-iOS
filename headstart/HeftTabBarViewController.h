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
- (void)showTextViewControllerWithString:(NSString*)text;
- (void)dismissTextViewController;
- (void)acceptSign:(UIImage*)accepted;
- (void)showHtmlViewControllerWithDetails:(NSDictionary*)details;
- (void)showNumPadViewBarButtonAnimated:(BOOL)animated;
- (void)hideNumPadViewBarButtonAnimated:(BOOL)animated;
@end
