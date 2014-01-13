//
//  PhoneViewController
//  headstart
//

#import "TabBarItemProtocol.h"

@interface NumPadViewController : UIViewController<TabBarItemProtocol, UITextFieldDelegate, UIActionSheetDelegate, UIPickerViewDelegate, UIPickerViewDataSource>{
    IBOutlet UISwitch *multiScan;
    IBOutlet UISwitch *buttonMode;
}
@end
