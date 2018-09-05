//
// Created by Juan Nuñez on 15/12/2017.
// Copyright (c) 2017 zdv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>


@interface SimulatorAccessory: NSObject

@property(nonatomic, readonly, getter=isConnected) BOOL connected;
@property(nonatomic, readonly) NSUInteger connectionID;
@property(nonatomic, readonly) NSString *manufacturer;
@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) NSString *modelNumber;
@property(nonatomic, readonly) NSString *serialNumber;
@property(nonatomic, readonly) NSString *firmwareRevision;
@property(nonatomic, readonly) NSString *hardwareRevision;
@property(nonatomic, readonly) NSArray *protocolStrings;

- (id)initWithConnectionID:(NSUInteger)newConnectionID
              manufacturer:(NSString *)newManufacturer
                      name:(NSString *)newName
               modelNumber:(NSString *)newModelNumber
              serialNumber:(NSString *)newSerialNumber
          firmwareRevision:(NSString *)newFirmwareRevision
          hardwareRevision:(NSString *)newHardwareRevision
           protocolStrings:(NSArray *)newProtocolStrings;

@end
