//
//  SettingsViewController.h
//  headstart
//

@interface SettingsViewController : UIViewController<UITableViewDelegate, UITableViewDelegate>{
	__weak IBOutlet UISwitch* refundSwitch;
	__weak IBOutlet UIButton* finInitButton;
	__weak IBOutlet UIButton* getLogsButton;
	int currentCurrency;
}

- (void)updateOnHeftClient:(BOOL)fOn;

- (IBAction)refundChanged:(UISwitch*)sender;
- (IBAction)financeInit:(UIButton*)sender;
- (IBAction)getLogs:(UIButton*)sender;

@end
