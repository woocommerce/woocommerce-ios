import SwiftUI

struct POSSettingsPaymentsDetailView: View {
    private let viewModel: POSSettingsPaymentsViewModel
    /// Gates an edit action on `editPOSSettings`. Defaults to running it directly (previews / no host gate).
    private let requestEditPermission: POSPermissionRequest

    init(viewModel: POSSettingsPaymentsViewModel,
         requestEditPermission: @escaping POSPermissionRequest = { $0() }) {
        self.viewModel = viewModel
        self.requestEditPermission = requestEditPermission
    }

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(title: Localization.paymentsTitle)
                .foregroundColor(.posSurface)

            ScrollView {
                VStack(spacing: POSSpacing.medium) {
                    POSInformationCard {
                        POSInformationCardFieldRowWithToggle(
                            label: Localization.paymentSuccessSoundTitle,
                            value: Localization.paymentSuccessSoundSubtitle,
                            showSeparator: false,
                            isOn: paymentSuccessSoundBinding
                        )
                    }
                }
                .posContentPadding(.horizontal, POSPadding.medium)
            }
        }
        .background(Color.posSurface)
    }

    /// Toggling the sound is an edit, so route changes through `editPOSSettings`:
    /// the value only flips once the operator holds the cap or a manager approves the override.
    private var paymentSuccessSoundBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isPaymentSuccessSoundEnabled },
            set: { newValue in
                requestEditPermission { viewModel.setPaymentSuccessSoundEnabled(newValue) }
            }
        )
    }
}

private extension POSSettingsPaymentsDetailView {
    enum Localization {
        static let paymentsTitle = NSLocalizedString(
            "posSettingsPaymentsDetailView.title",
            value: "Payments",
            comment: "Navigation title for the payments settings in Point of Sale settings."
        )

        static let paymentSuccessSoundTitle = NSLocalizedString(
            "posSettingsPaymentsDetailView.paymentSuccessSound.title",
            value: "Payment success sound",
            comment: "Title of the toggle that turns the sound played after a successful payment on or off in Point of Sale settings."
        )

        static let paymentSuccessSoundSubtitle = NSLocalizedString(
            "posSettingsPaymentsDetailView.paymentSuccessSound.subtitle",
            value: "Play a sound when a payment completes",
            comment: "Description of the toggle that turns the sound played after a successful payment on or off in Point of Sale settings."
        )
    }
}

#if DEBUG
#Preview {
    POSSettingsPaymentsDetailView(viewModel: POSSettingsPaymentsViewModel(paymentSettings: POSPaymentSettingsPreviewService(),
                                                                          analytics: EmptyPOSAnalytics()))
}
#endif
