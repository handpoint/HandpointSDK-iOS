//
//  HeftStatusReportPublic.h
//  headstart
//

/**
 *  @file   HeftStatusReportPublic.h
 *
 *  @brief  ResponseInfo, FinanceResponseInfo, LogInfo and HeftStatusReportDelegate protocol
 *
 *
 **/

/**
 @brief Base information for any feedback. Includes status code, status text and detailed xml.
 */
@protocol ResponseInfo
/** 
 @defgroup RI_PROTOCOL ResponseInfo Protocol
 Base information for any feedback. Includes status code, status text and detailed xml.
 @{
 */

/** 
 Code of the MPED status message.
 */
@property(nonatomic) int statusCode;
/** 
 Financial transaction status message.
 */
@property(nonatomic,strong) NSString* status;
/**
 Feedback with xml details about transaction from MPED inside.
 */
@property(nonatomic,strong) NSDictionary* xml;

/**@}*/

@end

/**
 @brief Feedback for any financial requests.
 */
@protocol FinanceResponseInfo<ResponseInfo>
/** 
 @defgroup FRI_PROTOCOL FinanceResponseInfo Protocol
 Feedback for any financial requests.
 @{
 */

/**
 @brief	The authorisedAmount - in the smallest unit for the given
 CurrencyCode - for the transaction. ISO 4217 defines number of digits in
 fractional part of currency for every currency code. Example
 1000 in the case where CurrencyCode is "0826" (GBP) the amount
 would be 10.00 pounds or 1000 pense.
 */
@property(nonatomic) NSInteger authorisedAmount;

/**
 @brief	The id of current transaction.
 */
@property(nonatomic,strong) NSString* transactionId;

/**
 @brief	Customer receipt of transaction from MPED in html format.
 */
@property(nonatomic,strong) NSString* customerReceipt;

/**
 @brief	Merchant receipt of transaction from MPED in html format.
 */
@property(nonatomic,strong) NSString* merchantReceipt;

/**@}*/

@end

/**
 @brief Feedback for log request.
 */
@protocol LogInfo<ResponseInfo>
/**
 @defgroup LI_PROTOCOL LogInfo Protocol
 Feedback for log request.
 @{
 */

/**
 @brief The history of actions and transactions from MPED that were logged.
 */
@property(nonatomic,strong) NSString* log;

/**@}*/

@end

@protocol HeftClient;

/**
 @brief HeftStatusReportDelegate protocol methods
 */
@protocol HeftStatusReportDelegate
/** @defgroup HSRD_PROTOCOL HeftStatusReportDelegate Notifications
 Notifications sent by the SDK on various events - connected to device, request signature, response on error  etc.
 @{
 */

/**
 Notifies that connection to specified device was created.
 @param client	Contains information about current connection or equals to nil, if connection wasn't created.
 */
- (void)didConnect:(id<HeftClient>)client;

/**
 Notifies about transaction current state.
 @param info	Includes status code, status text and detailed xml.
 */
- (void)responseStatus:(id<ResponseInfo>)info;

/**
 Notifies about error during transaction.
 @param info	Information about current transaction status.
 */
- (void)responseError:(id<ResponseInfo>)info;

/**
 Notifies that transaction has completed.
 @param info				Complete information about transaction.
 */
- (void)responseFinanceStatus:(id<FinanceResponseInfo>)info;

/**
 Notifies result of getting log information request.
 @param info				Contains history of actions and transactions from MPED since last responseLogInfo.
 */
- (void)responseLogInfo:(id<LogInfo>)info;

/**
 Notifies when cardholder's signature verification is needed.<br/> 
	It should be typically used to print receipt and accept customer sign. Handler has to call acceptSignature:(BOOL)flag with YES if sign is valid and NO otherwise. If handler doesn't process message for 45s transaction will be declined and cancelSignature called.
 @param receipt				The receipt of transaction in html format.
 */
- (void)requestSignature:(NSString*)receipt;

/**
 Notifies when signature validation is timed out for 45s.
 */
- (void)cancelSignature;

/**@}*/

@end
