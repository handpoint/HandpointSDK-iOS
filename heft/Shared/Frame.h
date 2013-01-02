#pragma once

#include "api/CmdIds.h"
#include "HeftCmdIds.h"

#pragma pack(push, 1)
struct FramePayload{
	UINT16 StartSequence;
	UINT8 iCommand;
	UINT16 code;
	UINT8 requestIndicator;
};
struct FrameEndPayload{
	UINT16 EndSequence;
	UINT16 crc;
};
#pragma pack(pop)

class Frame{
	vector<UINT8> write_data;
	bool bPartial;

	const UINT8* m_pData;
	int m_len;

	template<class T>
	T* GetPayload(){return reinterpret_cast<T*>(&write_data[0]);}
	const FrameEndPayload* GetEndPayload(){return reinterpret_cast<const FrameEndPayload*>(&m_pData[m_len - sizeof(FrameEndPayload)]);}
	//FramePayload* GetPayload(){return reinterpret_cast<FramePayload*>(&data[0]);}
	void AddCRC();

public:
	static const int ciMinSize = 6;

	Frame(const UINT8* pData, int len, bool partial);
	int GetLength(){return write_data.size();}
	UINT8* GetData(){return &write_data[0];}

	Frame(const UINT8* pData, int len);
	bool isValidCrc();
	bool isPartial(){return GetEndPayload()->EndSequence == FRAME_PARTIAL_END;}

	NSString* dump(NSString* prefix)const;
};