import Foundation
import Yosemite

final class SiteCountry {
    /// ResultsController: Whenever settings change, I will change. We both change. The world changes.
    ///
    private lazy var resultsController: ResultsController<StorageSiteSetting> = {
        let storageManager = AppDelegate.shared.storageManager
        let sitePredicate = NSPredicate(format: "siteID == %lld", StoresManager.shared.sessionManager.defaultStoreID ?? Int.min)
        let settingCountryPredicate = NSPredicate(format: "settingID ==[c] %@", Constants.countryKey)

        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sitePredicate, settingCountryPredicate])

        let siteIDKeyPath = #keyPath(StorageSiteSetting.siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageSiteSetting.siteID, ascending: false)
        return ResultsController<StorageSiteSetting>(storageManager: storageManager, sectionNameKeyPath: siteIDKeyPath, matching: compoundPredicate, sortedBy: [descriptor])
    }()

    init() {
        configureResultsController()
    }

    var siteCountry: String? {
        print("==== first ", resultsController.fetchedObjects.first)
        return resultsController.fetchedObjects.first?.value
    }

    /// Setup: ResultsController
    ///
    private func configureResultsController() {
        try? resultsController.performFetch()
    }
}


extension SiteCountry {
    enum CountryCode: String, CaseIterable {
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
}


// MARK: - Constants!
//
private extension SiteCountry {

    enum Constants {
        static let countryKey = "woocommerce_default_country"
    }
}
