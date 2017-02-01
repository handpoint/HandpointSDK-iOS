// #include "StdAfx.h"
#include "BCDCoder.h"

#include <string>
#include <cstdint>


void BCDCoder::Encode(const char* pStr, std::uint8_t* pBuf, int size) {
	const char* p = pStr;
	for(int i = 0; i < size; ++i){
		unsigned char c_hi = (*p++ - '0') & 0x0f;
		unsigned char c_lo = *p ? (*p++ - '0') & 0x0f : 0;
		pBuf[i] = c_hi << 4 | c_lo;
	}
}

std::string BCDCoder::Decode(const std::uint8_t* pBuf, int size) {
    std::string result;
    const std::uint8_t* p = pBuf;
	for(int i = 0; i < size; ++i){
		unsigned char c_hi = (*p >> 4) + '0';
		unsigned char c_lo = (*p++ & 0x0f) + '0';
		result += c_hi;
		result += c_lo;
	}
	return result;
}
