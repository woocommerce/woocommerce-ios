import UIKit

/// Represents a shipping carrier in the Woo Shipping extension.
enum WooShippingCarrier: String, Comparable, CaseIterable {
    case ups
    case usps
    case dhlExpress = "dhlexpress"
    case dhlEcommerce = "dhlecommerce"
    case dhlEcommerceAsia = "dhlecommerceasia"

    var logo: UIImage? {
        switch self {
        case .ups:
            return UIImage(named: "shipping-label-ups-logo")
        case .usps:
            return UIImage(named: "shipping-label-usps-logo")
        case .dhlExpress, .dhlEcommerce, .dhlEcommerceAsia:
            return UIImage(named: "shipping-label-dhl-logo")
        }
    }

    var name: String {
        switch self {
        case .ups:
            "UPS"
        case .usps:
            "USPS"
        case .dhlExpress:
            "DHL Express"
        case .dhlEcommerce:
            "DHL eCommerce"
        case .dhlEcommerceAsia:
            "DHL eCommerce Asia"
        }
    }

    static func < (lhs: WooShippingCarrier, rhs: WooShippingCarrier) -> Bool {
        guard let lhsIndex = allCases.firstIndex(of: lhs),
              let rhsIndex = allCases.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}
