import SwiftUI

struct WooShippingServiceCardView: View {
    let carrierLogo: UIImage?
    let title: String
    let rate: String
    let daysToDelivery: String
    let extraInfo: String

    var body: some View {
        HStack(alignment: .top) {
            if let carrierLogo {
                Image(uiImage: carrierLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
            }
            VStack(alignment: .leading) {
                AdaptiveStack {
                    Text(title)
                    Spacer()
                    Text(rate)
                        .bold()
                }
                Group {
                    Text(daysToDelivery).bold() + Text("  •  ") + Text(extraInfo)
                }
                .font(.footnote)
            }
        }
        .padding()
        .roundedBorder(cornerRadius: 8, lineColor: Color(.separator), lineWidth: 1)
    }
}

#Preview {
    WooShippingServiceCardView(carrierLogo: UIImage(named: "shipping-label-usps-logo"),
                               title: "USPS - Media Mail",
                               rate: "$7.63",
                               daysToDelivery: "7 business days",
                               extraInfo: "Includes tracking, insurance (up to $100.00), free pickup")
}
