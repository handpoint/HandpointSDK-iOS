#pragma once

// Control characters
#define STX() \x02
#define ETX() \x03
#define EOT() \x04
#define ENQ() \x05
#define ACK() \x06
#define DLE() \x10
#define NAK() \x15
#define ETB() \x17

#define FRAME_START			0x0210
#define FRAME_END			0x0310
#define FRAME_PARTIAL_END	0x1710
#define SESSION_END			0x0410
#define POLLING_SEQ			0x0510
#define POSITIVE_ACK		0x0610
#define NEGATIVE_ACK		0x1510

// Command types
#define CMD_XCMD()		C
#define CMD_IDLE()		I
#define CMD_PARAM()		P
#define CMD_SOFT()		S
#define CMD_FINAN()		F
#define CMD_HOST()		H
#define CMD_REPORT()	R
#define CMD_DEBUG()		D
#define CMD_LOG()		L

#define CMD_REQ()		'0'
#define CMD_RSP()		'1'

// Commands
#define CMD_XCMD_REQ		'C000'
#define CMD_XCMD_RSP		'C001'
#define CMD_INIT_REQ		'I000'
#define CMD_INIT_RSP		'I001'
#define CMD_IDLE_REQ		'I010'
#define CMD_IDLE_RSP		'I011'
#define CMD_START_PARAM_REQ	'P000'
#define CMD_DATA_PARAM_REQ	'P010'
#define CMD_END_PARAM_REQ	'P020'
#define CMD_SOFT_UPD_REQ	'S000'
#define CMD_SOFT_HEADER_REQ	'S010'
#define CMD_SOFT_DATA_REQ	'S020'
#define CMD_SOFT_UPDCNF_REQ	'S030'
#define CMD_FIN_SALE_REQ	'F000'
#define CMD_FIN_SALE_RSP	'F001'
#define CMD_FIN_REFUND_REQ	'F010'
#define CMD_FIN_REFUND_RSP	'F011'
#define CMD_FIN_SALEV_REQ	'F020'
#define CMD_FIN_SALEV_RSP	'F021'
#define CMD_FIN_REFUNDV_REQ	'F030'
#define CMD_FIN_REFUNDV_RSP	'F031'
#define CMD_FIN_STARTDAY_REQ	'F040'
#define CMD_FIN_STARTDAY_RSP	'F041'
#define CMD_FIN_ENDDAY_REQ	'F050'
#define CMD_FIN_ENDDAY_RSP	'F051'
#define CMD_FIN_INIT_REQ	'F060'
#define CMD_FIN_INIT_RSP	'F061'
#define CMD_FIN_RCVRD_TXN_RSLT        'F070'
#define CMD_FIN_RCVRD_TXN_RSLT_RSP    'F071'
#define CMD_HOST_CONN_REQ	'H000'
#define CMD_HOST_CONN_RSP	'H001'
#define CMD_HOST_SEND_REQ	'H010'
#define CMD_HOST_SEND_RSP	'H011'
#define CMD_HOST_RECV_REQ	'H020'
#define CMD_HOST_RECV_RSP	'H021'
#define CMD_HOST_DISC_REQ	'H030'
#define CMD_HOST_DISC_RSP	'H031'
#define CMD_STAT_INFO_RSP	'R001'
#define CMD_STAT_SIGN_REQ	'R010'
#define CMD_STAT_SIGN_RSP	'R011'
#define CMD_STAT_CHALENGE_REQ	'R020'
#define CMD_STAT_CHALENGE_RSP	'R021'
#define CMD_DBG_ENABLE_REQ	'D000'
#define CMD_DBG_ENABLE_RSP	'D001'
#define CMD_DBG_DISABLE_REQ	'D010'
#define CMD_DBG_DISABLE_RSP	'D011'
#define CMD_DBG_RESET_REQ	'D020'
#define CMD_DBG_RESET_RSP	'D021'
#define CMD_DBG_INFO_REQ	'D030'
#define CMD_DBG_INFO_RSP	'D031'
#define CMD_LOG_SET_LEV_REQ	'L000'
#define CMD_LOG_SET_LEV_RSP	'L001'
#define CMD_LOG_RST_INF_REQ	'L010'
#define CMD_LOG_RST_INF_RSP	'L011'
#define CMD_LOG_GET_INF_REQ	'L020'
#define CMD_LOG_GET_INF_RSP	'L021'
