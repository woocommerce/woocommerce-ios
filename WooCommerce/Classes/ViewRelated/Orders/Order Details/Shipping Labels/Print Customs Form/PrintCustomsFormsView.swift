import SwiftUI

struct PrintCustomsFormsView: View {
    let invoiceURLs: [String]

    var body: some View {
        VStack(spacing: Constants.verticalSpacing) {
            Text(Localization.customsFormTitle)
                .bodyStyle()
            VStack(spacing: Constants.verticalSpacing) {
                Image("woo-shipping-label-printing-instructions")
                Text(Localization.printingMessage)
                    .bodyStyle()
                    .multilineTextAlignment(.center)
            }
            .frame(width: Constants.imageWidth)

            if invoiceURLs.count == 1 {
                VStack(spacing: Constants.buttonSpacing) {
                    Button(action: {}, label: {
                        Text(Localization.singlePrintButton)
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
                            Text(String(format: Localization.packageNumber, index + 1))
                            Spacer()
                            Button(action: {}, label: {
                                Text(Localization.printButton)
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
        .navigationTitle(Localization.navigationTitle)
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

    enum Localization {
        static let navigationTitle = NSLocalizedString("Print customs invoice",
                                                       comment: "Navigation title of the Print Customs Invoice screen of Shipping Label flow")
        static let customsFormTitle = NSLocalizedString("Customs form",
                                                        comment: "Title on the Print Customs Invoice screen of Shipping Label flow")
        static let printingMessage = NSLocalizedString("A customs form must be printed and included on this international shipment",
                                                       comment: "Main message on the Print Customs Invoice screen of Shipping Label flow")
        static let singlePrintButton = NSLocalizedString("Print customs form",
                                                         comment: "Title of print button on Print Customs Invoice screen" +
                                                            " of Shipping Label flow when there's only one invoice")
        static let packageNumber = NSLocalizedString("Package %1$d",
                                                     comment: "Package index in Print Customs Invoice screen" +
                                                        " of Shipping Label flow if there are more than one invoice")
        static let printButton = NSLocalizedString("Print",
                                                   comment: "Title of print button on Print Customs Invoice" +
                                                    " screen of Shipping Label flow when there are more than one invoice")
        static let saveForLaterButton = NSLocalizedString("Save for later",
                                                          comment: "Save for later button on Print Customs Invoice screen of Shipping Label flow")
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
