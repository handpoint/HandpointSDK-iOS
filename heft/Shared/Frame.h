#pragma once

#include "api/CmdIds.h"
#include "HeftCmdIds.h"
#include <vector>
#include <cstdint>

#import <Foundation/Foundation.h>


#pragma pack(push, 1)
struct FramePayload{
    std::uint16_t StartSequence;
    std::uint8_t iCommand;
	std::uint16_t code;
	std::uint8_t requestIndicator;
};
struct FrameEndPayload{
	std::uint16_t EndSequence;
	std::uint16_t crc;
};
#pragma pack(pop)

class Frame{
    std::vector<std::uint8_t> write_data;
	bool bPartial;

    const std::uint8_t* m_pData;
	int m_len;

	template<class T>
	T* GetPayload(){
        return reinterpret_cast<T*>(&write_data[0]);
    }
	const FrameEndPayload* GetEndPayload(){return reinterpret_cast<const FrameEndPayload*>(&m_pData[m_len - sizeof(FrameEndPayload)]);}
	//FramePayload* GetPayload(){return reinterpret_cast<FramePayload*>(&data[0]);}
	void AddCRC();

public:
	static const int ciMinSize = 6;

    Frame(const std::uint8_t* pData, int len, bool partial);
	int GetLength(){return (int)write_data.size();}
    std::uint8_t* GetData(){return &write_data[0];}
    static int GetMetaDataSize(){return ciMinSize;}

    Frame(const std::uint8_t* pData, int len);
	bool isValidCrc();
	bool isPartial(){return GetEndPayload()->EndSequence == FRAME_PARTIAL_END;}

	NSString* dump(NSString* prefix)const;
};