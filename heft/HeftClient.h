//
//  HeftClient.h
//  headstart
//

/**
 *  @file   HeftClient.h
 *
 *  @brief  Heft protocol
 *
 *
 */

/**
 @brief param values for HeftClient -(BOOL)logSetLevel:(eLogLevel)level.
 */
typedef enum{
	eLogNone
	, eLogInfo
	, eLogFull
	, eLogDebug
} eLogLevel;

/** 
@brief HeftClient protocol methods.
 */
@protocol HeftClient<NSObject>
/** @defgroup HC_DELEGATE HeftClient Methods
 High level interface for Headstart API.
 @{
 */

//- (void)setDelegate:(NSObject<HeftClientDelegate>*)aDelegate;

/**
 Cancels current finance transaction if it's possible.
 */
- (void)cancel;

/** 
 Performs SALE transaction.
 @param amount - The amount - in the smallest unit for the given CurrencyCode -
 for the transaction. ISO 4217 defines number of digits in
 fractional part of currency for every currency code. Example
 1000 in the case where CurrencyCode is "0826" (GBP) the amount
 would be 10.00 pounds or 1000 pense.
 @param currency - The currency to use for the transaction. Code is four
 characters string containing ISO 4217 numeric value with
 leading zero(s). Examples: GPB = "0826", USD = "0840", EUR = "0978".
 There are three special cases for "USD", "EUR" and "GBP"
 which can be set instead of numeric values.
 @param present	Indicates whether the cardholder is present or not during the transaction.
 @param reference An optional reference id (max 25 characters) that can be associated with the authorization. Example value: 45678135.
 @return YES if request is sent and NO if there is active transaction already.
 */
- (BOOL)saleWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present;
- (BOOL)saleWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present reference:(NSString*)reference;

/** 
 Performs REFUND transaction.
 @param amount - The amount - in the smallest unit for the given CurrencyCode -
 for the transaction. ISO 4217 defines number of digits in
 fractional part of currency for every currency code. Example
 1000 in the case where CurrencyCode is "0826" (GBP) the amount
 would be 10.00 pounds or 1000 pense.
 @param currency - The currency to use for the transaction. Code is four
 characters string containing ISO 4217 numeric value with
 leading zero(s). Examples: GPB = "0826", USD = "0840", EUR = "0978".
 There are three special cases for "USD", "EUR" and "GBP"
 which can be set instead of numeric values.
 @param present - Indicates whether the cardholder is present or not during the transaction.
 @param reference An optional reference id (max 25 characters) that can be associated with the authorization. Example value: 45678135.
 @return YES if request is sent and NO if there is active transaction already.
 */
- (BOOL)refundWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present;
- (BOOL)refundWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present reference:(NSString*)reference;

/**
 Voids SALE transaction.
 @param amount - The amount - in the smallest unit for the given CurrencyCode -
 for the transaction. ISO 4217 defines number of digits in
 fractional part of currency for every currency code. Example
 1000 in the case where CurrencyCode is "0826" (GBP) the amount
 would be 10.00 pounds or 1000 pense.
 @param currency - The currency to use for the transaction. Code is four
 characters string containing ISO 4217 numeric value with
 leading zero(s). Examples: GPB = "0826", USD = "0840", EUR = "0978".
 There are three special cases for "USD", "EUR" and "GBP"
 which can be set instead of numeric values.
 @param present - Indicates whether the cardholder is present or not during the transaction.
 @param transaction - The id of transaction to void.
 @return YES if request is sent and NO if there is active transaction already.
 */
- (BOOL)saleVoidWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present transaction:(NSString*)transaction;

/**
 Voids REFUND transaction.
 @param amount - The amount - in the smallest unit for the given CurrencyCode -
 for the transaction. ISO 4217 defines number of digits in
 fractional part of currency for every currency code. Example
 1000 in the case where CurrencyCode is "0826" (GBP) the amount
 would be 10.00 pounds or 1000 pense.
 @param currency - The currency to use for the transaction. Code is four
 characters string containing ISO 4217 numeric value with
 leading zero(s). Examples: GPB = "0826", USD = "0840", EUR = "0978".
 There are three special cases for "USD", "EUR" and "GBP"
 which can be set instead of numeric values.
 @param present - Indicates whether the cardholder is present or not during the transaction.
 @param transaction - The id of transaction to void.
 @return YES if request is sent and NO if there is active transaction already.
 */
- (BOOL)refundVoidWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present transaction:(NSString*)transaction;

/**
 Performs start of the day request.
 @return YES if request is sent and NO if there is active transaction already.
 */
- (BOOL)financeStartOfDay;

/**
 Performs end of the day request.
 @return YES if request is sent and NO if there is active transaction already.
 */
- (BOOL)financeEndOfDay;

/**
 Performs financial initialization request.
 @return YES if request is sent and NO if there is active transaction already.
 */

- (BOOL)financeInit;

/**
 Set log level for device.
 @return YES if request is sent and NO if there is active transaction already.
 */
- (BOOL)logSetLevel:(eLogLevel)level;

/**
 Reset logging on device.
 @return YES if request is sent and NO if there is active transaction already.
 */
- (BOOL)logReset;

/**
 Performs get log info request.
 @return YES if request is sent and NO if there is active transaction already.
 */
- (BOOL)logGetInfo;

/**
 Indicates information about signature.
 @param flag - Shows signature  was accepted or not.
 */
- (void)acceptSignature:(BOOL)flag;

/**
 Dictionary with MPED info details, obtained by querying it from device on interface creation.
 */
@property(nonatomic, readonly) NSDictionary* mpedInfo;

/**@}*/

@end

/** @defgroup CD_MODULE Characteristics of the Device
 Characteristics of the device from mpedInfo dictionary like serial number, manufacturer code, etc.
 @{
 */
/**
 Serial Number.
 */
extern const NSString* kSerialNumberInfoKey;
/** 
 Public Key Version.
 */
extern const NSString* kPublicKeyVersionInfoKey;
/** 
 EMV Parameter Version.
 */
extern const NSString* kEMVParamVersionInfoKey;
/** 
 General Parameter.
 */
extern const NSString* kGeneralParamInfoKey;
/** 
 Manufacturer Code.
 */
extern const NSString* kManufacturerCodeInfoKey;
/** 
 Model Code.*/
extern const NSString* kModelCodeInfoKey;
/** 
 Application Name.
 */
extern const NSString* kAppNameInfoKey;
/** 
 Application Version.
 */
extern const NSString* kAppVersionInfoKey;
/** 
 XML Details.
 */
extern const NSString* kXMLDetailsInfoKey;

/**@}*/