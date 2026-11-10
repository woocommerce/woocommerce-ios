import StoreDesignSystem
import SwiftUI
import enum Yosemite.StatsTimeRangeV4

struct StoreDashboardCardSurface<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s0) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.storeSurfaceBright)
        .clipShape(.rect(cornerRadius: StoreRadius.extraLarge))
    }
}

struct StoreDashboardCardHeader<Actions: View>: View {
    let title: String
    let showsError: Bool
    let textStyle: StoreTextStyle
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    @ViewBuilder let actions: () -> Actions

    init(_ title: String,
         showsError: Bool = false,
         textStyle: StoreTextStyle = .titleSmall.emphasized,
         topPadding: CGFloat = StorePadding.p7,
         bottomPadding: CGFloat = StorePadding.p7,
         @ViewBuilder actions: @escaping () -> Actions) {
        self.title = title
        self.showsError = showsError
        self.textStyle = textStyle
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
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
                .storeTextStyle(textStyle)
                .foregroundStyle(.storeOnSurface)
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
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
    let textStyle: StoreTextStyle
    let showsDisclosureIndicator: Bool
    let action: () -> Void

    init(_ title: String,
         isDisabled: Bool = false,
         textStyle: StoreTextStyle = .labelLarge.emphasized,
         showsDisclosureIndicator: Bool = false,
         action: @escaping () -> Void) {
        self.title = title
        self.isDisabled = isDisabled
        self.textStyle = textStyle
        self.showsDisclosureIndicator = showsDisclosureIndicator
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: StoreSpacing.s3) {
                Text(title)
                    .storeTextStyle(textStyle)
                    .foregroundStyle(showsDisclosureIndicator ? Color.storePrimary : Color.storeOnSecondaryContainer)

                if showsDisclosureIndicator {
                    Spacer(minLength: StoreSpacing.s0)
                    StoreIcon.AngleRight.regular.image(size: .largeIncreased)
                        .foregroundStyle(.storeOnSurfaceVariant)
                        .flipsForRightToLeftLayoutDirection(true)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, showsDisclosureIndicator ? StorePadding.p5 : StorePadding.p4)
            .frame(maxWidth: showsDisclosureIndicator ? .infinity : nil,
                   minHeight: StoreSize.minimumTapTarget,
                   alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .padding(.leading, showsDisclosureIndicator ? StorePadding.p0 : StorePadding.p3)
        .padding(.bottom, showsDisclosureIndicator ? StorePadding.p0 : StorePadding.p1)
    }
}

struct StoreDashboardDateRangeHeader: View {
    let timeRange: StatsTimeRangeV4
    let dateText: String
    let customTitle: String
    let isDisabled: Bool
    let accessibilityPrefix: String
    let onSelect: (StatsTimeRangeV4) -> Void
    let onEditCustom: () -> Void

    var body: some View {
        HStack(spacing: StoreSpacing.s3) {
            Text(timeRange.isCustomTimeRange ? customTitle : timeRange.tabTitle)
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

    let text: String
    let showsInfoButton: Bool
    let infoAccessibilityLabel: String
    let onInfoTapped: () -> Void

    var body: some View {
        Group {
            if showsInfoButton {
                Button(action: onInfoTapped) {
                    content
                }
                .buttonStyle(.plain)
                .accessibilityLabel(text)
                .accessibilityHint(infoAccessibilityLabel)
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity)
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
}

private enum Localization {
    static let moreOptions = NSLocalizedString("More options", comment: "Accessibility label for an overflow menu.")
    static let filterOptions = NSLocalizedString(
        "Filter",
        comment: "Accessibility label for the filter menu on a Dashboard card."
    )
    static let dateRange = NSLocalizedString(
        "Date Range",
        comment: "Accessibility label for the date range selection menu on a Dashboard card."
    )
}
