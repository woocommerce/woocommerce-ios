import StoreDesignSystem
import SwiftUI
import Yosemite

struct StoreAnalyticsUpdateModeSheet: View {
    @State private var viewModel: AnalyticsUpdateModeBottomSheetViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingLearnMoreWebView = false
    @State private var notice: Notice?

    init(viewModel: AnalyticsUpdateModeBottomSheetViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s0) {
            VStack(alignment: .leading, spacing: StoreSpacing.s4) {
                Text(Localization.title)
                    .storeTextStyle(.titleLarge.strong)
                    .foregroundStyle(.storeOnSurface)
                Text(Localization.description)
                    .storeTextStyle(.bodyLarge)
                    .foregroundStyle(.storeOnSurfaceVariant)
            }
            .padding(.horizontal, StorePadding.p7)
            .padding(.vertical, StorePadding.p5)

            StoreRadioGroup(
                selection: Binding(get: { viewModel.selectedMode }, set: select),
                options: AnalyticsImportUpdateMode.allCases.map(Optional.some),
                rowSpacing: StoreSpacing.s0
            ) { mode in
                if let mode {
                    HStack(spacing: StoreSpacing.s4) {
                        VStack(alignment: .leading, spacing: StoreSpacing.s2) {
                            Text(mode.localizedTitle)
                                .storeTextStyle(.bodyLarge.emphasized)
                                .foregroundStyle(.storeOnSurface)
                            Text(mode.localizedDescription)
                                .storeTextStyle(.bodyMedium)
                                .foregroundStyle(.storeOnSurfaceVariant)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if viewModel.updatingMode == mode {
                            ProgressView().tint(.storePrimary)
                        }
                    }
                    .padding(.vertical, StorePadding.p5)
                    .accessibilityIdentifier("dashboard-analytics-import-update-mode-\(mode.rawValue)")
                }
            }
            .disabled(viewModel.isUpdating)
            .padding(.horizontal, StorePadding.p7)

            Text(footerText)
                .storeTextStyle(.bodySmall)
                .foregroundStyle(.storeOnSurfaceVariantLowest)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .environment(\.openURL, OpenURLAction { _ in
                    showingLearnMoreWebView = true
                    return .handled
                })
            .padding(.horizontal, StorePadding.p7)
            .padding(.vertical, StorePadding.p5)
        }
        .notice($notice)
        .sheet(isPresented: $showingLearnMoreWebView) {
            WebViewSheet(viewModel: Constants.learnMoreWebViewModel) {
                showingLearnMoreWebView = false
            }
        }
    }

    private func select(_ mode: AnalyticsImportUpdateMode?) {
        guard let mode else { return }
        Task { @MainActor in
            do {
                if try await viewModel.handleSelection(mode) {
                    dismiss()
                }
            } catch {
                notice = Notice(title: Localization.updateErrorNotice, feedbackType: .error)
            }
        }
    }

    private var footerText: AttributedString {
        var text = AttributedString(String.localizedStringWithFormat(Localization.footer, Localization.learnMore))
        guard let range = text.range(of: Localization.learnMore) else { return text }
        text[range].link = URL(string: Constants.learnMoreURL)
        text[range].foregroundColor = .storePrimary
        text[range].underlineStyle = .single
        return text
    }
}

private extension StoreAnalyticsUpdateModeSheet {
    enum Constants {
        static let learnMoreURL = "https://woocommerce.com/document/woocommerce-analytics/#section-24"
        static let learnMoreWebViewModel = WebViewSheetViewModel(
            url: URL(string: learnMoreURL)!,
            navigationTitle: Localization.learnMoreNavigationTitle,
            authenticated: false
        )
    }

    enum Localization {
        static let title = NSLocalizedString(
            "analyticsUpdateModeBottomSheet.title",
            value: "Analytics updates",
            comment: "Title of the analytics updates sheet"
        )
        static let description = NSLocalizedString(
            "analyticsUpdateModeBottomSheet.description",
            value: "Choose when analytics data is updated.",
            comment: "Description of the analytics updates sheet"
        )
        static let footer = NSLocalizedString(
            "analyticsUpdateModeBottomSheet.footerWithLearnMoreLink",
            value: "This is a store-wide setting, which also controls the \"Updates\" option in WooCommerce admin analytics settings. %1$@.",
            comment: "Footer of the analytics updates sheet"
        )
        static let learnMore = NSLocalizedString(
            "analyticsUpdateModeBottomSheet.learnMore",
            value: "Learn more",
            comment: "Link to WooCommerce Analytics documentation"
        )
        static let learnMoreNavigationTitle = NSLocalizedString(
            "analyticsUpdateModeBottomSheet.learnMoreNavigationTitle",
            value: "WooCommerce Analytics",
            comment: "Navigation title for WooCommerce Analytics documentation"
        )
        static let updateErrorNotice = NSLocalizedString(
            "analyticsUpdateModeBottomSheet.updateErrorNotice",
            value: "Couldn't update the setting. Please try again.",
            comment: "Notice shown when saving Analytics updates fails"
        )
    }
}

#Preview {
    StoreSheet {
        StoreAnalyticsUpdateModeSheet(
            viewModel: AnalyticsUpdateModeBottomSheetViewModel(
                siteID: 123,
                selectedMode: .scheduled,
                onModeUpdated: { _ in }
            )
        )
    }
}
