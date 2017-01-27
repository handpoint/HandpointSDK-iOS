//
//  HapiRemoteService.h
//  headstart
//
//  Created by Matti on 01/11/16.
//  Copyright © 2016 Handpoint. All rights reserved.
//

#ifndef HapiRemoteService_h
#define HapiRemoteService_h


// initialize Hapi with a shared secret, need to connect to the APi server at Handpoint
BOOL setupHandpointApiConnection(NSString* shared_secret);

// possible status values for callback block
typedef NS_ENUM(NSInteger, TipAdjustmentStatus)
{
    TipAdjustmentAuthorised = 1,
    TipAdjustmentDeclined = 2,
    TipAdjustmentFailed = 3,
};


// a defintion of the callback block for the tipAdjustment function
typedef void (^tipAdjustmentCompletionHandler)(TipAdjustmentStatus status);


/**
 Performs a tipAdjustment transaction. Note, shared secret must be set before calling.
 @param transaction -    The id of the transaction. This is the value returned in transactionId field of FinanceResponseInfo
                         which is passed to responseFinanceStatus after a Sale. This value must not be nil or empty.
 @param tipAmount -      The amount - in the smallest unit for the given CurrencyCode -
                         for the transaction. ISO 4217 defines number of digits in
                         fractional part of currency for every currency code. Example
                         1000 in the case where CurrencyCode is "0826" (GBP) the amount
                         would be 10.00 pounds or 1000 pense.
 @param handler -        the block that handles the result of the transaction (see definition of tipAdjustmentCompletionHandler)
                         The block takes on parameter of type TipAdjustmentStatus and one of three values
                         * TipAdjustmentAuthorised - the tipAdjustment was successfully added to the transaction.
                         * TipAdjustmentDeclined - the system declined to add tip to the transaction. See logs for further details.
                         * TipAdjustmentFailed - an error occurred while trying to add tip. See logs for further details.
                         The block will be called in the main (UI) thread of the app.
  @return YES if request is sent and NO if a parameter is invalid.
*/
BOOL tipAdjustment(NSString* transaction, NSInteger tipAmount, tipAdjustmentCompletionHandler handler);


#endif /* HapiRemoteService_h */
