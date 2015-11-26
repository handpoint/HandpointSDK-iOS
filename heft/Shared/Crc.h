#pragma once

#ifndef _CRC_INCLUDE_DEFINED_
#define _CRC_INCLUDE_DEFINED_

#include <cstdint>

namespace CRC {
    std::uint16_t CalcCRC(const std::uint8_t *paucData, std::int16_t shLength, std::uint16_t usSeed = 0);
}

#endif