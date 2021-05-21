import SwiftUI
import Yosemite

struct ShippingLabelCarrierRow: View {

    private let viewModel: ShippingLabelCarrierRowViewModel

    init(_ viewModel: ShippingLabelCarrierRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack(spacing: Constants.hStackSpacing) {
            if let image = viewModel.carrierLogo {
                ZStack {
                    Image(uiImage: image).frame(width: Constants.imageSize, height: Constants.imageSize)
                }
                .frame(width: Constants.zStackWidth)
            }
            VStack(alignment: .leading,
                   spacing: Constants.vStackSpacing) {
                HStack {
                    Text(viewModel.title)
                        .bodyStyle()
                    Spacer()
                    Text(viewModel.price)
                        .bodyStyle()
                }
                Text(viewModel.subtitle)
                    .footnoteStyle()
            }
        }
        .padding([.top, .bottom], Constants.hStackPadding)
        .padding([.leading, .trailing], Constants.padding)
        .frame(minHeight: Constants.minHeight)
        .contentShape(Rectangle())
    }
}

private extension ShippingLabelCarrierRow {
    enum Constants {
        static let zStackWidth: CGFloat = 48
        static let vStackSpacing: CGFloat = 8
        static let hStackSpacing: CGFloat = 25
        static let hStackPadding: CGFloat = 10
        static let minHeight: CGFloat = 60
        static let imageSize: CGFloat = 40
        static let padding: CGFloat = 16
    }
}

struct ShippingLabelCarrierRowViewModel: Identifiable {
    internal let id = UUID()
    let selected: Bool
    let rate: ShippingLabelCarrierRate
    let signatureRate: ShippingLabelCarrierRate?
    let adultSignatureRate: ShippingLabelCarrierRate?

    let title: String
    let subtitle: String
    let price: String
    var carrierLogo: UIImage?

    init(selected: Bool,
         rate: ShippingLabelCarrierRate,
         signatureRate: ShippingLabelCarrierRate? = nil,
         adultSignatureRate: ShippingLabelCarrierRate? = nil,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.selected = selected
        self.rate = rate
        self.signatureRate = signatureRate
        self.adultSignatureRate = adultSignatureRate

        title = rate.title
        let formatString = rate.deliveryDays == 1 ? Localization.businessDaySingular : Localization.businessDaysPlural
        subtitle = String(format: formatString, rate.deliveryDays)

        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        price = currencyFormatter.formatAmount(Decimal(rate.retailRate)) ?? ""

        carrierLogo = CarrierLogo(rawValue: rate.carrierID)?.image()
    }

    enum Localization {
        static let businessDaySingular =
            NSLocalizedString("%1$d business day", comment: "Singular format of number of business day in Shipping Labels > Carrier and Rates")
        static let businessDaysPlural =
            NSLocalizedString("%1$d business days", comment: "Plural format of number of business days in Shipping Labels > Carrier and Rates")
    }

    enum CarrierLogo: String {
        case ups
        case usps
        case dhlExpress = "dhlexpress"
        case dhlEcommerce = "dhlecommerce"
        case dhlEcommerceAsia = "dhlecommerceasia"

        func image() -> UIImage? {
            switch self {
            case .ups:
                return UIImage(named: "shipping-label-ups-logo")
            case .usps:
                return UIImage(named: "shipping-label-usps-logo")
            case .dhlExpress, .dhlEcommerce, .dhlEcommerceAsia:
                return UIImage(named: "shipping-label-fedex-logo")
            }
        }
    }
}

struct ShippingLabelCarrierRow_Previews: PreviewProvider {
    static var previews: some View {
        let sampleRate = ShippingLabelCarrierRow_Previews.sampleRate()
        let sampleRateEmptyCarrierID = ShippingLabelCarrierRow_Previews.sampleRate(carrierID: "")
        let viewModelWithImage = ShippingLabelCarrierRowViewModel(selected: false, rate: sampleRate)

        ShippingLabelCarrierRow(viewModelWithImage)
            .previewLayout(.fixed(width: 375, height: 60))
            .previewDisplayName("With Image")

        let viewModelWithoutImage = ShippingLabelCarrierRowViewModel(selected: false,
                                                                     rate: sampleRateEmptyCarrierID)

        ShippingLabelCarrierRow(viewModelWithoutImage)
            .previewLayout(.fixed(width: 375, height: 60))
            .previewDisplayName("Without Image")

        ShippingLabelCarrierRow(viewModelWithoutImage)
            .frame(maxWidth: 375, minHeight: 60)
            .previewLayout(.sizeThatFits)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewDisplayName("Large Font Size Roar!")

        let viewModelSelected = ShippingLabelCarrierRowViewModel(selected: true, rate: sampleRate)

        ShippingLabelCarrierRow(viewModelSelected)
            .frame(maxWidth: 375, minHeight: 60)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Selected")
    }

    private static func sampleRate(carrierID: String = "usps") -> ShippingLabelCarrierRate {
        return ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
                                        insurance: 0,
                                        retailRate: 40.060000000000002,
                                        rate: 40.060000000000002,
                                        rateID: "rate_a8a29d5f34984722942f466c30ea27ef",
                                        serviceID: "ParcelSelect",
                                        carrierID: "usps",
                                        shipmentID: "shp_e0e3c2f4606c4b198d0cbd6294baed56",
                                        hasTracking: true,
                                        isSelected: false,
                                        isPickupFree: true,
                                        deliveryDays: 2,
                                        deliveryDateGuaranteed: false)
    }
}
