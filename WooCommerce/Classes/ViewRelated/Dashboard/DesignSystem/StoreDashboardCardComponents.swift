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
        HStack(spacing: StoreSpacing.s3) {
            if showsError {
                StoreIcon.CircleInfo.regular.image(size: .medium)
                    .foregroundStyle(.storeError)
                    .accessibilityHidden(true)
            }
            Text(title)
                .storeTextStyle(.titleSmall.emphasized)
                .foregroundStyle(.storeOnSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
            actions()
        }
        .padding(.horizontal, StorePadding.p7)
        .padding(.top, StorePadding.p7)
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
            StoreIcon.Ellipsis.regular.image(size: .medium)
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(StorePadding.p7)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

private enum Localization {
    static let moreOptions = NSLocalizedString("More options", comment: "Accessibility label for an overflow menu.")
}
