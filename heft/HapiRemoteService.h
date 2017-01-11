//
//  HapiRemoteService.h
//  headstart
//
//  Created by Matti on 01/11/16.
//  Copyright © 2016 Handpoint. All rights reserved.
//

#ifndef HapiRemoteService_h
#define HapiRemoteService_h


/*
 The RPC interface to Hapi.
 These are methods that connect to the Handpoing Gateway withouth a connection 
 to a card reader.C To initialize the communication, a setup of the client must be done with a cardreader.
 */

//
// returns TRUE/YES if a connection has been set up
//         FALSE/NO if a error occurs
BOOL setupRemoteConnectionWithCardreader(NSString* shared_secret);

// typedef returnType (^TypeName)(parameterTypes);


typedef void (^tipAdjustmentCompletionHandler)(int status, NSString* errorCode);

// Parameters: NSString* transactionId
//
// Return value:
// # Callback/block.
//   When the method finishes, the callback block is called with the result of the remote transaction
//
BOOL tipAdjustment(NSString* transaction_id, NSInteger tipAmount, tipAdjustmentCompletionHandler handler);


#endif /* HapiRemoteService_h */
