import Foundation
import struct Yosemite.ShippingLabel

/// Generates a tracking URL for a shipping label based on the carrier.
struct ShippingLabelTrackingURLGenerator {
    static func url(for shippingLabel: ShippingLabel) -> URL? {
        guard let carrier = ShippingLabelCarrier(rawValue: shippingLabel.carrierID), shippingLabel.trackingNumber.isNotEmpty else {
            return nil
        }
        return URL(string: carrier.urlString(trackingNumber: shippingLabel.trackingNumber))
    }
}

private enum ShippingLabelCarrier: String {
    case USPS = "usps"
    case FedEx = "fedex"
    case UPS = "ups"
    case DHL = "dhl"
    case DHLExpress = "dhlexpress"
}

private extension ShippingLabelCarrier {
    func urlString(trackingNumber: String) -> String {
        switch self {
        case .USPS:
            return "https://tools.usps.com/go/TrackConfirmAction.action?tLabels=\(trackingNumber)"
        case .FedEx:
            return "https://www.fedex.com/apps/fedextrack/?action=track&tracknumbers=\(trackingNumber)"
        case .UPS:
            return "https://www.ups.com/track?loc=en_US&tracknum=\(trackingNumber)"
        case .DHL, .DHLExpress:
            return "https://www.dhl.com/en/express/tracking.html?AWB=\(trackingNumber)&brand=DHL"
        }
    }
}
