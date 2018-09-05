//
//  HeftStatusReportDelegate.h
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

@protocol HeftClient;
@protocol ResponseInfo;
@protocol FinanceResponseInfo;
@protocol LogInfo;
@protocol ScannerEventResponseInfo;
@protocol ScannerDisabledResponseInfo;

/**
 @brief HeftStatusReportDelegate protocol methods
 */
@protocol HeftStatusReportDelegate
/**
 Notifications sent by the SDK on various events - connected to device, request signature, response on error  etc.
 @{
 */

/**
 Notifies that connection to specified device was created.
 @param client	Contains information about current connection or equals to nil, if connection wasn't created.
 */
- (void)didConnect:(id <HeftClient>)client;

/**
 Notifies about transaction current state.
 @param info	Includes status code, status text and detailed xml.
 */
- (void)responseStatus:(id <ResponseInfo>)info;


/**
 Notifies about error during transaction.
 @param info	Information about current transaction status.
 */
- (void)responseError:(id <ResponseInfo>)info;

/**
 Notifies that transaction has completed.
 @param info				Complete information about transaction.
 */
- (void)responseFinanceStatus:(id <FinanceResponseInfo>)info;

/**
 Notifies result of getting log information request.
 @param info				Contains history of actions and transactions from MPED since last responseLogInfo.
 */
- (void)responseLogInfo:(id <LogInfo>)info;

/**
 Notifies when cardholder's signature verification is needed.<br/> 
	It should be typically used to print the merchant receipt and accept the customer signature. Handler has to call acceptSignature:(BOOL)flag with YES if the signature is valid and NO otherwise. If the handler doesn't process the message in a timely manner (as dictated by the card reader) then the transaction will be declined and cancelSignature called (note: the typical configured time period on the card reader is 90s).
 @param receipt				The merchant receipt of the transaction in html format.
 */
- (void)requestSignature:(NSString *)receipt;

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
- (void)responseRecoveredTransactionStatus:(id <FinanceResponseInfo>)info;

/**
 Notifies that a scan has been performed.
 @param info    Includes scanned code, status code, status text and detatailed xml.
 */
- (void)responseScannerEvent:(id <ScannerEventResponseInfo>)info;

/**
 Notifies that the scanner mode has been disabled.
 @param info    Includes status code, status text and detailed xml.
 */
- (void)responseScannerDisabled:(id <ScannerDisabledResponseInfo>)info;


/**
Returns the result of a EMV report request
 @param report  Includes the report
 */
- (void)responseEMVReport:(NSString *)report;

@end
