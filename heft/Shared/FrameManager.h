#pragma once

#include <vector>
#include <cstdint>

class Frame;
//class IConnection;
@class HeftConnection;
class RequestCommand;
class ResponseCommand;

class FrameManager{
    std::vector<Frame> frames;
    std::vector<std::uint8_t> data;

	ResponseCommand* Read(HeftConnection* connection, bool finance_timeout);
    bool ReadFrames(HeftConnection* connection, std::vector<std::uint8_t>& buf);

	static int EndPos(const std::uint8_t* pData, int pos, int len);

public:
	FrameManager(const RequestCommand& request, int max_frame_size);
	void Write(HeftConnection* connection/*, volatile bool& bCancel*/);
	void WriteWithoutAck(HeftConnection* connection/*, volatile bool& bCancel*/);

	template<class T>
	T* ReadResponse(HeftConnection* connection, bool finance_timeout)
    {
        return static_cast<T*>(Read(connection, finance_timeout));
    }

#ifdef UNIT_TESTING
    std::vector<Frame>& GetFrames(){return frames;}
    std::vector<std::uint8_t>& GetData(){return data;}
    bool ReadFrames_test(HeftConnection* connection, std::vector<std::uint8_t>& buf){return ReadFrames(connection, buf);}
#endif
};
