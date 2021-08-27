import SwiftUI

struct PrintCustomsFormsView: View {
    let invoiceURLs: [String]

    var body: some View {
        VStack(spacing: 24) {
            Text("Customs form")
                .bodyStyle()
            VStack(spacing: 24) {
                Image("woo-shipping-label-printing-instructions")
                Text("A customs form must be printed and included on this international shipment")
                    .bodyStyle()
                    .multilineTextAlignment(.center)
            }
            .frame(width: 235)

            if invoiceURLs.count == 1 {
                VStack(spacing: 8) {
                    Button(action: {}, label: {
                        Text("Print customs form")
                    })
                    .buttonStyle(PrimaryButtonStyle())

                    saveForLaterButton
                }
                .padding(.horizontal, 16)
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
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        Divider()
                    }

                    Spacer()

                    saveForLaterButton
                        .padding(.horizontal, 16)
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
