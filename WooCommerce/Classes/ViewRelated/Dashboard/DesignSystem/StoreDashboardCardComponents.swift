import StoreDesignSystem
import SwiftUI
import enum Yosemite.StatsTimeRangeV4

struct StoreDashboardCardSurface<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.storeSurfaceBright)
            .clipShape(.rect(cornerRadius: StoreRadius.extraLarge))
    }
}

struct StoreDashboardCardHeader<Actions: View>: View {
    let title: String
    let showsError: Bool
    @ViewBuilder let actions: () -> Actions

    init(_ title: String, showsError: Bool = false, @ViewBuilder actions: @escaping () -> Actions) {
        self.title = title
        self.showsError = showsError
        self.actions = actions
    }

    var body: some View {
        HStack(spacing: StoreSpacing.s5) {
            if showsError {
                Image(systemName: "exclamationmark.circle")
                    .imageScale(.large)
                    .foregroundStyle(.storeOnSurfaceVariant)
                    .accessibilityHidden(true)
            }
            Text(title)
                .storeTextStyle(.titleSmall.emphasized)
                .foregroundStyle(.storeOnSurface)
                .padding(.vertical, StorePadding.p7)
                .frame(maxWidth: .infinity, alignment: .leading)
            actions()
        }
        .padding(.horizontal, StorePadding.p5)
    }
}

struct StoreDashboardCardFilterHeader<Option>: View {
    let title: String
    let selectedOptionTitle: String
    let options: [Option]
    let isDisabled: Bool
    let optionTitle: (Option) -> String
    let isSelected: (Option) -> Bool
    let onSelect: (Option) -> Void

    var body: some View {
        HStack(spacing: StoreSpacing.s3) {
            Text(title)
            Text(selectedOptionTitle)
            Spacer(minLength: StoreSpacing.s0)
            Menu {
                ForEach(options.indices, id: \.self) { index in
                    let option = options[index]
                    Button {
                        onSelect(option)
                    } label: {
                        HStack(spacing: StoreSpacing.s3) {
                            Text(optionTitle(option))
                            Spacer()
                            if isSelected(option) {
                                StoreIcon.Check.solid.image(size: .small)
                            }
                        }
                    }
                }
            } label: {
                StoreIcon.BarsFilter.regular.image(size: .largeIncreased)
                    .foregroundStyle(.storeOnSurface)
                    .frame(minWidth: StoreSize.minimumTapTarget,
                           minHeight: StoreSize.minimumTapTarget,
                           alignment: .trailing)
                    .contentShape(.rect)
            }
            .disabled(isDisabled)
            .accessibilityLabel(Localization.filterOptions)
        }
        .storeTextStyle(.bodyMedium)
        .foregroundStyle(.storeOnSurface)
        .padding(.horizontal, StorePadding.p5)
    }
}

struct StoreDashboardOutlinedContent<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(StorePadding.p5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.storeSurface)
            .clipShape(.rect(cornerRadius: StoreRadius.medium))
            .overlay {
                RoundedRectangle(cornerRadius: StoreRadius.medium)
                    .stroke(Color.storeOutlineVariant, lineWidth: StoreStrokeWidth.regular)
            }
    }
}

struct StoreDashboardCardOverflowMenu<Actions: View>: View {
    let isDisabled: Bool
    @ViewBuilder let actions: () -> Actions

    init(isDisabled: Bool = false, @ViewBuilder actions: @escaping () -> Actions) {
        self.isDisabled = isDisabled
        self.actions = actions
    }

    var body: some View {
        Menu(content: actions) {
            StoreIcon.Ellipsis.regular.image(size: .largeIncreased)
                .foregroundStyle(.storeOnSurface)
                .frame(minWidth: StoreSize.minimumTapTarget,
                       minHeight: StoreSize.minimumTapTarget,
                       alignment: .trailing)
                .contentShape(.rect)
        }
        .disabled(isDisabled)
        .accessibilityLabel(Localization.moreOptions)
    }
}

struct StoreDashboardCardFooterAction: View {
    let title: String
    let isDisabled: Bool
    let action: () -> Void

    init(_ title: String, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .storeTextStyle(.labelLarge.emphasized)
                .foregroundStyle(.storeOnSecondaryContainer)
                .padding(.horizontal, StorePadding.p4)
                .frame(minHeight: StoreSize.minimumTapTarget)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .padding(.leading, StorePadding.p3)
        .padding(.bottom, StorePadding.p1)
    }
}

struct StoreDashboardDateRangeHeader: View {
    let timeRange: StatsTimeRangeV4
    let dateText: String
    let isDisabled: Bool
    let accessibilityPrefix: String
    let onSelect: (StatsTimeRangeV4) -> Void
    let onEditCustom: () -> Void

    var body: some View {
        HStack(spacing: StoreSpacing.s3) {
            Text(timeRange.isCustomTimeRange ? Localization.custom : timeRange.tabTitle)
                .storeTextStyle(.bodyMedium)
                .foregroundStyle(.storeOnSurface)
                .accessibilityIdentifier("\(accessibilityPrefix)-\(timeRange.menuAccessibilityIdentifier)")

            dateRangeValue
                .padding(StorePadding.p3)

            Spacer(minLength: StoreSpacing.s0)
            dateRangeMenu
        }
    }

    @ViewBuilder private var dateRangeValue: some View {
        if timeRange.isCustomTimeRange {
            Button(action: onEditCustom) {
                HStack(spacing: StoreSpacing.s3) {
                    Text(dateText)
                        .storeTextStyle(.bodyMedium)
                    StoreIcon.Pen.regular.image(size: .large)
                        .accessibilityHidden(true)
                }
                .foregroundStyle(.storeOnSecondaryContainer)
            }
            .buttonStyle(.plain)
        } else {
            Text(dateText)
                .storeTextStyle(.bodyMedium)
                .foregroundStyle(.storeOnSurface)
        }
    }

    private var dateRangeMenu: some View {
        Menu {
            ForEach(Constants.timeRanges, id: \.rawValue) { range in
                Button {
                    onSelect(range)
                } label: {
                    HStack {
                        Text(range.tabTitle)
                        if rangeMatchesSelection(range) {
                            StoreIcon.Check.solid.image(size: .small)
                        }
                    }
                }
                .accessibilityIdentifier(range.menuAccessibilityIdentifier)
            }
        } label: {
            StoreIcon.CalendarDays.regular.image(size: .largeIncreased)
                .foregroundStyle(.storeOnSurface)
                .frame(minWidth: StoreSize.minimumTapTarget,
                       minHeight: StoreSize.minimumTapTarget,
                       alignment: .trailing)
                .contentShape(.rect)
        }
        .disabled(isDisabled)
        .accessibilityIdentifier("\(accessibilityPrefix)-time-range-menu")
        .accessibilityLabel(Localization.dateRange)
    }

    private func rangeMatchesSelection(_ range: StatsTimeRangeV4) -> Bool {
        range.isCustomTimeRange && timeRange.isCustomTimeRange || range == timeRange
    }

    private enum Constants {
        static let timeRanges: [StatsTimeRangeV4] = [.today, .thisWeek, .thisMonth, .thisYear, .custom(from: .now, to: .now)]
    }
}

struct StoreDashboardTimestamp: View {
    @Environment(\.colorScheme) private var colorScheme

    let lastUpdatedTimestamp: String
    let showsScheduledUpdatesDelay: Bool
    let showsInfoButton: Bool
    let onInfoTapped: () -> Void

    var body: some View {
        Group {
            if showsInfoButton {
                Button(action: onInfoTapped) {
                    content
                }
                .buttonStyle(.plain)
                .accessibilityLabel(text)
                .accessibilityHint(Localization.scheduledUpdatesInfoAccessibilityLabel)
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity)
        .padding(StorePadding.p5)
    }

    private var content: some View {
        HStack(spacing: StoreSpacing.s2) {
            Text(text)
                .storeTextStyle(.bodyMedium)
                .foregroundStyle(colorScheme == .dark ? .storePaletteGray20 : .storePaletteGray60)
                .multilineTextAlignment(.center)
            if showsInfoButton {
                StoreIcon.CircleInfo.regular.image(size: .small)
                    .foregroundStyle(.storePrimary)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: StoreSize.minimumTapTarget)
        .contentShape(.rect)
    }

    private var text: String {
        showsScheduledUpdatesDelay ?
        Localization.scheduledUpdatesDelayText :
        Localization.lastUpdatedText(time: lastUpdatedTimestamp)
    }
}

private enum Localization {
    static let moreOptions = NSLocalizedString("More options", comment: "Accessibility label for an overflow menu.")
    static let filterOptions = NSLocalizedString(
        "storeDashboardCardFilterHeader.filterOptions",
        value: "Filter options",
        comment: "Accessibility label for the filter menu on a Dashboard card"
    )
    static let custom = NSLocalizedString(
        "storeDashboardDateRangeHeader.custom",
        value: "Custom",
        comment: "Title of the custom time range on a Dashboard card"
    )
    static let dateRange = NSLocalizedString(
        "storeDashboardDateRangeHeader.dateRange",
        value: "Date Range",
        comment: "Accessibility label for the date range selection menu on a Dashboard card"
    )
    static let scheduledUpdatesDelayText = NSLocalizedString(
        "storeDashboardTimestamp.scheduledUpdatesDelayText",
        value: "Stats may be up to 12 hours delayed",
        comment: "Text shown on a Dashboard card instead of the last updated timestamp when analytics updates are scheduled"
    )
    static let scheduledUpdatesInfoAccessibilityLabel = NSLocalizedString(
        "storeDashboardTimestamp.scheduledUpdatesInfoAccessibilityLabel",
        value: "Analytics update details",
        comment: "Accessibility hint for analytics update details on a Dashboard card"
    )

    static func lastUpdatedText(time: String) -> String {
        let format = NSLocalizedString(
            "storeDashboardTimestamp.lastUpdatedText",
            value: "Last Updated: %1$@",
            comment: "Time when a Dashboard card was last updated"
        )
        return String.localizedStringWithFormat(format, time)
    }
}
