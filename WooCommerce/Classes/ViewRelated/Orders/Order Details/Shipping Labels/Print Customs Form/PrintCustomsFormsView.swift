import SwiftUI

struct PrintCustomsFormsView: View {
    let invoiceURLs: [String]

    var body: some View {
        VStack(spacing: Constants.verticalSpacing) {
            Text("Customs form")
                .bodyStyle()
            VStack(spacing: Constants.verticalSpacing) {
                Image("woo-shipping-label-printing-instructions")
                Text("A customs form must be printed and included on this international shipment")
                    .bodyStyle()
                    .multilineTextAlignment(.center)
            }
            .frame(width: Constants.imageWidth)

            if invoiceURLs.count == 1 {
                VStack(spacing: Constants.buttonSpacing) {
                    Button(action: {}, label: {
                        Text("Print customs form")
                    })
                    .buttonStyle(PrimaryButtonStyle())

                    saveForLaterButton
                }
                .padding(.horizontal, Constants.horizontalPadding)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(invoiceURLs.enumerated()), id: \.element) { index, url in
                        HStack {
                            Text("Package \(index + 1)")
                            Spacer()
                            Button(action: {}, label: {
                                Text("Print")
                            })
                            .buttonStyle(LinkButtonStyle())
                        }
                        .padding(.horizontal, Constants.horizontalPadding)
                        .frame(height: Constants.printRowHeight)
                        Divider()
                    }

                    Spacer()

                    saveForLaterButton
                        .padding(.horizontal, Constants.horizontalPadding)
                        .frame(maxWidth: .infinity)
                }
                
            }

            Spacer()
        }
    }

    private var saveForLaterButton: some View {
        Button(action: {}, label: {
            Text("Save for later")
        })
        .buttonStyle(SecondaryButtonStyle())
    }
}

private extension PrintCustomsFormsView {
    enum Constants {
        static let verticalSpacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 16
        static let imageWidth: CGFloat = 235
        static let printRowHeight: CGFloat = 48
        static let buttonSpacing: CGFloat = 8
    }
}

struct PrintCustomsFormsView_Previews: PreviewProvider {
    static var previews: some View {
        PrintCustomsFormsView(invoiceURLs: ["https://woocommerce.com"])
            .previewDevice(PreviewDevice(rawValue: "iPhone 12"))
            .previewDisplayName("iPhone 12")
        
        PrintCustomsFormsView(invoiceURLs: ["https://woocommerce.com", "https://wordpress.com"])
            .previewDevice(PreviewDevice(rawValue: "iPhone 12 Pro Max"))
            .previewDisplayName("iPhone 12 Pro Max")
    }
}
