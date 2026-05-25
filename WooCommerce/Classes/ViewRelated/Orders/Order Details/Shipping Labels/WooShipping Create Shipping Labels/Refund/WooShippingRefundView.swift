import SwiftUI
import Yosemite
import struct WooFoundation.ScrollableVStack

/// View for requesting refund for a shipping label.
///
struct WooShippingRefundView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isRequestingRefund = false
    @State private var didFailToRequestRefund = false

    let viewModel: WooShippingRefundViewModel
    let onRefundRequested: (_ updatedLabel: ShippingLabel) -> Void

    var body: some View {
        ScrollableVStack(alignment: .leading,
                         padding: Layout.contentPadding,
                         spacing: Layout.contentSpacing) {
            HStack {
                Button(Localization.cancelButton) {
                    dismiss()
                }
                Spacer()
            }

            Text(Localization.title)
                .font(.title2)
                .bold()
                .padding(.vertical, Layout.titleExtraPadding)

            Text(String.localizedStringWithFormat(Localization.description, viewModel.refundDuration))

            Text(Localization.purchaseDate).bold() +
            Text(" ") +
            Text(viewModel.formattedPurchaseDate)

            Text(Localization.refundAmount).bold() +
            Text(" ") +
            Text(viewModel.formattedRefundAmount)

            Text(Localization.note)
                .italic()
            Spacer()
        }
        .font(.subheadline)
        .multilineTextAlignment(.leading)
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(String.localizedStringWithFormat(Localization.submitButton, "-" + viewModel.formattedRefundAmount)) {
                    Task { @MainActor in
                        await submitRefundRequest()
                    }
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isRequestingRefund))
                .padding()
            }
            .background(Color(.systemBackground))
        }
        .alert(Localization.ErrorAlert.title, isPresented: $didFailToRequestRefund) {
            Button(role: .cancel, action: {}, label: {
                Text(Localization.ErrorAlert.cancel)
            })

            Button {
                Task { @MainActor in
                    await submitRefundRequest()
                }
            } label: {
                Text(Localization.ErrorAlert.retry)
            }
        } message: {
            Text(Localization.ErrorAlert.message)
        }
    }
}

private extension WooShippingRefundView {
    func submitRefundRequest() async {
        isRequestingRefund = true
        defer {
            isRequestingRefund = false
        }
        do {
            let updatedLabel = try await viewModel.submitRefundRequest()
            onRefundRequested(updatedLabel)
        } catch {
            didFailToRequestRefund = true
        }
    }
}

private extension WooShippingRefundView {
    enum Layout {
        static let contentSpacing = CGFloat(8)
        static let titleExtraPadding = CGFloat(16)
        static let contentPadding = CGFloat(16)
    }

    enum Localization {
        static let title = NSLocalizedString(
            "wooShippingRefundView.title",
            value: "Request a shipping label refund",
            comment: "title on the Request shipping label refund view"
        )
        static let description = NSLocalizedString(
            "wooShippingRefundView.description",
            value: "Request a refund for your unused shipping label. " +
            "The refund process for the shipping label will begin immediately and " +
            "is typically completed within %1$d business days.",
            comment: "Description on the Request shipping label refund view. " +
            "The placeholder is the number of day to process the refund."
        )
        static let purchaseDate = NSLocalizedString(
            "wooShippingRefundView.purchaseDate",
            value: "Purchase date:",
            comment: "Purchase date label on the Request shipping label refund view."
        )
        static let refundAmount = NSLocalizedString(
            "wooShippingRefundView.refundAmount",
            value: "Amount eligible for refund:",
            comment: "Refund amount label on the Request shipping label refund view."
        )
        static let note = NSLocalizedString(
            "wooShippingRefundView.note",
            value: "Please note that this refund request applies only to the unused " +
            "shipping label and will not affect the order itself.",
            comment: "Note on the Request shipping label refund view"
        )
        static let cancelButton = NSLocalizedString(
            "wooShippingRefundView.cancelButton",
            value: "Cancel",
            comment: "Button to dismiss the Request shipping label refund view"
        )
        static let submitButton = NSLocalizedString(
            "wooShippingRefundView.submitButton",
            value: "Refund Label (%1$@)",
            comment: "Button to submit refund request the Request shipping label refund view"
        )
        enum ErrorAlert {
            static let title = NSLocalizedString(
                "wooShippingRefundView.errorAlert.title",
                value: "Refund request failed",
                comment: "Title of the error alert when requesting refund for a shipping label fails"
            )
            static let message = NSLocalizedString(
                "wooShippingRefundView.errorAlert.message",
                value: "We were unable to request a refund for your label. Please try again.",
                comment: "Message on the error alert when requesting refund for a shipping label fails"
            )
            static let retry = NSLocalizedString(
                "wooShippingRefundView.errorAlert.retry",
                value: "Retry",
                comment: "Button to retry when requesting refund for a shipping label fails"
            )
            static let cancel = NSLocalizedString(
                "wooShippingRefundView.errorAlert.cancel",
                value: "Cancel",
                comment: "Button to dismiss the error alert when requesting refund for a shipping label fails"
            )
        }
    }
}

#Preview {
    WooShippingRefundView(viewModel: .init(
        shippingLabel: ShippingLabel(
            siteID: 123,
            orderID: 456,
            shippingLabelID: 789,
            carrierID: "usps",
            shipmentID: "0",
            dateCreated: Date(),
            packageName: "unknown",
            rate: 12.11,
            currency: "usd",
            trackingNumber: "1345",
            serviceName: "",
            refundableAmount: 11.22,
            status: .purchased,
            refund: nil,
            originAddress: ShippingLabelAddress(company: "Automattic Inc.",
                                                name: "Tes",
                                                phone: "01234567",
                                                country: "USA",
                                                state: "CA",
                                                address1: "Woo Street",
                                                address2: "",
                                                city: "San Francisco",
                                                postcode: "90210"),
            destinationAddress: ShippingLabelAddress(company: "",
                                                     name: "La",
                                                     phone: "01234567",
                                                     country: "USA",
                                                     state: "NY",
                                                     address1: "Main Street",
                                                     address2: "",
                                                     city: "New York",
                                                     postcode: "10023"),
            productIDs: [],
            productNames: [],
            commercialInvoiceURL: nil,
            usedDate: nil,
            expiryDate: nil,
            hazmatCategory: nil,
        )
    ), onRefundRequested: { _ in })
}
