import StoreDesignSystem
import SwiftUI

struct StoreDashboardCardErrorView: View {
    @State private var showingSupportForm = false
    let retry: () -> Void

    var body: some View {
        VStack(spacing: StoreSpacing.s5) {
            StoreIcon.CircleInfo.regular.image(size: .largeIncreased)
                .foregroundStyle(.storeError)
                .accessibilityHidden(true)
            Text(Localization.errorTitle)
                .storeTextStyle(.titleLarge.strong)
            Text(Localization.errorMessage)
                .storeTextStyle(.bodyLarge)
                .foregroundStyle(.storeOnSurface)
                .multilineTextAlignment(.center)
                .contentShape(.rect)
                .onTapGesture { showingSupportForm = true }
                .accessibilityAddTraits(.isLink)
                .padding(.horizontal, StorePadding.p8)
            StoreButton(Localization.retry, variant: .outlined, action: retry)
                .frame(maxWidth: .infinity)
        }
        .foregroundStyle(.storeOnSurface)
        .padding(StorePadding.p5)
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showingSupportForm) { supportForm }
    }

    private var supportForm: some View {
        NavigationStack {
            SupportForm(isPresented: $showingSupportForm,
                        viewModel: SupportFormViewModel(mobileStatusReportProvider: MobileStatusReportProvider()))
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(Localization.errorDone) { showingSupportForm = false }
                    }
                }
        }
    }
}

struct StoreDashboardUnavailableAnalyticsView: View {
    @State private var showingSupportForm = false
    let title: String

    var body: some View {
        VStack(spacing: StoreSpacing.s5) {
            StoreIcon.ChartLineUp.regular.image(size: .extraLarge)
                .foregroundStyle(.storeOnSurfaceVariant)
                .accessibilityHidden(true)
            Text(title)
                .storeTextStyle(.titleLarge.strong)
            Text(Localization.unavailableDetails)
                .storeTextStyle(.bodyLarge)
                .foregroundStyle(.storeOnSurface)
            StoreButton(Localization.unavailableButton, variant: .outlined) { showingSupportForm = true }
        }
        .foregroundStyle(.storeOnSurface)
        .multilineTextAlignment(.center)
        .padding(StorePadding.p5)
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showingSupportForm) { supportForm }
    }

    private var supportForm: some View {
        NavigationStack {
            SupportForm(isPresented: $showingSupportForm,
                        viewModel: SupportFormViewModel(mobileStatusReportProvider: MobileStatusReportProvider()))
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(Localization.done) { showingSupportForm = false }
                    }
                }
        }
    }
}

private enum Localization {
    static let errorTitle = NSLocalizedString(
        "dashboardCardErrorView.errorTitle",
        value: "Unable to load data",
        comment: "The title of the error view when failed to load a Dashboard card"
    )
    static let errorMessage = String.localizedStringWithFormat(
        NSLocalizedString(
            "dashboardCardErrorView.errorMessage",
            value: "Try reloading this card. If the issue persists, please %1$@.",
            comment: "The info of the error view when failed to load store statistics on the Dashboard screen."
        ),
        contactSupport
    )
    static let contactSupport = NSLocalizedString(
        "dashboardCardErrorView.contactSupport",
        value: "contact support",
        comment: "Link to open the support form. Should be lowercased."
    )
    static let retry = NSLocalizedString(
        "dashboardCardErrorView.retry",
        value: "Retry",
        comment: "Button to reload the dashboard card on the Dashboard screen"
    )
    static let unavailableDetails = NSLocalizedString(
        "unavailableAnalyticsView.details",
        value: "Make sure you are running the latest version of WooCommerce on your site and enabling Analytics in WooCommerce Settings.",
        comment: "Text that explains how to get access to the Analytics module"
    )
    static let unavailableButton = NSLocalizedString(
        "unavailableAnalyticsView.buttonTitle",
        value: "Still need help? Contact us",
        comment: "Button title to contact support to get help with unavailable Analytics module"
    )
    static let errorDone = NSLocalizedString(
        "dashboardCardErrorView.dismissSupport",
        value: "Done",
        comment: "Button to dismiss the support form from the Dashboard generic error card."
    )
    static let done = NSLocalizedString(
        "unavailableAnalyticsView.dismissSupport",
        value: "Done",
        comment: "Button to dismiss the support form."
    )
}
