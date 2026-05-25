import SwiftUI

/// Detail screen for the New reviews push notification preferences. Reached by
/// tapping the New reviews row in `PushNotificationPreferencesView`. Navigation
/// chrome (title, Save bar button, discard confirmation) lives on the wrapping
/// `NewReviewNotificationPreferencesHostingController`.
///
struct NewReviewNotificationPreferencesDetailView: View {

    @Bindable private var viewModel: PushNotificationPreferencesViewModel

    init(viewModel: PushNotificationPreferencesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            masterToggleSection
            customizationSection
        }
        .listStyle(.insetGrouped)
        .background(Color(.listBackground))
        .disabled(viewModel.isSaving)
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        // `leftBarButtonItem` set in UIKit doesn't suppress SwiftUI's own back
        // button, so without this both render side-by-side and only the UIKit
        // one routes through the discard handler.
        .navigationBarBackButtonHidden(true)
        .notice($viewModel.errorNotice)
    }

    private var masterToggleSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Layout.titleDetailSpacing) {
                Toggle(Localization.enableTitle,
                       isOn: Binding(get: { viewModel.isStoreReviewEnabled },
                                     set: { viewModel.setStoreReviewEnabled($0) }))
                Text(Localization.enableSubtitle)
                    .foregroundStyle(Color(.secondaryLabel))
                    .captionStyle()
            }
        }
    }

    private var customizationSection: some View {
        Section {
            radioRow(title: Localization.allReviewsTitle,
                     subtitle: Localization.allReviewsSubtitle,
                     isSelected: viewModel.storeReviewMaxRating == nil) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.setStoreReviewMaxRating(nil)
                }
            }
            radioRow(title: Localization.lowRatedTitle,
                     subtitle: Localization.lowRatedSubtitle,
                     isSelected: viewModel.storeReviewMaxRating != nil) {
                let restore = viewModel.lastKnownStoreReviewMaxRating
                    ?? PushNotificationPreferencesViewModel.defaultStoreReviewMaxRating
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.setStoreReviewMaxRating(restore)
                }
            }
            if let currentRating = viewModel.storeReviewMaxRating {
                starPickerRow(selected: currentRating)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        } header: {
            Text(Localization.customizeHeader)
        }
        .disabled(!viewModel.isStoreReviewEnabled)
        .opacity(viewModel.isStoreReviewEnabled ? 1.0 : Layout.disabledOpacity)
    }

    private func radioRow(title: String,
                          subtitle: String,
                          isSelected: Bool,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Layout.contentSpacing) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color(.tertiaryLabel))
                    .font(.title3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Layout.titleDetailSpacing) {
                    Text(title)
                        .bodyStyle()
                    Text(subtitle)
                        .foregroundStyle(Color(.secondaryLabel))
                        .captionStyle()
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private func starPickerRow(selected: Int) -> some View {
        VStack(alignment: .leading, spacing: Layout.titleDetailSpacing) {
            // Reuses `storeReviewDetailText` so the picker's label and the list row stay in lockstep.
            // Safe because this view is only rendered when `storeReviewMaxRating != nil`, so the
            // computed property never returns the "All reviews" branch here.
            Text(viewModel.storeReviewDetailText)
                .foregroundStyle(Color.accentColor)
                .captionStyle()
            HStack(spacing: Layout.starSpacing) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        viewModel.setStoreReviewMaxRating(star)
                    } label: {
                        Image(systemName: star <= selected ? "star.fill" : "star")
                            .foregroundStyle(star <= selected ? Color(uiColor: .ratingStarFilled) : Color(uiColor: .ratingStarEmpty))
                            .font(.title2)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Self.starAccessibilityLabel(for: star))
                    .accessibilityAddTraits(star == selected ? [.isSelected, .isButton] : .isButton)
                }
                Spacer()
            }
        }
    }

    private static func starAccessibilityLabel(for star: Int) -> String {
        let format = star == 1 ? Localization.starAccessibilityFormatSingular
                               : Localization.starAccessibilityFormatPlural
        let count = NumberFormatter.localizedString(from: NSNumber(value: star), number: .none)
        return String.localizedStringWithFormat(format, count)
    }
}

private extension NewReviewNotificationPreferencesDetailView {
    enum Layout {
        static let contentSpacing: CGFloat = 12
        static let titleDetailSpacing: CGFloat = 4
        static let disabledOpacity: Double = 0.5
        static let starSpacing: CGFloat = 16
    }

    enum Localization {
        static let title = NSLocalizedString(
            "newReviewNotificationPreferencesDetailView.title",
            value: "New reviews",
            comment: "Title of the new-review push notification preferences detail screen."
        )
        static let enableTitle = NSLocalizedString(
            "newReviewNotificationPreferencesDetailView.enable.title",
            value: "Enable notifications",
            comment: "Title of the master toggle for new-review push notifications."
        )
        static let enableSubtitle = NSLocalizedString(
            "newReviewNotificationPreferencesDetailView.enable.subtitle",
            value: "Get notified when a review is left for your store.",
            comment: "Subtitle of the master toggle for new-review push notifications."
        )
        static let customizeHeader = NSLocalizedString(
            "newReviewNotificationPreferencesDetailView.notifyMeFor.header",
            value: "Notify me for",
            comment: "Section header for new-review notification customization options."
        )
        static let allReviewsTitle = NSLocalizedString(
            "newReviewNotificationPreferencesDetailView.allReviews.title",
            value: "All new reviews",
            comment: "Title of the radio row that enables notifications for every new review."
        )
        static let allReviewsSubtitle = NSLocalizedString(
            "newReviewNotificationPreferencesDetailView.allReviews.subtitle",
            value: "Ping for every review.",
            comment: "Subtitle of the radio row that enables notifications for every new review."
        )
        static let lowRatedTitle = NSLocalizedString(
            "newReviewNotificationPreferencesDetailView.lowRated.title",
            value: "Only low-rated reviews",
            comment: "Title of the radio row that filters notifications to reviews at or below a chosen rating."
        )
        static let lowRatedSubtitle = NSLocalizedString(
            "newReviewNotificationPreferencesDetailView.lowRated.subtitle",
            value: "Filter to reviews at or below your chosen rating.",
            comment: "Subtitle of the radio row that filters notifications to reviews at or below a chosen rating."
        )
        static let starAccessibilityFormatSingular = NSLocalizedString(
            "newReviewNotificationPreferencesDetailView.star.accessibilityFormat.singular",
            value: "%1$@ star",
            comment: "VoiceOver label for the 1-star button in the maximum-rating picker. %1$@ is the formatted star count."
        )
        static let starAccessibilityFormatPlural = NSLocalizedString(
            "newReviewNotificationPreferencesDetailView.star.accessibilityFormat.plural",
            value: "%1$@ stars",
            comment: "VoiceOver label for the 2-5 star buttons in the maximum-rating picker. %1$@ is the formatted star count."
        )
    }
}
