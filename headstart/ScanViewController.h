//
//  ScanViewController
//  headstart
//

#import "../heft/HeftManager.h"

@interface ScanViewController : UIViewController<HeftDiscoveryDelegate>

- (IBAction)startDiscovery;
- (IBAction)connect;
- (IBAction)resetDevices;

- (void)updateOnHeftClient:(BOOL)fOn;

@end
