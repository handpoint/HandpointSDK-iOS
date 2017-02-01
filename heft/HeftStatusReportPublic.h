//
//  HeftStatusReportPublic.h
//  headstart
//

#import <Foundation/Foundation.h>


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
 @brief The result of the financial transaction as one of:
   EFT_FINANC_STATUS_UNDEFINED                0x00
   EFT_FINANC_STATUS_TRANS_APPROVED           0x01
   EFT_FINANC_STATUS_TRANS_DECLINED           0x02
   EFT_FINANC_STATUS_TRANS_PROCESSED          0x03
   EFT_FINANC_STATUS_TRANS_NOT_PROCESSED      0x04
   EFT_FINANC_STATUS_TRANS_CANCELLED          0x05
 */
@property(nonatomic) NSInteger financialResult;

/**
 @brief indicates whether the card reader is about to restart or not (usually indicated after an update).
 If a restart is indicated then you have 2 seconds to start fetching the logs (before the card reader restarts).
 */
@property(nonatomic) BOOL isRestarting;

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
 @brief Feedback for scanner event.
 */
@protocol ScannerEventResponseInfo<ResponseInfo>
/**
 @defgroup SEI_PROTOCOL ScannerventInfo Protocol
 Feedback for any scanner events.
 @{
 */

/**
 @brief	The code that was scanned.
 */
@property(nonatomic,strong) NSString* scanCode;
/**@}*/
@end

/**
 @brief Deprecated: Feedback for enable scanner response.
 */
DEPRECATED_ATTRIBUTE
@protocol EnableScannerResponseInfo<ResponseInfo>
/**
 @defgroup SSEI_PROTOCOL EnableScannerResponseInfo Protocol
 Feedback for any scanner events.
 @{
 */
/**@}*/
@end

/**
 @brief Feedback for enable scanner response.
 */
@protocol ScannerDisabledResponseInfo<ResponseInfo>
/**
 @defgroup SSEI_PROTOCOL ScannerDisabledResponseInfo Protocol
 Feedback for any scanner events.
 @{
 */
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
	It should be typically used to print the merchant receipt and accept the customer signature. Handler has to call acceptSignature:(BOOL)flag with YES if the signature is valid and NO otherwise. If the handler doesn't process the message in a timely manner (as dictated by the card reader) then the transaction will be declined and cancelSignature called (note: the typical configured time period on the card reader is 90s).
 @param receipt				The merchant receipt of the transaction in html format.
 */
- (void)requestSignature:(NSString*)receipt;

/**
 Notifies when signature validation is timed out for 45s.
 */
- (void)cancelSignature;

/**@}*/

@optional

/**
 Notifies that a previously lost transaction result has been recovered.
 @param info				Complete information about the recovered transaction. nil if no lost transaction was found.
 */
- (void)responseRecoveredTransactionStatus:(id<FinanceResponseInfo>)info;

/**
 Notifies that a scan has been performed.
 @param info    Includes scanned code, status code, status text and detatailed xml.
 */
- (void)responseScannerEvent:(id<ScannerEventResponseInfo>)info;

/**
 Notifies that the scanner mode has been disabled.
 @param info    Includes status code, status text and detailed xml.
 */
-(void)responseScannerDisabled:(id<ScannerDisabledResponseInfo>)info;

/**
 DEPRECATED: use -(void)responseScannerDisabled:(id<ScannerDisabledResponseInfo>)info;
 
 Notifies that the scanner mode has been disabled.
 @param info    Includes status code, status text and detailed xml.
 */
- (void)responseEnableScanner:(id<EnableScannerResponseInfo>)info DEPRECATED_ATTRIBUTE;


/**
Returns the result of a EMV report request
 @param report  Includes the report
 */
- (void)responseEMVReport:(NSString*)report;

@end
