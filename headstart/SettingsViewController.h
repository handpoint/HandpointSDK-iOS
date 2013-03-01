//
//  SettingsViewController.h
//  headstart
//

@interface SettingsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>{
	__weak IBOutlet UISwitch* refundSwitch;
	__weak IBOutlet UIButton* finInitButton;
	__weak IBOutlet UIButton* getLogsButton;
	__weak IBOutlet UISegmentedControl *logLevelControl;
	int currentCurrency;
}

- (void)updateOnHeftClient:(BOOL)fOn;

- (IBAction)refundChanged:(UISwitch*)sender;
- (IBAction)financeInit:(UIButton*)sender;
- (IBAction)getLogs:(UIButton*)sender;

@end
