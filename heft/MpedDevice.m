//
//  MpedDevice.m
//  headstart
//

#import "MpedDevice.h"
#import "HeftConnection.h"
#import "HeftStatusReport.h"
#import "FinanceTransactionOperation.h"
#import "ResponseParser.h"

#import "StdAfx.h"
#import "RequestCommand.h"
#import "ResponseCommand.h"
#import "FrameManager.h"
#import "Frame.h"

const NSString* kSerialNumberInfoKey = @"SerialNumber";
const NSString* kPublicKeyVersionInfoKey = @"PublicKeyVersion";
const NSString* kEMVParamVersionInfoKey = @"EMVParamVersion";
const NSString* kGeneralParamInfoKey = @"GeneralParam";
const NSString* kManufacturerCodeInfoKey = @"ManufacturerCode";
const NSString* kModelCodeInfoKey = @"ModelCode";
const NSString* kAppNameInfoKey = @"AppName";
const NSString* kAppVersionInfoKey = @"AppVersion";
const NSString* kXMLDetailsInfoKey = @"XMLDetails";

NSString* statusMessages[] = {
	@""
	,@"Success"
	,@"Invalid data"
	,@"Processing error"
	,@"Not allowed"
	,@"Not initialized"
	,@"Connect timeout"
	,@"Connect error"
	,@"Sending error"
	,@"Receiveing error"
	,@"No data available"
	,@"Transaction not allowed"
	,@"Unsupported currency"
	,@"No host available"
	,@"Card reader error"
	,@"Card reading failed"
	,@"Invalid card"
	,@"Input timeout"
	,@"User cancelled"
	,@"Invalid signature"
	,@"Waiting card"
	,@"Card inserted"
	,@"Application selection"
	,@"Application confirmation"
	,@"Amount validation"
	,@"PIN input"
	,@"Manual card input"
	,@"Waiting card removal"
	,@"Tip input"
	,@"Shared secret invalid"
	,@""
	,@""
	,@"Connecting"
	,@"Sending"
	,@"Receiveing"
	,@"Disconnecting"
};

@interface MpedDevice ()<IResponseProcessor>
@end

enum eSignConditions{
	eNoSignCondition
	, eSignCondition
};

@implementation MpedDevice

@synthesize mpedInfo;

- (id)initWithConnection:(HeftConnection*)aConnection sharedSecret:(NSData*)aSharedSecret delegate:(NSObject<HeftStatusReportDelegate>*)aDelegate{
	if(aConnection){
		if(self = [super init]){
			LOG(@"MpedDevice::init");
			connection = aConnection;
			queue = [NSOperationQueue new];
			[queue setMaxConcurrentOperationCount:1];
			sharedSecret = aSharedSecret;
			delegate = aDelegate;
			signLock = [[NSConditionLock alloc] initWithCondition:eNoSignCondition];

			try{
				FrameManager fm(InitRequestCommand(), connection.maxBufferSize);
				fm.Write(connection);
				InitResponseCommand* pResponse = fm.ReadResponse<InitResponseCommand>(connection, false);
				connection.maxBufferSize = pResponse->GetBufferSize();
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
				[self sendResponseInfo:exception.stringId() xml:nil];
				self = nil;
			}
		}
	}
	else{
		[self sendResponseInfo:@"Cann't create bluetooth connection" xml:nil];
		self = nil;
	}

	return self;
}

- (void)dealloc{
	LOG(@"MpedDevice::dealloc");
	[connection shutdown];
}

#pragma mark HeftClient

- (void)cancel{
	LOG_RELEASE(Logger::eFine, @"Cancelling current financial transaction");
	FrameManager fm(IdleRequestCommand(), connection.maxBufferSize);
	fm.WriteWithoutAck(connection);
	LOG_RELEASE(Logger::eFiner, @"Cancel request sent to PED");
}

- (BOOL)saleWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present{
	LOG_RELEASE(Logger::eInfo, @"Starting SALE operation (amount:%d, currency:%@, card %@", amount, currency, present ? @"is present" : @"is not present");
	FinanceTransactionOperation* operation = [[FinanceTransactionOperation alloc] initWithRequest:new SaleRequestCommand(string([currency UTF8String]), amount, present)
																					   connection:connection resultsProcessor:self sharedSecret:sharedSecret];
	[queue addOperation:operation];
	return YES;
}

- (BOOL)refundWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present{
	LOG_RELEASE(Logger::eInfo, @"Starting REFUND operation (amount:%d, currency:%@, card %@", amount, currency, present ? @"is present" : @"is not present");
	FinanceTransactionOperation* operation = [[FinanceTransactionOperation alloc] initWithRequest:new RefundRequestCommand(string([currency UTF8String]), amount, present)
																					   connection:connection resultsProcessor:self sharedSecret:sharedSecret];
	[queue addOperation:operation];
	return YES;
}

- (BOOL)saleVoidWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present transaction:(NSString*)transaction{
	LOG_RELEASE(Logger::eInfo, @"Starting SALE VOID operation (transactionID:%@, amount:%d, currency:%@, card %@", transaction, amount, currency, present ? @"is present" : @"is not present");
	FinanceTransactionOperation* operation = [[FinanceTransactionOperation alloc] initWithRequest:new SaleVRequestCommand(string([currency UTF8String]), amount, present, string([transaction UTF8String]))
																					   connection:connection resultsProcessor:self sharedSecret:sharedSecret];
	[queue addOperation:operation];
	return YES;
}

- (BOOL)refundVoidWithAmount:(NSInteger)amount currency:(NSString*)currency cardholder:(BOOL)present transaction:(NSString*)transaction{
	LOG_RELEASE(Logger::eInfo, @"Starting REFUND VOID operation (transactionID:%@, amount:%d, currency:%@, card %@", transaction, amount, currency, present ? @"is present" : @"is not present");
	FinanceTransactionOperation* operation = [[FinanceTransactionOperation alloc] initWithRequest:new RefundVRequestCommand(string([currency UTF8String]), amount, present, string([transaction UTF8String]))
																					   connection:connection resultsProcessor:self sharedSecret:sharedSecret];
	[queue addOperation:operation];
	return YES;
}

- (BOOL)financeStartOfDay{
	FinanceTransactionOperation* operation = [[FinanceTransactionOperation alloc] initWithRequest:new StartOfDayRequestCommand()
																					   connection:connection resultsProcessor:self sharedSecret:sharedSecret];
	[queue addOperation:operation];
	return YES;
}

- (BOOL)financeEndOfDay{
	FinanceTransactionOperation* operation = [[FinanceTransactionOperation alloc] initWithRequest:new EndOfDayRequestCommand()
																					   connection:connection resultsProcessor:self sharedSecret:sharedSecret];
	[queue addOperation:operation];
	return YES;
}

- (BOOL)financeInit{
	FinanceTransactionOperation* operation = [[FinanceTransactionOperation alloc] initWithRequest:new FinanceInitRequestCommand()
																					   connection:connection resultsProcessor:self sharedSecret:sharedSecret];
	[queue addOperation:operation];
	return YES;
}

- (BOOL)logSetLevel:(eLogLevel)level{
	FinanceTransactionOperation* operation = [[FinanceTransactionOperation alloc] initWithRequest:new SetLogLevelRequestCommand(level)
																					   connection:connection resultsProcessor:self sharedSecret:sharedSecret];
	[queue addOperation:operation];
	return YES;
}

- (BOOL)logReset{
	FinanceTransactionOperation* operation = [[FinanceTransactionOperation alloc] initWithRequest:new ResetLogInfoRequestCommand()
																					   connection:connection resultsProcessor:self sharedSecret:sharedSecret];
	[queue addOperation:operation];
	return YES;
}

- (BOOL)logGetInfo{
	FinanceTransactionOperation* operation = [[FinanceTransactionOperation alloc] initWithRequest:new GetLogInfoRequestCommand()
																					   connection:connection resultsProcessor:self sharedSecret:sharedSecret];
	[queue addOperation:operation];
	return YES;
}

- (void)acceptSignature:(BOOL)flag{
	[signLock lock];
	signatureIsOk = flag;
	[signLock unlockWithCondition:eSignCondition];
}

#pragma mark ----

- (NSDictionary*)getValuesFromXml:(NSString*)xml path:(NSString*)path{
	NSXMLParser* xmlParser = [[NSXMLParser alloc] initWithData:[[NSData alloc] initWithBytesNoCopy:(void*)[xml UTF8String] length:[xml length] freeWhenDone:NO]];
	ResponseParser* parser = [[ResponseParser alloc] initWithPath:path];
	xmlParser.delegate = parser;
	Verify([xmlParser parse]);
	//LOG(@"%@", parser.result);
	return parser.result;
}

#pragma mark IResponseProcessor

- (void)sendResponseInfo:(NSString*)status xml:(NSDictionary*)xml{
	ResponseInfo* info = [ResponseInfo new];
	info.status = xml ? [xml objectForKey:@"StatusMessage"] : status;
	info.xml = xml;
	LOG_RELEASE(Logger::eFine, @"%@", info.status);
	[delegate performSelectorOnMainThread:@selector(responseStatus:) withObject:info waitUntilDone:NO];
}

- (int)processSign:(NSString*)receipt{
	int result = EFT_PP_STATUS_PROCESSING_ERROR;

	[delegate performSelectorOnMainThread:@selector(requestSignature:) withObject:receipt waitUntilDone:NO];

	if([signLock lockWhenCondition:eSignCondition beforeDate:[NSDate dateWithTimeIntervalSinceNow:ciTimeout[eFinanceTimeout]]]){
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
	if(status != EFT_PP_STATUS_SUCCESS)
		[self sendResponseInfo:statusMessages[status] xml:nil];
}

-(void)processEventInfoResponse:(EventInfoResponseCommand*)pResponse{
	[self sendResponseInfo:statusMessages[pResponse->GetStatus()] xml:[self getValuesFromXml:@(pResponse->GetXmlDetails().c_str()) path:@"EventInfoResponse"]];
}

-(void)processFinanceResponse:(FinanceResponseCommand*)pResponse{
	FinanceResponseInfo* info = [FinanceResponseInfo new];
	NSDictionary* xmlDetails = [self getValuesFromXml:@(pResponse->GetXmlDetails().c_str()) path:@"FinancialTransactionResponse"];
	info.xml = xmlDetails;
	info.status = pResponse->GetStatus() == EFT_PP_STATUS_SUCCESS ? [xmlDetails objectForKey:@"FinancialStatus"] : [xmlDetails objectForKey:@"StatusMessage"];
	info.customerReceipt = @(pResponse->GetCustomerReceipt().c_str());
	LOG_RELEASE(Logger::eFine, @"%@", info.status);
	[delegate performSelectorOnMainThread:@selector(responseFinanceStatus:) withObject:info waitUntilDone:NO];
}

-(void)processDebugInfoResponse:(DebugInfoResponseCommand*)pResponse{
}

-(void)processLogInfoResponse:(GetLogInfoResponseCommand*)pResponse{
	LogInfo* info = [LogInfo new];
	int status = pResponse->GetStatus();
	info.status = statusMessages[status];
	if(status == EFT_PP_STATUS_SUCCESS)
		info.log = @(pResponse->GetData().c_str());
	[delegate performSelectorOnMainThread:@selector(responseLogInfo:) withObject:info waitUntilDone:NO];
}

@end
