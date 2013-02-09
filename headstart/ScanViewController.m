//
//  ScanViewController
//  headstart
//

#import "ScanViewController.h"
#import "HeftTabBarViewController.h"

//#pragma comment(lib, "libc++")

@implementation ScanViewController{
	__weak IBOutlet UIButton* discoveryButton;
	__weak IBOutlet UIActivityIndicatorView* spinner;
	__weak IBOutlet UIButton* connectButton;
	__weak IBOutlet UIButton* resetButton;
	__weak IBOutlet UIPickerView* deviceList;
	NSMutableArray* devices;
	HeftTabBarViewController* __weak mainController;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
	if(self = [super initWithCoder:aDecoder]){
		mainController = (HeftTabBarViewController*)self.parentViewController;
	}
	return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];

	HeftManager* manager = [HeftManager sharedManager];
	manager.delegate = self;
	if(!manager.hasSources){
		discoveryButton.enabled = NO;
		connectButton.enabled = NO;
		resetButton.enabled = NO;
	}
	else{
		devices = [manager.devices mutableCopy];

		BOOL enabled = [devices count] != 0;
		connectButton.enabled = enabled;
		resetButton.enabled = enabled;
	}
}

/*- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
	return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (NSUInteger)supportedInterfaceOrientations{
	return UIInterfaceOrientationMaskPortrait;
}

#pragma mark IBAction

- (IBAction)startDiscovery{
	discoveryButton.enabled = NO;
	[spinner startAnimating];
	[[HeftManager sharedManager] startDiscovery:NO];
}

uint8_t ss[32] = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16
				, 0x17, 0x18, 0x19, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x30, 0x31, 0x32};

- (IBAction)connect{
	mainController.heftClient = nil;
	mainController.heftClient = [[HeftManager sharedManager] clientForDevice:[devices objectAtIndex:[deviceList selectedRowInComponent:0]] sharedSecret:[[NSData alloc] initWithBytes:ss length:sizeof(ss)] delegate:mainController];
}

- (IBAction)resetDevices{
	HeftManager* manager = [HeftManager sharedManager];
	[manager resetDevices];
	devices = [manager.devices mutableCopy];
	BOOL enabled = [devices count] != 0;
	connectButton.enabled = enabled;
	resetButton.enabled = enabled;
	[deviceList reloadAllComponents];
}

#pragma mark UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
	int count = [devices count];
	return count ? count : 1;
}

#pragma mark UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
	return row < [devices count] ? [[devices objectAtIndex:row] name] : @"";
}

#pragma mark HeftDiscoveryDelegate

- (void)hasSources{
	discoveryButton.enabled = YES;
	devices = [[HeftManager sharedManager].devices mutableCopy];
	BOOL enabled = [devices count] != 0;
	connectButton.enabled = enabled;
	resetButton.enabled = enabled;
	[deviceList reloadAllComponents];
}

- (void)noSources{
	discoveryButton.enabled = NO;
	[spinner stopAnimating];
	connectButton.enabled = NO;
	resetButton.enabled = NO;
	mainController.heftClient = nil;
	[devices removeAllObjects];
	[deviceList reloadAllComponents];
}

- (void)didDiscoverDevice:(HeftRemoteDevice*)newDevice{
	[devices addObject:newDevice];
	connectButton.enabled = YES;
	resetButton.enabled = YES;
	[deviceList reloadAllComponents];
}

- (void)didDiscoverFinished{
	discoveryButton.enabled = YES;
	[spinner stopAnimating];
}

@end
