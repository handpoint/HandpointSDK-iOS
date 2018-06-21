//
// Created by Juan Nuñez on 18/12/2017.
// Copyright (c) 2017 zdv. All rights reserved.
//

#import "FinanceResponse.h"
#import "XMLTags.h"

@implementation FinanceResponse
@synthesize financialResult, isRestarting, authorisedAmount,
transactionId, customerReceipt, merchantReceipt;

- (NSString *)statusMessage
{
    return self.xml[XMLTags.StatusMessage] ?: @"";
}

- (NSString *)type
{
    return self.xml[XMLTags.TransactionType] ?: @"";
}

- (NSString *)finStatus
{
    return self.xml[XMLTags.FinancialStatus] ?: @"";
}

- (NSString *)requestedAmount
{
    return self.xml[XMLTags.RequestedAmount] ?: @"0";
}

- (NSString *)gratuityAmount
{
    return self.xml[XMLTags.GratuityAmount] ?: @"0";
}

- (NSString *)gratuityPercentage
{
    return self.xml[XMLTags.GratuityPercentage] ?: @"0%";
}

- (NSString *)totalAmount
{
    return self.xml[XMLTags.TotalAmount] ?: @"0";
}

- (NSString *)currency
{
    return self.xml[XMLTags.Currency] ?: @"Unknown";
}

- (NSString *)eFTTransactionID
{
    return self.xml[XMLTags.EFTTransactionID] ?: @"";
}

- (NSString *)originalEFTTransactionID
{
    return self.xml[XMLTags.OriginalEFTTransactionID] ?: @"";
}

- (NSString *)eFTTimestamp
{
    return self.xml[XMLTags.EFTTimestamp] ?: @"";
}

- (NSString *)authorisationCode
{
    return self.xml[XMLTags.AuthorisationCode] ?: @"";
}

- (NSString *)verificationMethod
{
    return self.xml[XMLTags.CVM] ?: @"";
}

- (NSString *)cardEntryType
{
    return self.xml[XMLTags.CardEntryType] ?: @"";
}

- (NSString *)cardSchemeName
{
    return self.xml[XMLTags.CardSchemeName] ?: @"";
}

- (NSString *)errorMessage
{
    return self.xml[XMLTags.ErrorMessage] ?: @"";
}

- (NSString *)customerReference
{
    return self.xml[XMLTags.CustomerReference] ?: @"";
}

- (NSString *)budgetNumber
{
    return self.xml[XMLTags.BudgetNumber] ?: @"";
}

- (BOOL)recoveredTransaction
{
    NSString *recoveredTransaction = self.xml[XMLTags.RecoveredTransaction];
    return (recoveredTransaction) ? [recoveredTransaction boolValue] : NO;
}

- (NSString *)cardTypeId
{
    return self.xml[XMLTags.CardTypeId] ?: @"";
}

- (DeviceStatus *)deviceStatus
{
    return [[DeviceStatus alloc] initWithDictionary:self.xml];
}

- (NSString *)chipTransactionReport
{
    return self.xml[XMLTags.ChipTransactionReport] ?: @"";
}

- (NSString *)dueAmount
{
    return self.xml[XMLTags.DueAmount] ?: @"0";
}

- (NSString *)balance
{
    return self.xml[XMLTags.BalanceAmount] ?: @"0";
}

- (NSString *)cardToken
{
    return self.xml[XMLTags.CardToken] ?: @"";
}


- (NSDictionary *)toDictionary
{
    return @{
             @"statusMessage": self.statusMessage,
             @"type": self.type,
             @"finStatus": self.finStatus,
             @"requestedAmount": self.requestedAmount,
             @"gratuityAmount": self.gratuityAmount,
             @"gratuityPercentage": self.gratuityPercentage,
             @"totalAmount": self.totalAmount,
             @"currency": self.currency,
             @"transactionID": self.transactionId,
             @"eFTTransactionID": self.eFTTransactionID,
             @"originalEFTTransactionID": self.originalEFTTransactionID,
             @"eFTTimestamp": self.eFTTimestamp,
             @"authorisationCode": self.authorisationCode,
             @"verificationMethod": self.verificationMethod,
             @"cardEntryType": self.cardEntryType,
             @"cardSchemeName": self.cardSchemeName,
             @"errorMessage": self.errorMessage,
             @"customerReference": self.customerReference,
             @"budgetNumber": self.budgetNumber,
             @"recoveredTransaction": @(self.recoveredTransaction),
             @"cardTypeId": self.cardTypeId,
             @"merchantReceipt": self.merchantReceipt,
             @"customerReceipt": self.customerReceipt,
             @"deviceStatus": self.deviceStatus.toDictionary,
             @"chipTransactionReport": self.chipTransactionReport,
             @"dueAmount": self.dueAmount,
             @"balance": self.balance
             };
}

@end
