//
//  ScanViewController
//  headstart
//

#import <ExternalAccessory/ExternalAccessory.h>

#import "ScanViewController.h"
#import "HeftTabBarViewController.h"
#import "PickerElementView.h"
#import "HeftRemoteDevice.h"

#import "../heft/HeftClient.h"

//#pragma comment(lib, "libc++")

NSString*  const kCurrentDeviceName = @"currentDeviceName";

@implementation ScanViewController{
	__weak IBOutlet UIButton* discoveryButton;
	__weak IBOutlet UIActivityIndicatorView* spinner;
	__weak IBOutlet UIButton* connectButton;
	__weak IBOutlet UIButton* resetButton;
	__weak IBOutlet UIPickerView* deviceList;
	__weak IBOutlet UILabel *versionNumber;
	__weak IBOutlet UILabel *buildNumber;
	NSMutableArray* devices;
	__weak HeftTabBarViewController* mainController;
	UINib* pickerElement;
	HeftRemoteDevice* currentDevice;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
	if(self = [super initWithCoder:aDecoder]){
		mainController = (HeftTabBarViewController*)self.parentViewController;
		pickerElement = [UINib nibWithNibName:@"PickerElementView" bundle:nil];
	}
	return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];

	HeftManager* manager = [HeftManager sharedManager];
	manager.delegate = self;

	devices = manager.devicesCopy;
	BOOL enabled = [devices count] != 0;
	connectButton.enabled = enabled;
	versionNumber.text = [manager getSDKVersion];
	buildNumber.text = [manager getSDKBuildNumber];
    
	
//	if(!manager.hasSources){
//		discoveryButton.enabled = NO;
//		resetButton.enabled = NO;
//	}
//	else{
//		resetButton.enabled = enabled;
//	}
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

- (void)updateDevices{
	HeftManager* manager = [HeftManager sharedManager];
	devices = manager.devicesCopy;
	BOOL enabled = [devices count] != 0;
	connectButton.enabled = enabled;
	resetButton.enabled = enabled && manager.hasSources;
	[deviceList reloadAllComponents];
}

#pragma mark IBAction

- (IBAction)startDiscovery{
	discoveryButton.enabled = NO;
	if(currentDevice && !currentDevice.accessory)
		[self disconnect];
	connectButton.enabled = NO;
	[spinner startAnimating];
	[[HeftManager sharedManager] startDiscovery:NO];
}

uint8_t ss[32] = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16
				, 0x17, 0x18, 0x19, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x30, 0x31, 0x32};

- (IBAction)connect{
	[self executeConnect];
}

- (IBAction)resetDevices{
	[[HeftManager sharedManager] resetDevices];
	[self updateDevices];
}

#pragma mark TabBarItemProtocol

- (void)updateOnHeftClient:(BOOL)fOn{
	connectButton.enabled = YES;
	if (fOn){
		[[NSUserDefaults standardUserDefaults] setObject:currentDevice.name forKey:kCurrentDeviceName];
		[deviceList reloadAllComponents];
	}
	else
		currentDevice = nil;
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

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(PickerElementView*)view{

	if(!view)
		view = [pickerElement instantiateWithOwner:self options:nil][0];
	
	if (row < [devices count]){
		view.viewText.text = [devices[row] name];
		view.checkmarkPicture.hidden = !mainController.heftClient || devices[row] != currentDevice;
	}
	else{
		view.viewText.text = @"";
		view.checkmarkPicture.hidden = YES;
	}
	return view;
}

#pragma mark HeftDiscoveryDelegate

- (void)hasSources{
	discoveryButton.enabled = YES;

	[self updateDevices];

	Assert(!currentDevice);
	NSString* currentDeviceName = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentDeviceName];
	if(currentDeviceName){
		int index = [devices indexOfObjectPassingTest:^(HeftRemoteDevice* obj, NSUInteger idx, BOOL *stop){
			if([obj.name isEqualToString:currentDeviceName])
				*stop = YES;
			return *stop;
		}];

		if(index != NSNotFound){
			[deviceList selectRow:index inComponent:0 animated:NO];
			[self executeConnect];
		}
	}
}

- (void)noSources{
	discoveryButton.enabled = NO;
	[spinner stopAnimating];

	[self updateDevices];

	if(currentDevice && !currentDevice.accessory){
		mainController.heftClient = nil;
		[mainController hideNumPadViewBarButtonAnimated:YES];
		for(id vc in mainController.viewControllers)
			[vc updateOnHeftClient:NO];
	}
}

- (void)didDiscoverDevice:(HeftRemoteDevice*)newDevice{
	[devices addObject:newDevice];
	resetButton.enabled = YES;
	[deviceList reloadAllComponents];
}

- (void)didDiscoverFinished{
	discoveryButton.enabled = YES;
	connectButton.enabled = YES;
	[spinner stopAnimating];
}

- (void)didFindAccessoryDevice:(HeftRemoteDevice*)newDevice{
	connectButton.enabled = ![devices count] || connectButton.enabled;
	resetButton.enabled = [HeftManager sharedManager].hasSources;
	[devices addObject:newDevice];
	[deviceList reloadAllComponents];
}

- (void)didLostAccessoryDevice:(HeftRemoteDevice*)oldDevice{
	if(currentDevice && currentDevice.accessory){
		mainController.heftClient = nil;
		[mainController hideNumPadViewBarButtonAnimated:YES];
		for(id vc in mainController.viewControllers)
			[vc updateOnHeftClient:NO];
	}

	[devices removeObject:oldDevice];
	BOOL enabled = [devices count] != 0;
	connectButton.enabled = enabled && connectButton.enabled;
	resetButton.enabled = enabled && [HeftManager sharedManager].hasSources;
	[deviceList reloadAllComponents];
}

#pragma mark -

- (void)disconnect{
	if(currentDevice && mainController.heftClient){
		NSUInteger index = [devices indexOfObjectIdenticalTo:currentDevice];
		((PickerElementView*)[deviceList viewForRow:index forComponent:0]).checkmarkPicture.hidden = YES;

		currentDevice = nil;
		mainController.heftClient = nil;
		for(id vc in mainController.viewControllers)
			[vc updateOnHeftClient:NO];
		[mainController hideNumPadViewBarButtonAnimated:YES];
	}
}

- (void)executeConnect{
	[self disconnect];
	connectButton.enabled = NO;
	currentDevice = devices[[deviceList selectedRowInComponent:0]];
    NSString* uxiSSStr = @"07110E8D964A4A2E66202EA6AD746F14536FBA0566E2E047B6A85E5B01349274";
    NSData* uxiSS;
    NSMutableData* ssTmp = [NSMutableData data];
    
    for (int i = 0 ; i < 32; i++)
    {
        NSRange range = NSMakeRange (i*2, 2);
        NSString *bytes = [uxiSSStr substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:bytes];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [ssTmp appendBytes:&intValue length:1];
    }
    uxiSS = ssTmp;
    
	[[HeftManager sharedManager] clientForDevice:currentDevice sharedSecret:[[NSData alloc] initWithBytes:ss length:sizeof(ss)] delegate:mainController];
    //[[HeftManager sharedManager] clientForDevice:currentDevice sharedSecret:uxiSS delegate:mainController];
}

@end
