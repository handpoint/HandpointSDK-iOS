#pragma once

#include <string>
#include <cstdint>


namespace BCDCoder {
    void Encode(const char* pStr, std::uint8_t* pBuf, int size);
    std::string Decode(const std::uint8_t* pBuf, int size);
};
