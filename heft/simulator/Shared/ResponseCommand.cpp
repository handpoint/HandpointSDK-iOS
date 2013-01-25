#include "StdAfx.h"
#include "ResponseCommand.h"
#include "RequestCommand.h"

extern NSString* statusMessages[];

bool ResponseCommand::isResponseTo(const RequestCommand& request){
	return command_hsb == request.GetType();
}

EventInfoResponseCommand::EventInfoResponseCommand(int status) 
	: ResponseCommand(CMD_STAT_INFO_RSP, status)
{
	xml_details = [[NSString stringWithFormat:@"<EventInfoResponse><StatusMessage>%@</StatusMessage><CancelAllowed>true</CancelAllowed></EventInfoResponse>", statusMessages[status]] cStringUsingEncoding:NSUTF8StringEncoding];
}

int trans_id_seed = 1;
NSString* fin_type[] = {@"Sale", @"Refund", @"Sale void", @"Refund void", @"Start day", @"End day", @"Finance init"};

FinanceResponseCommand::FinanceResponseCommand(UINT32 cmd, UINT32 amount, eTransactionStatus status) 
	: ResponseCommand(cmd), 
	financial_status(status), authorised_amount(amount)
{
	static NSString* fin_status[] = {@"", @"Approved", @"Declined", @"Processed", @"Not Processed"};

	trans_id = [[NSString stringWithFormat:@"transactID%d", trans_id_seed++] cStringUsingEncoding:NSUTF8StringEncoding];

	NSString* buf = [NSString stringWithFormat:@"<p>Financial transaction #<b>%s</b></p>"
					"<p>Type: <b>%@</b></p>"
					"<p>Status: <b>%@</b></p>"
					"<p>Time: <b>%@</b></p>"
					"<p>Amount: <b>%.2f</b></p>"
					"<p>Card number: <b>**** **** **** ****</b></p>"
					, trans_id.c_str()
					, fin_type[(cmd >> 8) & 0xf]
					, fin_status[status]
					, [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle]
					, double(amount / 100)];
	merchant_receipt = [buf cStringUsingEncoding:NSUTF8StringEncoding];
	customer_receipt = merchant_receipt;

	xml_details = [[NSString stringWithFormat:@"<FinancialTransactionResponse><FinancialStatus>%@</FinancialStatus></FinancialTransactionResponse>", fin_status[status]] cStringUsingEncoding:NSUTF8StringEncoding];
}

FinanceResponseCommand::FinanceResponseCommand(UINT32 cmd, UINT32 amount, int status)
	: ResponseCommand(cmd, status),
	financial_status(eTransactionNotProcessed), authorised_amount(amount)
{
	trans_id = [[NSString stringWithFormat:@"transactID%d", trans_id_seed++] cStringUsingEncoding:NSUTF8StringEncoding];
	
	NSString* buf = [NSString stringWithFormat:@"<p>Financial transaction #<b>%s</b></p>"
					 "<p>Type: <b>%@</b></p>"
					 "<p>Status: <b>Not Processed</b></p>"
					 "<p>Time: <b>%@</b></p>"
					 "<p>Amount: <b>%.2f</b></p>"
					 "<p>Card number: <b>**** **** **** ****</b></p>"
					 , trans_id.c_str()
					 , fin_type[(cmd >> 8) & 0xf]
					 , [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle]
					 , double(amount / 100)];
	merchant_receipt = [buf cStringUsingEncoding:NSUTF8StringEncoding];
	customer_receipt = merchant_receipt;
	
	xml_details = [@"<FinancialTransactionResponse><StatusMessage>User Cancelled</StatusMessage></FinancialTransactionResponse>" cStringUsingEncoding:NSUTF8StringEncoding];
}

DebugInfoResponseCommand::DebugInfoResponseCommand() : ResponseCommand(CMD_DBG_INFO_REQ)
{
	data = "Debug info data";
}

GetLogInfoResponseCommand::GetLogInfoResponseCommand() : ResponseCommand(CMD_LOG_GET_INF_REQ)
{
	data = "Log info data";
}
