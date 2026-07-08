import SwiftUI

struct WooShippingPostPurchaseView: View {
    @ObservedObject private(set) var viewModel: WooShippingPostPurchaseViewModel

    let onRefundRequest: () -> Void

    @State private var isPrintingLabel = false
    @State private var showingLabelPrintingError = false

    @State private var isPrintingCustomsForm = false
    @State private var showingCustomsFormPrintingError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localization.readyToPrint)
                .headlineStyle()
            Text(Localization.printMessage)
                .font(.subheadline)
                .foregroundStyle(Color(.text))

            VStack(alignment: .leading, spacing: 16) {
                Menu {
                    ForEach(viewModel.labelSizes, id: \.self) { labelSize in
                        Button {
                            viewModel.selectedLabelSize = labelSize
                        } label: {
                            Text(labelSize.description)
                            if labelSize == viewModel.selectedLabelSize {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedLabelSize.description)
                            .bodyStyle()
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .bold()
                    }
                    .padding()
                    .roundedBorder(cornerRadius: 8, lineColor: Color(.separator), lineWidth: 1)
                }
                Button {
                    Task { @MainActor in
                        await printLabel()
                    }
                } label: {
                    Text(Localization.printButton)
                        .bold()
                }
                .buttonStyle(HighlightLoadingButtonStyle(isLoading: isPrintingLabel, background: Layout.panelHighlight, backgroundPressed: Layout.buttonPressed))
                NavigationLink {
                    ShippingLabelPrintingInstructionsView()
                        .navigationTitle(Localization.infoTitle)
                } label: {
                    HStack {
                        Image(systemName: "info.circle")
                        Text(Localization.info)
                            .font(.footnote)
                            .multilineTextAlignment(.leading)
                    }
                }
                Divider()
                Group {
                    if let trackingURL = viewModel.trackingURL {
                        NavigationLink {
                            WebView(isPresented: .constant(true), url: trackingURL)
                                .navigationTitle(Localization.trackShipment)
                        } label: {
                            HStack {
                                Text(Localization.trackShipment)
                                    .multilineTextAlignment(.leading)
                                Image(systemName: "arrow.up.right.square")
                            }
                        }
                    }
                    if let pickupURL = viewModel.pickupURL {
                        NavigationLink {
                            WebView(isPresented: .constant(true), url: pickupURL)
                                .navigationTitle(Localization.schedulePickup)
                        } label: {
                            HStack {
                                Text(Localization.schedulePickup)
                                    .multilineTextAlignment(.leading)
                                Image(systemName: "arrow.up.right.square")
                            }
                        }
                    }
                    if let commercialInvoiceURL = viewModel.commercialInvoiceURL {
                        Button {
                            Task { @MainActor in
                                await printCustomsForm(with: commercialInvoiceURL)
                            }
                        } label: {
                            HStack {
                                Text(Localization.printCustomsFormButton)
                                    .multilineTextAlignment(.leading)
                                if isPrintingCustomsForm {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                } else {
                                    Image(systemName: "arrow.up.right.square")
                                }
                            }
                        }
                    }
                    Button {
                        onRefundRequest()
                    } label: {
                        Text(Localization.requestRefund)
                    }
                    .renderedIf(viewModel.isRefundable)
                }
                .fixedSize(horizontal: false, vertical: true)
                .font(.subheadline)
                .bold()
            }
            .padding()
            .foregroundStyle(Layout.panelHighlight)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Layout.panelBackground)
            )

            Text(Localization.note)
                .footnoteStyle()
        }
        .padding(.vertical)
        .alert(Localization.PrintingError.shippingLabel, isPresented: $showingLabelPrintingError, actions: {
            Button(role: .cancel) {} label: {
                Text(Localization.PrintingError.cancel)
            }
            Button {
                Task { @MainActor in
                    await printLabel()
                }
            } label: {
                Text(Localization.PrintingError.retry)
            }
        }, message: {
            Text(Localization.PrintingError.message)
        })
        .alert(Localization.PrintingError.customsForm, isPresented: $showingCustomsFormPrintingError, actions: {
            Button(role: .cancel) {} label: {
                Text(Localization.PrintingError.cancel)
            }
            if let url = viewModel.commercialInvoiceURL {
                Button {
                    Task { @MainActor in
                        await printCustomsForm(with: url)
                    }
                } label: {
                    Text(Localization.PrintingError.retry)
                }
            }
        }, message: {
            Text(Localization.PrintingError.message)
        })
    }
}

private extension WooShippingPostPurchaseView {
    func printLabel() async {
        isPrintingLabel = true
        do {
            try await viewModel.printLabel()
        } catch {
            showingLabelPrintingError = true
            DDLogError("Error generating shipping label document for printing: \(error)")
        }
        isPrintingLabel = false
    }

    func printCustomsForm(with url: URL) async {
        isPrintingCustomsForm = true
        do {
            try await viewModel.printCustomsForm(with: url)
        } catch {
            showingCustomsFormPrintingError = true
            DDLogError("Error downloading customs form for printing: \(error)")
        }
        isPrintingCustomsForm = false
    }
}

private extension WooShippingPostPurchaseView {
    enum Layout {
        static let panelBackground = Color(light: .withColorStudio(name: .green, shade: .shade0),
                                                  dark: .withColorStudio(name: .green, shade: .shade100))
        static let panelHighlight = Color(light: .withColorStudio(name: .green, shade: .shade70),
                                                 dark: .withColorStudio(name: .green, shade: .shade50))
        static let buttonPressed: Color = .withColorStudio(name: .green, shade: .shade90)
    }

    enum Localization {
        static let readyToPrint = NSLocalizedString("wooShipping.createLabels.postPurchase.readyToPrint",
                                                    value: "Your shipping label is ready to print",
                                                    comment: "Heading displayed on the shipping label screen when a purchased shipping label can be printed")
        static let printMessage = NSLocalizedString("wooShipping.createLabels.postPurchase.printMessage",
                                                    value: "From here you can print the shipping label again or change the paper size of the label.",
                                                    comment: "Message displayed on the shipping label screen when a purchased shipping label can be printed")
        static let printButton = NSLocalizedString("wooShipping.createLabels.postPurchase.printButton",
                                                   value: "Print Shipping Label",
                                                   comment: "Title for button to print a purchased shipping label on the shipping label screen")
        static let info = NSLocalizedString("wooShipping.createLabels.postPurchase.info",
                                            value: "Learn how to print from your mobile device",
                                            comment: "Link for more information about how to print a purchased shipping label on the shipping label screen")
        static let infoTitle =
        NSLocalizedString("wooShipping.createLabels.postPurchase.infoTitle",
                          value: "Print from your mobile device",
                          comment: "Navigation bar title of shipping label printing instructions screen")
        static let trackShipment = NSLocalizedString("wooShipping.createLabels.postPurchase.trackShipment",
                                                     value: "Track shipment",
                                                     comment: "Link to track a shipment for a purchase shipping label on the shipping label screen")
        static let schedulePickup = NSLocalizedString("wooShipping.createLabels.postPurchase.schedulePickup",
                                                      value: "Schedule pickup",
                                                      comment: "Link to schedule a pickup for a purchased shipping label on the shipping label screen")
        static let requestRefund = NSLocalizedString("wooShipping.createLabels.postPurchase.requestRefund",
                                                     value: "Request refund",
                                                     comment: "Link to request a refund for a purchased shipping label on the shipping label screen")
        static let note = NSLocalizedString("wooShipping.createLabels.postPurchase.note",
                                            value: "Note: Reusing a printed label is a violation of our terms of service and may result in criminal charges.",
                                            comment: "Note about reusing a purchased shipping label on the shipping label screen")
        static let printCustomsFormButton = NSLocalizedString(
            "wooShipping.createLabels.postPurchase.printCustomsFormButton",
            value: "Print customs form",
            comment: "Title for button to print a customs form on the shipping label screen"
        )
        enum PrintingError {
            static let shippingLabel = NSLocalizedString(
                "wooShipping.createLabels.postPurchase.printingError.shippingLabel",
                value: "Error previewing shipping label",
                comment: "Title of the error alert when printing a shipping label fails in the post purchase flow."
            )
            static let customsForm = NSLocalizedString(
                "wooShipping.createLabels.postPurchase.printingError.customsForm",
                value: "Error downloading customs form",
                comment: "Title of the error alert when printing a customs form fails in the post purchase flow."
            )
            static let message = NSLocalizedString(
                "wooShipping.createLabels.postPurchase.printingError.message",
                value: "Do you want to try again?",
                comment: "Message of the error alert when printing a document fails in the post purchase flow."
            )
            static let cancel = NSLocalizedString(
                "wooShipping.createLabels.postPurchase.printingError.cancel",
                value: "Cancel",
                comment: "Button on the error alert when printing a document fails in the post purchase flow." +
                "Tapping on this button would cancel the printing."
            )
            static let retry = NSLocalizedString(
                "wooShipping.createLabels.postPurchase.printingError.retry",
                value: "Retry",
                comment: "Button on the error alert when printing a document fails in the post purchase flow." +
                "Tapping on this button would retry printing the shipping label."
            )
        }
    }
}

#Preview {
    WooShippingPostPurchaseView(viewModel: WooShippingPostPurchaseViewModel(siteID: 123,
                                                                            labelID: 1,
                                                                            labelSizes: [.label, .legal, .a4],
                                                                            isRefundable: true,
                                                                            trackingURL: URL(string: "https://woocommerce.com"),
                                                                            pickupURL: WooShippingCarrier.usps.pickupURL,
                                                                            commercialInvoiceURL: URL(string: "https://example.com")),
                                onRefundRequest: {})
        .padding()
}

#Preview("Label without links") {
    WooShippingPostPurchaseView(viewModel: WooShippingPostPurchaseViewModel(siteID: 123,
                                                                            labelID: 1,
                                                                            labelSizes: [.label, .legal, .a4],
                                                                            isRefundable: false,
                                                                            trackingURL: nil,
                                                                            pickupURL: nil,
                                                                            commercialInvoiceURL: nil),
                                onRefundRequest: {})
        .padding()
}
