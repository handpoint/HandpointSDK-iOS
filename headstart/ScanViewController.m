//
//  ScanViewController
//  headstart
//

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
	NSMutableArray* devices;
	__weak HeftTabBarViewController* mainController;
	UINib* pickerElement;
	NSString* currentDeviceName;
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
	[self executeConnect];
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

- (void)updateOnHeftClient:(BOOL)fOn{
	connectButton.enabled = YES;
	if (fOn){
		[[NSUserDefaults standardUserDefaults] setObject:currentDeviceName forKey:kCurrentDeviceName];
		[deviceList reloadAllComponents];
	}
	else
		currentDeviceName = nil;
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
		view.checkmarkPicture.hidden = ![[devices[row] name] isEqualToString:currentDeviceName];
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
	devices = [[HeftManager sharedManager].devices mutableCopy];
	BOOL enabled = [devices count] != 0;
	connectButton.enabled = enabled;
	resetButton.enabled = enabled;
	[deviceList reloadAllComponents];

	currentDeviceName = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentDeviceName];
	if(currentDeviceName){
		int index = [devices indexOfObjectPassingTest:^(HeftRemoteDevice* obj, NSUInteger idx, BOOL *stop){
			if([obj.name isEqualToString:currentDeviceName])
				*stop = YES;
			return *stop;
		}];

		if(index == NSNotFound)
			currentDeviceName = nil;
		else{
			[deviceList selectRow:index inComponent:0 animated:NO];
			[self executeConnect];
		}
	}
}

- (void)noSources{
	discoveryButton.enabled = NO;
	[spinner stopAnimating];
	connectButton.enabled = NO;
	resetButton.enabled = NO;
	mainController.heftClient = nil;
	[mainController hideNumPadViewBarButtonAnimated:YES];
	for(id vc in mainController.viewControllers)
		[vc updateOnHeftClient:NO];
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

#pragma mark -

- (void)executeConnect{
    NSUInteger index = [devices indexOfObjectPassingTest:^(HeftRemoteDevice* obj, NSUInteger idx, BOOL *stop){
		if([obj.name isEqualToString:currentDeviceName])
			*stop = YES;
		return *stop;
	}];
    ((PickerElementView*)[deviceList viewForRow:index forComponent:0]).checkmarkPicture.hidden = YES;
    
	mainController.heftClient = nil;
	for(id vc in mainController.viewControllers)
		[vc updateOnHeftClient:NO];
	connectButton.enabled = NO;
	[mainController hideNumPadViewBarButtonAnimated:YES];
	currentDeviceName = [devices[[deviceList selectedRowInComponent:0]] name];
	[[HeftManager sharedManager] clientForDevice:devices[[deviceList selectedRowInComponent:0]] sharedSecret:[[NSData alloc] initWithBytes:ss length:sizeof(ss)] delegate:mainController];
}
@end
