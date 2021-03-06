
#ifdef HEFT_SIMULATOR

#include "ResponseCommand.h"
#include "RequestCommand.h"
#import "XMLTags.h"

#include <cstdint>

using std::uint32_t;
using std::uint8_t;


extern NSArray* statusMessages;

bool ResponseCommand::isResponseTo(const RequestCommand& request){
    return command_hsb == request.GetType();
}

NSString * ConvertDictionaryToXMLRecursive(NSDictionary* dict, NSString* root)
{
    NSMutableString* retval = [[NSMutableString alloc] init];

    // Note: we have no guard against recursive inclusion of dictionaries
    for(NSString* key in dict)
    {
        id value = dict[key];
        
        if([value isKindOfClass:[NSDictionary class]])
        {
            value = ConvertDictionaryToXMLRecursive(value, key);
        }
        
        [retval appendString:[NSString stringWithFormat:@"<%@>%@</%@>", key, value, key]];
    }
    
    return retval;
}

string ConvertDictionaryToXML(NSDictionary* dict, NSString* root)
{
    NSMutableString* retval = [[NSMutableString alloc] init];

    [retval appendString:[NSString stringWithFormat:@"<%@>", root]];
    [retval appendString:ConvertDictionaryToXMLRecursive(dict, root)];
    [retval appendString:[NSString stringWithFormat:@"</%@>", root]];
    
    return [retval cStringUsingEncoding:NSUTF8StringEncoding];
}

EventInfoResponseCommand::EventInfoResponseCommand(int status, bool cancel_allowed)
	: ResponseCommand(EFT_PACKET_EVENT_INFO_RESP, status)
{
    NSMutableDictionary* xmlDict = [[NSMutableDictionary alloc] init];
    
    // Basic (always) tags
    xmlDict[@"BatteryCharging"]     = @"false";
    xmlDict[@"BatteryStatus"]       = @"57%";
    xmlDict[@"BatterymV"]           = @"3800";
    xmlDict[@"ExternalPower"]       = @"false";
    
    // event info specific tags
    xmlDict[@"StatusMessage"]       = status < [statusMessages count] ? statusMessages[status]
                                                                      :  @"Unknown status";
    xmlDict[@"CancelAllowed"]       = cancel_allowed ? @"true" : @"false";
    
    xml_details = ConvertDictionaryToXML(xmlDict, @"EventInfoResponse");
}

NSString* kTransIdSeedKey = @"last_trans_id";
NSString* fin_type[] = {@"Sale", @"Refund", @"Sale void", @"Refund void", @"Start day", @"End day", @"Finance init", @"Recovered Transaction"};
NSString* fin_type_transaction[] = {@"SALE", @"REFUND", @"VOID_SALE", @"VOID_REFUND", @"Start day", @"End day", @"HOST_INIT", @"RECOVER_TXN_RESULT"};

FinanceResponseCommand::FinanceResponseCommand(uint32_t cmd, const string& aCurrency, uint32_t amount, uint8_t status, BOOL recoveredTransaction)
	: ResponseCommand(cmd), 
	financial_status(status), authorised_amount(amount), trans_id(simulatorState.getTransUID())
    , recovered_transaction(recoveredTransaction)
{
    NSDateFormatter* iso_time = [[NSDateFormatter alloc] init];
    [iso_time setDateFormat:@"yyyyMMddHHmmss"];
    
    NSMutableDictionary* xmlDict = [[NSMutableDictionary alloc] init];
    
    // Basic (always) tags
    xmlDict[@"BatteryCharging"]     = @"false";
    xmlDict[@"BatteryStatus"]       = @"57%";
    xmlDict[@"BatterymV"]           = @"3800";
    xmlDict[@"ExternalPower"]       = @"false";
    
    // Financial transaction specific tags
    xmlDict[@"StatusMessage"]       = status < [statusMessages count] ? statusMessages[status]
                                                                      :  @"Unknown status";
    xmlDict[@"TransactionType"]     = fin_type_transaction[((cmd >> 8) & 0xff) - '0'];

    bool signature = simulatorState.isIcc() ? false : true;
    
    switch (cmd) {
        case EFT_PACKET_RECOVERED_TXN_RESULT:
            
            if(!simulatorState.isInException())
            {
                // Finance result specific tags
                xmlDict[@"ApplicationName"]     = @"mPOS";
                xmlDict[@"ApplicationVersion"]  = @"1.7.1.151";
                xmlDict[@"CVM"]                 = @"UNDEFINED";
                xmlDict[@"CardEntryType"]       = @"UNDEFINED";
                xmlDict[@"FinancialStatus"]     = @"FAILED";
                xmlDict[@"SerialNumber"]        = @"123400123";
                
                break;
            }
            
            xmlDict[@"TransactionType"]     = fin_type_transaction[((simulatorState.getType() >> 8) & 0xff) - '0'];
            
            // fallthrough
        default:
        case EFT_PACKET_SALE_VOID:
        case EFT_PACKET_REFUND_VOID:
        case EFT_PACKET_SALE:
        case EFT_PACKET_REFUND:
            
            merchant_receipt = !(signature && simulatorState.isAuthorized()) ? simulatorState.generateReceipt(true) : string(); // signature receipt will already have been delivered
            customer_receipt = simulatorState.generateReceipt(false);
            
            xmlDict[@"StatusMessage"]       = simulatorState.isAuthorized() ? [NSString stringWithFormat:@"AUTH CODE %05ld", (long)(simulatorState.getAuthCode())] : @"DECLINED"; // @"AUTH CODE 005354"; // variable

            // Finance result specific tags
            xmlDict[@"ApplicationName"]     = @"Simulator";
            xmlDict[@"ApplicationVersion"]  = @"1.7.1.151";
            xmlDict[@"BatchNumber"]         = @"8";
            xmlDict[@"EFTTimestamp"]        = [iso_time stringFromDate:[NSDate date]]; //@"20141212094555"; // variable
            xmlDict[@"SerialNumber"]        = @"123400123";
            
            if((cmd == EFT_PACKET_SALE_VOID) || (cmd == EFT_PACKET_REFUND_VOID))
            {
                if(simulatorState.isAuthorized())
                {
                    xmlDict[@"OriginalEFTTransactionID"] = [NSString stringWithUTF8String:simulatorState.getOrgTransUID().c_str()]; // @"ec174bfe-5aaa-4192-840f-c9a18666914b"; // variable (ON REVERSAL)
                }
            }
            else
            {
                xmlDict[@"CVM"]                 = signature ? @"SIGNATURE" : @"PIN"; // variable
                xmlDict[@"CardEntryType"]       = simulatorState.isIcc() ? @"ICC" : @"MSR";
                xmlDict[@"CardSchemeName"]      = @"MASTERCARD";
                xmlDict[@"CardTypeId"]          = @"3000";
                xmlDict[@"Currency"]            = [NSString stringWithUTF8String:aCurrency.c_str()]; // @"826"; // variable
                xmlDict[@"RequestedAmount"]     = [NSString stringWithFormat:@"%u", (unsigned int)(simulatorState.getAmount())];//@"100"; // variable
                xmlDict[@"TotalAmount"]         = [NSString stringWithFormat:@"%u", (unsigned int)(simulatorState.getAmount())];//@"100"; // variable
            }
            
            xmlDict[@"FinancialStatus"]     = simulatorState.isAuthorized() ? @"AUTHORISED" : @"DECLINED"; // variable

            if(simulatorState.isAuthorized())
            {
                xmlDict[@"FinancialStatus"]     = @"AUTHORISED"; // variable
                xmlDict[@"AuthorisationCode"]   = [NSString stringWithFormat:@"%05ld", (long)(simulatorState.getAuthCode())];//@"005354"; // variable
                xmlDict[@"TransactionID"]       = [NSString stringWithFormat:@"%ld", (long)(simulatorState.trans_id())]; //@"9268"; // variable
                xmlDict[@"EFTTransactionID"]    = [NSString stringWithUTF8String:simulatorState.getTransUID().c_str()];// @"6dc8d0ff-b49a-4f57-8ed7-5ef5d1cb1d1e"; // variable
            }
            else
            {
                xmlDict[@"FinancialStatus"]     = status == EFT_PP_STATUS_USER_CANCELLED ? @"CANCELLED" : @"DECLINED"; // variable
            }
            
            if(recoveredTransaction)
            {
                xmlDict[@"RecoveredTransaction"] = @"true";
            }
            
            break;

        case EFT_PACKET_START_DAY:
        case EFT_PACKET_END_DAY:
        case EFT_PACKET_HOST_INIT:
            
            // note: no status message is included as a result of these functions
            [xmlDict removeObjectForKey:@"StatusMessage"];
            
            xmlDict[@"CVM"]                 = @"UNDEFINED";
            xmlDict[@"CardEntryType"]       = @"UNDEFINED";
            xmlDict[@"FinancialStatus"]     = @"PROCESSED";
            
            break;
    }

    xml_details = ConvertDictionaryToXML(xmlDict, @"FinancialTransactionResponse");
}

TokenizeCardCommandResponseCommand::TokenizeCardCommandResponseCommand()
: ResponseCommand(EFT_PACKET_TOKENIZE_CARD_RESP)
{
    NSDictionary *xmlDict =  @{
                               XMLTags.StatusMessage: @"Card Token Success",
                               XMLTags.TransactionType: @"TOKENIZE_CARD",
                               XMLTags.FinancialStatus: @"AUTHORISED",
                               XMLTags.EFTTimestamp: @"20181114151925",
                               XMLTags.CardEntryType : @"MSR",
                               XMLTags.SerialNumber: @"918900602",
                               XMLTags.BatteryStatus: @"100",
                               XMLTags.BatterymV: @"5000",
                               XMLTags.BatteryCharging: @"false",
                               XMLTags.ExternalPower: @"true",
                               XMLTags.ApplicationName: @"mPOS",
                               XMLTags.ApplicationVersion: @"41.9.0.0",
                               XMLTags.CardToken: @"ABC4AFQQBC5UR5H",
                               XMLTags.CardTokenizationGuid: @"4c289fb0-e818-11e8-937f-8b302e5d0ae7",
                               XMLTags.ExpiryDateMMYY: @"1912",
                               XMLTags.MaskedCardNumber: @"************6427",
                               };
                            
    xml_details = ConvertDictionaryToXML(xmlDict, @"CardTokenizationResponse");
}

GetLogInfoResponseCommand::GetLogInfoResponseCommand() : ResponseCommand(EFT_PACKET_LOG_GETINFO)
{
	data = "Log info data";
}

XMLCommandResponseCommand::XMLCommandResponseCommand(int status, string xml)
    : ResponseCommand(EFT_PACKET_COMMAND, status)
    , xml_details(xml)
{
}

void SimulatorState::setAsAuthorized()
{
    _auth_code = (arc4random() % (99999 - 1000)) + 1000; // we want numbers between 1000 upto and including 99999
    _authorized = YES;
}

void SimulatorState::setAsDeclined()
{
    _auth_code = 0;
    _authorized = NO;
}

NSInteger SimulatorState::trans_id() const{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kTransIdSeedKey];
}

void SimulatorState::inc_trans_id(){
    [[NSUserDefaults standardUserDefaults] setInteger:(this->trans_id() + 1) forKey:kTransIdSeedKey];
}

string SimulatorState::generateReceipt(bool merchant_copy) const
{
    bool authorized = simulatorState.isAuthorized() ? true : false;
    bool reversal = (simulatorState.getType() == EFT_PACKET_SALE_VOID) || (simulatorState.getType() == EFT_PACKET_REFUND_VOID) ? true : false;
    bool refund = simulatorState.getType() == EFT_PACKET_REFUND ? true : false;
    bool sale = simulatorState.getType() == EFT_PACKET_SALE ? true : false;
    bool verified_by_pin = simulatorState.isIcc() ? true : false;
    bool verified_by_signature = simulatorState.isIcc() ? false : true;
    
    NSDateFormatter* day_of_month = [[NSDateFormatter alloc] init];
    [day_of_month setDateFormat:@"dd.MM.yyyy"];
    NSDateFormatter* time_of_day = [[NSDateFormatter alloc] init];
    [time_of_day setDateFormat:@"HH:mm"];
    
    NSNumberFormatter* currencyStyle = [[NSNumberFormatter alloc] init];
    [currencyStyle setNumberStyle:NSNumberFormatterDecimalStyle];
    [currencyStyle setMaximumFractionDigits:2];
    [currencyStyle setMinimumFractionDigits:2];
    
    NSString* buf = [NSString stringWithFormat:@"<html><body><div id='merchant_name'>Handpoint test</div><div id='merchant_address'>Digranesvegi 1 2h<br>200 Kópavogi<br>Iceland</div><br/>%@<div id='date'>Date: %@</div><div id='time'>Time: %@</div>%@Auth code: %@<br/>%@%@<br/><div id='receipt_owner'>%@</div><br/>Application Label: MASTERCARD<br/>Entry: ICC<br/>Card Scheme: MasterCard<br/>CardNumber: **** **** **** 0045<br/>Aid: A0000000041010<br/>APP PSN: 03<br/>{COPY_RECEIPT}<br/><div id='transaction_type'>%@</div><div id='amount_value'>%@</div>%@<br/>%@<br/>%@%@%@<br/>%@%@%@<br/><br/><div id='footer_text'>Please keep this receipt for your records</div></body></html>"
                     , merchant_copy ? @"MID: 1234567<br/>TID: 12345678<br/>" : @"MID: **34567<br/>TID: ****5678<br/>"
                     , [day_of_month stringFromDate:[NSDate date]]// @"12.12.2014"
                     , [time_of_day stringFromDate:[NSDate date]]// @"09:45"9
                     , merchant_copy && authorized ? [NSString stringWithFormat:@"Transaction No: %05ld<br/>", (long)(simulatorState.trans_id())] : @"" // variable
                     , authorized ? [NSString stringWithFormat:@"%05ld", (long)(simulatorState.getAuthCode())] : @"" // @"005354" // variable
                     , authorized ? [NSString stringWithFormat:@"Reference: %s<br/>", simulatorState.getTransUID().c_str()] : @"" // @"Reference: 6dc8d0ff-b49a-4f57-8ed7-5ef5d1cb1d1e<br/>" : @"" // variable
                     , authorized && reversal ? [NSString stringWithFormat:@"Original Reference: %s<br/>", simulatorState.getOrgTransUID().c_str()] : @""// @"Original Reference: ec174bfe-5aaa-4192-840f-c9a18666914b<br/>" : @"" // input
                     , merchant_copy ? @"** MERCHANT COPY **" : @"** CARDHOLDER COPY **"
                     , !reversal ? (sale ? @"SALE" : @"REFUND") : (simulatorState.getType() == EFT_PACKET_SALE_VOID ? @"SALE VOID" : @"REFUND VOID")
                     , [NSString stringWithFormat:@"%s%@", simulatorState.getCurrencyAbbreviation().c_str(), [currencyStyle stringFromNumber:[NSNumber numberWithDouble:(((double)simulatorState.getAmount())/100.0)]]] //[[NSNumber numberWithDouble:((double)simulatorState.getAmount())/100.0] descriptionWithLocale:[NSLocale currentLocale]]] // @"GBP1,00" // input
                     , refund ? @"Cr" : @""
                     , sale ? @"Your account will be debited with the above amount" : @"Your account will be credited with the above amount"
                     , !reversal && authorized && verified_by_pin ? @"** Cardholder PIN verified **" : @""
                     , !reversal && authorized && verified_by_pin && verified_by_signature ? @"<br/>" : @""
                     , !reversal && authorized && verified_by_signature ? @"** Verified by signature **" : @""
                     , !reversal && authorized && ((verified_by_signature && merchant_copy) || (!merchant_copy && refund)) ? @"<br/><br/><br/><br/>--------------------------------<br/>" : @""
                     , !reversal && authorized && verified_by_signature && merchant_copy ? @"Cardholder signature<br/>" : (!reversal && authorized && !merchant_copy && refund ? @"Merchant signature<br/>" : @"")
                     , authorized ? (sale ? @"** AUTHORISED **" : (refund ? @"** REFUND ACCEPTED **" : @"** REVERSAL ACCEPTED **" )) : @"** DECLINED **"
                     ];
    return [buf cStringUsingEncoding:NSUTF8StringEncoding];
}

#endif
