import SwiftUI
import Yosemite

struct ShippingLabelCarrierRow: View {

    private let viewModel: ShippingLabelCarrierRowViewModel

    init(_ viewModel: ShippingLabelCarrierRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack(alignment: .top, spacing: Constants.hStackSpacing) {
            if viewModel.selected {
                Image(uiImage: .checkmarkStyledImage)
                    .frame(width: Constants.imageSize, height: Constants.imageSize)
            }
            else if let image = viewModel.carrierLogo {
                VStack {
                    Image(uiImage: image)
                        .frame(width: Constants.imageSize, height: Constants.imageSize)
                }
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
                if viewModel.selected {
                    Text(viewModel.extraInfo)
                        .footnoteStyle()

                }
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
        static let vStackSpacing: CGFloat = 8
        static let hStackSpacing: CGFloat = 25
        static let hStackPadding: CGFloat = 10
        static let minHeight: CGFloat = 60
        static let imageSize: CGFloat = 40
        static let padding: CGFloat = 16
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
