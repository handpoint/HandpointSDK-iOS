//
//  HeftTabBarViewController.h
//  headstart
//

#import "../heft/HeftStatusReport.h"

@protocol HeftClient;

@interface HeftTabBarViewController : UITabBarController<HeftStatusReportDelegate>

@property(nonatomic, strong) id<HeftClient> heftClient;

@end
