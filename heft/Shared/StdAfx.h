#pragma once

#import <string>
#import <vector>

using std::string;
using std::vector;
using std::auto_ptr;
using std::exception;

typedef UInt8 BYTE;
typedef BYTE* LPBYTE;
typedef UInt8 UINT8;
typedef const char *PCSTR;
typedef PCSTR LPCSTR;
typedef char* LPSTR;
typedef unsigned short USHORT;
typedef short SHORT;
typedef UInt16 UINT16;
typedef UInt32 UINT32;
typedef SInt32 INT32;
typedef SInt64 __int64;

#define ATLASSERT(x) NSCAssert(x, @"ATLASSERT")
//#define makechar(x) #@x
//#define makemacro(x) makechar(x)
#define makestr(x) #x
#define makemacro1(x) (makestr(x)[0])
#define makemacro2(x) (*((UINT16*)makestr(x)))
#define makemacro4(x) (*((UINT32*)makestr(x)))

#include "atl.h"

#define dim(str) (sizeof(str) / sizeof(str[0]))
//#define LOG_RELEASE(x, ...) NSLog(__VA_ARGS__)
#define _T(x) @ x

//NSString* dump(NSString* prefix, const void* const pData, int len);
#import "Logger.h"
#import "Exception.h"
