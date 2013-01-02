//
//  ScanViewController
//  headstart
//

#import "../heft/HeftManager.h"

@interface ScanViewController : UIViewController<HeftDiscoveryDelegate>{
	IBOutlet __weak UIButton* discoveryButton;
	IBOutlet __weak UIButton* connectButton;
	IBOutlet __weak UIPickerView* deviceList;
	NSMutableArray* devices;
}

- (IBAction)startDiscovery;
- (IBAction)connect;

@end
