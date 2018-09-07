//
//  debug.h
//  headstart
//

#define Assert(x) NSAssert(x, @"Assert")
#ifdef DEBUG
	#define Verify(x) Assert(x)
	#define LOG(...) NSLog(__VA_ARGS__)
#else
	#define Verify(x) x
	#define LOG(...)
#endif
