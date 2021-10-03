import SwiftUI

struct PrintCustomsFormsView: View {
    private let invoiceURLs: [String]
    private let showsSaveForLater: Bool

    private let inProgressViewProperties = InProgressViewProperties(title: Localization.inProgressTitle, message: Localization.inProgressMessage)
    @State private var showingInProgress = false

    init(invoiceURLs: [String], showsSaveForLater: Bool = false) {
        self.invoiceURLs = invoiceURLs
        self.showsSaveForLater = showsSaveForLater
    }

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text(Localization.customsFormTitle)
                    .bodyStyle()
                    .padding(.top, Constants.verticalSpacing)
                VStack(spacing: Constants.verticalSpacing) {
                    Image("woo-shipping-label-printing-instructions")
                    Text(invoiceURLs.count == 1 ? Localization.singlePrintingMessage : Localization.printingMessage)
                        .bodyStyle()
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: Constants.imageWidth)
                .padding(.bottom, Constants.verticalSpacing)

                if invoiceURLs.count == 1 {
                    VStack(spacing: Constants.buttonSpacing) {
                        Button(action: {
                            guard let url = invoiceURLs.first else {
                                return
                            }
                            showPrintingView(for: url)
                        }, label: {
                            Text(Localization.singlePrintButton)
                        })
                        .buttonStyle(PrimaryButtonStyle())

                        saveForLaterButton
                    }
                    .padding(.horizontal, Constants.horizontalPadding)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(invoiceURLs.enumerated()), id: \.element) { index, url in
                            HStack {
                                Text(String(format: Localization.packageNumber, index + 1))
                                Spacer()
                                Button(action: {
                                    showPrintingView(for: url)
                                }, label: {
                                    HStack {
                                        Spacer()
                                        Text(Localization.printButton)
                                    }
                                })
                                .buttonStyle(LinkButtonStyle())
                            }
                            .padding(.leading, Constants.horizontalPadding)
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
        .navigationTitle(Localization.navigationTitle)
        .fullScreenCover(isPresented: $showingInProgress) {
            InProgressView(viewProperties: inProgressViewProperties)
                .edgesIgnoringSafeArea(.all)
        }
    }

    private var saveForLaterButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }, label: {
            Text(Localization.saveForLaterButton)
        })
        .buttonStyle(SecondaryButtonStyle())
        .renderedIf(showsSaveForLater)
    }

    private func showPrintingView(for path: String) {
        guard let url = URL(string: path) else {
            return
        }
        showingInProgress = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: url)

                DispatchQueue.main.async {
                    showingInProgress = false
                    let printController = UIPrintInteractionController()
                    printController.printingItem = data
                    printController.present(animated: true, completionHandler: nil)
                }
            } catch {
                DispatchQueue.main.async {
                    showingInProgress = false
                }
            }
        }
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
        static let singlePrintingMessage = NSLocalizedString("A customs form must be printed and included on this international shipment",
                                                       comment: "Main message on the Print Customs Invoice screen of Shipping Label flow")
        static let printingMessage = NSLocalizedString("Customs forms must be printed and included on these international shipments",
                                                       comment: "Main message on the Print Customs Invoice screen of Shipping Label flow for multiple invoices")
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
        static let inProgressTitle = NSLocalizedString("Preparing document",
                                                       comment: "Title of in-progress modal when preparing for printing customs invoice")
        static let inProgressMessage = NSLocalizedString("Please wait",
                                                         comment: "Message of in-progress modal when preparing for printing customs invoice")
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
