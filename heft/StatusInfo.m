#import "StatusInfo.h"
#import "XMLTags.h"
#import "CmdIds.h"

//TODO add method calls for the XML methods
@implementation StatusInfo

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
                        statusCode:(int)statusCode
{
    NSMutableDictionary *extendedDictionary = [dictionary mutableCopy];
    extendedDictionary[XMLTags.StatusCode] = @(statusCode);
    
    return [self initWithDictionary:extendedDictionary];
}
    
- (BOOL)cancelAllowed
{
    return [[self dictionary][XMLTags.StatusCode] boolValue];
}

- (int)status
{
    NSString *transactionStatus = [self dictionary][XMLTags.StatusCode];
    return [transactionStatus intValue];
}
    
- (NSString *)statusString
{
    switch (self.status)
    {
        case EFT_PP_STATUS_SUCCESS: return @"Success";
        case EFT_PP_STATUS_INVALID_DATA: return @"InvalidData";
        case EFT_PP_STATUS_PROCESSING_ERROR: return @"ProcessingError";
        case EFT_PP_STATUS_COMMAND_NOT_ALLOWED: return @"CommandNotAllowed";
        case EFT_PP_STATUS_NOT_INITIALISED: return @"NotInitialised";
        case EFT_PP_STATUS_CONNECT_TIMEOUT: return @"ConnectTimeout";
        case EFT_PP_STATUS_CONNECT_ERROR: return @"ConnectError";
        case EFT_PP_STATUS_SENDING_ERROR: return @"SendingError";
        case EFT_PP_STATUS_RECEIVING_ERROR: return @"ReceivingError";
        case EFT_PP_STATUS_NO_DATA_AVAILABLE: return @"NoDataAvailable";
        case EFT_PP_STATUS_TRANS_NOT_ALLOWED: return @"TransactionNotAllowed";
        case EFT_PP_STATUS_UNSUPPORTED_CURRENCY: return @"UnsupportedCurrency";
        case EFT_PP_STATUS_NO_HOST_AVAILABLE: return @"NoHostAvailable";
        case EFT_PP_STATUS_CARD_READER_ERROR: return @"CardReaderError";
        case EFT_PP_STATUS_CARD_READING_FAILED: return @"CardReadingFailed";
        case EFT_PP_STATUS_INVALID_CARD: return @"InvalidCard";
        case EFT_PP_STATUS_INPUT_TIMEOUT: return @"InputTimeout";
        case EFT_PP_STATUS_USER_CANCELLED: return @"UserCancelled";
        case EFT_PP_STATUS_INVALID_SIGNATURE: return @"InvalidSignature";
        case EFT_PP_STATUS_WAITING_CARD: return @"WaitingForCard";
        case EFT_PP_STATUS_CARD_INSERTED: return @"CardInserted";
        case EFT_PP_STATUS_APPLICATION_SELECTION: return @"ApplicationSelection";
        case EFT_PP_STATUS_APPLICATION_CONFIRMATION: return @"ApplicationConfirmation";
        case EFT_PP_STATUS_AMOUNT_VALIDATION: return @"AmountValidation";
        case EFT_PP_STATUS_PIN_INPUT: return @"PinInput";
        case EFT_PP_STATUS_MANUAL_CARD_INPUT: return @"ManualCardInput";
        case EFT_PP_STATUS_WAITING_CARD_REMOVAL: return @"WaitingForCardRemoval";
        case EFT_PP_STATUS_TIP_INPUT: return @"TipInput";
        case EFT_PP_STATUS_SHARED_SECRET_INVALID: return @"SharedSecretInvalid";
        case EFT_PP_STATUS_SHARED_SECRET_AUTH: return @"SharedSecretAuth";
        case EFT_PP_STATUS_WAITING_SIGNATURE: return @"WaitingSignature";
        case EFT_PP_STATUS_CONNECTING: return @"WaitingHostConnect";
        case EFT_PP_STATUS_SENDING: return @"WaitingHostSend";
        case EFT_PP_STATUS_RECEIVEING: return @"WaitingHostReceive";
        case EFT_PP_STATUS_DISCONNECTING: return @"WaitingHostDisconnect";
        case EFT_PP_STATUS_PIN_INPUT_COMPLETED: return @"PinInputCompleted";
        case EFT_PP_STATUS_POS_CANCELLED: return @"PosCancelled";
        case EFT_PP_STATUS_REQUEST_INVALID: return @"RequestInvalid";
        case EFT_PP_STATUS_CARD_CANCELLED: return @"CardCancelled";
        case EFT_PP_STATUS_CARD_BLOCKED: return @"CardBlocked";
        case EFT_PP_STATUS_REQUEST_AUTH_TIMEOUT: return @"RequestAuthTimeout";
        case EFT_PP_STATUS_REQUEST_PAYMENT_TIMEOUT: return @"RequestPaymentTimeout";
        case EFT_PP_STATUS_RESPONSE_AUTH_TIMEOUT: return @"ResponseAuthTimeout";
        case EFT_PP_STATUS_RESPONSE_PAYMENT_TIMEOUT: return @"ResponsePaymentTimeout";
        case EFT_PP_STATUS_ICC_CARD_SWIPED: return @"IccCardSwiped";
        case EFT_PP_STATUS_REMOVE_CARD: return @"RemoveCard";
        case EFT_PP_STATUS_SCANNER_IS_NOT_SUPPORTED: return @"ScannerIsNotSupported";
        case EFT_PP_STATUS_SCANNER_EVENT: return @"ScannerEvent";
        case EFT_PP_STATUS_BATTERY_TOO_LOW: return @"BatteryTooLow";
        case EFT_PP_STATUS_ACCOUNT_TYPE_SELECTION: return @"AccountTypeSelection";
        case EFT_PP_STATUS_BT_IS_NOT_SUPPORTED: return @"BtIsNotSupported";
        case EFT_PP_STATUS_PAYMENT_CODE_SELECTION: return @"PaymentCodeSelection";
        case EFT_PP_STATUS_PARTIAL_APPROVAL: return @"PartialApproval";
        case EFT_PP_STATUS_AMOUNT_DUE_VALIDATION: return @"AmountDueValidation";
        case EFT_PP_STATUS_INVALID_URL: return @"InvalidUrl";
        case EFT_PP_STATUS_WAITING_CUSTOMER_RECEIPT: return @"WaitingCustomerReceipt";
        case EFT_PP_STATUS_PRINTING_MERCHANT_RECEIPT: return @"PrintingMerchantReceipt";
        case EFT_PP_STATUS_PRINTING_CUSTOMER_RECEIPT: return @"PrintingCustomerReceipt";
        case EFT_PP_STATUS_WAITING_HOST_MSG_TO_HOST: return @"WaitingHostMessageRequest";
        case EFT_PP_STATUS_WAITING_HOST_MSG_RESP: return @"WaitingHostMessageResponse";
        case EFT_PP_STATUS_INITIALISATION_COMPLETE: return @"InitialisationComplete";
        default:
        return [NSString stringWithFormat:@"Status: %@", @(self.status)];
    }
}

- (NSString *)message
{
    return [self dictionary][XMLTags.StatusMessage] ?: @"";
}

- (DeviceStatus *)deviceStatus
{
    return [[DeviceStatus alloc] initWithDictionary:[self dictionary]];
}

@end
