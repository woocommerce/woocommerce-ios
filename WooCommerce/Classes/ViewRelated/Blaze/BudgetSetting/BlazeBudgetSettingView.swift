import SwiftUI

/// View to set budget for a new Blaze campaign
struct BlazeBudgetSettingView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.sizeCategory) private var sizeCategory
    @State private var showingImpressionInfo = false
    @State private var showingDurationSetting = false

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
            VStack {
                Text(viewModel.totalAmountText)
                    .bold()
                    .largeTitleStyle()

                Text(viewModel.formattedTotalDuration)
                    .foregroundColor(Color.secondary)
                    .bold()
                    .largeTitleStyle()

                Text(Localization.totalSpend)
                    .subheadlineStyle()
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

                // TODO: fetch impressions and display
                Text("2,588 - 3,458")
                    .bold()
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
        .padding(.top)
    }

    var durationSettingView: some View {
        NavigationView {
            ScrollView {
                // Duration slider
                VStack(spacing: Layout.sectionContentSpacing) {
                    Text(viewModel.formattedDayCount)
                        .fontWeight(.semibold)
                        .bodyStyle()

                    Slider(value: $viewModel.dayCount,
                           in: viewModel.dayCountSliderRange,
                           step: Double(BlazeBudgetSettingViewModel.Constants.dayCountSliderStep))
                }
                .padding(Layout.contentPadding)
                .padding(.top, Layout.sectionSpacing)

                // Start date picker
                VStack {
                    AdaptiveStack(horizontalAlignment: .leading) {
                        Text(Localization.starts)
                            .bodyStyle()

                        Spacer()

                        DatePicker(selection: $viewModel.startDate, in: Date()..., displayedComponents: [.date]) {
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
            "blazeBudgetSettingView.subtitle",
            value: "How much would you like to spend on your product promotion campaign?",
            comment: "Subtitle of the Blaze budget setting screen"
        )
        static let totalSpend = NSLocalizedString(
            "blazeBudgetSettingView.totalSpend",
            value: "Total spend",
            comment: "Label for total spend on the Blaze budget setting screen"
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
    }
}

struct BlazeBudgetSettingView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeBudgetSettingView(viewModel: BlazeBudgetSettingViewModel(dailyBudget: 5, duration: 7, startDate: .now) { _, _, _ in })
    }
}
