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
            impressionInfoView.presentationDetents(sizeCategory.isAccessibilityCategory ? [.medium, .large] : [.medium])
        }
        .sheet(isPresented: $showingDurationSetting) {
            durationSettingView.presentationDetents(sizeCategory.isAccessibilityCategory ? [.medium, .large] : [.medium])
        }
        .onAppear {
            duration = viewModel.dayCount
            startDate = viewModel.startDate
        }
    }
}

private extension BlazeBudgetSettingView {
    var mainContentView: some View {
        ScrollableVStack(padding: 0, spacing: Layout.sectionSpacing) {
            // Title and subtitle
            VStack(spacing: Layout.sectionContentSpacing) {
                Text(Localization.title)
                    .bold()
                    .largeTitleStyle()

                Text(Localization.subtitle)
                    .multilineTextAlignment(.center)
                    .subheadlineStyle()
            }

            // Daily budget amount details
            VStack(spacing: Layout.dailyBudgetSectionSpacing) {
                Text(Localization.dailySpend)
                    .foregroundStyle(Color(.text))
                    .subheadlineStyle()

                Text(String(format: "$%.0f", viewModel.dailyAmount))
                    .fontWeight(.semibold)
                    .largeTitleStyle()

                // Daily amount slider
                Slider(value: $viewModel.dailyAmount,
                       in: viewModel.dailyAmountSliderRange,
                       step: BlazeBudgetSettingViewModel.Constants.dailyAmountSliderStep)
            }

            // Schedule
            VStack(alignment: .leading) {
                // Title
                Text(Localization.schedule)
                    .foregroundStyle(Color(.text))
                    .subheadlineStyle()

                // Formatted duration
                AdaptiveStack(horizontalAlignment: .leading) {
                    Text(viewModel.formattedDateRange)
                    Spacer()
                    Button(Localization.edit) {
                        showingDurationSetting = true
                    }
                    .foregroundStyle(Color.accentColor)
                }
                .tertiaryTitleStyle()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Estimated impressions
            VStack(alignment: .leading) {
                Button {
                    showingImpressionInfo = true
                } label: {
                    AdaptiveStack(horizontalAlignment: .leading) {
                        Text(Localization.estimatedImpressions)
                        Image(systemName: "info.circle")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                .accessibilityHint(Localization.estimatedImpressionsAccessibilityHint)
                .renderedIf(viewModel.forecastedImpressionState != .failure)

                forecastedImpressionsView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    var forecastedImpressionsView: some View {
        switch viewModel.forecastedImpressionState {
        case .loading:
            ActivityIndicator(isAnimating: .constant(true), style: .medium)
        case .result(let formattedResult):
            Text(formattedResult)
                .fontWeight(.semibold)
                .tertiaryTitleStyle()
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
        VStack(alignment: .center, spacing: Layout.sectionContentSpacing) {
            Divider()
            // Total amount and duration
            AttributedText(viewModel.formattedAmountAndDuration)

            // CTA to confirm all settings
            Button(Localization.update) {
                viewModel.confirmSettings()
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding([.horizontal, .bottom], Layout.contentPadding)
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
            ScrollableVStack(alignment: .leading, padding: Layout.contentPadding, spacing: Layout.sectionSpacing) {

                // Start date picker
                AdaptiveStack(horizontalAlignment: .leading) {
                    Text(Localization.startDate)
                        .bodyStyle()

                    Spacer().renderedIf(sizeCategory.isAccessibilityCategory == false)

                    DatePicker(selection: $startDate,
                               in: viewModel.minDayAllowedInPickerSelection...viewModel.maxDayAllowedInPickerSelection,
                               displayedComponents: [.date]) {
                        EmptyView()
                    }
                    .datePickerStyle(.compact)
                }

                // Toggle to switch between evergreen and not. Hidden under a feature flag.
                Toggle(Localization.specifyDuration, isOn: $viewModel.hasEndDate)
                    .toggleStyle(.switch)
                    .renderedIf(ServiceLocator.featureFlagService.isFeatureFlagEnabled(.blazeEvergreenCampaigns))

                Text(Localization.evergreenDescription)
                    .secondaryBodyStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .renderedIf(viewModel.hasEndDate == false)

                // Duration slider - available only if the campaign is not evergreen
                VStack(alignment: .leading, spacing: Layout.sectionContentSpacing) {
                    // Duration and end date
                    AdaptiveStack(horizontalAlignment: .leading) {
                        Text(Localization.duration)
                            .bodyStyle()
                        Spacer().renderedIf(sizeCategory.isAccessibilityCategory == false)
                        AttributedText(viewModel.formatDayCount(duration))
                    }

                    Slider(value: $duration,
                           in: viewModel.dayCountSliderRange,
                           step: Double(BlazeBudgetSettingViewModel.Constants.dayCountSliderStep))
                }
                .renderedIf(viewModel.hasEndDate)

                Spacer()

                // CTA
                Button(Localization.apply) {
                    viewModel.didTapApplyDuration(dayCount: duration, since: startDate)
                    showingDurationSetting = false
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localization.schedule)
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
        static let dailyBudgetSectionSpacing: CGFloat = 8
        static let contentPadding: CGFloat = 16
        static let sectionContentSpacing: CGFloat = 16
        static let sectionSpacing: CGFloat = 32
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
            "blazeBudgetSettingView.description",
            value: "How much would you like to spend on your campaign, and how long should it run for?",
            comment: "Subtitle of the Blaze budget setting screen"
        )
        static let dailySpend = NSLocalizedString(
            "blazeBudgetSettingView.dailySpend",
            value: "Daily spend",
            comment: "Title label for the daily spend amount on the Blaze ads campaign budget settings screen."
        )
        static let estimatedImpressions = NSLocalizedString(
            "blazeBudgetSettingView.estimatedTotalImpressions",
            value: "Estimated total impressions",
            comment: "Label for the estimated impressions on the Blaze budget setting screen"
        )
        static let schedule = NSLocalizedString(
            "blazeBudgetSettingView.schedule",
            value: "Schedule",
            comment: "Label for the campaign schedule on the Blaze budget setting screen"
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
        static let duration = NSLocalizedString(
            "blazeBudgetSettingView.duration",
            value: "Duration",
            comment: "Title label of the Blaze campaign duration field"
        )
        static let startDate = NSLocalizedString(
            "blazeBudgetSettingView.startDate",
            value: "Start date",
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
        static let specifyDuration = NSLocalizedString(
            "blazeBudgetSettingView.specifyDuration",
            value: "Specify the duration",
            comment: "Switch to enable an end date for a Blaze campaign."
        )
        static let evergreenDescription = NSLocalizedString(
            "blazeBudgetSettingView.evergreenDescription",
            value: "Campaign will run until you stop it.",
            comment: "Label to explain when no end date is specified for a Blaze campaign."
        )
        static let estimatedImpressionsAccessibilityHint = NSLocalizedString(
            "blazeBudgetSettingView.estimatedImpressionsAccessibilityHint",
            value: "Tap for more information about estimated impressions",
            comment: "Accessibility hint for the estimated impression button on the Blaze campaign budget setting screen"
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
                                                                      startDate: tomorrow) { _, _, _, _ in })
    }
}
