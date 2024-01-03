import SwiftUI

/// View to set budget for a new Blaze campaign
struct BlazeBudgetSettingView: View {

    @Environment(\.dismiss) private var dismiss
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
                impressionInfoView.presentationDetents([.medium, .large])
            } else {
                impressionInfoView
            }
        }
        .sheet(isPresented: $showingDurationSetting) {
            if #available(iOS 16, *) {
                durationSettingView.presentationDetents([.medium, .large])
            } else {
                durationSettingView
            }
        }

    }
}

private extension BlazeBudgetSettingView {
    var mainContentView: some View {
        ScrollableVStack(spacing: Layout.sectionSpacing) {
            VStack(spacing: Layout.sectionContentSpacing) {
                Text(Localization.title)
                    .bold()
                    .largeTitleStyle()

                Text(Localization.subtitle)
                    .multilineTextAlignment(.center)
                    .subheadlineStyle()
            }

            VStack {
                Text("$35")
                    .bold()
                    .largeTitleStyle()

                Text("for 7 days")
                    .foregroundColor(Color.secondary)
                    .bold()
                    .largeTitleStyle()

                Text("Total spend $1055")
                    .subheadlineStyle()
            }

            VStack {
                Text("$5 daily")

                Slider(value: $viewModel.amount, in: 5...50, step: viewModel.dayCount)

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

            Text(Localization.duration)
                .secondaryBodyStyle()
                .padding(.horizontal, Layout.contentPadding)
                .padding(.top, Layout.sectionContentSpacing)

            HStack {
                Text("Dec 13 - Dec 19, 2023")
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

            Button(Localization.update) {
                // TODO: show duration sheet
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
        ScrollView {
            Text(Localization.setDuration)
                .headlineStyle()
                .padding(.horizontal, Layout.contentPadding)
                .padding(.vertical, Layout.sectionSpacing)

            Spacer()

            VStack(spacing: Layout.sectionContentSpacing) {
                Text("7 days")
                    .fontWeight(.semibold)
                    .bodyStyle()

                Slider(value: $viewModel.dayCount, in: 1...28, step: 1)
            }
            .padding(Layout.contentPadding)

            VStack {
                HStack {
                    Text(Localization.starts)
                        .bodyStyle()

                    Spacer()

                    DatePicker(selection: $viewModel.startDate, displayedComponents: [.date]) {
                        EmptyView()
                    }
                    .datePickerStyle(.compact)
                }
                .padding(Layout.contentPadding)

                Divider()
            }

            Spacer()

            Button(Localization.apply) {
                showingDurationSetting = false
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(Layout.contentPadding)
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
        BlazeBudgetSettingView(viewModel: BlazeBudgetSettingViewModel())
    }
}
