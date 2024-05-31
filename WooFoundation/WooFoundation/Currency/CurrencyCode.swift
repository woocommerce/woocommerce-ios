import Foundation
import Codegen
/// The 3-letter country code for supported currencies
///
public enum CurrencyCode: String, CaseIterable, Codable, GeneratedFakeable {
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
