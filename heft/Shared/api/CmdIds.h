/**
 *****************************************************************************
 *  @file   CMDIDS.h
 *
 *  @brief  IDs of the commands
 *
 *  01/09/2008 09:00
 *  Creation
 *
 */
/* (C) Copyright. handPoint, 2008-2014. All rights reserved.
 *
 * No part of this software may be used, stored, compiled, reproduced,
 * modified, transcribed, translated, transmitted, or transferred, in any form
 * or by any means whether electronic, mechanical, magnetic, optical,
 * or otherwise, without the express prior written permission of handPoint.
 *
 *****************************************************************************
**/
#ifndef _CMDIDS_H_
#define _CMDIDS_H_

//Command groups
#define EFT_PACKET_TYPE_POWER_ON        '@'
#define EFT_PACKET_TYPE_COMMAND         'C'
#define EFT_PACKET_TYPE_IDLE            'I'
#define EFT_PACKET_TYPE_PARAMS          'P'
#define EFT_PACKET_TYPE_SOFT_DWN        'S'
#define EFT_PACKET_TYPE_FINANC          'F'
#define EFT_PACKET_TYPE_HOST            'H'
#define EFT_PACKET_TYPE_STATUS          'R'
#define EFT_PACKET_TYPE_DEBUG           'D'
#define EFT_PACKET_TYPE_LOGGING         'L'

//Command
#define EFT_PACKET_COMMAND              "C000"
#define EFT_PACKET_COMMAND_RESP         "C001"

//Idle commands
#define EFT_PACKET_INIT                 "I000"
#define EFT_PACKET_INIT_RESP            "I001"
#define EFT_PACKET_IDLE                 "I010"
#define EFT_PACKET_IDLE_RESP            "I011"

//Parameter downloading
#define EFT_PACKET_START_PARAM          "P000"
#define EFT_PACKET_START_PARAM_RESP     "P001"
#define EFT_PACKET_PARAM_DATA           "P010"
#define EFT_PACKET_PARAM_DATA_RESP      "P011"
#define EFT_PACKET_END_PARAM            "P020"
#define EFT_PACKET_END_PARAM_RESP       "P021"

//Software downloading
#define EFT_PACKET_SOFT_REQUEST         "S000"
#define EFT_PACKET_SOFT_REQUEST_RESP    "S001"
#define EFT_PACKET_FILE_HEADER          "S010"
#define EFT_PACKET_FILE_HEADER_RESP     "S011"
#define EFT_PACKET_FILE_DATA            "S020"
#define EFT_PACKET_FILE_DATA_RESP       "S021"
#define EFT_PACKET_SOFT_CONFIRM         "S030"
#define EFT_PACKET_SOFT_CONFIRM_RESP    "S031"

//Financial transactions
#define EFT_PACKET_SALE                 "F000"
#define EFT_PACKET_SALE_RESP            "F001"
#define EFT_PACKET_REFUND               "F010"
#define EFT_PACKET_REFUND_RESP          "F011"
#define EFT_PACKET_SALE_VOID            "F020"
#define EFT_PACKET_SALE_VOID_RESP       "F021"
#define EFT_PACKET_REFUND_VOID          "F030"
#define EFT_PACKET_REFUND_VOID_RESP     "F031"
#define EFT_PACKET_START_DAY            "F040"
#define EFT_PACKET_START_DAY_RESP       "F041"
#define EFT_PACKET_END_DAY              "F050"
#define EFT_PACKET_END_DAY_RESP         "F051"
#define EFT_PACKET_HOST_INIT            "F060"
#define EFT_PACKET_HOST_INIT_RESP       "F061"
#define EFT_PACKET_RECOVERED_TXN_RESULT         "F070"
#define EFT_PACKET_RECOVERED_TXN_RESULT_RESP    "F071"

//Host communication
#define EFT_PACKET_HOST_CONNECT         "H000"
#define EFT_PACKET_HOST_CONNECT_RESP    "H001"
#define EFT_PACKET_HOST_SEND            "H010"
#define EFT_PACKET_HOST_SEND_RESP       "H011"
#define EFT_PACKET_HOST_RECEIVE         "H020"
#define EFT_PACKET_HOST_RECEIVE_RESP    "H021"
#define EFT_PACKET_HOST_DISCONNECT      "H030"
#define EFT_PACKET_HOST_DISCONNECT_RESP "H031"

//Status report
#define EFT_PACKET_EVENT_INFO_RESP      "R001"
#define EFT_PACKET_SIGNATURE_REQ        "R010"
#define EFT_PACKET_SIGNATURE_REQ_RESP   "R011"
#define EFT_PACKET_SHARE_SECRET_REQ     "R020"
#define EFT_PACKET_SHARE_SECRET_REQ_RESP "R021"

//Debugging
#define EFT_PACKET_DEBUG_ENABLE         "D000"
#define EFT_PACKET_DEBUG_ENABLE_RESP    "D001"
#define EFT_PACKET_DEBUG_DISABLE        "D010"
#define EFT_PACKET_DEBUG_DISABLE_RESP   "D011"
#define EFT_PACKET_DEBUG_RESET          "D020"
#define EFT_PACKET_DEBUG_RESET_RESP     "D021"
#define EFT_PACKET_DEBUG_GETINFO        "D030"
#define EFT_PACKET_DEBUG_GETINFO_RESP   "D031"

//Logging
#define EFT_PACKET_LOG_SET_LEVEL        "L000"
#define EFT_PACKET_LOG_SET_LEVEL_RESP   "L001"
#define EFT_PACKET_LOG_RESET			"L010"
#define EFT_PACKET_LOG_RESET_RESP		"L011"
#define EFT_PACKET_LOG_GETINFO			"L020"
#define EFT_PACKET_LOG_GETINFO_RESP		"L021"

//MPED status messages 
#define EFT_PP_STATUS_SUCCESS                   0x0001
#define EFT_PP_STATUS_INVALID_DATA              0x0002
#define EFT_PP_STATUS_PROCESSING_ERROR          0x0003
#define EFT_PP_STATUS_COMMAND_NOT_ALLOWED       0x0004
#define EFT_PP_STATUS_NOT_INITIALISED           0x0005
#define EFT_PP_STATUS_CONNECT_TIMEOUT           0x0006
#define EFT_PP_STATUS_CONNECT_ERROR             0x0007
#define EFT_PP_STATUS_SENDING_ERROR             0x0008
#define EFT_PP_STATUS_RECEIVING_ERROR           0x0009
#define EFT_PP_STATUS_NO_DATA_AVAILABLE         0x000a
#define EFT_PP_STATUS_TRANS_NOT_ALLOWED         0x000b
#define EFT_PP_STATUS_UNSUPPORTED_CURRENCY      0x000c
#define EFT_PP_STATUS_NO_HOST_AVAILABLE         0x000d
#define EFT_PP_STATUS_CARD_READER_ERROR         0x000e
#define EFT_PP_STATUS_CARD_READING_FAILED       0x000f
#define EFT_PP_STATUS_INVALID_CARD              0x0010
#define EFT_PP_STATUS_INPUT_TIMEOUT             0x0011
#define EFT_PP_STATUS_USER_CANCELLED            0x0012
#define EFT_PP_STATUS_INVALID_SIGNATURE         0x0013
#define EFT_PP_STATUS_WAITING_CARD              0x0014
#define EFT_PP_STATUS_CARD_INSERTED             0x0015
#define EFT_PP_STATUS_APPLICATION_SELECTION     0x0016
#define EFT_PP_STATUS_APPLICATION_CONFIRMATION  0x0017
#define EFT_PP_STATUS_AMOUNT_VALIDATION         0x0018
#define EFT_PP_STATUS_PIN_INPUT                 0x0019
#define EFT_PP_STATUS_MANUAL_CARD_INPUT         0x001a
#define EFT_PP_STATUS_WAITING_CARD_REMOVAL      0x001b
#define EFT_PP_STATUS_TIP_INPUT                 0x001c
#define EFT_PP_STATUS_SHARED_SECRET_INVALID     0x001d
#define EFT_PP_STATUS_SHARED_SECRET_AUTH        0x001e
#define EFT_PP_STATUS_WAITING_SIGNATURE         0x001f
#define EFT_PP_STATUS_WAITING_HOST_CONNECT      0x0020
#define EFT_PP_STATUS_WAITING_HOST_SEND         0x0021
#define EFT_PP_STATUS_WAITING_HOST_RECEIVE      0x0022
#define EFT_PP_STATUS_WAITING_HOST_DISCONNECT   0x0023
#define EFT_PP_STATUS_CONNECTING				0x0020
#define EFT_PP_STATUS_SENDING					0x0021
#define EFT_PP_STATUS_RECEIVEING				0x0022
#define EFT_PP_STATUS_DISCONNECTING				0x0023
#define EFT_PP_STATUS_PIN_INPUT_COMPLETED       0x0024
#define EFT_PP_STATUS_POS_CANCELLED             0x0025
#define EFT_PP_STATUS_REQUEST_INVALID           0x0026
#define EFT_PP_STATUS_CARD_CANCELLED            0x0027
#define EFT_PP_STATUS_CARD_BLOCKED              0x0028
#define EFT_PP_STATUS_REQUEST_AUTH_TIMEOUT      0x0029
#define EFT_PP_STATUS_REQUEST_PAYMENT_TIMEOUT   0x002A
#define EFT_PP_STATUS_RESPONSE_AUTH_TIMEOUT     0x002B
#define EFT_PP_STATUS_RESPONSE_PAYMENT_TIMEOUT  0x002C
#define EFT_PP_STATUS_ICC_CARD_SWIPED           0x002D
#define EFT_PP_STATUS_REMOVE_CARD               0x002E
#define EFT_PP_STATUS_SCANNER_IS_NOT_SUPPORTED  0x002F
#define EFT_PP_STATUS_SCANNER_EVENT             0x0030
#define EFT_PP_STATUS_BATTERY_TOO_LOW           0x0031
#define EFT_PP_STATUS_ACCOUNT_TYPE_SELECTION    0x0032 // Viscus: status code
#define EFT_PP_STATUS_BT_IS_NOT_SUPPORTED       0x0033

//transaction statuses
#define EFT_FINANC_STATUS_UNDEFINED                0x00
#define EFT_FINANC_STATUS_TRANS_APPROVED           0x01
#define EFT_FINANC_STATUS_TRANS_DECLINED           0x02
#define EFT_FINANC_STATUS_TRANS_PROCESSED          0x03
#define EFT_FINANC_STATUS_TRANS_NOT_PROCESSED      0x04
#define EFT_FINANC_STATUS_TRANS_CANCELLED          0x05
#define EFT_FINANC_STATUS_TRANS_DEVICE_RESET_MASK  0x80

//Financial transaction status messages
#define EFT_TRANS_UNDEFINED 	                0x0000
#define EFT_TRANS_APPROVED 						0x0001
#define EFT_TRANS_DECLINED  					0x0002
#define EFT_TRANS_PROCESSED 					0x0003
#define EFT_TRANS_NOT_PROCESSED 				0x0004
#define EFT_TRANS_CANCELLED						0x0005

//general transaction types
#define EFT_FINANC_UNDEFINED                        0x00
#define EFT_FINANC_SALE                             0x01
#define EFT_FINANC_SALE_VOID                        0x02
#define EFT_FINANC_REFUND                           0x03
#define EFT_FINANC_REFUND_VOID                      0x04
#define EFT_FINANC_SALE_CANCELLATION                0x05
#define EFT_FINANC_REFUND_CANCELLATION              0x06
#define EFT_FINANC_HOST_INIT                        0x07
// Used only in receipt template vvvv
#define EFT_FINANC_CANCEL                           0x08
#define EFT_FINANC_VOID                             0x09
// Used only in receipt template ^^^^
#define EFT_FINANC_RECOVER_TXN_RESULT               0x0A

#endif
