#pragma once

class Frame;
//class IConnection;
@class HeftConnection;
class RequestCommand;
class ResponseCommand;

class FrameManager{
	vector<Frame> frames;
	vector<UINT8> data;

	ResponseCommand* Read(HeftConnection* connection, bool finance_timeout);
	bool ReadFrames(HeftConnection* connection, vector<UINT8>& buf);

	static int EndPos(const UINT8* pData, int pos, int len);

public:
	FrameManager(const RequestCommand& request, int max_frame_size);
	void Write(HeftConnection* connection/*, volatile bool& bCancel*/);
	void WriteWithoutAck(HeftConnection* connection/*, volatile bool& bCancel*/);

	template<class T>
	T* ReadResponse(HeftConnection* connection, bool finance_timeout){return static_cast<T*>(Read(connection, finance_timeout));}

#ifdef UNIT_TESTING
	vector<Frame>& GetFrames(){return frames;}
	vector<UINT8>& GetData(){return data;}
	bool ReadFrames_test(HeftConnection* connection, vector<UINT8>& buf){return ReadFrames(connection, buf);}
#endif
};
