import SwiftUI

struct ShippingLabelCarrierRow: View {

    let title: String
    let subtitle: String
    let price: String
    let image: UIImage

    var body: some View {
        HStack(spacing: Constants.hStackSpacing) {
            ZStack {
                Image(uiImage: image).frame(width: Constants.imageSize, height: Constants.imageSize)
            }
            .frame(width: Constants.zStackWidth)
            .padding(.leading, Constants.padding)
            VStack(alignment: .leading,
                   spacing: Constants.vStackSpacing) {
                HStack {
                    Text(title)
                        .bodyStyle()
                    Spacer()
                    Text(price)
                        .bodyStyle()
                }
                Text(subtitle)
                    .footnoteStyle()
            }
            .padding(.trailing, Constants.padding)
        }
        .padding([.top, .bottom], Constants.hStackPadding)
        .frame(minHeight: Constants.height)
        .contentShape(Rectangle())
    }
}

private extension ShippingLabelCarrierRow {
    enum Constants {
        static let zStackWidth: CGFloat = 48
        static let vStackSpacing: CGFloat = 8
        static let hStackSpacing: CGFloat = 25
        static let hStackPadding: CGFloat = 10
        static let height: CGFloat = 60
        static let imageSize: CGFloat = 40
        static let padding: CGFloat = 16
    }
}

struct ShippingLabelCarrierRow_Previews: PreviewProvider {
    static var previews: some View {
        ShippingLabelCarrierRow(title: "UPS Ground",
                                subtitle: "3 business days",
                                price: "$2.49",
                                image: UIImage(named: "shipping-label-ups-logo")!)
            .previewLayout(.fixed(width: 375, height: 60))
    }
}
