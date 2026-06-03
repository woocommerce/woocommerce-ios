import SwiftUI
import enum Yosemite.AnalyticsImportUpdateMode

/// Bottom sheet that explains and edits how WooCommerce Analytics imports update data.
/// Backed by the `woocommerce_analytics_scheduled_import` site setting.
struct AnalyticsUpdateModeBottomSheet: View {
    @State private var viewModel: AnalyticsUpdateModeBottomSheetViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingLearnMoreWebView = false
    @State private var notice: Notice?

    init(viewModel: AnalyticsUpdateModeBottomSheetViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                header
                typeSelector
                footer
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.bottom, Layout.bottomPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .presentationDetents([.fraction(Layout.preferredDetentFraction), .large])
        .presentationDragIndicator(.visible)
        .notice($notice)
        .sheet(isPresented: $showingLearnMoreWebView) {
            WebViewSheet(viewModel: Constants.learnMoreWebViewModel) {
                showingLearnMoreWebView = false
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localization.title)
                .font(.title3.weight(.semibold))
                .padding(.top, Layout.titleTopPadding)

            Text(Localization.description)
                .bodyStyle()
                .padding(.top, Layout.titleToDescriptionSpacing)
        }
    }

    private var typeSelector: some View {
        VStack(alignment: .leading, spacing: Layout.rowSpacing) {
            ForEach(AnalyticsImportUpdateMode.allCases, id: \.rawValue) { mode in
                Button {
                    handleSelection(of: mode)
                } label: {
                    row(for: mode)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isUpdating)
                .accessibilityIdentifier("dashboard-analytics-import-update-mode-\(mode.rawValue)")
            }
        }
        .padding(.top, Layout.descriptionToOptionsSpacing)
    }

    private var footer: some View {
        Text(
            AttributedString.withEmbeddedLink(
                mainContent: Localization.footer,
                linkText: Localization.learnMore,
                link: Constants.learnMoreURL,
                font: .footnote,
                foregroundColor: Color(.secondaryLabel)
            )
        )
        .environment(\.openURL, OpenURLAction { _ in
            showingLearnMoreWebView = true
            return .handled
        })
        .padding(.top, Layout.optionsToFooterSpacing)
    }

    private func handleSelection(of mode: AnalyticsImportUpdateMode) {
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

    @ViewBuilder
    private func row(for mode: AnalyticsImportUpdateMode) -> some View {
        let isSelected = viewModel.selectedMode == mode
        let isUpdating = viewModel.updatingMode == mode
        HStack(alignment: .top, spacing: Layout.rowCheckmarkSpacing) {
            VStack(alignment: .leading, spacing: Layout.rowTitleSubtitleSpacing) {
                Text(mode.localizedTitle)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(mode.localizedDescription)
                    .font(.subheadline.weight(.regular))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            trailingAccessory(isSelected: isSelected, isUpdating: isUpdating)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func trailingAccessory(isSelected: Bool, isUpdating: Bool) -> some View {
        if isUpdating {
            ProgressView()
                .progressViewStyle(.circular)
        } else if isSelected {
            Image(uiImage: .checkmarkStyledImage)
        }
    }
}

extension AnalyticsImportUpdateMode {
    var localizedTitle: String {
        switch self {
        case .scheduled:
            return Localization.scheduledTitle
        case .immediate:
            return Localization.immediateTitle
        }
    }

    var localizedDescription: String {
        switch self {
        case .scheduled:
            return Localization.scheduledDescription
        case .immediate:
            return Localization.immediateDescription
        }
    }
}

extension AnalyticsUpdateModeBottomSheet {
    enum Constants {
        static let learnMoreURL = "https://woocommerce.com/document/woocommerce-analytics/#section-24"
        static let learnMoreWebViewModel = WebViewSheetViewModel(url: URL(string: learnMoreURL)!,
                                                                 navigationTitle: Localization.learnMoreNavigationTitle,
                                                                 authenticated: false)
    }

    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let titleTopPadding: CGFloat = 29
        static let titleToDescriptionSpacing: CGFloat = 10
        static let descriptionToOptionsSpacing: CGFloat = 24
        static let optionsToFooterSpacing: CGFloat = 24
        static let bottomPadding: CGFloat = 24
        static let rowSpacing: CGFloat = 20
        static let rowTitleSubtitleSpacing: CGFloat = 3
        static let rowCheckmarkSpacing: CGFloat = 12
        static let preferredDetentFraction: CGFloat = 0.62
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "analyticsUpdateModeBottomSheet.title",
        value: "Analytics updates",
        comment: "Title of the bottom sheet that explains and lets the merchant choose how WooCommerce Analytics imports update data."
    )
    static let description = NSLocalizedString(
        "analyticsUpdateModeBottomSheet.description",
        value: "Choose when analytics data is updated.",
        comment: "Description shown below the title of the analytics updates bottom sheet on the dashboard."
    )
    static let footer = NSLocalizedString(
        "analyticsUpdateModeBottomSheet.footerWithLearnMoreLink",
        value: "This is a store-wide setting, which also controls the \"Updates\" option in WooCommerce admin analytics settings. %1$@.",
        comment: "Clarification text shown below the analytics update options on the dashboard bottom sheet. " +
        "The placeholder is a link for Learn more, please ensure to keep the trailing period."
    )
    static let learnMore = NSLocalizedString(
        "analyticsUpdateModeBottomSheet.learnMore",
        value: "Learn more",
        comment: "Link text in the analytics updates bottom sheet footer that opens WooCommerce Analytics documentation."
    )
    static let learnMoreNavigationTitle = NSLocalizedString(
        "analyticsUpdateModeBottomSheet.learnMoreNavigationTitle",
        value: "WooCommerce Analytics",
        comment: "Navigation title for the WooCommerce Analytics documentation web view."
    )
    static let updateErrorNotice = NSLocalizedString(
        "analyticsUpdateModeBottomSheet.updateErrorNotice",
        value: "Couldn't update the setting. Please try again.",
        comment: "Notice shown when saving the analytics update mode setting fails."
    )
    static let scheduledTitle = NSLocalizedString(
        "analyticsUpdateModeBottomSheet.scheduledTitle",
        value: "Scheduled",
        comment: "Analytics update option that imports analytics data on a schedule."
    )
    static let scheduledDescription = NSLocalizedString(
        "analyticsUpdateModeBottomSheet.scheduledDescription",
        value: "Updates automatically every 12 hours.\nRecommended for high order volume stores.",
        comment: "Description of the Scheduled analytics update option."
    )
    static let immediateTitle = NSLocalizedString(
        "analyticsUpdateModeBottomSheet.immediateTitle",
        value: "Immediately",
        comment: "Analytics update option that imports analytics data as soon as new data is available."
    )
    static let immediateDescription = NSLocalizedString(
        "analyticsUpdateModeBottomSheet.immediateDescription",
        value: "Updates as soon as new data is available.",
        comment: "Description of the Immediately analytics update option."
    )
}

#Preview("Default") {
    Color.gray
        .sheet(isPresented: .constant(true)) {
            AnalyticsUpdateModeBottomSheet(
                viewModel: AnalyticsUpdateModeBottomSheetViewModel(
                    siteID: 123,
                    selectedMode: .scheduled,
                    onModeUpdated: { _ in }
                )
            )
        }
}
