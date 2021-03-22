
#import "XMLTags.h"

@implementation XMLTags

//TODO create static versions of the strings
//The type of transaction performed
+ (NSString *)TransactionType
{
    return @"TransactionType";
}

//The result of the transaction:
+ (NSString *)FinancialStatus
{
    return @"FinancialStatus";
}

//The amount requested by the POS, as requested by the POS (i.e. no decimal point).
+ (NSString *)RequestedAmount
{
    return @"RequestedAmount";
}

//The gratuity amount entered by the cardholder, if any.
+ (NSString *)GratuityAmount
{
    return @"GratuityAmount";
}

//The gratuity amount, as a percentage of the requested amount.
+ (NSString *)GratuityPercentage
{
    return @"GratuityPercentage";
}

//The total of the gratuity and requested amount.
+ (NSString *)TotalAmount
{
    return @"TotalAmount";
}

//The currency code used for the transaction.
+ (NSString *)Currency
{
    return @"Currency";
}

//The transaction number used for this transaction, as maintained by the Eft Client.
+ (NSString *)TransactionID
{
    return @"TransactionID";
}

//The EFT reference, given by the system, to make the transaction unique.
+ (NSString *)EFTTransactionID
{
    return @"EFTTransactionID";
}

//he original EFT reference, given by the POS, as part of a VOID_SALE or a VOID_REFUND transaction.
+ (NSString *)OriginalEFTTransactionID
{
    return @"OriginalEFTTransactionID";
}

//The date and time of the transaction, in ISO format (@YYYYMMDDHHmmSS).
+ (NSString *)EFTTimestamp
{
    return @"EFTTimestamp";
}

//The transaction authorization code, as given by the system.
+ (NSString *)AuthorisationCode
{
    return @"AuthorisationCode";
}

//The Cardholder Verfication Method:
+ (NSString *)CVM
{
    return @"CVM";
}

//The card data acquisition type:
+ (NSString *)CardEntryType
{
    return @"CardEntryType";
}

//The card, reported, scheme name.
+ (NSString *)CardSchemeName
{
    return @"CardSchemeName";
}

+ (NSString *)CancelAllowed
{
    return @"CancelAllowed";
}

+ (NSString *)StatusCode
{
    return @"StatusCode";
}

//A human readable description for the returned Status.
+ (NSString *)StatusMessage
{
    return @"StatusMessage";
}

//The serial number of the PAD
+ (NSString *)SerialNumber
{
    return @"SerialNumber";
}

//A number, followed by the % sign, which indicates current charge level of the battery.
+ (NSString *)BatteryStatus
{
    return @"BatteryStatus";
}

//An integer, which represent the batter charge, in mV.
+ (NSString *)BatterymV
{
    return @"BatterymV";
}

// Indicates whether the battery is charging, or not. Values are true or false.
+ (NSString *)BatteryCharging
{
    return @"BatteryCharging";
}

//Indicates whether the PED is connected to an external power source e.g. a AC adapter). Values are true or false.
+ (NSString *)ExternalPower
{
    return @"ExternalPower";
}

//The name of the application running on the PED.
+ (NSString *)ApplicationName
{
    return @"ApplicationName";
}

//A version string of the form “major.minor.build” e.g. “1.2.118”).
+ (NSString *)ApplicationVersion
{
    return @"ApplicationVersion";
}

// The current name used as a Bluetooth device name for this card reader during Bluetooth discovery
+ (NSString *)BluetoothName
{
    return @"BluetoothName";
}

//Description of the error, if any.
+ (NSString *)ErrorMessage
{
    return @"ErrorMessage";
}

//An optional customer reference id (ans..25). Up to 25 letters, digits, spaces and symbols allowed.
+ (NSString *)CustomerReference
{
    return @"CustomerReference";
}

//Number of months that the sale amount is to be distributed to.
+ (NSString *)BudgetNumber
{
    return @"BudgetNumber";
}

+ (NSString *)Timeout
{
    return @"timeout";
}

//A flag describing if a transaction was recovered after a com error.
+ (NSString *)RecoveredTransaction
{
    return @"RecoveredTransaction";
}

+ (NSString *)CardTypeId
{
    return @"CardTypeId";
}

// Transaction chip report for the last performed transaction
+ (NSString *)ChipTransactionReport
{
    return @"ChipTransactionReport";
}

// in case of a partial approval, this is the amount due
+ (NSString *)DueAmount
{
    return @"DueAmount";
}

+ (NSString *)BalanceAmount
{
    return @"BalanceAmount";
}

+ (NSString *)BalanceCurrency
{
    return @"BalanceCurrency";
}

+ (NSString *)BalanceSign
{
    return @"BalanceSign";
}

+ (NSString *)CardToken
{
    return @"CardToken";
}

+ (NSString *)CardTokenizationGuid
{
    return @"CardTokenizationGuid";
}

+ (NSString *)ExpiryDateMMYY
{
    return @"ExpiryDateMMYY";
}

+ (NSString *)MaskedCardNumber
{
    return @"MaskedCardNumber";
}

+ (NSString *)TenderType
{
    return @"TenderType";
}

+ (NSString *)PaymentScenario
{
    return @"paymentScenario";
}

+ (NSString *)CustomerLanguagePref
{
    return @"customerLanguagePref";
}

+ (NSString *)Mid
{
    return @"mid";
}

+ (NSString *)Tid
{
    return @"tid";
}

@end

