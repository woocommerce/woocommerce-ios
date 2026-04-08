import SwiftUI
import struct WooFoundation.ScrollableVStack

/// Shared view for reviewing carrier Terms and Conditions.
///
/// The view provides a scaffold (title, optional address, message, confirm button, error handling)
/// and accepts a `@ViewBuilder` closure for the carrier-specific checkbox content.
///
struct CarrierTermsView<ViewModel: CarrierTermsViewModel, Checkboxes: View>: View {

    @ObservedObject var viewModel: ViewModel

    @ViewBuilder let checkboxes: (ViewModel) -> Checkboxes

    let onConfirmation: () -> Void

    @State private var didFailToConfirmAcceptance = false

    @State private var externalURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            ScrollableVStack(alignment: .leading,
                             padding: Layout.contentPadding,
                             spacing: Layout.sectionSpacing) {
                Text(viewModel.title)
                    .font(.title3)
                    .bold()

                if let address = viewModel.displayedOriginAddress {
                    VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                        Text(Localization.shippingFrom)
                            .headlineStyle()
                        Text(address)
                            .foregroundStyle(Color.primary)
                            .subheadlineStyle()
                        Divider()
                    }
                    .accessibilityElement(children: .combine)
                }

                Text(viewModel.message)

                VStack(alignment: .leading, spacing: Layout.contentPadding) {
                    checkboxes(viewModel)
                }

                Spacer()
            }

            VStack(spacing: 0) {
                Divider()

                Button(Localization.confirmButton, action: {
                    Task { @MainActor in
                        await confirmAcceptance()
                    }
                })
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isConfirming))
                .padding(Layout.contentPadding)
                .disabled(!viewModel.shouldEnableConfirmButton)
            }
        }
        .padding(.top, Layout.contentPadding)
        .alert(Localization.errorTitle, isPresented: $didFailToConfirmAcceptance) {
            Button(Localization.retry) {
                Task { @MainActor in
                    await confirmAcceptance()
                }
            }
            Button(Localization.cancel, role: .cancel) {}
        } message: {
            Text(Localization.errorMessage)
        }
        .environment(\.openURL, OpenURLAction { url in
            externalURL = url
            return .handled
        })
        .safariSheet(url: $externalURL)
    }
}

private extension CarrierTermsView {
    @MainActor
    func confirmAcceptance() async {
        do {
            let result = try await viewModel.confirmAcceptance()
            if result {
                onConfirmation()
            } else {
                didFailToConfirmAcceptance = true
            }
        } catch {
            DDLogError("⛔️ Error accepting terms of service \(error)")
            didFailToConfirmAcceptance = true
        }
    }
}

private extension CarrierTermsView {
    enum Layout {
        static let contentPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let contentSpacing: CGFloat = 8
    }

    enum Localization {
        static let shippingFrom = NSLocalizedString(
            "carrierTermsView.shippingFrom",
            value: "Shipping from",
            comment: "Title label for the origin address on the carrier Terms and Conditions view"
        )
        static let confirmButton = NSLocalizedString(
            "carrierTermsView.confirmButton",
            value: "Confirm and continue",
            comment: "Button to confirm all agreements on the carrier Terms and Conditions view"
        )
        static let errorTitle = NSLocalizedString(
            "carrierTermsView.errorTitle",
            value: "Error confirming acceptance",
            comment: "Title of the alert when confirming agreements on the carrier Terms and Conditions view fails"
        )
        static let errorMessage = NSLocalizedString(
            "carrierTermsView.errorMessage",
            value: "An unexpected error occurred when confirming your acceptance. Please try again.",
            comment: "Message of the alert when confirming agreements on the carrier Terms and Conditions view fails"
        )
        static let retry = NSLocalizedString(
            "carrierTermsView.retry",
            value: "Retry",
            comment: "Button to retry confirming agreements on the carrier Terms and Conditions view"
        )
        static let cancel = NSLocalizedString(
            "carrierTermsView.cancel",
            value: "Cancel",
            comment: "Button to cancel confirming agreements on the carrier Terms and Conditions view"
        )
    }
}
