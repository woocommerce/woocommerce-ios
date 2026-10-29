import StoreDesignSystem
import SwiftUI
import Yosemite

struct StoreAnalyticsUpdateModeSheet: View {
    @State private var viewModel: AnalyticsUpdateModeBottomSheetViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingLearnMoreWebView = false
    @State private var hasUpdateError = false

    init(viewModel: AnalyticsUpdateModeBottomSheetViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s5) {
            Text(Localization.title)
                .storeTextStyle(.titleLarge.strong)
                .foregroundStyle(.storeOnSurface)

            Text(Localization.description)
                .storeTextStyle(.bodyMedium)
                .foregroundStyle(.storeOnSurfaceVariant)

            Spacer()
                .frame(height: StoreSpacing.s3)

            VStack(alignment: .leading, spacing: StoreSpacing.s5) {
                ForEach(AnalyticsImportUpdateMode.allCases, id: \.rawValue) { mode in
                    optionButton(for: mode)
                }
            }
            .disabled(viewModel.isUpdating)

            if hasUpdateError {
                Text(Localization.updateErrorNotice)
                    .storeTextStyle(.bodySmall)
                    .foregroundStyle(.storeError)
            }

            Text(footerText)
                .storeTextStyle(.bodySmall)
                .foregroundStyle(.storeOnSurfaceVariant)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .environment(\.openURL, OpenURLAction { _ in
                    showingLearnMoreWebView = true
                    return .handled
                })

            Spacer()
                .frame(height: StoreSpacing.s5)
        }
        .padding(.horizontal, StorePadding.p5)
        .padding(.top, StorePadding.p5)
        .sheet(isPresented: $showingLearnMoreWebView) {
            WebViewSheet(viewModel: Constants.learnMoreWebViewModel) {
                showingLearnMoreWebView = false
            }
        }
    }

    private func optionButton(for mode: AnalyticsImportUpdateMode) -> some View {
        Button {
            select(mode)
        } label: {
            HStack(spacing: StoreSpacing.s5) {
                VStack(alignment: .leading, spacing: StoreSpacing.s2) {
                    Text(mode.localizedTitle)
                        .storeTextStyle(.titleMedium.strong)
                        .foregroundStyle(.storeOnSurface)
                    Text(mode.localizedDescription)
                        .storeTextStyle(.bodyMedium)
                        .foregroundStyle(.storeOnSurfaceVariant)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                optionAccessory(for: mode)
                    .frame(width: StoreSpacing.s7, height: StoreSpacing.s7)
            }
            .padding(.vertical, StorePadding.p3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(viewModel.selectedMode == mode ? .isSelected : [])
        .accessibilityIdentifier("dashboard-analytics-import-update-mode-\(mode.rawValue)")
    }

    @ViewBuilder
    private func optionAccessory(for mode: AnalyticsImportUpdateMode) -> some View {
        if viewModel.updatingMode == mode {
            ProgressView()
                .tint(.storePrimary)
        } else if viewModel.selectedMode == mode {
            StoreIcon.Check.solid.image(size: .largeIncreased)
                .foregroundStyle(.storePrimary)
                .accessibilityHidden(true)
        }
    }

    private func select(_ mode: AnalyticsImportUpdateMode) {
        hasUpdateError = false
        Task { @MainActor in
            do {
                if try await viewModel.handleSelection(mode) {
                    dismiss()
                }
            } catch {
                hasUpdateError = true
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
