import SwiftUI

/// View to set the schedule for a Blaze campaign.
///
struct BlazeScheduleSettingView: View {
    @Environment(\.sizeCategory) private var sizeCategory
    @State private var startDate: Date
    @State private var hasEndDate: Bool
    @State private var duration: Double

    private let durationTextFormatter: (Double) -> NSAttributedString
    private let completionHandler: (Date, Bool, Double) -> Void
    private let dismissHandler: () -> Void

    private let minDayAllowedInPickerSelection = Date.now + 60 * 60 * 24 // Current date + 1 day

    /// Using Double because Slider doesn't work with Int
    private let dayCountSliderRange = Double(Constants.minimumDayCount)...Double(Constants.maximumDayCount)

    // Start date needs to be inside the accepted range that is max 60 days from today
    // (internally, we validate 61 to simplify the logic related to timezones).
    private let maxDayAllowedInPickerSelection = Calendar.current.date(byAdding: .day, value: 61, to: Date())!

    init(startDate: Date,
         hasEndDate: Bool,
         duration: Double,
         durationTextFormatter: @escaping (Double) -> NSAttributedString,
         onCompletion: @escaping (Date, Bool, Double) -> Void,
         onDismiss: @escaping () -> Void) {
        self.startDate = startDate
        self.hasEndDate = hasEndDate
        self.duration = duration
        self.durationTextFormatter = durationTextFormatter
        self.completionHandler = onCompletion
        self.dismissHandler = onDismiss
    }

    var body: some View {
        NavigationView {
            ScrollableVStack(alignment: .leading, padding: Layout.contentPadding, spacing: Layout.sectionSpacing) {

                // Start date picker
                AdaptiveStack(horizontalAlignment: .leading) {
                    Text(Localization.startDate)
                        .bodyStyle()

                    Spacer().renderedIf(sizeCategory.isAccessibilityCategory == false)

                    DatePicker(selection: $startDate,
                               in: minDayAllowedInPickerSelection...maxDayAllowedInPickerSelection,
                               displayedComponents: [.date]) {
                        EmptyView()
                    }
                               .datePickerStyle(.compact)
                }

                // Toggle to switch between evergreen and not. Hidden under a feature flag.
                Toggle(Localization.specifyDuration, isOn: $hasEndDate)
                    .toggleStyle(.switch)
                    .renderedIf(ServiceLocator.featureFlagService.isFeatureFlagEnabled(.blazeEvergreenCampaigns))

                Text(Localization.evergreenDescription)
                    .secondaryBodyStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .renderedIf(hasEndDate == false)

                // Duration slider - available only if the campaign is not evergreen
                VStack(alignment: .leading, spacing: Layout.sectionContentSpacing) {
                    // Duration and end date
                    AdaptiveStack(horizontalAlignment: .leading) {
                        Text(Localization.duration)
                            .bodyStyle()
                        Spacer().renderedIf(sizeCategory.isAccessibilityCategory == false)
                        AttributedText(durationTextFormatter(duration))
                    }

                    Slider(value: $duration,
                           in: dayCountSliderRange,
                           step: Double(BlazeBudgetSettingViewModel.Constants.dayCountSliderStep))
                }
                .renderedIf(hasEndDate)

                Spacer()

                // CTA
                Button(Localization.apply) {
                    completionHandler(startDate, hasEndDate, duration)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localization.schedule)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel) {
                        dismissHandler()
                    }
                }
            }
        }
    }
}

private extension BlazeScheduleSettingView {
    enum Layout {
        static let contentPadding: CGFloat = 16
        static let sectionContentSpacing: CGFloat = 16
        static let sectionSpacing: CGFloat = 32
    }

    enum Constants {
        static let minimumDayCount = 1
        static let maximumDayCount = 28
    }

    enum Localization {
        static let schedule = NSLocalizedString(
            "blazeScheduleSettingView.schedule",
            value: "Schedule",
            comment: "Label for the campaign schedule on the Blaze budget setting screen"
        )
        static let startDate = NSLocalizedString(
            "blazeScheduleSettingView.startDate",
            value: "Start date",
            comment: "Label of the start date picker on the Blaze campaign duration setting screen"
        )
        static let specifyDuration = NSLocalizedString(
            "blazeScheduleSettingView.specifyDuration",
            value: "Specify the duration",
            comment: "Switch to enable an end date for a Blaze campaign."
        )
        static let evergreenDescription = NSLocalizedString(
            "blazeScheduleSettingView.evergreenDescription",
            value: "Campaign will run until you stop it.",
            comment: "Label to explain when no end date is specified for a Blaze campaign."
        )
        static let apply = NSLocalizedString(
            "blazeScheduleSettingView.apply",
            value: "Apply",
            comment: "Button to apply the changes on the Blaze campaign duration setting screen"
        )
        static let duration = NSLocalizedString(
            "blazeScheduleSettingView.duration",
            value: "Duration",
            comment: "Title label of the Blaze campaign duration field"
        )
        static let cancel = NSLocalizedString(
            "blazeScheduleSettingView.cancel",
            value: "Cancel",
            comment: "Button to dismiss the Blaze schedule setting screen"
        )
    }
}

#Preview {
    BlazeScheduleSettingView(startDate: .now, hasEndDate: true, duration: 3, durationTextFormatter: { _ in
        NSAttributedString(string: "test")
    }, onCompletion: { _, _, _ in }, onDismiss: {})
}
