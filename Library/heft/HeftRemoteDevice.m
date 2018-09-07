//
//  HeftRemoteDevice.m
//  headstart
//

#import "HeftRemoteDevice.h"
#import "SimulatorAccessory.h"

@interface HeftRemoteDevice ()

@property (nonatomic) NSString *internalName;
@property (nonatomic) NSString *internalAddress;
@property (nonatomic) EAAccessory *internalAccessory;

- (instancetype)initWithSimulator:(SimulatorAccessory *)simulator;

@end

@implementation HeftRemoteDevice

- (instancetype)initWithAccessory:(EAAccessory *)accessory
{
    self = [super init];

    if (self)
    {
        self.internalName = accessory.name;
        self.internalAddress = [NSString stringWithFormat:@"68:AA:%@", @([accessory connectionID])];
        self.internalAccessory = accessory;
    }

    return self;
}

- (instancetype)initWithSimulator:(SimulatorAccessory *)simulator
{
    self = [super init];

    if (self)
    {
        self.internalName = simulator.name;
        self.internalAddress = [NSString stringWithFormat:@"68:AA:%@", @([simulator connectionID])];
        self.internalAccessory = nil;
    }

    return self;
}


#pragma mark property

- (NSString *)name
{
    return self.internalName;
}

- (NSString *)address
{
    return self.internalAddress;
}

- (EAAccessory *)accessory
{
    return self.internalAccessory;
}

+ (instancetype)Simulator
{
    SimulatorAccessory *simulator = [[SimulatorAccessory alloc] initWithConnectionID:24373085
                                                                        manufacturer:@"Handpoint"
                                                                                name:@"Simulator"
                                                                         modelNumber:@""
                                                                        serialNumber:@"123400123"
                                                                    firmwareRevision:@"2.2.7"
                                                                    hardwareRevision:@"1.0.0"
                                                                     protocolStrings:@[@"com.datecs.pinpad"]];

    return [[HeftRemoteDevice alloc] initWithSimulator:simulator];
}

@end
