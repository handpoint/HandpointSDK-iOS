//
//  MpedDevice.m
//  headstart
//

#include <string>

#import "MpedDevice.h"
#import "HeftConnection.h"
#import "ResponseParser.h"
#import "HeftManager.h"

#import "exception.h"
#import "Logger.h"
#import "debug.h"

#import "ScannerDisabledResponse.h"
#import "HeftStatusReportDelegate.h"
#import "ScannerEventResponseInfo.h"
#import "FinanceResponseInfo.h"
#import "LogInfoObject.h"
#import "ScannerEventResponse.h"
#import "FinanceResponse.h"
#import "XMLTags.h"

#ifdef HEFT_SIMULATOR

#import "simulator/Shared/RequestCommand.h"
#import "simulator/Shared/ResponseCommand.h"
#import "simulator/MPosOperation.h"

#else

#import "FrameManager.h"
#import "Frame.h"
#import "Shared/RequestCommand.h"
#import "Shared/ResponseCommand.h"
#import "MPosOperation.h"
#import "XMLTags.h"
#import "SaleOptions.h"
#import "MerchantAuth.h"

#endif


const NSString *kSerialNumberInfoKey = @"SerialNumber";
const NSString *kPublicKeyVersionInfoKey = @"PublicKeyVersion";
const NSString *kEMVParamVersionInfoKey = @"EMVParamVersion";
const NSString *kGeneralParamInfoKey = @"GeneralParam";
const NSString *kManufacturerCodeInfoKey = @"ManufacturerCode";
const NSString *kModelCodeInfoKey = @"ModelCode";
const NSString *kAppNameInfoKey = @"AppName";
const NSString *kAppVersionInfoKey = @"AppVersion";
const NSString *kXMLDetailsInfoKey = @"XMLDetails";

NSArray *statusMessages = @[
        @"Undefined", @"Success", @"Invalid data", @"Processing error", @"Command not allowed", @"Device is not initialized", @"Connection timeout detected", @"Connection error", @"Send error", @"Receiving error", @"No data available", @"Transaction not allowed", @"Currency not supported", @"No host configuration found", @"Card reader error", @"Failed to read card data", @"Invalid card", @"Timeout waiting for user input", @"User cancelled the transaction", @"Invalid signature", @"Waiting for card", @"Card detected", @"Waiting for application selection", @"Waiting for application confirmation", @"Waiting for amount validation", @"Waiting for PIN entry", @"Waiting for manual card data", @"Waiting for card removal", @"Waiting for gratuity", @"Shared secret invalid", @"Authenticating POS", @"Waiting for signature", @"Connecting to host", @"Sending data to host", @"Waiting for data from host", @"Disconnecting from host", @"PIN entry completed", @"Merchant cancelled the transaction", @"Request invalid", @"Card cancelled the transaction", @"Blocked card", @"Request for authorisation timed out", @"Request for payment timed out", @"Response to authorisation request timed out", @"Response to payment request timed out", @"Please insert card in chip reader", @"Remove the card from the reader", @"This device does not have a scanner", @"", @"Operation cancelled, the battery is too low. Please charge.", @"Waiting for accoutn type selection", @"Bluetooth is not supported on this device"];


@interface MpedDevice () <IResponseProcessor>
@end

enum eSignConditions
{
    eNoSignCondition, eSignCondition
};

@implementation MpedDevice
{
    HeftConnection *connection;

    __weak NSObject <HeftStatusReportDelegate> *delegate;
    NSConditionLock *signLock;
    BOOL signatureIsOk;
    BOOL cancelAllowed;
    BOOL isScanning;
    BOOL isWaitingIdleResponse;
}

@synthesize mpedInfo;
@synthesize isTransactionResultPending;

- (id)initWithConnection:(HeftConnection *)aConnection
            sharedSecret:(NSString *)aSharedSecret
                delegate:(NSObject <HeftStatusReportDelegate> *)aDelegate
{
    LOG(@"MpedDevice::initWithConnection");

#ifndef HEFT_SIMULATOR
    if (aConnection)
    {
#endif
        if (self = [super init])
        {
            LOG(@"MpedDevice::init");
            delegate = aDelegate;
            signLock = [[NSConditionLock alloc] initWithCondition:eNoSignCondition];
            cancelAllowed = NO; // cancel is only allowed when an operation is under way.
            isScanning = NO;
            isWaitingIdleResponse = NO;

#ifdef HEFT_SIMULATOR
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
            self.sharedSecret = aSharedSecret;

            try
            {

                FrameManager fm(InitRequestCommand(connection.maxFrameSize,
                        [HeftManager sharedManager].version
                        ),
                        connection.maxFrameSize
                );

                fm.Write(connection);

                std::unique_ptr<InitResponseCommand> pResponse(fm.ReadResponse<InitResponseCommand>(connection, false));

                if (!pResponse)
                {
                    throw communication_exception(@"initWithConnection: pResponse is empty");
                }

                LOG(@"Status: %d", pResponse->GetStatus());
                if (pResponse->GetStatus() == EFT_PP_STATUS_INVALID_DATA)
                {
                    // try init again, but now without the XML and all that
                    fm = FrameManager(InitRequestCommand(0, nil), connection.maxFrameSize);
                    fm.Write(connection);
                    pResponse.reset(fm.ReadResponse<InitResponseCommand>(connection, false));
                    LOG(@"Status: %d", pResponse->GetStatus());
                    if (pResponse->GetStatus() == EFT_PP_STATUS_INVALID_DATA)
                    {
                        // we tried twice, with and without the buffer size request
                        // "What we've got here is failure to communicate"
                        throw communication_exception(@"Error trying to initialize. EFT_PP_STATUS_INVALID_DATA");
                    }
                }

                auto bufferSize = pResponse->GetBufferSize();
                LOG(@"Buffersize from reader: %d", bufferSize);
                if (bufferSize >= 2048 && connection.maxFrameSize <= 2048)
                {
                    // probably an old reader, we did not request 2048 or greater
                    // which is poorly supported by iOS
                    // connection.maxFrameSize = 256;
                    // LOG(@"Buffersize set to 256");
                }
                else
                {
                    connection.maxFrameSize = bufferSize;
                }

                NSDictionary *xml = [self getValuesFromXml:@(pResponse->GetXmlDetails().c_str())
                                                      path:@"InitResponse"];
                if ([xml count] > 0)
                {
                    NSString *trp = xml[@"TransactionResultPending"];
                    isTransactionResultPending = (trp != nil) && [trp isEqualToString:@"true"];
                }
                else
                {
                    isTransactionResultPending = NO;
                }
                /*
                 I´ve seriously debated whether or not to create a new dictionary object in the MpedDevice interface,
                 to hold the xml details from the above xml details parse, and reached the conclusion that currently
                 there is no need for it as mpedInfo already provides all important information.
                 But, in preparation for the future, I´ve decided that we should deprecate the kXMLDetailsInfoKey tag.
                 */

                mpedInfo = @{
                        kSerialNumberInfoKey: @(pResponse->GetSerialNumber().c_str()), 
                        kPublicKeyVersionInfoKey: @(pResponse->GetPublicKeyVer()), 
                        kEMVParamVersionInfoKey: @(pResponse->GetEmvParamVer()), 
                        kGeneralParamInfoKey: @(pResponse->GetGeneralParamVer()), 
                        kManufacturerCodeInfoKey: @(pResponse->GetManufacturerCode()), 
                        kModelCodeInfoKey: @(pResponse->GetModelCode()), 
                        kAppNameInfoKey: @(pResponse->GetAppName().c_str()), 
                        kAppVersionInfoKey: @(pResponse->GetAppVer()), 
                        kXMLDetailsInfoKey: @(pResponse->GetXmlDetails().c_str())
                };
            }
            catch (connection_broken_exception &cb_exception)
            {
                LOG(@"MpedDevice, CONNECTION BROKEN EXCEPTION - NEED TO HANDLE EOT.");
                [self sendResponseError:cb_exception.stringId()];
                self = nil;
            }
            catch (heft_exception &exception)
            {
                [self sendResponseError:exception.stringId()];
                self = nil;
            }
#endif
        }
#ifndef HEFT_SIMULATOR
    }
    else
    {
        [self sendResponseError:@"Can't create bluetooth connection"];
        self = nil;
    }
#endif

    return self;
}

- (void)dealloc
{
    LOG(@"MpedDevice::dealloc");
    [self shutdown];
}

- (void)shutdown
{
    LOG(@"MpedDevice::shutdown");
    [connection shutdown];
    connection = nil;
}

#pragma mark HeftClient

- (void)cancel
{
    if (!cancelAllowed)
    {
        LOG_RELEASE(Logger::eFine, @"Cancelling is not allowed at this stage.");

        return;
    }

    LOG_RELEASE(Logger::eFine, @"Cancelling current operation");
    cancelAllowed = NO;

#if HEFT_SIMULATOR
    // [queue cancelAllOperations];
#else
    isWaitingIdleResponse = YES;
    FrameManager fm(IdleRequestCommand(), connection.maxFrameSize);
    fm.WriteWithoutAck(connection);
#endif
    LOG_RELEASE(Logger::eFiner, @"Cancel request sent to PED");


}


- (BOOL)postOperationToQueueIfNew:(MPosOperation *)operation
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        [operation start];
    });

    return YES;
}

- (BOOL)saleWithAmount:(NSInteger)amount currency:(NSString *)currency
{
    return [self saleWithAmount:amount
                       currency:currency
                        options:[SaleOptions new]];
}

- (BOOL)saleWithAmount:(NSInteger)amount
              currency:(NSString*)currency
               options:(SaleOptions *)options
{
    return [self saleWithAmount:amount
                       currency:currency
                        options:options
                       tokenize:NO];
}

- (BOOL)saleWithAmount:(NSInteger)amount
              currency:(NSString*)currency
               options:(SaleOptions *)options
              tokenize:(BOOL)tokenize
{
    if(isWaitingIdleResponse)
    {
        LOG_RELEASE(Logger::eInfo, @"Device is busy, please retry after a short wait.");
        return NO;
    }

    LOG_RELEASE(Logger::eInfo,
            @"Starting SALE operation (amount:%d, currency:%@, %@",
            (int) amount, currency, options);

    NSMutableDictionary *map = [NSMutableDictionary new];

    if ([options.customerReference length] != 0) {
        map[@"CustomerReference"] = options.customerReference;
    }

    if ([options.divideByMonths length] != 0)
    {
        map[@"BudgetNumber"] = options.divideByMonths;
    }

    if (options.merchantAuth != nil)
    {
        map[@"agreement"] = options.merchantAuth.toXML;
    }

    if (tokenize) {
        map[@"tokenizeCard"] = @"1";
    }

    NSString *params = [self generateXMLFromDictionary:@{@"FinancialTransactionRequest": map} appendHeader:YES];

    FinanceRequestCommand *frq = new FinanceRequestCommand(EFT_PACKET_SALE,
            std::string([currency UTF8String]),
            (std::uint32_t) amount,
            YES,
            std::string(),
            std::string([params UTF8String])
    );

    return [self postFinanceRequestCommand:frq];
}

- (BOOL)saleAndTokenizeCardWithAmount:(NSInteger)amount
                             currency:(NSString *)currency
{
    return [self saleAndTokenizeCardWithAmount:amount
                                      currency:currency
                                       options:[SaleOptions new]];
}

- (BOOL)saleAndTokenizeCardWithAmount:(NSInteger)amount
                             currency:(NSString *)currency
                              options:(SaleOptions *)options
{
    return [self saleWithAmount:amount
                       currency:currency
                        options:options
                       tokenize:YES];
}

- (BOOL)tokenizeCard
{
    return [self tokenizeCardWithCustomerReference:nil];
}

- (BOOL)tokenizeCardWithCustomerReference:(NSString *)reference
{

    LOG_RELEASE(Logger::eInfo, @"Starting TOKENIZE CARD operation, %@", reference);

    if(isWaitingIdleResponse)
    {
        LOG_RELEASE(Logger::eInfo, @"Device is busy, please retry after a short wait.");
        return NO;
    }

    NSMutableDictionary *map = [NSMutableDictionary new];
    
    if ([reference length])
    {
        map[@"CustomerReference"] = reference;
    }
    
    NSString *params = [self generateXMLFromDictionary:@{@"TokenizeCardRequest": map} appendHeader:YES];
    
    MPosOperation *operation = [[MPosOperation alloc] initWithRequest:new TokenizeCardRequestCommand(std::string([params UTF8String]))
                                                           connection:connection
                                                     resultsProcessor:self
                                                         sharedSecret:self.sharedSecret];
    isTransactionResultPending = NO;
    return [self postOperationToQueueIfNew:operation];
}

- (BOOL)refundWithAmount:(NSInteger)amount
                currency:(NSString *)currency
{
    return [self refundWithAmount:amount
                         currency:currency
                          options:[MerchantAuthOptions new]];
}

- (BOOL)refundWithAmount:(NSInteger)amount
                currency:(NSString *)currency
                 options:(MerchantAuthOptions *)options
{
    return [self refundWithAmount:amount
                         currency:currency
                      transaction:nil
                          options:options];
}

- (BOOL)refundWithAmount:(NSInteger)amount
                currency:(NSString*)currency
             transaction:(NSString*)transaction
{
    return [self refundWithAmount:amount
                         currency:currency
                      transaction:transaction
                          options:[MerchantAuthOptions new]];
}

- (BOOL)refundWithAmount:(NSInteger)amount
                currency:(NSString*)currency
             transaction:(NSString*)transaction
                 options:(MerchantAuthOptions *)options

{
    if(isWaitingIdleResponse)
    {
        LOG_RELEASE(Logger::eInfo, @"Device is busy, please retry after a short wait.");
        return NO;
    }

    LOG_RELEASE(Logger::eInfo, @"Starting REFUND operation (amount:%d, currency:%@, %@",
            amount, currency, dictionary);

    NSMutableDictionary *map = [NSMutableDictionary new];

    if ([options.customerReference length] != 0) {
        map[@"CustomerReference"] = options.customerReference;
    }

    if (options.merchantAuth != nil)
    {
        map[@"agreement"] = options.merchantAuth.toXML;
    }

    NSString *params = [self generateXMLFromDictionary:@{@"FinancialTransactionRequest": map} appendHeader:YES];

    FinanceRequestCommand *frc = new FinanceRequestCommand(EFT_PACKET_REFUND,
            std::string([currency UTF8String]),
            (std::uint32_t) amount,
            YES,
            transaction ? std::string([transaction UTF8String]) : std::string(),
            std::string([params UTF8String]));

    return [self postFinanceRequestCommand:frc];
}

- (BOOL)saleVoidWithAmount:(NSInteger)amount
                  currency:(NSString *)currency
               transaction:(NSString *)transaction
{
    return [self saleVoidWithAmount:amount
                           currency:currency
                        transaction:transaction
                         options:[Options new]];
}

- (BOOL)saleVoidWithAmount:(NSInteger)amount
                  currency:(NSString *)currency
               transaction:(NSString *)transaction
                   options:(Options *)options
{
    if(isWaitingIdleResponse)
    {
        LOG_RELEASE(Logger::eInfo, @"Device is busy, please retry after a short wait.");
        return NO;
    }

    LOG_RELEASE(Logger::eInfo,
            @"Starting SALE VOID operation (transactionID:%@, amount:%d, currency:%@, %@", transaction, (int) amount, currency, dictionary);

    NSMutableDictionary *map = [NSMutableDictionary new];

    if ([options.customerReference length] != 0) {
        map[@"CustomerReference"] = options.customerReference;
    }

    NSString *params = [self generateXMLFromDictionary:@{@"FinancialTransactionRequest": map} appendHeader:YES];

    // an empty transaction id is actually not allowed here, but we will let the EFT Client take care of that
    FinanceRequestCommand *frc = new FinanceRequestCommand(EFT_PACKET_SALE_VOID,
            std::string([currency UTF8String]),
            (std::uint32_t) amount,
            YES,
            std::string([transaction UTF8String]),
            std::string([params UTF8String]));

    return [self postFinanceRequestCommand:frc];
}

- (BOOL)refundVoidWithAmount:(NSInteger)amount
                    currency:(NSString *)currency
                 transaction:(NSString *)transaction
{
    return [self refundVoidWithAmount:amount
                             currency:currency
                          transaction:transaction
                              options:[Options new]];
}

- (BOOL)refundVoidWithAmount:(NSInteger)amount
                    currency:(NSString *)currency
                 transaction:(NSString *)transaction
                     options:(Options *)options
{
    if(isWaitingIdleResponse)
    {
        LOG_RELEASE(Logger::eInfo, @"Device is busy, please retry after a short wait.");
        return NO;
    }

    LOG_RELEASE(Logger::eInfo,
            @"Starting REFUND VOID operation (transactionID:%@, amount:%d, currency:%@, %@", transaction, (int) amount, currency, dictionary);

    NSMutableDictionary *map = [NSMutableDictionary new];

    if ([options.customerReference length] != 0) {
        map[@"CustomerReference"] = options.customerReference;
    }

    NSString *params = [self generateXMLFromDictionary:@{@"FinancialTransactionRequest": map} appendHeader:YES];

    // an empty transaction id is actually not allowed here, but we will let the EFT Client take care of that
    FinanceRequestCommand *frc = new FinanceRequestCommand(EFT_PACKET_REFUND_VOID,
            std::string([currency UTF8String]),
            (std::uint32_t) amount,
            YES,
            std::string([transaction UTF8String]),
            std::string([params UTF8String]));

    return [self postFinanceRequestCommand:frc];
}

- (BOOL)retrievePendingTransaction
{
    if(isWaitingIdleResponse)
    {
        LOG_RELEASE(Logger::eInfo, @"Device is busy, please retry after a short wait.");
        return NO;
    }
    FinanceRequestCommand *frc = new FinanceRequestCommand(EFT_PACKET_RECOVERED_TXN_RESULT, "0" // must be like this or we throw an invalid currency exception
            , 0, YES, std::string(), std::string());

    MPosOperation *operation = [[MPosOperation alloc] initWithRequest:frc
                                                           connection:connection
                                                     resultsProcessor:self
                                                         sharedSecret:self.sharedSecret];
    BOOL return_value = [self postOperationToQueueIfNew:operation];
    if (return_value)
    {
        isTransactionResultPending = NO;
    }
    return return_value;
}

- (BOOL)enableScanner
{
    return [self enableScannerWithMultiScan:TRUE buttonMode:TRUE timeoutSeconds:0];
}

- (BOOL)enableScannerWithMultiScan:(BOOL)multiScan
{
    return [self enableScannerWithMultiScan:multiScan buttonMode:TRUE timeoutSeconds:0];
}

- (BOOL)enableScannerWithMultiScan:(BOOL)multiScan buttonMode:(BOOL)buttonMode
{
    return [self enableScannerWithMultiScan:multiScan buttonMode:buttonMode timeoutSeconds:0];
}

- (BOOL)enableScannerWithMultiScan:(BOOL)multiScan buttonMode:(BOOL)buttonMode timeoutSeconds:(NSInteger)timeoutSeconds
{
    if(isWaitingIdleResponse)
    {
        LOG_RELEASE(Logger::eInfo, @"Device is busy, please retry after a short wait.");
        return NO;
    }

    if(isScanning)
    {
        LOG_RELEASE(Logger::eInfo, @"Scanner is already enabled.");
        return NO;
    }

    LOG_RELEASE(Logger::eInfo, @"Scanner mode enabled.");

    NSMutableDictionary *map = [@{} mutableCopy];

    // default timeoutvalue is 60 seconds
    long timeoutSecondsParameter = timeoutSeconds == 0 ? 60 : timeoutSeconds;
    if (timeoutSecondsParameter > 65535)
    {
        // the max value supported by the reader
        timeoutSecondsParameter = 65535;
    }

    map[@"multiScan"] = multiScan ? @"true" : @"false";
    map[@"buttonMode"] = buttonMode ? @"true" : @"false";
    map[@"timeoutSeconds"] = @(timeoutSecondsParameter);

    NSString *params = [self generateXMLFromDictionary:@{@"enableScanner": map} appendHeader:YES];

    XMLCommandRequestCommand *xcr = new XMLCommandRequestCommand(std::string([params UTF8String]));
    MPosOperation *operation = [[MPosOperation alloc] initWithRequest:xcr
                                                           connection:connection
                                                     resultsProcessor:self
                                                         sharedSecret:self.sharedSecret];

    isScanning = YES;
    // hardcoded here - should be able to cancel multiscan when nothing has been scanned
    cancelAllowed = YES;
    return [self postOperationToQueueIfNew:operation];
}

- (void)disableScanner
{
    [self cancel];
}

- (BOOL)financeStartOfDay
{
    if(isWaitingIdleResponse)
    {
        LOG_RELEASE(Logger::eInfo, @"Device is busy, please retry after a short wait.");
        return NO;
    }
    MPosOperation *operation = [[MPosOperation alloc] initWithRequest:new StartOfDayRequestCommand()
                                                           connection:connection
                                                     resultsProcessor:self
                                                         sharedSecret:self.sharedSecret];
    isTransactionResultPending = NO;
    return [self postOperationToQueueIfNew:operation];
}

- (BOOL)financeEndOfDay
{
    if(isWaitingIdleResponse)
    {
        LOG_RELEASE(Logger::eInfo, @"Device is busy, please retry after a short wait.");
        return NO;
    }

    MPosOperation *operation = [[MPosOperation alloc] initWithRequest:new EndOfDayRequestCommand()
                                                           connection:connection
                                                     resultsProcessor:self
                                                         sharedSecret:self.sharedSecret];
    isTransactionResultPending = NO;
    return [self postOperationToQueueIfNew:operation];
}

- (BOOL)financeInit
{
    if(isWaitingIdleResponse)
    {
        LOG_RELEASE(Logger::eInfo, @"Device is busy, please retry after a short wait.");
        return NO;
    }

    MPosOperation *operation = [[MPosOperation alloc] initWithRequest:new FinanceInitRequestCommand()
                                                           connection:connection
                                                     resultsProcessor:self
                                                         sharedSecret:self.sharedSecret];
    isTransactionResultPending = NO;
    return [self postOperationToQueueIfNew:operation];
}

- (BOOL)logSetLevel:(eLogLevel)level
{
    if(isWaitingIdleResponse)
    {
        LOG_RELEASE(Logger::eInfo, @"Device is busy, please retry after a short wait.");
        return NO;
    }
    MPosOperation *operation = [[MPosOperation alloc] initWithRequest:new SetLogLevelRequestCommand(level)
                                                           connection:connection
                                                     resultsProcessor:self
                                                         sharedSecret:self.sharedSecret];
    return [self postOperationToQueueIfNew:operation];
}

- (BOOL)logReset
{
    if(isWaitingIdleResponse)
    {
        LOG_RELEASE(Logger::eInfo, @"Device is busy, please retry after a short wait.");
        return NO;
    }
    MPosOperation *operation = [[MPosOperation alloc] initWithRequest:new ResetLogInfoRequestCommand()
                                                           connection:connection
                                                     resultsProcessor:self
                                                         sharedSecret:self.sharedSecret];
    return [self postOperationToQueueIfNew:operation];
}

- (BOOL)logGetInfo
{
    if(isWaitingIdleResponse)
    {
        LOG_RELEASE(Logger::eInfo, @"Device is busy, please retry after a short wait.");
        return NO;
    }
    MPosOperation *operation = [[MPosOperation alloc] initWithRequest:new GetLogInfoRequestCommand()
                                                           connection:connection
                                                     resultsProcessor:self
                                                         sharedSecret:self.sharedSecret];
    return [self postOperationToQueueIfNew:operation];
}

- (void)acceptSignature:(BOOL)flag
{
    [signLock lock];
    signatureIsOk = flag;
    [signLock unlockWithCondition:eSignCondition];
}

- (BOOL)getEMVConfiguration
{
    LOG(@"MpedDevice getEMVConfiguration");

    if(isWaitingIdleResponse)
    {
        LOG_RELEASE(Logger::eInfo, @"Device is busy, please retry after a short wait.");
        return NO;
    }
    NSString *params = [self generateXMLFromDictionary:@{@"getReport": @{@"name": @"EMVConfiguration"}}
                                          appendHeader:YES];

    XMLCommandRequestCommand *xcr = new XMLCommandRequestCommand(std::string([params UTF8String]));
    MPosOperation *operation = [[MPosOperation alloc] initWithRequest:xcr
                                                           connection:connection
                                                     resultsProcessor:self
                                                         sharedSecret:self.sharedSecret];

    return [self postOperationToQueueIfNew:operation];
}


#pragma mark -

- (NSDictionary *)getValuesFromXml:(NSString *)xml path:(NSString *)path
{
    NSData *xmlData = [[NSData alloc] initWithBytesNoCopy:(void *) [xml UTF8String]
                                                   length:[xml length]
                                             freeWhenDone:NO];

    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:xmlData];
    ResponseParser *parser = [[ResponseParser alloc] initWithPath:path];
    xmlParser.delegate = parser;
    [xmlParser parse];
    return parser.result;
}

#pragma mark IResponseProcessor

- (void)sendScannerEvent:(NSString *)status code:(int)code xml:(NSDictionary *)xml
{
    ScannerEventResponse *info = [ScannerEventResponse new];
    info.statusCode = code;
    info.status = xml ? xml[@"StatusMessage"] : status;
    info.scanCode = xml ? xml[@"code"] : @"";

    LOG_RELEASE(Logger::eFine, @"%@", info.scanCode);

    if ([delegate respondsToSelector:@selector(responseScannerEvent:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            id <HeftStatusReportDelegate> tmp = self->delegate;
            [tmp responseScannerEvent:info];
        });
    }
}

- (void)sendEnableScannerResponse:(NSString *)status code:(int)code xml:(NSDictionary *)xml
{
    LOG_RELEASE(Logger::eFine, @"Scanner disabled");

    if ([delegate respondsToSelector:@selector(responseScannerDisabled:)])
    {
        ScannerDisabledResponse *info = [ScannerDisabledResponse new];
        info.statusCode = code;
        info.status = xml ? xml[@"StatusMessage"] : status;
        info.xml = xml;
        isScanning = NO;
        dispatch_async(dispatch_get_main_queue(), ^
        {
            id <HeftStatusReportDelegate> tmp = self->delegate;
            [tmp responseScannerDisabled:info];
        });
    }

    cancelAllowed = NO;
}

- (void)sendResponseInfo:(NSString *)status code:(int)code xml:(NSDictionary *)xml
{
    ResponseInfoObject *info = [ResponseInfoObject new];
    info.statusCode = code;
    info.status = xml ? xml[@"StatusMessage"] : status;
    info.xml = xml;
    LOG_RELEASE(Logger::eFine, @"%@", info.status);
    dispatch_async(dispatch_get_main_queue(), ^
    {
        id <HeftStatusReportDelegate> tmp = self->delegate;
        LOG_RELEASE(Logger::eFine, @"calling responseStatus");
        [tmp responseStatus:info];
    });
    //cancelAllowed is already set in the caller
}

- (void)sendResponseError:(NSString *)status
{
    ResponseInfoObject *info = [ResponseInfoObject new];
    info.status = status;
    LOG_RELEASE(Logger::eFine, @"sendResponseError: %@", status);

    dispatch_async(dispatch_get_main_queue(), ^
    {
        id <HeftStatusReportDelegate> tmp = self->delegate;
        [tmp responseError:info];
    });
    cancelAllowed = NO;
}

- (void)sendReportResult:(NSString *)report
{
    if ([delegate respondsToSelector:@selector(responseEMVReport:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            id <HeftStatusReportDelegate> tmp = self->delegate;
            [tmp responseEMVReport:report];
        });
    }
    else
    {
        LOG_RELEASE(Logger::eFine,
                @"%@", @"responseEMVReport not implemented in delegate. Report not returned to client");
    }
}

- (int)processSign:(SignatureRequestCommand *)pRequest
{
    int result = EFT_PP_STATUS_PROCESSING_ERROR;

    // note: cancelAllowed = NO; // is not needed here as the card reader will send us a status message with the flag set correctly just before
    dispatch_async(dispatch_get_main_queue(), ^
    {
        id <HeftStatusReportDelegate> tmp = self->delegate;
        [tmp requestSignature:@(pRequest->GetReceipt().c_str())];
    });

    NSDictionary *xml = [self getValuesFromXml:@(pRequest->GetXmlDetails().c_str())
                                          path:@"SignatureRequiredRequest"];

    double wait_time = [xml[@"timeout"] doubleValue];

    if ([signLock lockWhenCondition:eSignCondition beforeDate:[NSDate dateWithTimeIntervalSinceNow:wait_time]])
    {
        result = signatureIsOk ? EFT_PP_STATUS_SUCCESS : EFT_PP_STATUS_INVALID_SIGNATURE;
        signatureIsOk = NO;
        [signLock unlockWithCondition:eNoSignCondition];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            id <HeftStatusReportDelegate> tmp = self->delegate;
            [tmp cancelSignature];
        });
    }

    return result;
}

- (void)processResponse:(ResponseCommand *)pResponse
{
    int status = pResponse->GetStatus();
    if (status != EFT_PP_STATUS_SUCCESS)
    {
        [self sendResponseInfo:statusMessages[status]
                          code:status
                           xml:nil];

#ifdef HEFT_SIMULATOR
        [NSThread sleepForTimeInterval:1.];
#endif
    }
}

- (void)processXMLCommandResponseCommand:(XMLCommandResponseCommand *)pResponse
{
    NSDictionary *xml;
    // the XML response can be of various types, here we must check the type (perhaps just best/fastest
    // to search for a string in the start of the XML response string instead of trying to parse)
    // the type of the xml is always at the top (first two lines)
    xml = [self getValuesFromXml:@(pResponse->GetXmlReturn().c_str()) path:@"enableScannerResponse"];
    if ([xml count] > 0)
    {
        int status = pResponse->GetStatus();
        NSString *statusMessage = status < ([statusMessages count] - 1) ? statusMessages[status] : @"Unknown status";
        [self sendEnableScannerResponse:statusMessage code:status xml:xml];
    }
    else
    {
        xml = [self getValuesFromXml:@(pResponse->GetXmlReturn().c_str()) path:@"getReportResponse"];
        if ([xml count] > 0)
        {
            NSString *report_data = xml[@"Data"];
            [self sendReportResult:report_data];
        }

    }

#ifdef HEFT_SIMULATOR
    [NSThread sleepForTimeInterval:1.];
#endif
}

- (void)processEventInfoResponse:(EventInfoResponseCommand *)pResponse
{
    int status = pResponse->GetStatus();
    NSString *statusMessage = status < ([statusMessages count] - 1) ? statusMessages[status] : @"Unknown status";
    NSDictionary *xml;
    if ([(xml = [self getValuesFromXml:@(pResponse->GetXmlDetails().c_str()) path:@"EventInfoResponse"]) count] > 0)
    {
        NSString *ca = xml[@"CancelAllowed"];
        cancelAllowed = (ca != nil) && [ca isEqualToString:@"true"];

        [self sendResponseInfo:statusMessage code:status xml:xml];
    }
    else if ([(xml = [self getValuesFromXml:@(pResponse->GetXmlDetails().c_str()) path:@"scannerEvent"]) count] > 0)
    {
        // the card reader scannerEvent message doesn't include a CancelAllowed flag, but we know the card reader accepts a cancel at this stage
        NSString *ca = xml[@"CancelAllowed"];
        cancelAllowed = (ca == nil) || [ca isEqualToString:@"true"]; // i.e. NO if not there or not set to "true" (e.g. if set to "false")
        [self sendScannerEvent:statusMessage code:status xml:xml];
    }
#ifdef HEFT_SIMULATOR
    [NSThread sleepForTimeInterval:1.];
#endif
    return;
}

- (void)processTokenizeCardCommandResponseCommand:(TokenizeCardCommandResponseCommand *)pResponse
{
    int status = pResponse->GetStatus();
    FinanceResponse *info = [FinanceResponse new];
     
    NSDictionary *xmlDetails = [self getValuesFromXml:@(pResponse->GetXmlDetails().c_str())
                                                 path:@"CardTokenizationResponse"];
    info.xml = xmlDetails;

    info.financialResult = [info.xml[XMLTags.FinancialStatus] integerValue];
    info.isRestarting = NO;
    info.statusCode = status;

    info.status = status == EFT_PP_STATUS_SUCCESS ? xmlDetails[@"FinancialStatus"] : xmlDetails[@"StatusMessage"];
    info.authorisedAmount = 0;
    info.transactionId = @"";
    info.customerReceipt = @"";
    info.merchantReceipt = @"";

    dispatch_async(dispatch_get_main_queue(), ^
    {
        id <HeftStatusReportDelegate> tmp = self->delegate;
        [tmp responseFinanceStatus:info];
    });

    if(pResponse->GetStatus() == EFT_PP_STATUS_SHARED_SECRET_INVALID) {
        [self financeInit];
    }
    
    cancelAllowed = NO;

#ifdef HEFT_SIMULATOR
    [NSThread sleepForTimeInterval:1.];
#endif
}

-(void)processIdleResponseCommand:(IdleResponseCommand *)pCommand
{
    isWaitingIdleResponse = NO;
    cancelAllowed = NO;
#ifdef HEFT_SIMULATOR
    [NSThread sleepForTimeInterval:1.];
#endif
}

- (void)processFinanceResponse:(FinanceResponseCommand *)pResponse
{
    int status = pResponse->GetStatus();
    FinanceResponse *info = [FinanceResponse new];
    info.financialResult = pResponse->GetFinancialStatus();
    info.isRestarting = pResponse->isRestarting();
    info.statusCode = status;
    NSDictionary *xmlDetails = [self getValuesFromXml:@(pResponse->GetXmlDetails().c_str())
                                                 path:@"FinancialTransactionResponse"];
    info.xml = xmlDetails;
    info.status = status == EFT_PP_STATUS_SUCCESS ?
            xmlDetails[@"FinancialStatus"] :
            xmlDetails[@"StatusMessage"];
    info.authorisedAmount = pResponse->GetAmount();
    info.transactionId = @(pResponse->GetTransID().c_str());
    info.customerReceipt = @(pResponse->GetCustomerReceipt().c_str());
    info.merchantReceipt = @(pResponse->GetMerchantReceipt().c_str());

    NSString *rt = xmlDetails[@"RecoveredTransaction"];
    BOOL transactionResultPending = (rt != nil) && [rt isEqualToString:@"true"];

    LOG_RELEASE(Logger::eFine, @"%@", info.status);

    // check if we have a block - if so, post that block instead of calling the event/callback
    // although it looks the same, we just call the block with parameters instead of the other

    if (!pResponse->isRecoveredTransaction())
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            id <HeftStatusReportDelegate> tmp = self->delegate;
            [tmp responseFinanceStatus:info];
        });
    }
    else
    {
        info = transactionResultPending ? info : nil;
        dispatch_async(dispatch_get_main_queue(), ^
        {
            id <HeftStatusReportDelegate> tmp = self->delegate;
            [tmp responseRecoveredTransactionStatus:info];
        });
    }
    
    if(pResponse->GetStatus() == EFT_PP_STATUS_SHARED_SECRET_INVALID) {
        [self financeInit];
    }
    
    cancelAllowed = NO;
}

- (void)processLogInfoResponse:(GetLogInfoResponseCommand *)pResponse
{
    LogInfoObject *info = [LogInfoObject new];
    int status = pResponse->GetStatus();
    info.statusCode = status;
    info.status = statusMessages[status];
    if (status == EFT_PP_STATUS_SUCCESS)
    {
        info.log = @(pResponse->GetData().c_str());
    }

    dispatch_async(dispatch_get_main_queue(), ^
    {
        id <HeftStatusReportDelegate> tmp = self->delegate;
        [tmp responseLogInfo:info];
    });

    cancelAllowed = NO;
}

- (BOOL)cancelIfPossible
{
    if (cancelAllowed)
    {
        [self cancel];
        return YES;
    }
    else
    {
        return NO;
    }
}


- (NSString *)generateXMLFromDictionary:(NSDictionary *)dictionary
                           appendHeader:(BOOL)appendHeader
{
    NSMutableString *result = [NSMutableString new];

    if (appendHeader)
    {
        [result appendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"];
    }

    for (NSString *key in dictionary.allKeys)
    {
        NSObject *obj = dictionary[key];

        if (obj)
        {
            if ([obj isKindOfClass:[NSDictionary class]])
            {
                obj = [self generateXMLFromDictionary:(NSDictionary *) obj appendHeader:NO];
            }

            [result appendFormat:@"<%@>%@</%@>", key, obj, key];
        }
    }

    return result;
}

- (BOOL)postFinanceRequestCommand:(FinanceRequestCommand *)financeRequestCommand
{
    if(isWaitingIdleResponse)
    {
        LOG_RELEASE(Logger::eInfo, @"Device is busy, please retry after a short wait.");
        return NO;
    }
    MPosOperation *operation = [[MPosOperation alloc] initWithRequest:financeRequestCommand
                                                           connection:connection
                                                     resultsProcessor:self
                                                         sharedSecret:self.sharedSecret];
    isTransactionResultPending = NO;
    return [self postOperationToQueueIfNew:operation];
}

@end
