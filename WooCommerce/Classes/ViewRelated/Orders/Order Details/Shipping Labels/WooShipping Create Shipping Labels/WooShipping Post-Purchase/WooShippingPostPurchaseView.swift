import SwiftUI

struct WooShippingPostPurchaseView: View {
    @State private var viewModel = WooShippingPostPurchaseViewModel()

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
                    // TODO: Request label from remote and open print dialog
                } label: {
                    Text(Localization.printButton)
                        .bold()
                }
                .buttonStyle(HighlightButtonStyle(background: Layout.panelHighlight, backgroundPressed: Layout.buttonPressed))
                Button {
                    // TODO: Open instructions for how to print
                } label: {
                    HStack {
                        Image(systemName: "info.circle")
                        Text(Localization.info)
                            .font(.footnote)
                    }
                }
                Divider()
                Group {
                    Button {
                        // TODO: Open link for shipment tracking
                    } label: {
                        HStack {
                            Text(Localization.trackShipment)
                            Image(systemName: "arrow.up.right.square")
                        }
                    }
                    Button {
                        // TODO: Open link to schedule pickup
                    } label: {
                        HStack {
                            Text(Localization.schedulePickup)
                            Image(systemName: "arrow.up.right.square")
                        }
                    }
                    Button {
                        // TODO: Request label refund
                    } label: {
                        Text(Localization.requestRefund)
                    }
                }
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
    }
}

private extension WooShippingPostPurchaseView {
    enum Layout {
        static let panelBackground: Color = Color(light: .withColorStudio(name: .green, shade: .shade0),
                                                  dark: .withColorStudio(name: .green, shade: .shade100))
        static let panelHighlight: Color = Color(light: .withColorStudio(name: .green, shade: .shade70),
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
    }
}

#Preview {
    WooShippingPostPurchaseView()
        .padding()
}
