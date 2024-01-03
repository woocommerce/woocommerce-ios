import SwiftUI

/// View to set budget for a new Blaze campaign
struct BlazeBudgetSettingView: View {

    @Environment(\.dismiss) var dismiss

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

                    Slider(value: $viewModel.amount) {
                        Text("")
                    } minimumValueLabel: {
                        Text("")
                    } maximumValueLabel: {
                        Text("")
                    }

                    Text(Localization.estimatedImpressions)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    + Text(" ")
                    + Text(Image(systemName: "info.circle"))
                        .font(.subheadline)

                    Text("2,588 - 3,458")
                        .bold()
                        .font(.subheadline)
                }
            }
        }
        .padding(Layout.contentPadding)
        .safeAreaInset(edge: .bottom) {
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
                        .bodyStyle()
                }
                .padding(.horizontal, Layout.contentPadding)

                Button(Localization.update) {
                    // TODO: show duration sheet
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding([.horizontal, .bottom], Layout.contentPadding)
                .padding(.top, Layout.sectionContentSpacing)
            }
            .background(Color(.systemBackground))
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
    }
}

struct BlazeBudgetSettingView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeBudgetSettingView(viewModel: BlazeBudgetSettingViewModel())
    }
}
