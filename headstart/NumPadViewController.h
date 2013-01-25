//
//  PhoneViewController
//  headstart
//

@protocol HeftClient;

@interface NumPadViewController : UIViewController

- (void)updateOnHeftClient:(BOOL)fOn;

- (IBAction)sale;
- (IBAction)refund;
- (IBAction)digit:(UIButton*)sender;
- (IBAction)zeros;
- (IBAction)clearDigit;

@end
