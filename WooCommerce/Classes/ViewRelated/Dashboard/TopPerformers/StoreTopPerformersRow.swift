import Kingfisher
import StoreDesignSystem
import SwiftUI

struct StoreTopPerformersRow: View {
    @ScaledMetric(relativeTo: .body) private var imageSize = Constants.imageSize

    let data: TopPerformersRow.Data
    let showsDivider: Bool

    var body: some View {
        Button(action: { data.tapHandler?() }) {
            AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .top) {
                KFImage(data.imageURL)
                    .placeholder {
                        Image(uiImage: data.placeHolder)
                            .foregroundStyle(.storeOnSurfaceVariant)
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(.rect(cornerRadius: StoreRadius.small))
                    .accessibilityHidden(true)
                    .renderedIf(data.showImage)

                VStack(spacing: StoreSpacing.s0) {
                    HStack(alignment: .top, spacing: StoreSpacing.s3) {
                        VStack(alignment: .leading, spacing: StoreSpacing.s2) {
                            Text(data.name)
                                .storeTextStyle(.titleMedium)
                                .lineLimit(2)
                            Text(data.details)
                                .storeTextStyle(.bodyMedium)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(data.value)
                            .storeTextStyle(.titleMedium)
                    }
                    .foregroundStyle(.storeOnSurface)
                    .multilineTextAlignment(.leading)

                    if showsDivider {
                        StoreDivider()
                            .padding(.top, StorePadding.p3)
                    }
                }
            }
            .padding(.horizontal, StorePadding.p5)
            .padding(.top, StorePadding.p3)
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(data.tapHandler == nil)
        .accessibilityElement(children: .combine)
    }
}

private extension StoreTopPerformersRow {
    enum Constants {
        // Matches the shared Android ProductThumbnail default used by this card.
        static let imageSize: CGFloat = 42
    }
}
