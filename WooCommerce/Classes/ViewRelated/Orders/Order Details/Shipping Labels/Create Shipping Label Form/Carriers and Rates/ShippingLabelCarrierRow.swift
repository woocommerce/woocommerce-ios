import SwiftUI

struct ShippingLabelCarrierRow: View {

    private let viewModel: ShippingLabelCarrierRowViewModel

    var carrierLogo: UIImage? {
        guard let carrier = viewModel.carrier else {
            return nil
        }
        return CarrierLogo(rawValue: carrier)?.image()
    }

    init(_ viewModel: ShippingLabelCarrierRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack(spacing: Constants.hStackSpacing) {
            if let image = carrierLogo {
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

struct ShippingLabelCarrierRowViewModel: Identifiable {
    internal let id = UUID()
    let title: String
    let subtitle: String
    let price: String
    let carrier: String?
}

struct ShippingLabelCarrierRow_Previews: PreviewProvider {
    static var previews: some View {
        let viewModelWithImage = ShippingLabelCarrierRowViewModel(title: "UPS Ground",
                                                         subtitle: "3 business days",
                                                         price: "$2.49",
                                                         carrier: "usps")

        let viewModelWithoutImage = ShippingLabelCarrierRowViewModel(title: "UPS Ground",
                                                         subtitle: "3 business days",
                                                         price: "$2.49",
                                                         carrier: nil)

        ShippingLabelCarrierRow(viewModelWithImage)
            .previewLayout(.fixed(width: 375, height: 60))
            .previewDisplayName("With Image")

        ShippingLabelCarrierRow(viewModelWithoutImage)
            .previewLayout(.fixed(width: 375, height: 60))
            .previewDisplayName("Without Image")

        ShippingLabelCarrierRow(viewModelWithoutImage)
            .frame(maxWidth: 375, minHeight: 60)
            .previewLayout(.sizeThatFits)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewDisplayName("Large Font Size Roar!")
    }
}
