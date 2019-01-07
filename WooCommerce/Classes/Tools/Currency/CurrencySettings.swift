import Foundation
import Yosemite

/// Site-wide settings for displaying prices/money
///
public class CurrencySettings {
    /// Shared Instance
    ///
    static let shared = CurrencySettings()


    // MARK: - Enums

    /// The 3-letter country code for supported currencies
    ///
    public enum CurrencyCode: String, CaseIterable {
        case AED, AFN, ALL, AMD, ANG, AOA, ARS, AUD, AWG, AZN, BAM, BBD, BDT, BGN, BHD, BIF, BMD, BND, BOB, BRL, BSD, BTC, BTN, BWP, BYR, BYN, BZD, CAD, CDF, CHF, CLP, CNY, COP, CRC, CUC, CUP, CVE, CZK, DJF, DKK, DOP, DZD, EGP, ERN, ETB, EUR, FJD, FKP, GBP, GEL, GGP, GHS, GIP, GMD, GNF, GTQ, GYD, HKD, HNL, HRK, HTG, HUF, IDR, ILS, IMP, INR, IQD, IRR, IRT, ISK, JEP, JMD, JOD, JPY, KES, KGS, KHR, KMF, KPW, KRW, KWD, KYD, KZT, LAK, LBP, LKR, LRD, LSL, LYD, MAD, MDL, MGA, MKD, MMK, MNT, MOP, MRO, MUR, MVR, MWK, MXN, MYR, MZN, NAD, NGN, NIO, NOK, NPR, NZD, OMR, PAB, PEN, PGK, PHP, PKR, PLN, PRB, PYG, QAR, RMB, RON, RSD, RUB, RWF, SAR, SBD, SCR, SDG, SEK, SGD, SHP, SLL, SOS, SRD, SSP, STD, SYP, SZL, THB, TJS, TMT, TND, TOP, TRY, TTD, TWD, TZS, UAH, UGX, USD, UYU, UZS, VEF, VND, VUV, WST, XAF, XCD, XOF, XPF, YER, ZAR, ZMW
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

    /// ResultsController: Whenever settings change, I will change. We both change. The world changes.
    ///
    private lazy var resultsController: ResultsController<StorageSiteSetting> = {
        let storageManager = AppDelegate.shared.storageManager

        let resultsController = ResultsController<StorageSiteSetting>(storageManager: storageManager, sectionNameKeyPath: nil, sortedBy: [])

        resultsController.onDidChangeObject = { [weak self] (object, indexPath, type, newIndexPath) in
            self?.updateCurrencyOptions(with: object)
        }

        return resultsController
    }()


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
    /// Provides sane defaults for when site settings aren't available
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

    func beginListeningToSiteSettingsUpdates() {
        try? resultsController.performFetch()
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
            return "&#x62f;.&#x625;".strippedHTML
        case .AFN:
            return "&#x60b;".strippedHTML
        case .ALL:
            return "L"
        case .AMD:
            return "AMD"
        case .ANG:
            return "&fnof;".strippedHTML
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
            return "&#2547;&nbsp;".strippedHTML
        case .BGN:
            return "&#1083;&#1074;.".strippedHTML
        case .BHD:
            return ".&#x62f;.&#x628;".strippedHTML
        case .BIF:
            return "Fr"
        case .BMD:
            return "\u{0024}"
        case .BND:
            return "\u{0024}"
        case .BOB:
            return "Bs."
        case .BRL:
            return "&#82;&#36;".strippedHTML
        case .BSD:
            return "\u{0024}"
        case .BTC:
            return "&#3647;".strippedHTML
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
            return "&#67;&#72;&#70;".strippedHTML
        case .CLP:
            return "\u{0024}"
        case .CNY:
            return "&yen;".strippedHTML
        case .COP:
            return "\u{0024}"
        case .CRC:
            return "&#x20a1;".strippedHTML
        case .CUC:
            return "\u{0024}"
        case .CUP:
            return "\u{0024}"
        case .CVE:
            return "\u{0024}"
        case .CZK:
            return "&#75;&#269;".strippedHTML
        case .DJF:
            return "Fr"
        case .DKK:
            return "DKK"
        case .DOP:
            return "RD\u{0024}".strippedHTML
        case .DZD:
            return "&#x62f;.&#x62c;".strippedHTML
        case .EGP:
            return "EGP"
        case .ERN:
            return "Nfk"
        case .ETB:
            return "Br"
        case .EUR:
            return "&euro;".strippedHTML
        case .FJD:
            return "\u{0024}"
        case .FKP:
            return "\u{00A3}"
        case .GBP:
            return "\u{00A3}"
        case .GEL:
            return "&#x10da;".strippedHTML
        case .GGP:
            return "\u{00A3}"
        case .GHS:
            return "&#x20b5;".strippedHTML
        case .GIP:
            return "\u{00A3}"
        case .GMD:
            return "D".strippedHTML
        case .GNF:
            return "Fr".strippedHTML
        case .GTQ:
            return "Q".strippedHTML
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
            return "&#70;&#116;".strippedHTML
        case .IDR:
            return "Rp"
        case .ILS:
            return "&#8362;".strippedHTML
        case .IMP:
            return "\u{00A3}"
        case .INR:
            return "&#8377;".strippedHTML
        case .IQD:
            return "&#x639;.&#x62f;".strippedHTML
        case .IRR:
            return "&#xfdfc;".strippedHTML
        case .IRT:
            return "&#x062A;&#x0648;&#x0645;&#x0627;&#x0646;".strippedHTML
        case .ISK:
            return "kr."
        case .JEP:
            return "\u{00A3}"
        case .JMD:
            return "\u{0024}"
        case .JOD:
            return "&#x62f;.&#x627;".strippedHTML
        case .JPY:
            return "&yen;".strippedHTML
        case .KES:
            return "KSh"
        case .KGS:
            return "&#x441;&#x43e;&#x43c;".strippedHTML
        case .KHR:
            return "&#x17db;".strippedHTML
        case .KMF:
            return "Fr"
        case .KPW:
            return "&#x20a9;".strippedHTML
        case .KRW:
            return "&#8361;".strippedHTML
        case .KWD:
            return "&#x62f;.&#x643;".strippedHTML
        case .KYD:
            return "\u{0024}"
        case .KZT:
            return "KZT"
        case .LAK:
            return "&#8365;".strippedHTML
        case .LBP:
            return "&#x644;.&#x644;".strippedHTML
        case .LKR:
            return "&#xdbb;&#xdd4;".strippedHTML
        case .LRD:
            return "\u{0024}"
        case .LSL:
            return "L"
        case .LYD:
            return "&#x644;.&#x62f;".strippedHTML
        case .MAD:
            return "&#x62f;.&#x645;.".strippedHTML
        case .MDL:
            return "MDL"
        case .MGA:
            return "Ar"
        case .MKD:
            return "&#x434;&#x435;&#x43d;".strippedHTML
        case .MMK:
            return "Ks"
        case .MNT:
            return "&#x20ae;".strippedHTML
        case .MOP:
            return "P"
        case .MRO:
            return "UM"
        case .MUR:
            return "&#x20a8;".strippedHTML
        case .MVR:
            return ".&#x783;".strippedHTML
        case .MWK:
            return "MK"
        case .MXN:
            return "\u{0024}"
        case .MYR:
            return "&#82;&#77;".strippedHTML
        case .MZN:
            return "MT"
        case .NAD:
            return "\u{0024}"
        case .NGN:
            return "&#8358;".strippedHTML
        case .NIO:
            return "C\u{0024}".strippedHTML
        case .NOK:
            return "&#107;&#114;".strippedHTML
        case .NPR:
            return "&#8360;".strippedHTML
        case .NZD:
            return "\u{0024}"
        case .OMR:
            return "&#x631;.&#x639;.".strippedHTML
        case .PAB:
            return "B/.".strippedHTML
        case .PEN:
            return "S/.".strippedHTML
        case .PGK:
            return "K".strippedHTML
        case .PHP:
            return "&#8369;".strippedHTML
        case .PKR:
            return "&#8360;".strippedHTML
        case .PLN:
            return "&#122;&#322;".strippedHTML
        case .PRB:
            return "&#x440;.".strippedHTML
        case .PYG:
            return "&#8370;".strippedHTML
        case .QAR:
            return "&#x631;.&#x642;".strippedHTML
        case .RMB:
            return "&yen;".strippedHTML
        case .RON:
            return "lei"
        case .RSD:
            return "&#x434;&#x438;&#x43d;.".strippedHTML
        case .RUB:
            return "&#8381;".strippedHTML
        case .RWF:
            return "Fr"
        case .SAR:
            return "&#x631;.&#x633;".strippedHTML
        case .SBD:
            return "\u{0024}"
        case .SCR:
            return "&#x20a8;".strippedHTML
        case .SDG:
            return "&#x62c;.&#x633;.".strippedHTML
        case .SEK:
            return "&#107;&#114;".strippedHTML
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
            return "&#x644;.&#x633;".strippedHTML
        case .SZL:
            return "L"
        case .THB:
            return "&#3647;".strippedHTML
        case .TJS:
            return "&#x405;&#x41c;".strippedHTML
        case .TMT:
            return "m"
        case .TND:
            return "&#x62f;.&#x62a;".strippedHTML
        case .TOP:
            return "T\u{0024}".strippedHTML
        case .TRY:
            return "&#8378;".strippedHTML
        case .TTD:
            return "\u{0024}"
        case .TWD:
            return "&#78;&#84;&#36;".strippedHTML
        case .TZS:
            return "Sh"
        case .UAH:
            return "&#8372;".strippedHTML
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
            return "&#8363;".strippedHTML
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
            return "&#xfdfc;".strippedHTML
        case .ZAR:
            return "&#82;".strippedHTML
        case .ZMW:
            return "ZK"
        }
    }
}


// MARK: -

private extension CurrencySettings {
    enum Constants {
        static let currencyCodeKey = "woocommerce_currency"
        static let currencyPositionKey = "woocommerce_currency_pos"
        static let thousandSeparatorKey = "woocommerce_price_thousand_sep"
        static let decimalSeparatorKey = "woocommerce_price_decimal_sep"
        static let numberOfDecimalsKey = "woocommerce_price_num_decimals"
    }
}
