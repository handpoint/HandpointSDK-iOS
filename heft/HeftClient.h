//
//  HeftClient.h
//  headstart
//

typedef enum{
	eLogNone
	, eLogInfo
	, eLogFull
	, eLogDebug
} eLogLevel;

@protocol HeftClient <NSObject>

//- (void)setDelegate:(NSObject<HeftClientDelegate>*)aDelegate;

- (void)cancel;
- (BOOL)saleWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present;
- (BOOL)refundWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present;
- (BOOL)saleVoidWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present transaction:(NSString*)transaction;
- (BOOL)refundVoidWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present transaction:(NSString*)transaction;
- (BOOL)financeStartOfDay;
- (BOOL)financeEndOfDay;
- (BOOL)financeInit;
- (BOOL)logSetLevel:(eLogLevel)level;
- (BOOL)logReset;
- (BOOL)logGetInfo;
- (void)acceptSignature:(BOOL)flag;

@property(nonatomic, readonly) NSDictionary* mpedInfo;

@end

extern const NSString* kSerialNumberInfoKey;
extern const NSString* kPublicKeyVersionInfoKey;
extern const NSString* kEMVParamVersionInfoKey;
extern const NSString* kGeneralParamInfoKey;
extern const NSString* kManufacturerCodeInfoKey;
extern const NSString* kModelCodeInfoKey;
extern const NSString* kAppNameInfoKey;
extern const NSString* kAppVersionInfoKey;
extern const NSString* kXMLDetailsInfoKey;
