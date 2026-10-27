import StoreDesignSystem
import SwiftUI

/// A titled group of More tab actions displayed in a Design System surface container.
struct StoreHubMenuSection: View {
    let title: String
    let items: [HubMenuItem]
    let onMenuItemTap: (HubMenuItem) -> Void

    var body: some View {
        if items.isNotEmpty {
            VStack(alignment: .leading, spacing: StoreSpacing.s3) {
                Text(title)
                    .storeTextStyle(.bodyLarge.emphasized)
                    .foregroundStyle(.storeOnSurfaceVariant)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: StoreSpacing.s0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        StoreHubMenuRow(item: item, onTap: onMenuItemTap)

                        if index < items.count - 1 {
                            StoreDivider(variant: .inset)
                        }
                    }
                }
                .background(Color.storeSurfaceBright)
                .clipShape(RoundedRectangle(cornerRadius: StoreRadius.extraLarge))
            }
        }
    }
}
