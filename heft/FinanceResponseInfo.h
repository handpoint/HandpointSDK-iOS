//
// Created by Juan Nuñez on 14/12/2017.
// Copyright (c) 2017 zdv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseInfo.h"

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

@interface FinanceResponseInfo : ResponseInfo<FinanceResponseInfo>
@end