#pragma once

#include <stdint.h>


typedef uint8_t BYTE;
typedef BYTE* LPBYTE;
typedef uint8_t UINT8;
typedef const char *PCSTR;
typedef PCSTR LPCSTR;
typedef char* LPSTR;
typedef unsigned short USHORT;
typedef short SHORT;
typedef uint16_t UINT16;
typedef uint32_t UINT32;
typedef int32_t INT32;
typedef int64_t __int64;

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
