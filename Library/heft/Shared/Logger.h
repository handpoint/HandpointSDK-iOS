#pragma once

#include <Foundation/Foundation.h>

class Logger
{
public:
	enum eLevel{eAll, eFinest, eFiner, eFine, eConfig, eInfo, eWarning, eSevere, eOff};

	static Logger& instance(){
        return logger;
    }
	
    void setFileName(NSString* filename);
	
    void setLevel(eLevel level) {m_level = level;}

	bool isLogable(eLevel level)
    {
        return level >= m_level;
    }
    
	void log(NSString* format, ...);

private:
	static Logger logger;
	Logger();
	Logger(const Logger& arg);
	~Logger(){}
	Logger& operator =(const Logger& arg);

	eLevel m_level;
};


// Objective C rewrite would look something like this, with a C++ wrapper
/*
typedef NS_ENUM(NSUInteger, eLevel) {eAll, eFinest, eFiner, eFine, eConfig, eInfo, eWarning, eSevere, eOff};

@interface HPLogger : NSObject
+ (id) instance;
- (void) setFileName:(NSString*)fileName;
- (void) setLevel:(eLevel)level;
- (BOOL) isLogable:(eLevel)level;
- (void) log:(NSString*)format, ...;

@property NSString *fileName;
@property eLevel level;
 */


NSString* dump(NSString* prefix, const void* const pData, int len);



#ifdef HEFT_SIMULATOR
#define LOG_RELEASE(level, ...) LOG(__VA_ARGS__)
#else
#ifdef DEBUG
#define LOG_RELEASE(level, ...) if(Logger::instance().isLogable(level)) Logger::instance().log(__VA_ARGS__);
#else
#define LOG_RELEASE(level, ...)
#endif
#endif
