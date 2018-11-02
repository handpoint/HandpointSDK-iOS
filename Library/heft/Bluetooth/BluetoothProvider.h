//
// Created by Juan Nuñez on 2018-09-25.
// Copyright (c) 2018 Handpoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HeftClient;
@protocol BluetoothDevice;
@protocol HeftStatusReportDelegate;

typedef void (^VoidBlock) (void);
typedef void (^ConnectBlock) (id <HeftClient> *client);
typedef void (^ErrorBlock) (NSError *error);
typedef void (^DeviceDiscoveryFinished) (NSArray *devices);

@protocol BluetoothProvider <NSObject>

@property(nonatomic, readonly) NSArray* connectedCardReaders;

- (BOOL)disconnectWithErrorBlock:(ErrorBlock)errorBlock;

- (void)connectWithDevice:(id<BluetoothDevice>)device
             successBlock:(ConnectBlock)connectBlock
   disconnectedEventBlock:(VoidBlock)disconnectedEventBlock
               errorBlock:(ErrorBlock)errorBlock
                 delegate:(id <HeftStatusReportDelegate>)delegate;

//TODO should remove the success block as it is notified in the
// disconnect block from the connection
- (void)disconnectSuccessBlock:(ConnectBlock)connectBlock
                    errorBlock:(ErrorBlock)errorBlock;

/**
 Start search for all available BT devices.
 */
- (void)startDiscoveryWithSuccessBlock:(DeviceDiscoveryFinished)resultBlock
                            errorBlock:(ErrorBlock)errorBlock;

/*
 *
 - (NSArray *)search:(VoidBlock)completed;

- (void)connectToDevice:(HeftRemoteDevice *)device
       withSharedSecret:(NSString *)sharedSecret
               delegate:(id <HeftStatusReportDelegate>)delegate;
- (void)disconnect;
- (void)cleanup;
- (NSData *)read:(NSUInteger)dataLength;
- (void)write:(NSData *)data;
 * */

@end