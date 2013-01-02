//
//  PhoneViewController
//  headstart
//

@protocol HeftClient;

@interface PhoneViewController : UIViewController{
	IBOutlet __weak UIButton* saleButton;
	IBOutlet __weak UITextField* amount;
}

@property(nonatomic, weak) id<HeftClient> heftClient;

- (IBAction)sale;

@end
