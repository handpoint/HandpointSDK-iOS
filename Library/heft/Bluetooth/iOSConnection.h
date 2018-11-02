//
//  iOSConnection.h
//  headstart
//

#import "Connection.h"
@protocol Connection;

@interface iOSConnection : NSObject<Connection>

@property(nonatomic) int maxFrameSize;
@property(nonatomic) int ourBufferSize;

@end

extern const int64_t ciTimeout[];
