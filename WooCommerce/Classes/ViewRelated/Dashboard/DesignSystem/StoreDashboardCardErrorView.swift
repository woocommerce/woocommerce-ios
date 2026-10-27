import StoreDesignSystem
import SwiftUI

struct StoreDashboardCardErrorView: View {
    @State private var showingSupportForm = false

    private let retry: () -> Void

    init(retry: @escaping () -> Void) {
        self.retry = retry
    }

    var body: some View {
        VStack(spacing: StoreSpacing.s5) {
            StoreIcon.CircleInfo.regular.image(size: .large)
                .foregroundStyle(.storeError)
                .accessibilityHidden(true)

            VStack(spacing: StoreSpacing.s2) {
                Text(Localization.title)
                    .storeTextStyle(.bodyLarge.emphasized)
                Text(Localization.message)
                    .storeTextStyle(.bodyMedium)
                    .foregroundStyle(.storeOnSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .contentShape(.rect)
                    .onTapGesture {
                        showingSupportForm = true
                    }
                    .accessibilityAddTraits(.isLink)
            }

            StoreButton(Localization.retry, variant: .outlined, action: retry)
        }
        .foregroundStyle(.storeOnSurface)
        .padding(StorePadding.p7)
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showingSupportForm) {
            supportForm
        }
    }

    private var supportForm: some View {
        NavigationStack {
            SupportForm(
                isPresented: $showingSupportForm,
                viewModel: SupportFormViewModel(mobileStatusReportProvider: MobileStatusReportProvider())
            )
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.done) {
                        showingSupportForm = false
                    }
                }
            }
        }
    }
}

private extension StoreDashboardCardErrorView {
    enum Localization {
        static let title = NSLocalizedString(
            "dashboardCardErrorView.errorTitle",
            value: "Unable to load data",
            comment: "The title of the error view when failed to load a Dashboard card"
        )
        static let message = String.localizedStringWithFormat(
            NSLocalizedString(
                "dashboardCardErrorView.errorMessage",
                value: "Try reloading this card. If the issue persists, please %1$@.",
                comment: "The info of the error view when failed to load a Dashboard card."
            ),
            NSLocalizedString(
                "dashboardCardErrorView.contactSupport",
                value: "contact support",
                comment: "Link to open the support form. Should be lowercased."
            )
        )
        static let retry = NSLocalizedString(
            "dashboardCardErrorView.retry",
            value: "Retry",
            comment: "Button to reload the dashboard card on the Dashboard screen"
        )
        static let done = NSLocalizedString(
            "dashboardCardErrorView.dismissSupport",
            value: "Done",
            comment: "Button to dismiss the support form from the Dashboard generic error card."
        )
    }
}
