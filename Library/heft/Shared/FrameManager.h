#pragma once

#include <vector>
#include <cstdint>

class Frame;
//class IConnection;
@class iOSConnection;
class RequestCommand;
class ResponseCommand;

class FrameManager{
    std::vector<Frame> frames;
    std::vector<std::uint8_t> data;

	ResponseCommand* Read(iOSConnection* connection, bool finance_timeout);
	bool ReadFrames(iOSConnection* connection, std::vector<std::uint8_t>& buf);

	static int EndPos(const std::uint8_t* pData, int pos, int len);
public:
    FrameManager(const RequestCommand& request, int max_frame_size);
    
    // copy and move constructors
    /*
    FrameManager(const FrameManager& other);

    FrameManager(FrameManager&& other);
    FrameManager & operator= (const FrameManager& other);
    ~FrameManager();
     */
    static void TearDown();
	void Write(iOSConnection* connection/*, volatile bool& bCancel*/);
	void WriteWithoutAck(iOSConnection* connection/*, volatile bool& bCancel*/);

	template<class T>
	T* ReadResponse(iOSConnection* connection, bool finance_timeout)
	{
        return static_cast<T*>(Read(connection, finance_timeout));
    }

#ifdef UNIT_TESTING
    std::vector<Frame>& GetFrames(){return frames;}
    std::vector<std::uint8_t>& GetData(){return data;}
	bool ReadFrames_test(iOSConnection* connection, std::vector<std::uint8_t>& buf){return ReadFrames(connection, buf);}
#endif
};
