import SwiftUI

/// View to set budget for a new Blaze campaign
struct BlazeBudgetSettingView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.sizeCategory) private var sizeCategory
    @State private var showingImpressionInfo = false
    @State private var showingDurationSetting = false
    @State private var duration: Double = 0
    @State private var startDate = Date()

    @ObservedObject private var viewModel: BlazeBudgetSettingViewModel

    init(viewModel: BlazeBudgetSettingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: Layout.sectionSpacing) {
            // Cancel button
            HStack {
                Button(Localization.cancel) {
                    dismiss()
                }
                Spacer()
            }

            mainContentView
        }
        .padding(Layout.contentPadding)
        .safeAreaInset(edge: .bottom) {
            footerView
        }
        .sheet(isPresented: $showingImpressionInfo) {
            if #available(iOS 16, *) {
                impressionInfoView.presentationDetents(sizeCategory.isAccessibilityCategory ? [.medium, .large] : [.medium])
            } else {
                impressionInfoView
            }
        }
        .sheet(isPresented: $showingDurationSetting) {
            if #available(iOS 16, *) {
                durationSettingView.presentationDetents(sizeCategory.isAccessibilityCategory ? [.medium, .large] : [.medium])
            } else {
                durationSettingView
            }
        }
        .onAppear {
            duration = viewModel.dayCount
            startDate = viewModel.startDate
        }
    }
}

private extension BlazeBudgetSettingView {
    var mainContentView: some View {
        ScrollableVStack(spacing: Layout.sectionSpacing) {
            // Title and subtitle
            VStack(spacing: Layout.sectionContentSpacing) {
                Text(Localization.title)
                    .bold()
                    .largeTitleStyle()

                Text(Localization.subtitle)
                    .multilineTextAlignment(.center)
                    .subheadlineStyle()
            }

            // Total budget amount details
            // If the campaign is evergreen, display the weekly budget instead
            VStack {
                Text(viewModel.isEvergreen ? Localization.weeklySpend : Localization.totalSpend)
                    .subheadlineStyle()

                Text(viewModel.isEvergreen ? viewModel.weeklyAmountText : viewModel.totalAmountText)
                    .bold()
                    .largeTitleStyle()

                Text(viewModel.formattedTotalDuration)
                    .foregroundColor(Color.secondary)
                    .bold()
                    .largeTitleStyle()
                    .renderedIf(viewModel.isEvergreen == false)
            }

            // Daily amount slider and estimated impression
            VStack {
                Text(viewModel.dailyAmountText)

                Slider(value: $viewModel.dailyAmount,
                       in: viewModel.dailyAmountSliderRange,
                       step: BlazeBudgetSettingViewModel.Constants.dailyAmountSliderStep)

                AdaptiveStack {
                    Text(Localization.estimatedImpressions)
                    Image(systemName: "info.circle")
                }
                .font(.subheadline)
                .onTapGesture {
                    showingImpressionInfo = true
                }
                .renderedIf(viewModel.forecastedImpressionState != .failure)

                forecastedImpressionsView
            }
        }
    }

    @ViewBuilder
    var forecastedImpressionsView: some View {
        switch viewModel.forecastedImpressionState {
        case .loading:
            ActivityIndicator(isAnimating: .constant(true), style: .medium)
        case .result(let formattedResult):
            Text(formattedResult)
                .bold()
                .font(.subheadline)
        case .failure:
            Button {
                Task {
                    await viewModel.retryFetchingImpressions()
                }
            } label: {
                Text(Localization.forecastingFailed)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
        }
    }

    var footerView: some View {
        VStack(alignment: .leading, spacing: Layout.sectionContentSpacing) {
            Divider()

            // Duration title
            Text(Localization.duration)
                .secondaryBodyStyle()
                .padding(.horizontal, Layout.contentPadding)
                .padding(.top, Layout.sectionContentSpacing)

            // Formatted duration
            HStack {
                Text(viewModel.formattedDateRange)
                    .bold()
                    .bodyStyle()
                Text("·")
                Text(Localization.edit)
                    .foregroundColor(.accentColor)
                    .bodyStyle()
            }
            .padding(.horizontal, Layout.contentPadding)
            .onTapGesture {
                showingDurationSetting = true
            }

            // CTA to confirm all settings
            Button(Localization.update) {
                viewModel.confirmSettings()
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding([.horizontal, .bottom], Layout.contentPadding)
            .padding(.top, Layout.sectionContentSpacing)
        }
        .background(Color(.systemBackground))
    }

    var impressionInfoView: some View {
        NavigationView {
            ScrollView {
                Text(Localization.impressionInfo)
                    .bodyStyle()
                    .padding(Layout.contentPadding)
            }
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.done) {
                        showingImpressionInfo = false
                    }
                }
            }
        }
    }

    var durationSettingView: some View {
        NavigationView {
            ScrollView {

                Toggle(Localization.evergreenCampaign, isOn: $viewModel.isEvergreen)
                    .toggleStyle(.switch)
                    .padding(Layout.contentPadding)
                    .padding(.top, Layout.sectionSpacing)

                // Duration slider
                VStack(spacing: Layout.sectionContentSpacing) {
                    Text(viewModel.formatDayCount(duration))
                        .fontWeight(.semibold)
                        .bodyStyle()

                    Slider(value: $duration,
                           in: viewModel.dayCountSliderRange,
                           step: Double(BlazeBudgetSettingViewModel.Constants.dayCountSliderStep))
                }
                .padding(Layout.contentPadding)
                .renderedIf(viewModel.isEvergreen == false)

                // Start date picker
                VStack {
                    AdaptiveStack(horizontalAlignment: .leading) {
                        Text(Localization.starts)
                            .bodyStyle()

                        Spacer()

                        DatePicker(selection: $startDate,
                                   in: viewModel.minDayAllowedInPickerSelection...viewModel.maxDayAllowedInPickerSelection,
                                   displayedComponents: [.date]) {
                            EmptyView()
                        }
                        .datePickerStyle(.compact)
                    }
                    .padding(Layout.contentPadding)

                    Divider()
                }

                Spacer()

                // CTA
                Button(Localization.apply) {
                    viewModel.didTapApplyDuration(dayCount: duration, since: startDate)
                    showingDurationSetting = false
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(Layout.contentPadding)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localization.setDuration)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel) {
                        showingDurationSetting = false
                    }
                }
            }
        }
    }
}

private extension BlazeBudgetSettingView {
    enum Layout {
        static let contentPadding: CGFloat = 16
        static let sectionContentSpacing: CGFloat = 8
        static let sectionSpacing: CGFloat = 40
    }

    enum Localization {
        static let cancel = NSLocalizedString(
            "blazeBudgetSettingView.cancel",
            value: "Cancel",
            comment: "Button to dismiss the Blaze budget setting screen"
        )
        static let title = NSLocalizedString(
            "blazeBudgetSettingView.title",
            value: "Set your budget",
            comment: "Title of the Blaze budget setting screen"
        )
        static let subtitle = NSLocalizedString(
            "blazeBudgetSettingView.subtitle",
            value: "How much would you like to spend on your product promotion campaign?",
            comment: "Subtitle of the Blaze budget setting screen"
        )
        static let totalSpend = NSLocalizedString(
            "blazeBudgetSettingView.totalSpend",
            value: "Total spend",
            comment: "Label for total spend on the Blaze budget setting screen"
        )
        static let weeklySpend = NSLocalizedString(
            "blazeBudgetSettingView.weeklySpend",
            value: "Weekly spend",
            comment: "Label for weekly spend on the Blaze budget setting screen"
        )
        static let estimatedImpressions = NSLocalizedString(
            "blazeBudgetSettingView.estimatedImpressions",
            value: "Estimated people reached per day",
            comment: "Label for the estimated impressions on the Blaze budget setting screen"
        )
        static let duration = NSLocalizedString(
            "blazeBudgetSettingView.duration",
            value: "Duration",
            comment: "Label for the campaign duration on the Blaze budget setting screen"
        )
        static let edit = NSLocalizedString(
            "blazeBudgetSettingView.edit",
            value: "Edit",
            comment: "Button to edit the campaign duration on the Blaze budget setting screen"
        )
        static let update = NSLocalizedString(
            "blazeBudgetSettingView.update",
            value: "Update",
            comment: "Button to update the budget on the Blaze budget setting screen"
        )
        static let impressions = NSLocalizedString(
            "blazeBudgetSettingView.impressions",
            value: "Impressions",
            comment: "Title of the modal to explain Blaze campaign impressions"
        )
        static let impressionInfo = NSLocalizedString(
            "blazeBudgetSettingView.impressionInfo",
            value: "Impressions reflect the frequency with which your ad appears to potential customers.\n\n" +
            "While exact numbers can't be assured due to fluctuating online traffic and user behavior," +
            " we aim to match your ad's actual impressions as closely as possible to your target count.\n\n" +
            "Remember, impressions are about visibility, not action taken by viewers.",
            comment: "Explanation about Blaze campaign impression"
        )
        static let done = NSLocalizedString(
            "blazeBudgetSettingView.done",
            value: "Done",
            comment: "Button to dismiss the Blaze impression info screen"
        )
        static let setDuration = NSLocalizedString(
            "blazeBudgetSettingView.setDuration",
            value: "Set duration",
            comment: "Title of the Blaze campaign duration setting screen"
        )
        static let starts = NSLocalizedString(
            "blazeBudgetSettingView.starts",
            value: "Starts",
            comment: "Label of the start date picker on the Blaze campaign duration setting screen"
        )
        static let apply = NSLocalizedString(
            "blazeBudgetSettingView.apply",
            value: "Apply",
            comment: "Button to apply the changes on the Blaze campaign duration setting screen"
        )
        static let forecastingFailed = NSLocalizedString(
            "blazeBudgetSettingView.forecastingFailed",
            value: "Failed to estimate impressions. Retry?",
            comment: "Button to retry fetching estimated impressions on the Blaze campaign duration setting screen"
        )
        static let evergreenCampaign = NSLocalizedString(
            "blazeBudgetSettingView.evergreenCampaign",
            value: "Run until I stop it",
            comment: "Switch to toggle evergreen mode on or off for a Blaze campaign."
        )
    }
}

struct BlazeBudgetSettingView_Previews: PreviewProvider {
    static var previews: some View {
        let tomorrow = Date.now + 60 * 60 * 24 // Current date + 1 day
        BlazeBudgetSettingView(viewModel: BlazeBudgetSettingViewModel(siteID: 123,
                                                                      dailyBudget: 5,
                                                                      isEvergreen: true,
                                                                      duration: 7,
                                                                      startDate: tomorrow) { _, _, _ in })
    }
}
