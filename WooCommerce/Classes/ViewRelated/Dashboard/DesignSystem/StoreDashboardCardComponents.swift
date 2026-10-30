import StoreDesignSystem
import SwiftUI

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
        HStack(spacing: StoreSpacing.s0) {
            if showsError {
                Image(systemName: "exclamationmark.circle")
                    .imageScale(.large)
                    .foregroundStyle(.storeOnSurfaceVariant)
                    .accessibilityHidden(true)
            }
            Text(title)
                .storeTextStyle(.titleSmall.emphasized)
                .foregroundStyle(.storeOnSurface)
                .padding(.leading, showsError ? StorePadding.p5 : StorePadding.p0)
                .padding(.trailing, StorePadding.p5)
                .padding(.vertical, StorePadding.p7)
                .frame(maxWidth: .infinity, alignment: .leading)
            actions()
        }
        .padding(.leading, StorePadding.p5)
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
                .frame(minWidth: StoreSize.minimumTapTarget, minHeight: StoreSize.minimumTapTarget)
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

private enum Localization {
    static let moreOptions = NSLocalizedString("More options", comment: "Accessibility label for an overflow menu.")
}
