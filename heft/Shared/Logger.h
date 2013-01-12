#pragma once

class Logger{
public:
	enum eLevel{eAll, eFinest, eFiner, eFine, eConfig, eInfo, eWarning, eSevere, eOff};

	static Logger& instance(){return logger;}
	void setFileName(NSString* filename);
	void setLevel(eLevel level){m_level = level;}

	bool isLogable(eLevel level){return level >= m_level;}
	void log(NSString* format, ...);

private:
	static Logger logger;
	Logger();
	Logger(const Logger& arg);
	~Logger(){}
	Logger& operator =(const Logger& arg);

	NSString* fileName;
	NSMutableString* logStr;
	eLevel m_level;
};

#ifdef HEFT_SIMULATOR
#define LOG_RELEASE(level, ...) LOG(__VA_ARGS__)
#else
#define LOG_RELEASE(level, ...) if(Logger::instance().isLogable(level)) Logger::instance().log(__VA_ARGS__);
#endif

NSString* dump(NSString* prefix, const void* const pData, int len);
