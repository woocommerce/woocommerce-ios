import Foundation
/// The 3-letter country code for supported currencies
///
public enum CurrencyCode: String, CaseIterable, Codable {
    // A
    case AED, AFN, ALL, AMD, ANG, AOA, ARS, AUD, AWG, AZN,
    // B
    BAM, BBD, BDT, BGN, BHD, BIF, BMD, BND, BOB, BRL, BSD, BTC, BTN, BWP, BYR, BYN, BZD,
    // C
    CAD, CDF, CHF, CLP, CNY, COP, CRC, CUC, CUP, CVE, CZK,
    // D
    DJF, DKK, DOP, DZD,
    // E
    EGP, ERN, ETB, EUR, FJD,
    // F
    FKP,
    // G
    GBP, GEL, GGP, GHS, GIP, GMD, GNF, GTQ, GYD,
    // H
    HKD, HNL, HRK, HTG, HUF,
    // I
    IDR, ILS, IMP, INR, IQD, IRR, IRT, ISK,
    // J
    JEP, JMD, JOD, JPY,
    // K
    KES, KGS, KHR, KMF, KPW, KRW, KWD, KYD, KZT,
    // L
    LAK, LBP, LKR, LRD, LSL, LYD,
    // M
    MAD, MDL, MGA, MKD, MMK, MNT, MOP, MRO, MUR, MVR, MWK, MXN, MYR, MZN,
    // N
    NAD, NGN, NIO, NOK, NPR, NZD,
    // O
    OMR,
    // P
    PAB, PEN, PGK, PHP, PKR, PLN, PRB, PYG,
    // Q
    QAR,
    // R
    RMB, RON, RSD, RUB, RWF,
    // S
    SAR, SBD, SCR, SDG, SEK, SGD, SHP, SLL, SOS, SRD, SSP, STD, SYP, SZL,
    // T
    THB, TJS, TMT, TND, TOP, TRY, TTD, TWD, TZS,
    // U
    UAH, UGX, USD, UYU, UZS,
    // V
    VEF, VND, VUV,
    // W
    WST,
    // X
    XAF, XCD, XOF, XPF,
    // Y
    YER,
    // Z
    ZAR, ZMW

    public init?(caseInsensitiveRawValue: String) {
        self.init(rawValue: caseInsensitiveRawValue.uppercased())
    }
}

public extension CurrencyCode {
    /// Sometimes we want to use the smallest currency unit when dealing with amounts. Use this multiplier to convert it to that unit.
    /// Source: Currency Decimals e.g. https://stripe.com/docs/currencies
    /// 
    var smallestCurrencyUnitMultiplier: Int {
        switch self {
        case .BIF, .CLP, .DJF, .GNF, .JPY, .KMF, .KRW, .MGA, .PYG, .RWF, .UGX, .VND, .VUV, .XAF, .XOF, .XPF:
            return 1
        case .BHD, .JOD, .KWD, .OMR, .TND:
            return 1000
        default:
            return 100
        }
    }
}

public extension CurrencyCode {
    var name: String {
        switch self {
        // A
        case .AED:
            return NSLocalizedString("United Arab Emirates Dirham", comment: "Currency name for AED")
        case .AFN:
            return NSLocalizedString("Afghan Afghani", comment: "Currency name for AFN")
        case .ALL:
            return NSLocalizedString("Albanian Lek", comment: "Currency name for ALL")
        case .AMD:
            return NSLocalizedString("Armenian Dram", comment: "Currency name for AMD")
        case .ANG:
            return NSLocalizedString("Netherlands Antillean Guilder", comment: "Currency name for ANG")
        case .AOA:
            return NSLocalizedString("Angolan Kwanza", comment: "Currency name for AOA")
        case .ARS:
            return NSLocalizedString("Argentine Peso", comment: "Currency name for ARS")
        case .AUD:
            return NSLocalizedString("Australian Dollar", comment: "Currency name for AUD")
        case .AWG:
            return NSLocalizedString("Aruban Florin", comment: "Currency name for AWG")
        case .AZN:
            return NSLocalizedString("Azerbaijani Manat", comment: "Currency name for AZN")
        // B
        case .BAM:
            return NSLocalizedString("Bosnia and Herzegovina Convertible Mark", comment: "Currency name for BAM")
        case .BBD:
            return NSLocalizedString("Barbadian Dollar", comment: "Currency name for BBD")
        case .BDT:
            return NSLocalizedString("Bangladeshi Taka", comment: "Currency name for BDT")
        case .BGN:
            return NSLocalizedString("Bulgarian Lev", comment: "Currency name for BGN")
        case .BHD:
            return NSLocalizedString("Bahraini Dinar", comment: "Currency name for BHD")
        case .BIF:
            return NSLocalizedString("Burundian Franc", comment: "Currency name for BIF")
        case .BMD:
            return NSLocalizedString("Bermudian Dollar", comment: "Currency name for BMD")
        case .BND:
            return NSLocalizedString("Brunei Dollar", comment: "Currency name for BND")
        case .BOB:
            return NSLocalizedString("Bolivian Boliviano", comment: "Currency name for BOB")
        case .BRL:
            return NSLocalizedString("Brazilian Real", comment: "Currency name for BRL")
        case .BSD:
            return NSLocalizedString("Bahamian Dollar", comment: "Currency name for BSD")
        case .BTC:
            return NSLocalizedString("Bitcoin", comment: "Currency name for BTC")
        case .BTN:
            return NSLocalizedString("Bhutanese Ngultrum", comment: "Currency name for BTN")
        case .BWP:
            return NSLocalizedString("Botswana Pula", comment: "Currency name for BWP")
        case .BYR:
            return NSLocalizedString("Belarusian Ruble (2000–2016)", comment: "Currency name for BYR")
        case .BYN:
            return NSLocalizedString("Belarusian Ruble (2016–present)", comment: "Currency name for BYN")
        case .BZD:
            return NSLocalizedString("Belize Dollar", comment: "Currency name for BZD")
        // C
        case .CAD:
            return NSLocalizedString("Canadian Dollar", comment: "Currency name for CAD")
        case .CDF:
            return NSLocalizedString("Congolese Franc", comment: "Currency name for CDF")
        case .CHF:
            return NSLocalizedString("Swiss Franc", comment: "Currency name for CHF")
        case .CLP:
            return NSLocalizedString("Chilean Peso", comment: "Currency name for CLP")
        case .CNY:
            return NSLocalizedString("Chinese Yuan", comment: "Currency name for CNY")
        case .COP:
            return NSLocalizedString("Colombian Peso", comment: "Currency name for COP")
        case .CRC:
            return NSLocalizedString("Costa Rican Colón", comment: "Currency name for CRC")
        case .CUC:
            return NSLocalizedString("Cuban Convertible Peso", comment: "Currency name for CUC")
        case .CUP:
            return NSLocalizedString("Cuban Peso", comment: "Currency name for CUP")
        case .CVE:
            return NSLocalizedString("Cape Verdean Escudo", comment: "Currency name for CVE")
        case .CZK:
            return NSLocalizedString("Czech Koruna", comment: "Currency name for CZK")
        // D
        case .DJF:
            return NSLocalizedString("Djiboutian Franc", comment: "Currency name for DJF")
        case .DKK:
            return NSLocalizedString("Danish Krone", comment: "Currency name for DKK")
        case .DOP:
            return NSLocalizedString("Dominican Peso", comment: "Currency name for DOP")
        case .DZD:
            return NSLocalizedString("Algerian Dinar", comment: "Currency name for DZD")
        // E
        case .EGP:
            return NSLocalizedString("Egyptian Pound", comment: "Currency name for EGP")
        case .ERN:
            return NSLocalizedString("Eritrean Nakfa", comment: "Currency name for ERN")
        case .ETB:
            return NSLocalizedString("Ethiopian Birr", comment: "Currency name for ETB")
        case .EUR:
            return NSLocalizedString("Euro", comment: "Currency name for EUR")
        case .FJD:
            return NSLocalizedString("Fijian Dollar", comment: "Currency name for FJD")
        // F
        case .FKP:
            return NSLocalizedString("Falkland Islands Pound", comment: "Currency name for FKP")
        // G
        case .GBP:
            return NSLocalizedString("Pound Sterling", comment: "Currency name for GBP")
        case .GEL:
            return NSLocalizedString("Georgian Lari", comment: "Currency name for GEL")
        case .GGP:
            return NSLocalizedString("Guernsey Pound", comment: "Currency name for GGP")
        case .GHS:
            return NSLocalizedString("Ghanaian Cedi", comment: "Currency name for GHS")
        case .GIP:
            return NSLocalizedString("Gibraltar Pound", comment: "Currency name for GIP")
        case .GMD:
            return NSLocalizedString("Gambian Dalasi", comment: "Currency name for GMD")
        case .GNF:
            return NSLocalizedString("Guinean Franc", comment: "Currency name for GNF")
        case .GTQ:
            return NSLocalizedString("Guatemalan Quetzal", comment: "Currency name for GTQ")
        case .GYD:
            return NSLocalizedString("Guyanaese Dollar", comment: "Currency name for GYD")
        // H
        case .HKD:
            return NSLocalizedString("Hong Kong Dollar", comment: "Currency name for HKD")
        case .HNL:
            return NSLocalizedString("Honduran Lempira", comment: "Currency name for HNL")
        case .HRK:
            return NSLocalizedString("Croatian Kuna", comment: "Currency name for HRK")
        case .HTG:
            return NSLocalizedString("Haitian Gourde", comment: "Currency name for HTG")
        case .HUF:
            return NSLocalizedString("Hungarian Forint", comment: "Currency name for HUF")
        // I
        case .IDR:
            return NSLocalizedString("Indonesian Rupiah", comment: "Currency name for IDR")
        case .ILS:
            return NSLocalizedString("Israeli New Sheqel", comment: "Currency name for ILS")
        case .IMP:
            return NSLocalizedString("Isle of Man Pound", comment: "Currency name for IMP")
        case .INR:
            return NSLocalizedString("Indian Rupee", comment: "Currency name for INR")
        case .IQD:
            return NSLocalizedString("Iraqi Dinar", comment: "Currency name for IQD")
        case .IRR:
            return NSLocalizedString("Iranian Rial", comment: "Currency name for IRR")
        case .IRT:
            return NSLocalizedString("Iranian Toman", comment: "Currency name for IRT")
        case .ISK:
            return NSLocalizedString("Icelandic Króna", comment: "Currency name for ISK")
        // J
        case .JEP:
            return NSLocalizedString("Jersey Pound", comment: "Currency name for JEP")
        case .JMD:
            return NSLocalizedString("Jamaican Dollar", comment: "Currency name for JMD")
        case .JOD:
            return NSLocalizedString("Jordanian Dinar", comment: "Currency name for JOD")
        case .JPY:
            return NSLocalizedString("Japanese Yen", comment: "Currency name for JPY")
        // K
        case .KES:
            return NSLocalizedString("Kenyan Shilling", comment: "Currency name for KES")
        case .KGS:
            return NSLocalizedString("Kyrgystani Som", comment: "Currency name for KGS")
        case .KHR:
            return NSLocalizedString("Cambodian Riel", comment: "Currency name for KHR")
        case .KMF:
            return NSLocalizedString("Comorian Franc", comment: "Currency name for KMF")
        case .KPW:
            return NSLocalizedString("North Korean Won", comment: "Currency name for KPW")
        case .KRW:
            return NSLocalizedString("South Korean Won", comment: "Currency name for KRW")
        case .KWD:
            return NSLocalizedString("Kuwaiti Dinar", comment: "Currency name for KWD")
        case .KYD:
            return NSLocalizedString("Cayman Islands Dollar", comment: "Currency name for KYD")
        case .KZT:
            return NSLocalizedString("Kazakhstani Tenge", comment: "Currency name for KZT")
        // L
        case .LAK:
            return NSLocalizedString("Laotian Kip", comment: "Currency name for LAK")
        case .LBP:
            return NSLocalizedString("Lebanese Pound", comment: "Currency name for LBP")
        case .LKR:
            return NSLocalizedString("Sri Lankan Rupee", comment: "Currency name for LKR")
        case .LRD:
            return NSLocalizedString("Liberian Dollar", comment: "Currency name for LRD")
        case .LSL:
            return NSLocalizedString("Lesotho Loti", comment: "Currency name for LSL")
        case .LYD:
            return NSLocalizedString("Libyan Dinar", comment: "Currency name for LYD")
        // M
        case .MAD:
            return NSLocalizedString("Moroccan Dirham", comment: "Currency name for MAD")
        case .MDL:
            return NSLocalizedString("Moldovan Leu", comment: "Currency name for MDL")
        case .MGA:
            return NSLocalizedString("Malagasy Ariary", comment: "Currency name for MGA")
        case .MKD:
            return NSLocalizedString("Macedonian Denar", comment: "Currency name for MKD")
        case .MMK:
            return NSLocalizedString("Myanmar Kyat", comment: "Currency name for MMK")
        case .MNT:
            return NSLocalizedString("Mongolian Tugrik", comment: "Currency name for MNT")
        case .MOP:
            return NSLocalizedString("Macanese Pataca", comment: "Currency name for MOP")
        case .MRO:
            return NSLocalizedString("Mauritanian Ouguiya", comment: "Currency name for MRO")
        case .MUR:
            return NSLocalizedString("Mauritian Rupee", comment: "Currency name for MUR")
        case .MVR:
            return NSLocalizedString("Maldivian Rufiyaa", comment: "Currency name for MVR")
        case .MWK:
            return NSLocalizedString("Malawian Kwacha", comment: "Currency name for MWK")
        case .MXN:
            return NSLocalizedString("Mexican Peso", comment: "Currency name for MXN")
        case .MYR:
            return NSLocalizedString("Malaysian Ringgit", comment: "Currency name for MYR")
        case .MZN:
            return NSLocalizedString("Mozambican Metical", comment: "Currency name for MZN")
        // N
        case .NAD:
            return NSLocalizedString("Namibian Dollar", comment: "Currency name for NAD")
        case .NGN:
            return NSLocalizedString("Nigerian Naira", comment: "Currency name for NGN")
        case .NIO:
            return NSLocalizedString("Nicaraguan Córdoba", comment: "Currency name for NIO")
        case .NOK:
            return NSLocalizedString("Norwegian Krone", comment: "Currency name for NOK")
        case .NPR:
            return NSLocalizedString("Nepalese Rupee", comment: "Currency name for NPR")
        case .NZD:
            return NSLocalizedString("New Zealand Dollar", comment: "Currency name for NZD")
        // O
        case .OMR:
            return NSLocalizedString("Omani Rial", comment: "Currency name for OMR")
        // P
        case .PAB:
            return NSLocalizedString("Panamanian Balboa", comment: "Currency name for PAB")
        case .PEN:
            return NSLocalizedString("Peruvian Nuevo Sol", comment: "Currency name for PEN")
        case .PGK:
            return NSLocalizedString("Papua New Guinean Kina", comment: "Currency name for PGK")
        case .PHP:
            return NSLocalizedString("Philippine Peso", comment: "Currency name for PHP")
        case .PKR:
            return NSLocalizedString("Pakistani Rupee", comment: "Currency name for PKR")
        case .PLN:
            return NSLocalizedString("Polish Złoty", comment: "Currency name for PLN")
        case .PRB:
            return NSLocalizedString("Transnistrian Ruble", comment: "Currency name for PRB")
        case .PYG:
            return NSLocalizedString("Paraguayan Guarani", comment: "Currency name for PYG")
        // Q
        case .QAR:
            return NSLocalizedString("Qatari Riyal", comment: "Currency name for QAR")
        // R
        case .RMB:
            return NSLocalizedString("Chinese Renminbi (Yuan)", comment: "Currency name for RMB")
        case .RON:
            return NSLocalizedString("Romanian Leu", comment: "Currency name for RON")
        case .RSD:
            return NSLocalizedString("Serbian Dinar", comment: "Currency name for RSD")
        case .RUB:
            return NSLocalizedString("Russian Ruble", comment: "Currency name for RUB")
        case .RWF:
            return NSLocalizedString("Rwandan Franc", comment: "Currency name for RWF")
        // S
        case .SAR:
            return NSLocalizedString("Saudi Riyal", comment: "Currency name for SAR")
        case .SBD:
            return NSLocalizedString("Solomon Islands Dollar", comment: "Currency name for SBD")
        case .SCR:
            return NSLocalizedString("Seychellois Rupee", comment: "Currency name for SCR")
        case .SDG:
            return NSLocalizedString("Sudanese Pound", comment: "Currency name for SDG")
        case .SEK:
            return NSLocalizedString("Swedish Krona", comment: "Currency name for SEK")
        case .SGD:
            return NSLocalizedString("Singapore Dollar", comment: "Currency name for SGD")
        case .SHP:
            return NSLocalizedString("Saint Helena Pound", comment: "Currency name for SHP")
        case .SLL:
            return NSLocalizedString("Sierra Leonean Leone", comment: "Currency name for SLL")
        case .SOS:
            return NSLocalizedString("Somali Shilling", comment: "Currency name for SOS")
        case .SRD:
            return NSLocalizedString("Surinamese Dollar", comment: "Currency name for SRD")
        case .SSP:
            return NSLocalizedString("South Sudanese Pound", comment: "Currency name for SSP")
        case .STD:
            return NSLocalizedString("São Tomé and Príncipe Dobra", comment: "Currency name for STD")
        case .SYP:
            return NSLocalizedString("Syrian Pound", comment: "Currency name for SYP")
        case .SZL:
            return NSLocalizedString("Swazi Lilangeni", comment: "Currency name for SZL")
        // T
        case .THB:
            return NSLocalizedString("Thai Baht", comment: "Currency name for THB")
        case .TJS:
            return NSLocalizedString("Tajikistani Somoni", comment: "Currency name for TJS")
        case .TMT:
            return NSLocalizedString("Turkmenistan Manat", comment: "Currency name for TMT")
        case .TND:
            return NSLocalizedString("Tunisian Dinar", comment: "Currency name for TND")
        case .TOP:
            return NSLocalizedString("Tongan Paʻanga", comment: "Currency name for TOP")
        case .TRY:
            return NSLocalizedString("Turkish Lira", comment: "Currency name for TRY")
        case .TTD:
            return NSLocalizedString("Trinidad and Tobago Dollar", comment: "Currency name for TTD")
        case .TWD:
            return NSLocalizedString("New Taiwan Dollar", comment: "Currency name for TWD")
        case .TZS:
            return NSLocalizedString("Tanzanian Shilling", comment: "Currency name for TZS")
        // U
        case .UAH:
            return NSLocalizedString("Ukrainian Hryvnia", comment: "Currency name for UAH")
        case .UGX:
            return NSLocalizedString("Ugandan Shilling", comment: "Currency name for UGX")
        case .USD:
            return NSLocalizedString("US Dollar", comment: "Currency name for USD")
        case .UYU:
            return NSLocalizedString("Uruguayan Peso", comment: "Currency name for UYU")
        case .UZS:
            return NSLocalizedString("Uzbekistan Som", comment: "Currency name for UZS")
        // V
        case .VEF:
            return NSLocalizedString("Venezuelan Bolívar", comment: "Currency name for VEF")
        case .VND:
            return NSLocalizedString("Vietnamese Dong", comment: "Currency name for VND")
        case .VUV:
            return NSLocalizedString("Vanuatu Vatu", comment: "Currency name for VUV")
        // W
        case .WST:
            return NSLocalizedString("Samoan Tala", comment: "Currency name for WST")
        // X
        case .XAF:
            return NSLocalizedString("Central African CFA Franc", comment: "Currency name for XAF")
        case .XCD:
            return NSLocalizedString("East Caribbean Dollar", comment: "Currency name for XCD")
        case .XOF:
            return NSLocalizedString("West African CFA Franc", comment: "Currency name for XOF")
        case .XPF:
            return NSLocalizedString("CFP Franc", comment: "Currency name for XPF")
        // Y
        case .YER:
            return NSLocalizedString("Yemeni Rial", comment: "Currency name for YER")
        // Z
        case .ZAR:
            return NSLocalizedString("South African Rand", comment: "Currency name for ZAR")
        case .ZMW:
            return NSLocalizedString("Zambian Kwacha", comment: "Currency name for ZMW")
        }
    }
}

