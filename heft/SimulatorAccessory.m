//
// Created by Juan Nuñez on 15/12/2017.
// Copyright (c) 2017 zdv. All rights reserved.
//

#import "SimulatorAccessory.h"

@interface SimulatorAccessory ()

@property(nonatomic, getter=isConnected) BOOL connected;
@property(nonatomic) NSUInteger connectionID;
@property(nonatomic) NSString *manufacturer;
@property(nonatomic) NSString *name;
@property(nonatomic) NSString *modelNumber;
@property(nonatomic) NSString *serialNumber;
@property(nonatomic) NSString *firmwareRevision;
@property(nonatomic) NSString *hardwareRevision;
@property(nonatomic) NSArray *protocolStrings;

@end

@implementation SimulatorAccessory

@synthesize connectionID, manufacturer, name, modelNumber, serialNumber, firmwareRevision, hardwareRevision, protocolStrings;

- (id)initWithConnectionID:(NSUInteger)newConnectionID
              manufacturer:(NSString *)newManufacturer
                      name:(NSString *)newName
               modelNumber:(NSString *)newModelNumber
              serialNumber:(NSString *)newSerialNumber
          firmwareRevision:(NSString *)newFirmwareRevision
          hardwareRevision:(NSString *)newHardwareRevision
           protocolStrings:(NSArray *)newProtocolStrings;
{
    self = [super init];

    if(self)
    {
        self.connectionID = newConnectionID;
        self.manufacturer = newManufacturer;
        self.name = newName;
        self.modelNumber = newModelNumber;
        self.serialNumber = newSerialNumber;
        self.firmwareRevision = newFirmwareRevision;
        self.hardwareRevision = newHardwareRevision;
        self.protocolStrings = newProtocolStrings;
    }

    return self;
}

- (BOOL)isConnected
{
    return YES;
}

@end
