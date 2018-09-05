// #include "StdAfx.h"

#include "Logger.h"
#include <cstdint>


Logger Logger::logger;

Logger::Logger()
{
#ifdef DEBUG
    m_level = eAll;
#else
    m_level = eInfo;
#endif
}

void Logger::setFileName(NSString* filename)
{
}

void Logger::log(NSString* format, ...)
{
#ifdef DEBUG
    
	va_list vlist;
	va_start(vlist, format);
    NSMutableString* logStr = [NSMutableString new];
    
	[logStr appendString:[NSDateFormatter localizedStringFromDate:[NSDate new] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle]];
	[logStr appendString:@": "];
	[logStr appendString:[[NSString alloc] initWithFormat:format arguments:vlist]];
	[logStr appendString:@"\n"];


	NSLogv(format, vlist);
#endif
}

NSString* dump(NSString* prefix, const void* const pData, int len)
{
    const std::uint8_t* const p = reinterpret_cast<const std::uint8_t* const>(pData);
	NSMutableString* result = [prefix mutableCopy];
	for(int i = 0; i < len; ++i)
		[result appendFormat:@" %02X", p[i]];
	return result;
}
