import SwiftUI

struct POSSettingsPaymentsDetailView: View {
    @Environment(\.posMetrics) private var metrics
    private let viewModel: POSSettingsPaymentsViewModel

    init(viewModel: POSSettingsPaymentsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: metrics.spacing.none) {
            POSPageHeaderView(title: Localization.paymentsTitle)
                .foregroundColor(.posSurface)

            ScrollView {
                VStack(spacing: metrics.spacing.medium) {
                    POSInformationCard {
                        POSInformationCardFieldRowWithToggle(
                            label: Localization.paymentSuccessSoundTitle,
                            value: Localization.paymentSuccessSoundSubtitle,
                            showSeparator: false,
                            isOn: paymentSuccessSoundBinding
                        )
                    }
                }
                .posContentPadding(.horizontal, metrics.padding.medium)
            }
        }
        .background(Color.posSurface)
    }

    private var paymentSuccessSoundBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isPaymentSuccessSoundEnabled },
            set: { newValue in
                viewModel.setPaymentSuccessSoundEnabled(newValue)
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
