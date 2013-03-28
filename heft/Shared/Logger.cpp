#include "StdAfx.h"
#include "Logger.h"

Logger Logger::logger;

Logger::Logger() : m_level(eFiner){
	fileName = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"release_log.txt"];
	logStr = [NSMutableString new];
}

void Logger::setFileName(NSString* filename){
	if(m_level != eOff && !fileName){
		[[NSFileManager defaultManager] removeItemAtPath:fileName error:NULL];
		fileName = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:filename];
		[logStr writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	}
}

void Logger::log(NSString* format, ...){
	va_list vlist;
	va_start(vlist, format);

	[logStr appendString:[NSDateFormatter localizedStringFromDate:[NSDate new] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle]];
	[logStr appendString:@": "];
	[logStr appendString:[[NSString alloc] initWithFormat:format arguments:vlist]];
	[logStr appendString:@"\n"];

	[logStr writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:NULL];

#ifdef DEBUG
	NSLogv(format, vlist);
#endif
}

NSString* dump(NSString* prefix, const void* const pData, int len){
	const UINT8* const p = reinterpret_cast<const UINT8* const>(pData);
	NSMutableString* result = [prefix mutableCopy];
	for(int i = 0; i < len; ++i)
		[result appendFormat:@" %02X", p[i]];
	return result;
}
