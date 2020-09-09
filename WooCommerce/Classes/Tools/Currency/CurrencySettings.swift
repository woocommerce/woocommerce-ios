import Foundation
import Yosemite

/// Site-wide settings for displaying prices/money
///
public class CurrencySettings {

    // MARK: - Enums

    /// The 3-letter country code for supported currencies
    ///
    public enum CurrencyCode: String, CaseIterable {
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
    }

    /// Designates where the currency symbol is located on a formatted price
    ///
    public enum CurrencyPosition: String {
        case left = "left"
        case right = "right"
        case leftSpace = "left_space"
        case rightSpace = "right_space"
    }

    /// Default currency settings
    ///
    public enum Default {
        static let code = CurrencyCode.USD
        static let position = CurrencyPosition.left
        static let thousandSeparator = ","
        static let decimalSeparator = "."
        static let decimalPosition = 2
    }


    // MARK: - Variables

    /// Public variables, privately set
    ///
    public private(set) var currencyCode: CurrencyCode
    public private(set) var currencyPosition: CurrencyPosition
    public private(set) var thousandSeparator: String
    public private(set) var decimalSeparator: String
    public private(set) var numberOfDecimals: Int

    // MARK: - Initializers & Methods

    /// Designated Initializer:
    /// Used primarily for testing and by the convenience initializers.
    ///
    init(currencyCode: CurrencyCode, currencyPosition: CurrencyPosition, thousandSeparator: String, decimalSeparator: String, numberOfDecimals: Int) {
        self.currencyCode = currencyCode
        self.currencyPosition = currencyPosition
        self.thousandSeparator = thousandSeparator
        self.decimalSeparator = decimalSeparator
        self.numberOfDecimals = numberOfDecimals
    }


    /// Convenience Initializer:
    /// Provides some defaults for when site settings aren't available
    ///
    convenience init() {
        self.init(currencyCode: CurrencySettings.Default.code,
                  currencyPosition: CurrencySettings.Default.position,
                  thousandSeparator: CurrencySettings.Default.thousandSeparator,
                  decimalSeparator: CurrencySettings.Default.decimalSeparator,
                  numberOfDecimals: CurrencySettings.Default.decimalPosition)
    }

    /// Convenience Initializer:
    /// This is the preferred way to create an instance with the settings coming from the site.
    ///
    convenience init(siteSettings: [SiteSetting]) {
        self.init()

        siteSettings.forEach { updateCurrencyOptions(with: $0) }
    }

    func updateCurrencyOptions(with siteSetting: SiteSetting) {
        let value = siteSetting.value

        switch siteSetting.settingID {
        case Constants.currencyCodeKey:
            let currencyCode = CurrencyCode(rawValue: value) ?? CurrencySettings.Default.code
            self.currencyCode = currencyCode
        case Constants.currencyPositionKey:
            let currencyPosition = CurrencyPosition(rawValue: value) ?? CurrencySettings.Default.position
            self.currencyPosition = currencyPosition
        case Constants.thousandSeparatorKey:
            self.thousandSeparator = value
        case Constants.decimalSeparatorKey:
            self.decimalSeparator = value
        case Constants.numberOfDecimalsKey:
            let numberOfDecimals = Int(value) ?? CurrencySettings.Default.decimalPosition
            self.numberOfDecimals = numberOfDecimals
        default:
            break
        }
    }

    /// Returns the currency symbol associated with the specified country code.
    ///
    func symbol(from code: CurrencyCode) -> String {
        // Currency codes pulled from WC:
        // https://docs.woocommerce.com/wc-apidocs/source-function-get_woocommerce_currency.html#473
        switch code {
        case .AED:
            return "\u{62f}.\u{625}"
        case .AFN:
            return "\u{60b}"
        case .ALL:
            return "L"
        case .AMD:
            return "AMD"
        case .ANG:
            return "\u{0192}"
        case .AOA:
            return "Kz"
        case .ARS:
            return "\u{0024}"
        case .AUD:
            return "\u{0024}"
        case .AWG:
            return "Afl."
        case .AZN:
            return "AZN"
        case .BAM:
            return "KM"
        case .BBD:
            return "\u{0024}"
        case .BDT:
            return "\u{2547}\u{00A0}"
        case .BGN:
            return "\u{43b}\u{432}."
        case .BHD:
            return ".\u{62f}.\u{628}"
        case .BIF:
            return "Fr"
        case .BMD:
            return "\u{0024}"
        case .BND:
            return "\u{0024}"
        case .BOB:
            return "Bs."
        case .BRL:
            return "\u{52}\u{24}"
        case .BSD:
            return "\u{0024}"
        case .BTC:
            return "\u{e3f}"
        case .BTN:
            return "Nu."
        case .BWP:
            return "P"
        case .BYR:
            return "Br"
        case .BYN:
            return "Br"
        case .BZD:
            return "\u{0024}"
        case .CAD:
            return "\u{0024}"
        case .CDF:
            return "Fr"
        case .CHF:
            return "\u{43}\u{48}\u{46}"
        case .CLP:
            return "\u{0024}"
        case .CNY:
            return "\u{00A5}"
        case .COP:
            return "\u{0024}"
        case .CRC:
            return "\u{20a1}"
        case .CUC:
            return "\u{0024}"
        case .CUP:
            return "\u{0024}"
        case .CVE:
            return "\u{0024}"
        case .CZK:
            return "\u{4b}\u{10d}"
        case .DJF:
            return "Fr"
        case .DKK:
            return "DKK"
        case .DOP:
            return "RD\u{0024}"
        case .DZD:
            return "\u{62f}.\u{62c}"
        case .EGP:
            return "EGP"
        case .ERN:
            return "Nfk"
        case .ETB:
            return "Br"
        case .EUR:
            return "\u{20AC}"
        case .FJD:
            return "\u{0024}"
        case .FKP:
            return "\u{00A3}"
        case .GBP:
            return "\u{00A3}"
        case .GEL:
            return "\u{10da}"
        case .GGP:
            return "\u{00A3}"
        case .GHS:
            return "\u{20b5}"
        case .GIP:
            return "\u{00A3}"
        case .GMD:
            return "D"
        case .GNF:
            return "Fr"
        case .GTQ:
            return "Q"
        case .GYD:
            return "\u{0024}"
        case .HKD:
            return "\u{0024}"
        case .HNL:
            return "L"
        case .HRK:
            return "Kn"
        case .HTG:
            return "G"
        case .HUF:
            return "\u{46}\u{74}"
        case .IDR:
            return "Rp"
        case .ILS:
            return "\u{20aa}"
        case .IMP:
            return "\u{00A3}"
        case .INR:
            return "\u{20B9}"
        case .IQD:
            return "\u{639}.\u{62f}"
        case .IRR:
            return "\u{fdfc}"
        case .IRT:
            return "\u{062A}\u{0648}\u{0645}\u{0627}\u{0646}"
        case .ISK:
            return "kr."
        case .JEP:
            return "\u{00A3}"
        case .JMD:
            return "\u{0024}"
        case .JOD:
            return "\u{62f}.\u{627}"
        case .JPY:
            return "\u{00A5}"
        case .KES:
            return "KSh"
        case .KGS:
            return "\u{441}\u{43e}\u{43c}"
        case .KHR:
            return "\u{17db}"
        case .KMF:
            return "Fr"
        case .KPW:
            return "\u{20a9}"
        case .KRW:
            return "\u{20a9}"
        case .KWD:
            return "\u{62f}.\u{643}"
        case .KYD:
            return "\u{0024}"
        case .KZT:
            return "KZT"
        case .LAK:
            return "\u{20ad}"
        case .LBP:
            return "\u{644}.\u{644}"
        case .LKR:
            return "\u{dbb}\u{dd4}"
        case .LRD:
            return "\u{0024}"
        case .LSL:
            return "L"
        case .LYD:
            return "\u{644}.\u{62f}"
        case .MAD:
            return "\u{62f}.\u{645}."
        case .MDL:
            return "MDL"
        case .MGA:
            return "Ar"
        case .MKD:
            return "\u{434}\u{435}\u{43d}"
        case .MMK:
            return "Ks"
        case .MNT:
            return "\u{20ae}"
        case .MOP:
            return "P"
        case .MRO:
            return "UM"
        case .MUR:
            return "\u{20a8}"
        case .MVR:
            return ".\u{783}"
        case .MWK:
            return "MK"
        case .MXN:
            return "\u{0024}"
        case .MYR:
            return "\u{52}\u{4d}"
        case .MZN:
            return "MT"
        case .NAD:
            return "\u{0024}"
        case .NGN:
            return "\u{20a6}"
        case .NIO:
            return "C\u{0024}"
        case .NOK:
            return "\u{6b}\u{72}"
        case .NPR:
            return "\u{20a8}"
        case .NZD:
            return "\u{0024}"
        case .OMR:
            return "\u{631}.\u{639}."
        case .PAB:
            return "B/."
        case .PEN:
            return "S/."
        case .PGK:
            return "K"
        case .PHP:
            return "\u{20b1}"
        case .PKR:
            return "\u{20a8}"
        case .PLN:
            return "\u{7a}\u{142}"
        case .PRB:
            return "\u{440}."
        case .PYG:
            return "\u{47}\u{73}"
        case .QAR:
            return "\u{631}.\u{642}"
        case .RMB:
            return "\u{00A5}"
        case .RON:
            return "lei"
        case .RSD:
            return "\u{434}\u{438}\u{43d}."
        case .RUB:
            return "\u{20bd}"
        case .RWF:
            return "Fr"
        case .SAR:
            return "\u{631}.\u{633}"
        case .SBD:
            return "\u{0024}"
        case .SCR:
            return "\u{20a8}"
        case .SDG:
            return "\u{62c}.\u{633}."
        case .SEK:
            return "\u{6b}\u{72}"
        case .SGD:
            return "\u{0024}"
        case .SHP:
            return "\u{00A3}"
        case .SLL:
            return "Le"
        case .SOS:
            return "Sh"
        case .SRD:
            return "\u{0024}"
        case .SSP:
            return "\u{00A3}"
        case .STD:
            return "Db"
        case .SYP:
            return "\u{644}.\u{633}"
        case .SZL:
            return "L"
        case .THB:
            return "\u{e3f}"
        case .TJS:
            return "\u{405}\u{41c}"
        case .TMT:
            return "m"
        case .TND:
            return "\u{62f}.\u{62a}"
        case .TOP:
            return "T\u{0024}"
        case .TRY:
            return "\u{20BA}"
        case .TTD:
            return "\u{0024}"
        case .TWD:
            return "\u{4e}\u{54}\u{24}"
        case .TZS:
            return "Sh"
        case .UAH:
            return "\u{20b4}"
        case .UGX:
            return "UGX"
        case .USD:
            return "\u{0024}"
        case .UYU:
            return "\u{0024}"
        case .UZS:
            return "UZS"
        case .VEF:
            return "Bs F"
        case .VND:
            return "\u{20ab}"
        case .VUV:
            return "Vt"
        case .WST:
            return "T"
        case .XAF:
            return "CFA"
        case .XCD:
            return "\u{0024}"
        case .XOF:
            return "CFA"
        case .XPF:
            return "Fr"
        case .YER:
            return "\u{fdfc}"
        case .ZAR:
            return "\u{52}"
        case .ZMW:
            return "ZK"
        }
    }
}


// MARK: - Constants!
//
private extension CurrencySettings {

    enum Constants {
        static let currencyCodeKey = "woocommerce_currency"
        static let currencyPositionKey = "woocommerce_currency_pos"
        static let thousandSeparatorKey = "woocommerce_price_thousand_sep"
        static let decimalSeparatorKey = "woocommerce_price_decimal_sep"
        static let numberOfDecimalsKey = "woocommerce_price_num_decimals"
    }
}
