import SwiftUI
import Yosemite

struct OrderDetailsShipmentDetailsView: View {
    let shipment: WooShippingShipment
    let totalShipmentCount: Int
    let eligibleForCreatingShippingLabel: Bool

    let onViewItems: () -> Void
    let onCreateLabel: () -> Void
    let onViewLabel: (ShippingLabel) -> Void
    let onRefund: (ShippingLabel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.contentPadding) {
            HStack {
                Text(String.localizedStringWithFormat(Localization.shipmentFormat, shipmentIndex))
                    .headlineStyle()
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Layout.checkColor)
                    .renderedIf(!canCreateLabel)
                Spacer()
                if let label = shipment.shippingLabel, label.refund == nil {
                    Menu {
                        Button(Localization.requestRefund) {
                            onRefund(label)
                        }
                        .renderedIf(label.isRefundable)
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(Color.accentColor)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(.vertical, Layout.extraSpacing)
            .accessibilityElement(children: .combine)

            if shipment.shippingLabel?.refund != nil {
                Text(Localization.refundMessage)
                    .font(.subheadline)
                    .padding(Layout.contentPadding)
                    .background(Color.withColorStudio(name: .blue, shade: .shade5).opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
            }

            Divider()
                .padding(.trailing, -Layout.contentPadding)

            Button(action: onViewItems) {
                HStack {
                    Text(itemCountTitle)
                    Spacer()
                    Image(systemName: "chevron.forward")
                        .foregroundStyle(Color(.tertiaryLabel))
                        .fontWeight(.semibold)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if canCreateLabel && eligibleForCreatingShippingLabel {
                Divider()
                    .padding(.trailing, -Layout.contentPadding)

                Button(Localization.createShippingLabel, action: onCreateLabel)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.vertical, Layout.extraSpacing)

            } else if let shippingLabel = shipment.shippingLabel, shippingLabel.refund == nil {
                Divider()
                    .padding(.trailing, -Layout.contentPadding)

                HStack {
                    Image(uiImage: .locationImage)
                        .renderingMode(.template)
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading) {
                        Text(Localization.trackingNumber)
                        Text(shippingLabel.trackingNumber)
                            .subheadlineStyle()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Menu {
                        Button(Localization.copyTrackingNumber) {
                            shippingLabel.trackingNumber.sendToPasteboard(includeTrailingNewline: false)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(Color.accentColor)
                            .fontWeight(.semibold)
                    }
                }
                .accessibilityElement(children: .combine)

                Divider()
                    .padding(.trailing, -Layout.contentPadding)

                Button {
                    onViewLabel(shippingLabel)
                } label: {
                    HStack {
                        Text(Localization.viewShippingLabel)
                        Spacer()
                        Image(systemName: "chevron.forward")
                            .foregroundStyle(Color(.tertiaryLabel))
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private extension OrderDetailsShipmentDetailsView {
    var shipmentIndex: String {
        guard let intID = Int(shipment.index) else {
            return shipment.index
        }
        return "\(intID + 1)/\(totalShipmentCount)"
    }

    var itemCountTitle: String {
        String.pluralize(
            shipment.items.map { $0.quantity.intValue }.reduce(0, +),
            singular: Localization.itemCountSingular,
            plural: Localization.itemCountPlural
        )
    }

    var canCreateLabel: Bool {
        shipment.shippingLabel == nil || shipment.shippingLabel?.refund != nil
    }
}

private extension OrderDetailsShipmentDetailsView {
    enum Layout {
        static let contentPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let extraSpacing: CGFloat = 8
        static let checkColor = Color(light: .withColorStudio(name: .green, shade: .shade70),
                                      dark: .withColorStudio(name: .green, shade: .shade50))
    }
    enum Localization {
        static let shipmentFormat = NSLocalizedString(
            "orderDetailsShipmentDetailsView.title",
            value: "Shipment %1$@",
            comment: "Order shipment title format. The placeholder indicates the index of the shipping label package."
        )
        static let requestRefund = NSLocalizedString(
            "orderDetailsShipmentDetailsView.requestRefund",
            value: "Request a refund",
            comment: "Button to request a refund for a purchased shipping label."
        )
        static let refundMessage = NSLocalizedString(
            "orderDetailsShipmentDetailsView.refundMessage",
            value: "You have successfully submitted a request for refund. " +
            "You can purchase a new label.",
            comment: "Message for a refunded shipping label."
        )
        static let itemCountSingular = NSLocalizedString(
            "orderDetailsShipmentDetailsView.itemCountSingular",
            value: "%1$d item",
            comment: "Singular item count for a shipment. Reads like: 1 item"
        )
        static let itemCountPlural = NSLocalizedString(
            "orderDetailsShipmentDetailsView.itemCountPlural",
            value: "%1$d items",
            comment: "Plural item count for a shipment. Reads like: 2 items"
        )
        static let createShippingLabel = NSLocalizedString(
            "orderDetailsShipmentDetailsView.createShippingLabel",
            value: "Create Shipping Label",
            comment: "Button to create a shipping label for a shipment"
        )
        static let trackingNumber = NSLocalizedString(
            "orderDetailsShipmentDetailsView.trackingNumber",
            value: "Tracking number",
            comment: "Title for the tracking number of a shipping label"
        )
        static let copyTrackingNumber = NSLocalizedString(
            "orderDetailsShipmentDetailsView.copyTrackingNumber",
            value: "Copy tracking number",
            comment: "Button to copy the tracking number of a shipping label"
        )
        static let viewShippingLabel = NSLocalizedString(
            "orderDetailsShipmentDetailsView.viewShippingLabel",
            value: "View purchased shipping label",
            comment: "Button to view details of a shipping label"
        )
    }
}
