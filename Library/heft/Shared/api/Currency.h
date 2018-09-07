
#import <Foundation/Foundation.h>

@interface Currency : NSObject

@property (readonly, nonatomic) NSString *alpha;
@property (readonly, nonatomic) NSInteger code;
@property (readonly, nonatomic) NSString *symbol;
@property (readonly, nonatomic) NSInteger fractionDigits;
@property (readonly, nonatomic) NSString *name;

+ (NSArray *)AllCurrencies;

+ (instancetype)AED;

+ (instancetype)AFN;

+ (instancetype)ALL;

+ (instancetype)AMD;

+ (instancetype)ANG;

+ (instancetype)AOA;

+ (instancetype)ARS;

+ (instancetype)AUD;

+ (instancetype)AWG;

+ (instancetype)AZN;

+ (instancetype)BAM;

+ (instancetype)BBD;

+ (instancetype)BDT;

+ (instancetype)BGN;

+ (instancetype)BHD;

+ (instancetype)BIF;

+ (instancetype)BMD;

+ (instancetype)BND;

+ (instancetype)BOB;

+ (instancetype)BOV;

+ (instancetype)BRL;

+ (instancetype)BSD_;

+ (instancetype)BTN;

+ (instancetype)BWP;

+ (instancetype)BYR;

+ (instancetype)BZD;

+ (instancetype)CAD;

+ (instancetype)CDF;

+ (instancetype)CHF;

+ (instancetype)CLP;

+ (instancetype)CNY;

+ (instancetype)COP;

+ (instancetype)COU;

+ (instancetype)CRC;

+ (instancetype)CUC;

+ (instancetype)CUP;

+ (instancetype)CVE;

+ (instancetype)CZK;

+ (instancetype)DJF;

+ (instancetype)DKK;

+ (instancetype)DOP;

+ (instancetype)DZD;

+ (instancetype)EGP;

+ (instancetype)ERN;

+ (instancetype)ETB;

+ (instancetype)EUR;

+ (instancetype)FJD;

+ (instancetype)FKP;

+ (instancetype)GBP;

+ (instancetype)GEL;

+ (instancetype)GHS;

+ (instancetype)GIP;

+ (instancetype)GMD;

+ (instancetype)GNF;

+ (instancetype)GTQ;

+ (instancetype)GYD;

+ (instancetype)HKD;

+ (instancetype)HNL;

+ (instancetype)HRK;

+ (instancetype)HTG;

+ (instancetype)HUF;

+ (instancetype)IDR;

+ (instancetype)ILS;

+ (instancetype)INR;

+ (instancetype)IQD;

+ (instancetype)IRR;

+ (instancetype)ISK;

+ (instancetype)JMD;

+ (instancetype)JOD;

+ (instancetype)JPY;

+ (instancetype)KES;

+ (instancetype)KGS;

+ (instancetype)KHR;

+ (instancetype)KMF;

+ (instancetype)KPW;

+ (instancetype)KRW;

+ (instancetype)KWD;

+ (instancetype)KYD;

+ (instancetype)KZT;

+ (instancetype)LAK;

+ (instancetype)LBP;

+ (instancetype)LKR;

+ (instancetype)LRD;

+ (instancetype)LSL;

+ (instancetype)LTL;

+ (instancetype)LYD;

+ (instancetype)MAD;

+ (instancetype)MDL;

+ (instancetype)MGA;

+ (instancetype)MKD;

+ (instancetype)MMK;

+ (instancetype)MNT;

+ (instancetype)MOP;

+ (instancetype)MRO;

+ (instancetype)MUR;

+ (instancetype)MVR;

+ (instancetype)MWK;

+ (instancetype)MXN;

+ (instancetype)MXV;

+ (instancetype)MYR;

+ (instancetype)MZN;

+ (instancetype)NAD;

+ (instancetype)NGN;

+ (instancetype)NIO;

+ (instancetype)NOK;

+ (instancetype)NPR;

+ (instancetype)NZD;

+ (instancetype)OMR;

+ (instancetype)PAB;

+ (instancetype)PEN;

+ (instancetype)PGK;

+ (instancetype)PHP;

+ (instancetype)PKR;

+ (instancetype)PLN;

+ (instancetype)PYG;

+ (instancetype)QAR;

+ (instancetype)RON;

+ (instancetype)RSD;

+ (instancetype)RUB;

+ (instancetype)RWF;

+ (instancetype)SAR;

+ (instancetype)SBD;

+ (instancetype)SCR;

+ (instancetype)SDG;

+ (instancetype)SEK;

+ (instancetype)SGD;

+ (instancetype)SHP;

+ (instancetype)SLL;

+ (instancetype)SOS;

+ (instancetype)SRD;

+ (instancetype)SSP;

+ (instancetype)STD;

+ (instancetype)SYP;

+ (instancetype)SZL;

+ (instancetype)THB;

+ (instancetype)TJS;

+ (instancetype)TMT;

+ (instancetype)TND;

+ (instancetype)TOP;

+ (instancetype)TRY;

+ (instancetype)TTD;

+ (instancetype)TWD;

+ (instancetype)TZS;

+ (instancetype)UAH;

+ (instancetype)UGX;

+ (instancetype)USD;

+ (instancetype)UZS;

+ (instancetype)VEF;

+ (instancetype)VND;

+ (instancetype)VUV;

+ (instancetype)WST;

+ (instancetype)XAF;

+ (instancetype)XCD;

+ (instancetype)XOF;

+ (instancetype)XPF;

+ (instancetype)YER;

+ (instancetype)ZAR;

+ (instancetype)ZMW;

+ (instancetype)ZWL;

+ (instancetype)UNKNOWN;

- (NSString *)sendableCurrencyCode;

+ (Currency *)currencyFromAlpha:(NSString *)alpha;

+ (Currency *)currencyFromCode:(NSNumber *)code;

@end
