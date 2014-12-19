//
//  MpedDevice.m
//  headstart
//

#import "StdAfx.h"

#import "MpedDevice.h"
#import "HeftConnection.h"
#import "HeftStatusReport.h"
#import "ResponseParser.h"
#include "HeftCmdIds.h"

#if HEFT_SIMULATOR
#import "simulator/Shared/RequestCommand.h"
#import "simulator/Shared/ResponseCommand.h"
#import "simulator/MPosOperation.h"
#else
#import "FrameManager.h"
#import "Frame.h"
#import "Shared/RequestCommand.h"
#import "Shared/ResponseCommand.h"
#import "MPosOperation.h"
#endif

const NSString* kSerialNumberInfoKey = @"SerialNumber";
const NSString* kPublicKeyVersionInfoKey = @"PublicKeyVersion";
const NSString* kEMVParamVersionInfoKey = @"EMVParamVersion";
const NSString* kGeneralParamInfoKey = @"GeneralParam";
const NSString* kManufacturerCodeInfoKey = @"ManufacturerCode";
const NSString* kModelCodeInfoKey = @"ModelCode";
const NSString* kAppNameInfoKey = @"AppName";
const NSString* kAppVersionInfoKey = @"AppVersion";
const NSString* kXMLDetailsInfoKey = @"XMLDetails";

const int ciTimeout[] = {20 , 15, 1, 45};

NSString* statusMessages[] = {
	@"Undefined"
	,@"Success"
	,@"Invalid data"
	,@"Processing error"
	,@"Command not allowed"
	,@"Device is not initialized"
	,@"Connection timeout detected"
	,@"Connection error"
	,@"Send error"
	,@"Receiving error"
	,@"No data available"
	,@"Transaction not allowed"
	,@"Currency not supported"
	,@"No host configuration found"
	,@"Card reader error"
	,@"Failed to read card data"
	,@"Invalid card"
	,@"Timeout waiting for user input"
	,@"User cancelled the transaction"
	,@"Invalid signature"
	,@"Waiting for card"
	,@"Card detected"
	,@"Waiting for application selection"
	,@"Waiting for application confirmation"
	,@"Waiting for amount validation"
	,@"Waiting for PIN entry"
	,@"Waiting for manual card data"
	,@"Waiting for card removal"
	,@"Waiting for gratuity"
	,@"Shared secret invalid"
	,@"Authenticating POS"
	,@"Waiting for signature"
	,@"Connecting to host"
	,@"Sending data to host"
	,@"Waiting for data from host"
	,@"Disconnecting from host"
    ,@"PIN entry completed"
    ,@"Merchant cancelled the transaction"
    ,@"Request invalid"
    ,@"Card cancelled the transaction"
    ,@"Blocked card"
    ,@"Request for authorisation timed out"
    ,@"Request for payment timed out"
    ,@"Response to authorisation request timed out"
    ,@"Response to payment request timed out"
    ,@"Please insert card in chip reader"
    ,@"Remove the card from the reader"
    ,@"This device does not have a scanner"
    ,@""
    ,@"Operation cancelled, the battery is too low. Please charge."
    ,@"Waiting for accoutn type selection"
    ,@"Bluetooth is not supported on this device"
};

@interface MpedDevice ()<IResponseProcessor>
@end

enum eSignConditions{
	eNoSignCondition
	, eSignCondition
};

@implementation MpedDevice{
	HeftConnection* connection;
	NSOperationQueue* queue;
	//NSObject<HeftClientDelegate>* delegate;
	NSData* sharedSecret;
	__weak NSObject<HeftStatusReportDelegate>* delegate;
	NSConditionLock* signLock;
	BOOL signatureIsOk;
}

@synthesize mpedInfo;
@synthesize isTransactionResultPending;

- (id)initWithConnection:(HeftConnection*)aConnection sharedSecret:(NSData*)aSharedSecret delegate:(NSObject<HeftStatusReportDelegate>*)aDelegate{
#if !HEFT_SIMULATOR
	if(aConnection){
#endif
		if(self = [super init]){
			LOG(@"MpedDevice::init");
			queue = [NSOperationQueue new];
			[queue setMaxConcurrentOperationCount:1];
			delegate = aDelegate;
			signLock = [[NSConditionLock alloc] initWithCondition:eNoSignCondition];

#if HEFT_SIMULATOR
			mpedInfo = @{
				kSerialNumberInfoKey:@"000123400123"
				, kPublicKeyVersionInfoKey:@1
				, kEMVParamVersionInfoKey:@1
				, kGeneralParamInfoKey:@1
				, kManufacturerCodeInfoKey:@0
				, kModelCodeInfoKey:@0
				, kAppNameInfoKey:@"Simulator"
				, kAppVersionInfoKey:@0x0107
				, kXMLDetailsInfoKey:@""
			};
            
            isTransactionResultPending = simulatorState.isInException();
#else
			connection = aConnection;
			sharedSecret = aSharedSecret;
			try{
				FrameManager fm(InitRequestCommand(), connection.maxFrameSize);
				fm.Write(connection);
				InitResponseCommand* pResponse = dynamic_cast<InitResponseCommand*>(reinterpret_cast<ResponseCommand*>(fm.ReadResponse<InitResponseCommand>(connection, false)));
				if(!pResponse)
					throw communication_exception();
				connection.maxFrameSize = pResponse->GetBufferSize()-2; // Hotfix: 2048 bytes causes buffer overflow in EFT client.

                NSDictionary* xml;
                if([(xml = [self getValuesFromXml:@(pResponse->GetXmlDetails().c_str()) path:@"InitResponse"]) count]> 0)
                {
                    NSString* trp = [xml objectForKey:@"TransactionResultPending"];
                    isTransactionResultPending = ((trp != nil) && [trp isEqualToString:@"true"]) ? YES : NO;
                }
                else
                {
                    isTransactionResultPending = NO;
                }
                /*
                 I´ve seriously debated whether or not to create a new dictionary object in the MpedDevice interface, to hold the xml details from the above xml details parse, and reached the conclusion that currently there is no need for it as mpedInfo already provides all important information.
                 But, in preparation for the future, I´ve decided that we should deprecate the kXMLDetailsInfoKey tag.
                 */

                mpedInfo = @{
					kSerialNumberInfoKey:@(pResponse->GetSerialNumber().c_str())
					, kPublicKeyVersionInfoKey:@(pResponse->GetPublicKeyVer())
					, kEMVParamVersionInfoKey:@(pResponse->GetEmvParamVer())
					, kGeneralParamInfoKey:@(pResponse->GetGeneralParamVer())
					, kManufacturerCodeInfoKey:@(pResponse->GetManufacturerCode())
					, kModelCodeInfoKey:@(pResponse->GetModelCode())
					, kAppNameInfoKey:@(pResponse->GetAppName().c_str())
					, kAppVersionInfoKey:@(pResponse->GetAppVer())
					, kXMLDetailsInfoKey:@(pResponse->GetXmlDetails().c_str())
				};
			}
			catch(heft_exception& exception){
				[self sendResponseError:exception.stringId()];
				self = nil;
			}
#endif
		}
#if !HEFT_SIMULATOR
	}
	else{
		[self sendResponseError:@"Can't create bluetooth connection"];
		self = nil;
	}
#endif

	return self;
}

- (void)dealloc{
	LOG(@"MpedDevice::dealloc");
	[connection shutdown];
}

#pragma mark HeftClient

- (void)cancel{
	if(![queue operationCount])
		return;
	LOG_RELEASE(Logger::eFine, @"Cancelling current operation");
#if HEFT_SIMULATOR
	[queue cancelAllOperations];
#else
	FrameManager fm(IdleRequestCommand(), connection.maxFrameSize);
	fm.WriteWithoutAck(connection);
#endif
	LOG_RELEASE(Logger::eFiner, @"Cancel request sent to PED");
}

- (BOOL)postOperationToQueueIfNew:(MPosOperation*)operation{
	if([queue operationCount])
		return NO;

	[queue addOperation:operation];

	return YES;
}

- (BOOL)saleWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present{
	return [self saleWithAmount:amount currency:currency cardholder:present reference:@""];
}

- (BOOL)saleWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present reference:(NSString*)reference{
	LOG_RELEASE(Logger::eInfo, @"Starting SALE operation (amount:%d, currency:%@, card %@, customer reference:%@", amount, currency, present ? @"is present" : @"is not present", reference);
    NSString *params = @"";
    if(reference != NULL && reference.length != 0) {
        params = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
                  @"<FinancialTransactionRequest>"
                  @"<CustomerReference>"
                  @"%@"
                  @"</CustomerReference>"
                  @"</FinancialTransactionRequest>",
                  reference];
    }
	MPosOperation* operation = [[MPosOperation alloc] initWithRequest:new FinanceRequestCommand(CMD_FIN_SALE_REQ, string([currency UTF8String]), (UINT32)amount, present, string(), string([params UTF8String]))
                                                                                       connection:connection resultsProcessor:self sharedSecret:sharedSecret];
    isTransactionResultPending = NO;
	return [self postOperationToQueueIfNew:operation];
}

- (BOOL)saleWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present reference:(NSString*)reference divideBy:(NSString *)months{
	LOG_RELEASE(Logger::eInfo, @"Starting SALE operation (amount:%d, currency:%@, card %@, customer reference:%@, divided by: %@ months", amount, currency, present ? @"is present" : @"is not present", reference, months);
    NSString *params = @"";
    NSString *refrenceString = @"";
    NSString *monthsString = @"";
    if(reference != NULL && reference.length != 0) {
        refrenceString = [NSString stringWithFormat:
                        @"<CustomerReference>"
                        @"%@"
                        @"</CustomerReference>",
                        reference];
    }
    if(months != NULL && months.length != 0) {
        monthsString = [NSString stringWithFormat:
                        @"<BudgetNumber>"
                        @"%@"
                        @"</BudgetNumber>",
                        months];
    }
    if( refrenceString.length != 0 || monthsString.length != 0) {
        params = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
                  @"<FinancialTransactionRequest>"
                  @"%@"
                  @"%@"
                  @"</FinancialTransactionRequest>",
                  refrenceString, monthsString];
    }
    
	MPosOperation* operation = [[MPosOperation alloc] initWithRequest:new FinanceRequestCommand(CMD_FIN_SALE_REQ, string([currency UTF8String]), (UINT32)amount, present, string(), string([params UTF8String]))
                                                           connection:connection
                                                     resultsProcessor:self
                                                         sharedSecret:sharedSecret];
    isTransactionResultPending = NO;
	return [self postOperationToQueueIfNew:operation];
}


- (BOOL)refundWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present{
	return [self refundWithAmount:amount currency:currency cardholder:present reference:@""];
}

- (BOOL)refundWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present reference:(NSString *)reference{
	LOG_RELEASE(Logger::eInfo, @"Starting REFUND operation (amount:%d, currency:%@, card %@, customer reference:%@", amount, currency, present ? @"is present" : @"is not present", reference);
    NSString *params = @"";
    if(reference != NULL && reference.length != 0) {
        params = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
                  @"<FinancialTransactionRequest>"
                  @"<CustomerReference>"
                  @"%@"
                  @"</CustomerReference>"
                  @"</FinancialTransactionRequest>",
                  reference];
    }
	MPosOperation* operation = [[MPosOperation alloc] initWithRequest:new FinanceRequestCommand(CMD_FIN_REFUND_REQ, string([currency UTF8String]), (UINT32)amount, present, string(), string([params UTF8String]))
																					   connection:connection resultsProcessor:self sharedSecret:sharedSecret];
    isTransactionResultPending = NO;
	return [self postOperationToQueueIfNew:operation];
}

- (BOOL)saleVoidWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present transaction:(NSString*)transaction{
	LOG_RELEASE(Logger::eInfo, @"Starting SALE VOID operation (transactionID:%@, amount:%d, currency:%@, card %@", transaction, amount, currency, present ? @"is present" : @"is not present");
    // an empty transaction id is actually not allowed here, but we will let the EFT Client take care of that
	MPosOperation* operation = [[MPosOperation alloc] initWithRequest:new FinanceRequestCommand(CMD_FIN_SALEV_REQ, string([currency UTF8String]), (UINT32)amount, present, string([transaction UTF8String]), string())
																					   connection:connection resultsProcessor:self sharedSecret:sharedSecret];
    isTransactionResultPending = NO;
	return [self postOperationToQueueIfNew:operation];
}

- (BOOL)refundVoidWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present transaction:(NSString*)transaction{
	LOG_RELEASE(Logger::eInfo, @"Starting REFUND VOID operation (transactionID:%@, amount:%d, currency:%@, card %@", transaction, amount, currency, present ? @"is present" : @"is not present");
    // an empty transaction id is actually not allowed here, but we will let the EFT Client take care of that
	MPosOperation* operation = [[MPosOperation alloc] initWithRequest:new FinanceRequestCommand(CMD_FIN_REFUNDV_REQ, string([currency UTF8String]), (UINT32)amount, present, string([transaction UTF8String]), string())
																					   connection:connection resultsProcessor:self sharedSecret:sharedSecret];
    isTransactionResultPending = NO;
	return [self postOperationToQueueIfNew:operation];
}

- (BOOL)retrievePendingTransaction{
    MPosOperation* operation = [[MPosOperation alloc] initWithRequest:new FinanceRequestCommand(CMD_FIN_RCVRD_TXN_RSLT
                                                                                                , "0" // must be like this or we throw an invalid currency exception
                                                                                                , 0
                                                                                                , YES
                                                                                                , string()
                                                                                                , string())
                                                           connection:connection
                                                     resultsProcessor:self
                                                         sharedSecret:sharedSecret];
    BOOL return_value = [self postOperationToQueueIfNew:operation];
    if(return_value){
        isTransactionResultPending = NO;
    }
    return return_value;
}

-(BOOL)enableScanner{
	return [self enableScannerWithMultiScan:TRUE buttonMode:TRUE timeoutSeconds:0];
}
-(BOOL)enableScannerWithMultiScan:(BOOL)multiScan{
	return [self enableScannerWithMultiScan:multiScan buttonMode:TRUE timeoutSeconds:0];
}
-(BOOL)enableScannerWithMultiScan:(BOOL)multiScan buttonMode:(BOOL)buttonMode{
	return [self enableScannerWithMultiScan:multiScan buttonMode:buttonMode timeoutSeconds:0];
}

//Deprecated enable scanner function names
-(BOOL)enableScanner:(BOOL)multiScan{
	return [self enableScannerWithMultiScan:multiScan buttonMode:TRUE timeoutSeconds:0];
}
-(BOOL)enableScanner:(BOOL)multiScan buttonMode:(BOOL)buttonMode{
	return [self enableScannerWithMultiScan:multiScan buttonMode:buttonMode timeoutSeconds:0];
}
-(BOOL)enableScanner:(BOOL)multiScan buttonMode:(BOOL)buttonMode timeoutSeconds:(NSInteger)timeoutSeconds{
	return [self enableScannerWithMultiScan:multiScan buttonMode:buttonMode timeoutSeconds:timeoutSeconds];
}

-(BOOL)enableScannerWithMultiScan:(BOOL)multiScan buttonMode:(BOOL)buttonMode timeoutSeconds:(NSInteger)timeoutSeconds{
    LOG_RELEASE(Logger::eInfo, @"Scanner mode enabled.");
    //NSString *params = @"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><enableScanner></enableScanner>";
    NSString *params = @"";
    NSString *multiScanString = @"";
    NSString *buttonModeString = @"";
    NSString *timeoutSecondsString = @"";
    if(!multiScan) {
        multiScanString = [NSString stringWithFormat:
                          @"<multiScan>"
                          @"false"
                          @"</multiScan>"];
    }
    if(!buttonMode) {
        buttonModeString = [NSString stringWithFormat:
                        @"<buttonMode>"
                        @"false"
                        @"</buttonMode>"];
    }
    if(timeoutSeconds) {
        timeoutSecondsString = [NSString stringWithFormat:
                        @"<timeoutSeconds>"
                        @"%ld"
                        @"</timeoutSeconds>",
                        (long)timeoutSeconds];
    }
    params = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
                  @"<enableScanner>"
                  @"%@"
                  @"%@"
                  @"%@"
                  @"</enableScanner>",
                  multiScanString, buttonModeString, timeoutSecondsString];
    
    MPosOperation* operation = [[MPosOperation alloc] initWithRequest: new XMLCommandRequestCommand(string([params UTF8String])) connection:connection resultsProcessor:self sharedSecret:sharedSecret];
    
    return [self postOperationToQueueIfNew:operation];
}

-(void)disableScanner{
    [self cancel];
}
- (BOOL)financeStartOfDay{
	MPosOperation* operation = [[MPosOperation alloc] initWithRequest:new StartOfDayRequestCommand()
																					   connection:connection resultsProcessor:self sharedSecret:sharedSecret];
    isTransactionResultPending = NO;
	return [self postOperationToQueueIfNew:operation];
}

- (BOOL)financeEndOfDay{
	MPosOperation* operation = [[MPosOperation alloc] initWithRequest:new EndOfDayRequestCommand()
																					   connection:connection resultsProcessor:self sharedSecret:sharedSecret];
    isTransactionResultPending = NO;
	return [self postOperationToQueueIfNew:operation];
}

- (BOOL)financeInit{
	MPosOperation* operation = [[MPosOperation alloc] initWithRequest:new FinanceInitRequestCommand()
																					   connection:connection resultsProcessor:self sharedSecret:sharedSecret];
    isTransactionResultPending = NO;
	return [self postOperationToQueueIfNew:operation];
}

- (BOOL)logSetLevel:(eLogLevel)level{
	MPosOperation* operation = [[MPosOperation alloc] initWithRequest:new SetLogLevelRequestCommand(level)
																					   connection:connection resultsProcessor:self sharedSecret:sharedSecret];
	return [self postOperationToQueueIfNew:operation];
}

- (BOOL)logReset{
	MPosOperation* operation = [[MPosOperation alloc] initWithRequest:new ResetLogInfoRequestCommand()
																					   connection:connection resultsProcessor:self sharedSecret:sharedSecret];
	return [self postOperationToQueueIfNew:operation];
}

- (BOOL)logGetInfo{
	MPosOperation* operation = [[MPosOperation alloc] initWithRequest:new GetLogInfoRequestCommand()
																					   connection:connection resultsProcessor:self sharedSecret:sharedSecret];
	return [self postOperationToQueueIfNew:operation];
}

- (void)acceptSignature:(BOOL)flag{
	[signLock lock];
	signatureIsOk = flag;
	[signLock unlockWithCondition:eSignCondition];
}

#pragma mark -

- (NSDictionary*)getValuesFromXml:(NSString*)xml path:(NSString*)path{
	NSXMLParser* xmlParser = [[NSXMLParser alloc] initWithData:[[NSData alloc] initWithBytesNoCopy:(void*)[xml UTF8String] length:[xml length] freeWhenDone:NO]];
	ResponseParser* parser = [[ResponseParser alloc] initWithPath:path];
	xmlParser.delegate = parser;
	//LOG(@"%@", xml);
	[xmlParser parse];
	//Verify([xmlParser parse]);
	//LOG(@"%@", xmlParser.parserError);
	//LOG(@"%@", parser.result);
	return parser.result;
}

#pragma mark IResponseProcessor
- (void)sendScannerEvent:(NSString*)status code:(int)code xml:(NSDictionary*)xml{
    ScannerEventResponseInfo* info = [ScannerEventResponseInfo new];
    info.statusCode = code;
    info.status = xml ? [xml objectForKey:@"StatusMessage"] : status;
    info.scanCode = xml ? [xml objectForKey:@"code"] : @"";
    LOG_RELEASE(Logger::eFine, @"%@", info.scanCode);
    if([delegate respondsToSelector:@selector(responseScannerEvent:)])
    {
        [delegate performSelectorOnMainThread:@selector(responseScannerEvent:) withObject:info waitUntilDone:NO];
    }
}
-(void)sendEnableScannerResponse:(NSString*)status code:(int)code xml:(NSDictionary*)xml{
    LOG_RELEASE(Logger::eFine, @"Scanner disabled");
    
    if([delegate respondsToSelector:@selector(responseEnableScanner:)])
    {
        EnableScannerResponseInfo* info = [EnableScannerResponseInfo new];
        info.statusCode = code;
        info.status = xml ? [xml objectForKey:@"StatusMessage"] : status;
        info.xml = xml;
        [delegate performSelectorOnMainThread:@selector(responseEnableScanner:) withObject:info waitUntilDone:NO];
    }
    if([delegate respondsToSelector: @selector(responseScannerDisabled:)])
    {
        ScannerDisabledResponseInfo* info = [ScannerDisabledResponseInfo new];
        info .statusCode =  code;
        info.status = xml ? [xml objectForKey:@"StatusMessage"] : status;
        info.xml = xml;
        [delegate performSelectorOnMainThread:@selector(responseScannerDisabled:) withObject:info waitUntilDone:NO];
    }
}
- (void)sendResponseInfo:(NSString*)status code:(int)code xml:(NSDictionary*)xml{
	ResponseInfo* info = [ResponseInfo new];
	info.statusCode = code;
	info.status = xml ? [xml objectForKey:@"StatusMessage"] : status;
	info.xml = xml;
	LOG_RELEASE(Logger::eFine, @"%@", info.status);
	[delegate performSelectorOnMainThread:@selector(responseStatus:) withObject:info waitUntilDone:NO];
}

-(void)sendResponseError:(NSString*)status{
	ResponseInfo* info = [ResponseInfo new];
	info.status = status;
	LOG_RELEASE(Logger::eFine, @"%@", info.status);
	[delegate performSelectorOnMainThread:@selector(responseError:) withObject:info waitUntilDone:NO];
}

- (int)processSign:(SignatureRequestCommand*)pRequest{
	int result = EFT_PP_STATUS_PROCESSING_ERROR;

	[delegate performSelectorOnMainThread:@selector(requestSignature:) withObject:@(pRequest->GetReceipt().c_str()) waitUntilDone:NO];
    
    NSDictionary* xml = [self getValuesFromXml:@(pRequest->GetXmlDetails().c_str()) path:@"SignatureRequiredRequest"];
    
    double wait_time = [xml[@"timeout"] doubleValue];

	if([signLock lockWhenCondition:eSignCondition beforeDate:[NSDate dateWithTimeIntervalSinceNow:wait_time]]){
		result = signatureIsOk ? EFT_PP_STATUS_SUCCESS : EFT_PP_STATUS_INVALID_SIGNATURE;
		signatureIsOk = NO;
		[signLock unlockWithCondition:eNoSignCondition];
	}
	else
		[delegate performSelectorOnMainThread:@selector(cancelSignature) withObject:nil waitUntilDone:NO];

	return result;
}

-(void)processResponse:(ResponseCommand*)pResponse{
	int status = pResponse->GetStatus();
	if(status != EFT_PP_STATUS_SUCCESS){
		[self sendResponseInfo:statusMessages[status] code:status xml:nil];
#if HEFT_SIMULATOR
		[NSThread sleepForTimeInterval:1.];
#endif
	}
}

-(void)processXMLCommandResponseCommand:(XMLCommandResponseCommand*)pResponse{
	int status = pResponse->GetStatus();
	NSString* statusMessage = status < dim(statusMessages) ? statusMessages[status] : @"Unknown status";
    //if responseEnableScanner
    NSDictionary* xml;
    if([(xml = [self getValuesFromXml:@(pResponse->GetXmlReturn().c_str()) path:@"enableScannerResponse"]) count]> 0)
    {
        [self sendEnableScannerResponse:statusMessage code:status xml:xml];
    }

#if HEFT_SIMULATOR
	[NSThread sleepForTimeInterval:1.];
#endif
}

-(void)processEventInfoResponse:(EventInfoResponseCommand*)pResponse{
	int status = pResponse->GetStatus();
    NSString* statusMessage = status < dim(statusMessages) ? statusMessages[status] : @"Unknown status";
    NSDictionary* xml;
    if([(xml = [self getValuesFromXml:@(pResponse->GetXmlDetails().c_str()) path:@"EventInfoResponse"]) count]> 0)
    {
        [self sendResponseInfo:statusMessage code:status xml:xml];
    }
    else if([(xml = [self getValuesFromXml:@(pResponse->GetXmlDetails().c_str()) path:@"scannerEvent"]) count]> 0)
    {
        [self sendScannerEvent:statusMessage code:status xml:xml];
    }
#if HEFT_SIMULATOR
    [NSThread sleepForTimeInterval:1.];
#endif
    return;
}

-(void)processFinanceResponse:(FinanceResponseCommand*)pResponse{
	int status = pResponse->GetStatus();
	FinanceResponseInfo* info = [FinanceResponseInfo new];
    info.financialResult = pResponse->GetFinancialStatus();
    info.isRestarting = pResponse->isRestarting();
	info.statusCode = status;
	NSDictionary* xmlDetails = [self getValuesFromXml:@(pResponse->GetXmlDetails().c_str()) path:@"FinancialTransactionResponse"];
	info.xml = xmlDetails;
	info.status = status == EFT_PP_STATUS_SUCCESS ? [xmlDetails objectForKey:@"FinancialStatus"] : [xmlDetails objectForKey:@"StatusMessage"];
	info.authorisedAmount = pResponse->GetAmount();
	info.transactionId = @(pResponse->GetTransID().c_str());
	info.customerReceipt = @(pResponse->GetCustomerReceipt().c_str());
	info.merchantReceipt = @(pResponse->GetMerchantReceipt().c_str());
    
    NSString* rt = [xmlDetails objectForKey:@"RecoveredTransaction"];
    BOOL transactionResultPending = ((rt != nil) && [rt isEqualToString:@"true"]) ? YES : NO;
    
	LOG_RELEASE(Logger::eFine, @"%@", info.status);
    if(!pResponse->isRecoveredTransaction()){
        [delegate performSelectorOnMainThread:@selector(responseFinanceStatus:) withObject:info waitUntilDone:NO];
    } else {
        info = transactionResultPending ? info : nil;
        [delegate performSelectorOnMainThread:@selector(responseRecoveredTransactionStatus:) withObject:info waitUntilDone:NO];
    }
}

/*-(void)processDebugInfoResponse:(DebugInfoResponseCommand*)pResponse{
}*/

-(void)processLogInfoResponse:(GetLogInfoResponseCommand*)pResponse{
	LogInfo* info = [LogInfo new];
	int status = pResponse->GetStatus();
	info.statusCode = status;
	info.status = statusMessages[status];
	if(status == EFT_PP_STATUS_SUCCESS)
		info.log = @(pResponse->GetData().c_str());
	[delegate performSelectorOnMainThread:@selector(responseLogInfo:) withObject:info waitUntilDone:NO];
}

@end
