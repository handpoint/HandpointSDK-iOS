#pragma once

#include <cstdint>

class Command{
protected:
	static const int ciMinSize = 4;

#pragma pack(push, 1)
	struct CommandPayload{
        std::uint32_t command;
	};
#pragma pack(pop)

public:
	Command(){}
	virtual ~Command(){}
	virtual bool isResponse() = 0;
};
