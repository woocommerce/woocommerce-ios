import Kingfisher
import StoreDesignSystem
import SwiftUI

/// Store identity and store-switching control displayed at the top of the More tab.
struct StoreHubMenuHeader: View {
    let storeTitle: String
    let planName: String
    let storeURL: URL
    let avatarURL: URL?
    let switchStoreEnabled: Bool
    let onSwitchStore: () -> Void

    var body: some View {
        Group {
            if switchStoreEnabled {
                Button(action: onSwitchStore) {
                    content
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("switch-store-button")
            } else {
                content
                    .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.storeSurfaceBright)
        .clipShape(RoundedRectangle(cornerRadius: StoreRadius.extraLarge))
    }

    private var content: some View {
        HStack(spacing: StoreSpacing.s4) {
            avatar

            VStack(alignment: .leading, spacing: StoreSpacing.s1) {
                storeNameAndPlan

                Text(storeURL.host ?? storeURL.absoluteString)
                    .storeTextStyle(.bodySmall)
                    .foregroundStyle(.storeOnSurfaceVariant)
                    .lineLimit(1)
                    .accessibilityIdentifier("store-url")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if switchStoreEnabled {
                StoreIcon.AngleDown.regular.image(size: .medium)
                    .foregroundStyle(.storeOnSurface)
                    .accessibilityHidden(true)
            }
        }
        .padding(StorePadding.p7)
        .contentShape(Rectangle())
    }

    private var storeNameAndPlan: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: StoreSpacing.s2) {
                storeName
                planBadge
            }

            VStack(alignment: .leading, spacing: StoreSpacing.s1) {
                storeName
                planBadge
            }
        }
    }

    private var storeName: some View {
        Text(storeTitle)
            .storeTextStyle(.titleLarge.emphasized)
            .foregroundStyle(.storeOnSurface)
            .lineLimit(2)
            .accessibilityIdentifier("store-title")
    }

    @ViewBuilder
    private var planBadge: some View {
        if planName.isNotEmpty {
            StoreBadge(planName)
        }
    }

    private var avatar: some View {
        KFImage(avatarURL)
            .placeholder { Image(uiImage: .gravatarPlaceholderImage).resizable() }
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: StoreSize.iconContainerSize, height: StoreSize.iconContainerSize)
            .clipShape(RoundedRectangle(cornerRadius: StoreRadius.medium))
            .accessibilityHidden(true)
    }
}
