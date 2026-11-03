import Kingfisher
import StoreDesignSystem
import SwiftUI

struct StoreProductStockRow: View {
    @ScaledMetric private var scale: CGFloat = 1.0

    let data: ProductStockRow.RowData
    let showDivider: Bool
    let tapHandler: () -> Void

    var body: some View {
        Button(action: tapHandler) {
            VStack(spacing: StoreSpacing.s0) {
                HStack(alignment: .center, spacing: StoreSpacing.s5) {
                    KFImage(data.imageURL)
                        .placeholder {
                            Image(uiImage: .productPlaceholderImage)
                                .foregroundStyle(.storeOnSurfaceVariant)
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: Layout.thumbnailSize * scale,
                               height: Layout.thumbnailSize * scale)
                        .clipShape(.rect(cornerRadius: StoreRadius.small))

                    VStack(alignment: .leading, spacing: StoreSpacing.s2) {
                        Text(data.name)
                            .storeTextStyle(.titleMedium)
                        if data.subtitle.isNotEmpty {
                            Text(data.subtitle)
                                .storeTextStyle(.bodyMedium)
                        }
                    }
                    .multilineTextAlignment(.leading)

                    Spacer(minLength: StoreSpacing.s0)

                    Text(data.accessoryText)
                        .storeTextStyle(.titleMedium)
                        .foregroundStyle(data.accessoryIsError ? .storeOnErrorContainer : .storeOnSurface)
                        .padding(.horizontal, StorePadding.p2)
                        .background(data.accessoryIsError ? Color.storeErrorContainer : .clear)
                        .clipShape(.rect(cornerRadius: StoreRadius.medium))
                }
                .foregroundStyle(.storeOnSurface)
                .padding(StorePadding.p5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)

                if showDivider {
                    StoreDivider(variant: .inset)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private extension StoreProductStockRow {
    enum Layout {
        static let thumbnailSize: CGFloat = 40
    }
}
