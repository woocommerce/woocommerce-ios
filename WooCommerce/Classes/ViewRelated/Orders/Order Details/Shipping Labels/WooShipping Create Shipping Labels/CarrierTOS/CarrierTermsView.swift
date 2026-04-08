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
                             padding: CarrierTermsViewLayout.contentPadding,
                             spacing: CarrierTermsViewLayout.sectionSpacing) {
                Text(viewModel.title)
                    .font(.title3)
                    .bold()

                if let address = viewModel.displayedOriginAddress {
                    VStack(alignment: .leading, spacing: CarrierTermsViewLayout.contentSpacing) {
                        Text(CarrierTermsViewLocalization.shippingFrom)
                            .headlineStyle()
                        Text(address)
                            .foregroundStyle(Color.primary)
                            .subheadlineStyle()
                        Divider()
                    }
                    .accessibilityElement(children: .combine)
                }

                Text(viewModel.message)

                VStack(alignment: .leading, spacing: CarrierTermsViewLayout.contentPadding) {
                    checkboxes(viewModel)
                }

                Spacer()
            }

            VStack(spacing: 0) {
                Divider()

                Button(CarrierTermsViewLocalization.confirmButton, action: {
                    Task { @MainActor in
                        await confirmAcceptance()
                    }
                })
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isConfirming))
                .padding(CarrierTermsViewLayout.contentPadding)
                .disabled(!viewModel.shouldEnableConfirmButton)
            }
        }
        .padding(.top, CarrierTermsViewLayout.contentPadding)
        .alert(CarrierTermsViewLocalization.errorTitle, isPresented: $didFailToConfirmAcceptance) {
            Button(CarrierTermsViewLocalization.retry) {
                Task { @MainActor in
                    await confirmAcceptance()
                }
            }
            Button(CarrierTermsViewLocalization.cancel, role: .cancel) {}
        } message: {
            Text(CarrierTermsViewLocalization.errorMessage)
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

// MARK: - Constants
private enum CarrierTermsViewLayout {
    static let contentPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let contentSpacing: CGFloat = 8
}

private enum CarrierTermsViewLocalization {
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
