//
//  HeftManager.h
//  headstart
//

/**
 *  @file   HeftManager.h
 *
 *  @brief  HeftManager interface
 *
 *
 **/

#import <Foundation/Foundation.h>
#import "HeftDiscovery.h"


@protocol HeftClient;
@protocol HeftStatusReportDelegate;
@class HeftRemoteDevice;

@interface HeftManager : NSObject <HeftDiscovery>

+ (HeftManager *)sharedManager;
@property (nonatomic, readonly) NSString *version;

/**
 Starts creation of a connection to the specified device.
 @param device					Device to be connected.
 @param sharedSecretString		Shared Secret information in string format
 @param aDelegate				Delegate which will be perform HeftStatusReportDelegate notifications.
 */
- (void)clientForDevice:(HeftRemoteDevice *)device
           sharedSecret:(NSString *)sharedSecret
               delegate:(NSObject <HeftStatusReportDelegate> *)delegate;

- (void)cleanup;

@end

/*
@interface SimpleHeftManager
- (NSArray*) connectedCardReaders;

@property(nonatomic,readonly) HeftClient* cardReader;

@end
*/
