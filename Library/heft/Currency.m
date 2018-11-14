
#import "Currency.h"

@interface Currency ()

@property (readwrite, nonatomic) NSString *alpha;
@property (readwrite, nonatomic) NSInteger code;
@property (readwrite, nonatomic) NSString *symbol;
@property (readwrite, nonatomic) NSInteger fractionDigits;
@property (readwrite, nonatomic) NSString *name;

@end

@implementation Currency

- (instancetype)initWithAlpha:(NSString *)alpha
                         code:(NSInteger)code
                       symbol:(NSString *)symbol
               fractionDigits:(NSInteger)fractionDigits
                         name:(NSString *)name
{
    self = [super init];

    if (self)
    {
        self.alpha = alpha;
        self.code = code;
        self.symbol = symbol;
        self.fractionDigits = fractionDigits;
        self.name = name;
    }

    return self;
}

+ (NSArray *)AllCurrencies
{
    return @[[Currency AED],[Currency AFN],[Currency ALL],[Currency AMD],[Currency ANG],[Currency AOA],[Currency ARS],[Currency AUD],[Currency AWG],[Currency AZN],[Currency BAM],[Currency BBD],[Currency BDT],[Currency BGN],[Currency BHD],[Currency BIF],[Currency BMD],[Currency BND],[Currency BOB],[Currency BOV],[Currency BRL],[Currency BSD_],[Currency BTN],[Currency BWP],[Currency BYR],[Currency BZD],[Currency CAD],[Currency CDF],[Currency CHF],[Currency CLP],[Currency CNY],[Currency COP],[Currency COU],[Currency CRC],[Currency CUC],[Currency CUP],[Currency CVE],[Currency CZK],[Currency DJF],[Currency DKK],[Currency DOP],[Currency DZD],[Currency EGP],[Currency ERN],[Currency ETB],[Currency EUR],[Currency FJD],[Currency FKP],[Currency GBP],[Currency GEL],[Currency GHS],[Currency GIP],[Currency GMD],[Currency GNF],[Currency GTQ],[Currency GYD],[Currency HKD],[Currency HNL],[Currency HRK],[Currency HTG],[Currency HUF],[Currency IDR],[Currency ILS],[Currency INR],[Currency IQD],[Currency IRR],[Currency ISK],[Currency JMD],[Currency JOD],[Currency JPY],[Currency KES],[Currency KGS],[Currency KHR],[Currency KMF],[Currency KPW],[Currency KRW],[Currency KWD],[Currency KYD],[Currency KZT],[Currency LAK],[Currency LBP],[Currency LKR],[Currency LRD],[Currency LSL],[Currency LTL],[Currency LYD],[Currency MAD],[Currency MDL],[Currency MGA],[Currency MKD],[Currency MMK],[Currency MNT],[Currency MOP],[Currency MRO],[Currency MUR],[Currency MVR],[Currency MWK],[Currency MXN],[Currency MXV],[Currency MYR],[Currency MZN],[Currency NAD],[Currency NGN],[Currency NIO],[Currency NOK],[Currency NPR],[Currency NZD],[Currency OMR],[Currency PAB],[Currency PEN],[Currency PGK],[Currency PHP],[Currency PKR],[Currency PLN],[Currency PYG],[Currency QAR],[Currency RON],[Currency RSD],[Currency RUB],[Currency RWF],[Currency SAR],[Currency SBD],[Currency SCR],[Currency SDG],[Currency SEK],[Currency SGD],[Currency SHP],[Currency SLL],[Currency SOS],[Currency SRD],[Currency SSP],[Currency STD],[Currency SYP],[Currency SZL],[Currency THB],[Currency TJS],[Currency TMT],[Currency TND],[Currency TOP],[Currency TRY],[Currency TTD],[Currency TWD],[Currency TZS],[Currency UAH],[Currency UGX],[Currency USD],[Currency UZS],[Currency VEF],[Currency VND],[Currency VUV],[Currency WST],[Currency XAF],[Currency XCD],[Currency XOF],[Currency XPF],[Currency YER],[Currency ZAR],[Currency ZMW],[Currency ZWL]];
}

+ (instancetype)AED
{
    return [[self alloc] initWithAlpha:@"AED"
                                  code:784
                                symbol:@"د.إ"
                        fractionDigits:2
                                  name:@"United Arab Emirates dirham"];
}

+ (instancetype)AFN
{
    return [[self alloc] initWithAlpha:@"AFN" code:971 symbol:@"Afs" fractionDigits:2 name:@"Afghani"];
}

+ (instancetype)ALL
{
    return [[self alloc] initWithAlpha:@"ALL" code:8 symbol:@"Lek" fractionDigits:2 name:@"Lek"];
}

+ (instancetype)AMD
{
    return [[self alloc] initWithAlpha:@"AMD" code:51 symbol:@"" fractionDigits:0 name:@"Armenian dram"];
}

+ (instancetype)ANG
{
    return [[self alloc] initWithAlpha:@"ANG"
                                  code:532
                                symbol:@"ƒ"
                        fractionDigits:2
                                  name:@"Netherlands Antillean guilder"];
}

+ (instancetype)AOA
{
    return [[self alloc] initWithAlpha:@"AOA" code:973 symbol:@"" fractionDigits:1 name:@"Kwanza"];
}

+ (instancetype)ARS
{
    return [[self alloc] initWithAlpha:@"ARS" code:32 symbol:@"$" fractionDigits:2 name:@"Argentine peso"];
}

+ (instancetype)AUD
{
    return [[self alloc] initWithAlpha:@"AUD" code:36 symbol:@"$" fractionDigits:2 name:@"Australian dollar"];
}

+ (instancetype)AWG
{
    return [[self alloc] initWithAlpha:@"AWG" code:533 symbol:@"ƒ" fractionDigits:2 name:@"Aruban guilder"];
}

+ (instancetype)AZN
{
    return [[self alloc] initWithAlpha:@"AZN" code:944 symbol:@"ман" fractionDigits:2 name:@"Azerbaijanian manat"];
}

+ (instancetype)BAM
{
    return [[self alloc] initWithAlpha:@"BAM" code:977 symbol:@"KM" fractionDigits:2 name:@"Convertible marks"];
}

+ (instancetype)BBD
{
    return [[self alloc] initWithAlpha:@"BBD" code:52 symbol:@"$" fractionDigits:2 name:@"Barbados dollar"];
}

+ (instancetype)BDT
{
    return [[self alloc] initWithAlpha:@"BDT" code:50 symbol:@"৳" fractionDigits:2 name:@"Bangladeshi taka"];
}

+ (instancetype)BGN
{
    return [[self alloc] initWithAlpha:@"BGN" code:975 symbol:@"лв" fractionDigits:2 name:@"Bulgarian lev"];
}

+ (instancetype)BHD
{
    return [[self alloc] initWithAlpha:@"BHD" code:48 symbol:@"BD" fractionDigits:3 name:@"Bahraini dinar"];
}

+ (instancetype)BIF
{
    return [[self alloc] initWithAlpha:@"BIF" code:108 symbol:@"FBu" fractionDigits:0 name:@"Burundian franc"];
}

+ (instancetype)BMD
{
    return [[self alloc] initWithAlpha:@"BMD" code:60 symbol:@"$" fractionDigits:2 name:@"Bermudian dollar"];
}

+ (instancetype)BND
{
    return [[self alloc] initWithAlpha:@"BND" code:96 symbol:@"$" fractionDigits:2 name:@"Brunei dollar"];
}

+ (instancetype)BOB
{
    return [[self alloc] initWithAlpha:@"BOB" code:68 symbol:@"$b" fractionDigits:2 name:@"Boliviano"];
}

+ (instancetype)BOV
{
    return [[self alloc] initWithAlpha:@"BOV" code:984 symbol:@"" fractionDigits:2 name:@"Bolivian Mvdol (funds code)"];
}

+ (instancetype)BRL
{
    return [[self alloc] initWithAlpha:@"BRL" code:986 symbol:@"R$" fractionDigits:2 name:@"Brazilian real"];
}

+ (instancetype)BSD_
{
    return [[self alloc] initWithAlpha:@"BSD" code:44 symbol:@"$" fractionDigits:2 name:@"Bahamian dollar"];
}

+ (instancetype)BTN
{
    return [[self alloc] initWithAlpha:@"BTN" code:64 symbol:@"" fractionDigits:2 name:@"Ngultrum"];
}

+ (instancetype)BWP
{
    return [[self alloc] initWithAlpha:@"BWP" code:72 symbol:@"" fractionDigits:2 name:@"Pula"];
}

+ (instancetype)BYR
{
    return [[self alloc] initWithAlpha:@"BYR" code:974 symbol:@"p." fractionDigits:0 name:@"Belarusian ruble"];
}

+ (instancetype)BZD
{
    return [[self alloc] initWithAlpha:@"BZD" code:84 symbol:@"BZ$" fractionDigits:2 name:@"Belize dollar"];
}

+ (instancetype)CAD
{
    return [[self alloc] initWithAlpha:@"CAD" code:124 symbol:@"$" fractionDigits:2 name:@"Canadian dollar"];
}

+ (instancetype)CDF
{
    return [[self alloc] initWithAlpha:@"CDF" code:976 symbol:@"" fractionDigits:2 name:@"Franc Congolais"];
}

+ (instancetype)CHF
{
    return [[self alloc] initWithAlpha:@"CHF" code:756 symbol:@"CHF" fractionDigits:2 name:@"Swiss franc"];
}

+ (instancetype)CLP
{
    return [[self alloc] initWithAlpha:@"CLP" code:152 symbol:@"$" fractionDigits:0 name:@"Chilean peso"];
}

+ (instancetype)CNY
{
    return [[self alloc] initWithAlpha:@"CNY" code:156 symbol:@"¥" fractionDigits:1 name:@"Chinese Yuan"];
}

+ (instancetype)COP
{
    return [[self alloc] initWithAlpha:@"COP" code:170 symbol:@"$" fractionDigits:0 name:@"Colombian peso"];
}

+ (instancetype)COU
{
    return [[self alloc] initWithAlpha:@"COU" code:970 symbol:@"" fractionDigits:2 name:@"Unidad de Valor Real"];
}

+ (instancetype)CRC
{
    return [[self alloc] initWithAlpha:@"CRC" code:188 symbol:@"₡" fractionDigits:2 name:@"Costa Rican colon"];
}

+ (instancetype)CUC
{
    return [[self alloc] initWithAlpha:@"CUC" code:931 symbol:@"$MN" fractionDigits:2 name:@"Cuban convertible peso"];
}

+ (instancetype)CUP
{
    return [[self alloc] initWithAlpha:@"CUP" code:192 symbol:@"₱" fractionDigits:2 name:@"Cuban peso"];
}

+ (instancetype)CVE
{
    return [[self alloc] initWithAlpha:@"CVE" code:132 symbol:@"" fractionDigits:2 name:@"Cape Verde escudo"];
}

+ (instancetype)CZK
{
    return [[self alloc] initWithAlpha:@"CZK" code:203 symbol:@"Kč" fractionDigits:2 name:@"Czech Koruna"];
}

+ (instancetype)DJF
{
    return [[self alloc] initWithAlpha:@"DJF" code:262 symbol:@"" fractionDigits:0 name:@"Djibouti franc"];
}

+ (instancetype)DKK
{
    return [[self alloc] initWithAlpha:@"DKK" code:208 symbol:@"kr" fractionDigits:2 name:@"Danish krone"];
}

+ (instancetype)DOP
{
    return [[self alloc] initWithAlpha:@"DOP" code:214 symbol:@"RD$" fractionDigits:2 name:@"Dominican peso"];
}

+ (instancetype)DZD
{
    return [[self alloc] initWithAlpha:@"DZD" code:12 symbol:@"" fractionDigits:2 name:@"Algerian dinar"];
}

+ (instancetype)EGP
{
    return [[self alloc] initWithAlpha:@"EGP" code:818 symbol:@"£" fractionDigits:2 name:@"Egyptian pound"];
}

+ (instancetype)ERN
{
    return [[self alloc] initWithAlpha:@"ERN" code:232 symbol:@"" fractionDigits:2 name:@"Nakfa"];
}

+ (instancetype)ETB
{
    return [[self alloc] initWithAlpha:@"ETB" code:230 symbol:@"" fractionDigits:2 name:@"Ethiopian birr"];
}

+ (instancetype)EUR
{
    return [[self alloc] initWithAlpha:@"EUR" code:978 symbol:@"€" fractionDigits:2 name:@"euro"];
}

+ (instancetype)FJD
{
    return [[self alloc] initWithAlpha:@"FJD" code:242 symbol:@"$" fractionDigits:2 name:@"Fiji dollar"];
}

+ (instancetype)FKP
{
    return [[self alloc] initWithAlpha:@"FKP" code:238 symbol:@"£" fractionDigits:2 name:@"Falkland Islands pound"];
}

+ (instancetype)GBP
{
    return [[self alloc] initWithAlpha:@"GBP" code:826 symbol:@"£" fractionDigits:2 name:@"Pound sterling"];
}

+ (instancetype)GEL
{
    return [[self alloc] initWithAlpha:@"GEL" code:981 symbol:@"" fractionDigits:2 name:@"Lari"];
}

+ (instancetype)GHS
{
    return [[self alloc] initWithAlpha:@"GHS" code:936 symbol:@"" fractionDigits:2 name:@"Cedi"];
}

+ (instancetype)GIP
{
    return [[self alloc] initWithAlpha:@"GIP" code:292 symbol:@"£" fractionDigits:2 name:@"Gibraltar pound"];
}

+ (instancetype)GMD
{
    return [[self alloc] initWithAlpha:@"GMD" code:270 symbol:@"" fractionDigits:2 name:@"Dalasi"];
}

+ (instancetype)GNF
{
    return [[self alloc] initWithAlpha:@"GNF" code:324 symbol:@"" fractionDigits:0 name:@"Guinea franc"];
}

+ (instancetype)GTQ
{
    return [[self alloc] initWithAlpha:@"GTQ" code:320 symbol:@"Q" fractionDigits:2 name:@"Quetzal"];
}

+ (instancetype)GYD
{
    return [[self alloc] initWithAlpha:@"GYD" code:328 symbol:@"$" fractionDigits:2 name:@"Guyana dollar"];
}

+ (instancetype)HKD
{
    return [[self alloc] initWithAlpha:@"HKD" code:344 symbol:@"$" fractionDigits:2 name:@"Hong Kong dollar"];
}

+ (instancetype)HNL
{
    return [[self alloc] initWithAlpha:@"HNL" code:340 symbol:@"L" fractionDigits:2 name:@"Lempira"];
}

+ (instancetype)HRK
{
    return [[self alloc] initWithAlpha:@"HRK" code:191 symbol:@"kn" fractionDigits:2 name:@"Croatian kuna"];
}

+ (instancetype)HTG
{
    return [[self alloc] initWithAlpha:@"HTG" code:332 symbol:@"" fractionDigits:2 name:@"Haiti gourde"];
}

+ (instancetype)HUF
{
    return [[self alloc] initWithAlpha:@"HUF" code:348 symbol:@"Ft" fractionDigits:2 name:@"Forint"];
}

+ (instancetype)IDR
{
    return [[self alloc] initWithAlpha:@"IDR" code:360 symbol:@"Rp" fractionDigits:0 name:@"Rupiah"];
}

+ (instancetype)ILS
{
    return [[self alloc] initWithAlpha:@"ILS" code:376 symbol:@"₪" fractionDigits:2 name:@"Israeli new sheqel"];
}

+ (instancetype)INR
{
    return [[self alloc] initWithAlpha:@"INR" code:356 symbol:@"₹" fractionDigits:2 name:@"Indian rupee"];
}

+ (instancetype)IQD
{
    return [[self alloc] initWithAlpha:@"IQD" code:368 symbol:@"" fractionDigits:0 name:@"Iraqi dinar"];
}

+ (instancetype)IRR
{
    return [[self alloc] initWithAlpha:@"IRR" code:364 symbol:@"﷼" fractionDigits:0 name:@"Iranian rial"];
}

+ (instancetype)ISK
{
    return [[self alloc] initWithAlpha:@"ISK" code:352 symbol:@"kr" fractionDigits:0 name:@"Iceland krona"];
}

+ (instancetype)JMD
{
    return [[self alloc] initWithAlpha:@"JMD" code:388 symbol:@"J$" fractionDigits:2 name:@"Jamaican dollar"];
}

+ (instancetype)JOD
{
    return [[self alloc] initWithAlpha:@"JOD" code:400 symbol:@"" fractionDigits:3 name:@"Jordanian dinar"];
}

+ (instancetype)JPY
{
    return [[self alloc] initWithAlpha:@"JPY" code:392 symbol:@"¥" fractionDigits:0 name:@"Japanese yen"];
}

+ (instancetype)KES
{
    return [[self alloc] initWithAlpha:@"KES" code:404 symbol:@"" fractionDigits:2 name:@"Kenyan shilling"];
}

+ (instancetype)KGS
{
    return [[self alloc] initWithAlpha:@"KGS" code:417 symbol:@"лв" fractionDigits:2 name:@"Som"];
}

+ (instancetype)KHR
{
    return [[self alloc] initWithAlpha:@"KHR" code:116 symbol:@"៛" fractionDigits:0 name:@"Riel"];
}

+ (instancetype)KMF
{
    return [[self alloc] initWithAlpha:@"KMF" code:174 symbol:@"" fractionDigits:0 name:@"Comoro franc"];
}

+ (instancetype)KPW
{
    return [[self alloc] initWithAlpha:@"KPW" code:408 symbol:@"₩" fractionDigits:0 name:@"North Korean won"];
}

+ (instancetype)KRW
{
    return [[self alloc] initWithAlpha:@"KRW" code:410 symbol:@"₩" fractionDigits:0 name:@"South Korean won"];
}

+ (instancetype)KWD
{
    return [[self alloc] initWithAlpha:@"KWD" code:414 symbol:@"" fractionDigits:3 name:@"Kuwaiti dinar"];
}

+ (instancetype)KYD
{
    return [[self alloc] initWithAlpha:@"KYD" code:136 symbol:@"$" fractionDigits:2 name:@"Cayman Islands dollar"];
}

+ (instancetype)KZT
{
    return [[self alloc] initWithAlpha:@"KZT" code:398 symbol:@"лв" fractionDigits:2 name:@"Tenge"];
}

+ (instancetype)LAK
{
    return [[self alloc] initWithAlpha:@"LAK" code:418 symbol:@"₭" fractionDigits:0 name:@"Kip"];
}

+ (instancetype)LBP
{
    return [[self alloc] initWithAlpha:@"LBP" code:422 symbol:@"£" fractionDigits:0 name:@"Lebanese pound"];
}

+ (instancetype)LKR
{
    return [[self alloc] initWithAlpha:@"LKR" code:144 symbol:@"₨" fractionDigits:2 name:@"Sri Lanka rupee"];
}

+ (instancetype)LRD
{
    return [[self alloc] initWithAlpha:@"LRD" code:430 symbol:@"$" fractionDigits:2 name:@"Liberian dollar"];
}

+ (instancetype)LSL
{
    return [[self alloc] initWithAlpha:@"LSL" code:426 symbol:@"" fractionDigits:2 name:@"Lesotho loti"];
}

+ (instancetype)LTL
{
    return [[self alloc] initWithAlpha:@"LTL" code:440 symbol:@"Lt" fractionDigits:2 name:@"Lithuanian litas"];
}

+ (instancetype)LYD
{
    return [[self alloc] initWithAlpha:@"LYD" code:434 symbol:@"" fractionDigits:3 name:@"Libyan dinar"];
}

+ (instancetype)MAD
{
    return [[self alloc] initWithAlpha:@"MAD" code:504 symbol:@"" fractionDigits:2 name:@"Moroccan dirham"];
}

+ (instancetype)MDL
{
    return [[self alloc] initWithAlpha:@"MDL" code:498 symbol:@"" fractionDigits:2 name:@"Moldovan leu"];
}

+ (instancetype)MGA
{
    return [[self alloc] initWithAlpha:@"MGA" code:969 symbol:@"Ar" fractionDigits:2 name:@"Malagasy ariary"];
}

+ (instancetype)MKD
{
    return [[self alloc] initWithAlpha:@"MKD" code:807 symbol:@"ден" fractionDigits:2 name:@"Denar"];
}

+ (instancetype)MMK
{
    return [[self alloc] initWithAlpha:@"MMK" code:104 symbol:@"" fractionDigits:0 name:@"Kyat"];
}

+ (instancetype)MNT
{
    return [[self alloc] initWithAlpha:@"MNT" code:496 symbol:@"₮" fractionDigits:2 name:@"Tughrik"];
}

+ (instancetype)MOP
{
    return [[self alloc] initWithAlpha:@"MOP" code:446 symbol:@"" fractionDigits:1 name:@"Pataca"];
}

+ (instancetype)MRO
{
    return [[self alloc] initWithAlpha:@"MRO" code:478 symbol:@"UM" fractionDigits:2 name:@"Mauritanian ouguiya"];
}

+ (instancetype)MUR
{
    return [[self alloc] initWithAlpha:@"MUR" code:480 symbol:@"₨" fractionDigits:2 name:@"Mauritius rupee"];
}

+ (instancetype)MVR
{
    return [[self alloc] initWithAlpha:@"MVR" code:462 symbol:@"" fractionDigits:2 name:@"Rufiyaa"];
}

+ (instancetype)MWK
{
    return [[self alloc] initWithAlpha:@"MWK" code:454 symbol:@"" fractionDigits:2 name:@"Kwacha"];
}

+ (instancetype)MXN
{
    return [[self alloc] initWithAlpha:@"MXN" code:484 symbol:@"$" fractionDigits:2 name:@"Mexican peso"];
}

+ (instancetype)MXV
{
    return [[self alloc] initWithAlpha:@"MXV" code:979 symbol:@"" fractionDigits:2 name:@"Mexican Unidad de Inversion"];
}

+ (instancetype)MYR
{
    return [[self alloc] initWithAlpha:@"MYR" code:458 symbol:@"RM" fractionDigits:2 name:@"Malaysian ringgit"];
}

+ (instancetype)MZN
{
    return [[self alloc] initWithAlpha:@"MZN" code:943 symbol:@"MT" fractionDigits:2 name:@"Metical"];
}

+ (instancetype)NAD
{
    return [[self alloc] initWithAlpha:@"NAD" code:516 symbol:@"$" fractionDigits:2 name:@"Namibian dollar"];
}

+ (instancetype)NGN
{
    return [[self alloc] initWithAlpha:@"NGN" code:566 symbol:@"₦" fractionDigits:2 name:@"Naira"];
}

+ (instancetype)NIO
{
    return [[self alloc] initWithAlpha:@"NIO" code:558 symbol:@"C$" fractionDigits:2 name:@"Cordoba oro"];
}

+ (instancetype)NOK
{
    return [[self alloc] initWithAlpha:@"NOK" code:578 symbol:@"kr" fractionDigits:2 name:@"Norwegian krone"];
}

+ (instancetype)NPR
{
    return [[self alloc] initWithAlpha:@"NPR" code:524 symbol:@"₨" fractionDigits:2 name:@"Nepalese rupee"];
}

+ (instancetype)NZD
{
    return [[self alloc] initWithAlpha:@"NZD" code:554 symbol:@"$" fractionDigits:2 name:@"New Zealand dollar"];
}

+ (instancetype)OMR
{
    return [[self alloc] initWithAlpha:@"OMR" code:512 symbol:@"﷼" fractionDigits:3 name:@"Rial Omani"];
}

+ (instancetype)PAB
{
    return [[self alloc] initWithAlpha:@"PAB" code:590 symbol:@"B/." fractionDigits:2 name:@"Balboa"];
}

+ (instancetype)PEN
{
    return [[self alloc] initWithAlpha:@"PEN" code:604 symbol:@"S/." fractionDigits:2 name:@"Nuevo sol"];
}

+ (instancetype)PGK
{
    return [[self alloc] initWithAlpha:@"PGK" code:598 symbol:@"" fractionDigits:2 name:@"Kina"];
}

+ (instancetype)PHP
{
    return [[self alloc] initWithAlpha:@"PHP" code:608 symbol:@"₱" fractionDigits:2 name:@"Philippine peso"];
}

+ (instancetype)PKR
{
    return [[self alloc] initWithAlpha:@"PKR" code:586 symbol:@"₨" fractionDigits:2 name:@"Pakistan rupee"];
}

+ (instancetype)PLN
{
    return [[self alloc] initWithAlpha:@"PLN" code:985 symbol:@"zł" fractionDigits:2 name:@"Z?oty"];
}

+ (instancetype)PYG
{
    return [[self alloc] initWithAlpha:@"PYG" code:600 symbol:@"Gs" fractionDigits:0 name:@"Guarani"];
}

+ (instancetype)QAR
{
    return [[self alloc] initWithAlpha:@"QAR" code:634 symbol:@"﷼" fractionDigits:2 name:@"Qatari rial"];
}

+ (instancetype)RON
{
    return [[self alloc] initWithAlpha:@"RON" code:946 symbol:@"lei" fractionDigits:2 name:@"Romanian new leu"];
}

+ (instancetype)RSD
{
    return [[self alloc] initWithAlpha:@"RSD" code:941 symbol:@"Дин." fractionDigits:2 name:@"Serbian dinar"];
}

+ (instancetype)RUB
{
    return [[self alloc] initWithAlpha:@"RUB" code:643 symbol:@"руб" fractionDigits:2 name:@"Russian rouble"];
}

+ (instancetype)RWF
{
    return [[self alloc] initWithAlpha:@"RWF" code:646 symbol:@"" fractionDigits:0 name:@"Rwanda franc"];
}

+ (instancetype)SAR
{
    return [[self alloc] initWithAlpha:@"SAR" code:682 symbol:@"﷼" fractionDigits:2 name:@"Saudi riyal"];
}

+ (instancetype)SBD
{
    return [[self alloc] initWithAlpha:@"SBD" code:90 symbol:@"$" fractionDigits:2 name:@"Solomon Islands dollar"];
}

+ (instancetype)SCR
{
    return [[self alloc] initWithAlpha:@"SCR" code:690 symbol:@"₨" fractionDigits:2 name:@"Seychelles rupee"];
}

+ (instancetype)SDG
{
    return [[self alloc] initWithAlpha:@"SDG" code:938 symbol:@"" fractionDigits:2 name:@"Sudanese pound"];
}

+ (instancetype)SEK
{
    return [[self alloc] initWithAlpha:@"SEK" code:752 symbol:@"kr" fractionDigits:2 name:@"Swedish krona/kronor"];
}

+ (instancetype)SGD
{
    return [[self alloc] initWithAlpha:@"SGD" code:702 symbol:@"$" fractionDigits:2 name:@"Singapore dollar"];
}

+ (instancetype)SHP
{
    return [[self alloc] initWithAlpha:@"SHP" code:654 symbol:@"£" fractionDigits:2 name:@"Saint Helena pound"];
}

+ (instancetype)SLL
{
    return [[self alloc] initWithAlpha:@"SLL" code:694 symbol:@"" fractionDigits:0 name:@"Leone"];
}

+ (instancetype)SOS
{
    return [[self alloc] initWithAlpha:@"SOS" code:706 symbol:@"S" fractionDigits:2 name:@"Somali shilling"];
}

+ (instancetype)SRD
{
    return [[self alloc] initWithAlpha:@"SRD" code:968 symbol:@"$" fractionDigits:2 name:@"Surinam dollar"];
}

+ (instancetype)SSP
{
    return [[self alloc] initWithAlpha:@"SSP" code:728 symbol:@"£" fractionDigits:2 name:@"South Sudanese pound"];
}

+ (instancetype)STD
{
    return [[self alloc] initWithAlpha:@"STD" code:678 symbol:@"Db" fractionDigits:0 name:@"Dobra"];
}

+ (instancetype)SYP
{
    return [[self alloc] initWithAlpha:@"SYP" code:760 symbol:@"£" fractionDigits:2 name:@"Syrian pound"];
}

+ (instancetype)SZL
{
    return [[self alloc] initWithAlpha:@"SZL" code:748 symbol:@"" fractionDigits:2 name:@"Lilangeni"];
}

+ (instancetype)THB
{
    return [[self alloc] initWithAlpha:@"THB" code:764 symbol:@"฿" fractionDigits:2 name:@"Baht"];
}

+ (instancetype)TJS
{
    return [[self alloc] initWithAlpha:@"TJS" code:972 symbol:@"" fractionDigits:2 name:@"Somoni"];
}

+ (instancetype)TMT
{
    return [[self alloc] initWithAlpha:@"TMT" code:934 symbol:@"" fractionDigits:2 name:@"Manat"];
}

+ (instancetype)TND
{
    return [[self alloc] initWithAlpha:@"TND" code:788 symbol:@"" fractionDigits:3 name:@"Tunisian dinar"];
}

+ (instancetype)TOP
{
    return [[self alloc] initWithAlpha:@"TOP" code:776 symbol:@"T$" fractionDigits:2 name:@"Pa'anga"];
}

+ (instancetype)TRY
{
    return [[self alloc] initWithAlpha:@"TRY" code:949 symbol:@"" fractionDigits:2 name:@"Turkish lira"];
}

+ (instancetype)TTD
{
    return [[self alloc] initWithAlpha:@"TTD"
                                  code:780
                                symbol:@"TT$"
                        fractionDigits:2
                                  name:@"Trinidad and Tobago dollar"];
}

+ (instancetype)TWD
{
    return [[self alloc] initWithAlpha:@"TWD" code:901 symbol:@"NT$" fractionDigits:1 name:@"New Taiwan dollar"];
}

+ (instancetype)TZS
{
    return [[self alloc] initWithAlpha:@"TZS" code:834 symbol:@"" fractionDigits:2 name:@"Tanzanian shilling"];
}

+ (instancetype)UAH
{
    return [[self alloc] initWithAlpha:@"UAH" code:980 symbol:@"₴" fractionDigits:2 name:@"Hryvnia"];
}

+ (instancetype)UGX
{
    return [[self alloc] initWithAlpha:@"UGX" code:800 symbol:@"USh" fractionDigits:0 name:@"Uganda shilling"];
}

+ (instancetype)USD
{
    return [[self alloc] initWithAlpha:@"USD" code:840 symbol:@"$" fractionDigits:2 name:@"US dollar"];
}

+ (instancetype)UZS
{
    return [[self alloc] initWithAlpha:@"UZS" code:860 symbol:@"лв" fractionDigits:2 name:@"Uzbekistan som"];
}

+ (instancetype)VEF
{
    return [[self alloc] initWithAlpha:@"VEF" code:937 symbol:@"Bs" fractionDigits:2 name:@"Venezuelan bolivar fuerte"];
}

+ (instancetype)VND
{
    return [[self alloc] initWithAlpha:@"VND" code:704 symbol:@"₫" fractionDigits:0 name:@"Vietnamese Dong"];
}

+ (instancetype)VUV
{
    return [[self alloc] initWithAlpha:@"VUV" code:548 symbol:@"" fractionDigits:0 name:@"Vatu"];
}

+ (instancetype)WST
{
    return [[self alloc] initWithAlpha:@"WST" code:882 symbol:@"" fractionDigits:2 name:@"Samoan tala"];
}

+ (instancetype)XAF
{
    return [[self alloc] initWithAlpha:@"XAF" code:950 symbol:@"FCFA" fractionDigits:0 name:@"CFA franc BEAC"];
}

+ (instancetype)XCD
{
    return [[self alloc] initWithAlpha:@"XCD" code:951 symbol:@"$" fractionDigits:2 name:@"East Caribbean dollar"];
}

+ (instancetype)XOF
{
    return [[self alloc] initWithAlpha:@"XOF" code:952 symbol:@"CFA" fractionDigits:0 name:@"CFA Franc BCEAO"];
}

+ (instancetype)XPF
{
    return [[self alloc] initWithAlpha:@"XPF" code:953 symbol:@"F" fractionDigits:0 name:@"CFP franc"];
}

+ (instancetype)YER
{
    return [[self alloc] initWithAlpha:@"YER" code:886 symbol:@"﷼" fractionDigits:0 name:@"Yemeni rial"];
}

+ (instancetype)ZAR
{
    return [[self alloc] initWithAlpha:@"ZAR" code:710 symbol:@"R" fractionDigits:2 name:@"South African rand"];
}

+ (instancetype)ZMW
{
    return [[self alloc] initWithAlpha:@"ZMW" code:967 symbol:@"ZK" fractionDigits:2 name:@"Kwacha"];
}

+ (instancetype)ZWL
{
    return [[self alloc] initWithAlpha:@"ZWL" code:932 symbol:@"Z$" fractionDigits:2 name:@"Zimbabwe dollar"];
}

+ (instancetype)UNKNOWN
{
    return [[self alloc] initWithAlpha:@"Unknown" code:0 symbol:@"" fractionDigits:0 name:@""];
}

+ (Currency *)currencyFromAlpha:(NSString *)alpha
{
    
    if (alpha == nil || [alpha isEqualToString:@""])
    {
        return Currency.UNKNOWN;
    }
    else
    {
        for(Currency *currency in [Currency AllCurrencies])
        {
            if ([alpha isEqualToString:[currency alpha]])
            {
                return currency;
            }
        }
    }
    
    return Currency.UNKNOWN;
}

- (NSString *)sendableCurrencyCode
{
    return [NSString stringWithFormat:@"%04ld", (long) self.code];
}

+ (Currency *)currencyFromCode:(NSNumber *)code
{
    
    if (code == nil || code == 0)
    {
        return Currency.UNKNOWN;
    }
    else
    {
        for(Currency *currency in [Currency AllCurrencies])
        {
            if ([code integerValue] == currency.code)
            {
                return currency;
            }
        }
    }
    
    return Currency.UNKNOWN;
}


@end
