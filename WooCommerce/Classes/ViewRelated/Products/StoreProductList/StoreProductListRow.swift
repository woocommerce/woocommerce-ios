import StoreDesignSystem
import SwiftUI
import WooFoundation
import Yosemite

/// Design-system Products list row; plain content, the hosting table cell owns taps.
struct StoreProductListRow: View {
    @ScaledMetric(relativeTo: .body) private var imageSize = StoreSize.iconContainerSize
    @ScaledMetric(relativeTo: .body) private var minHeight = Constants.minHeight

    let viewModel: ProductsTabProductViewModel
    /// Selected or highlighted in the table.
    let isSelected: Bool
    /// `nil` outside select mode, where the row has no checkbox.
    let isChecked: Bool?
    let showsDivider: Bool

    var body: some View {
        VStack(spacing: StoreSpacing.s0) {
            HStack(alignment: .center, spacing: StoreSpacing.s5) {
                if let isChecked {
                    // `accessibilityHidden` leaves this Button exposed; the cell's selected trait carries the state.
                    StoreCheckbox(isOn: .constant(isChecked))
                        .allowsHitTesting(false)
                        .accessibilityRepresentation {
                            Color.clear.accessibilityHidden(true)
                        }
                }
                thumbnail
                VStack(alignment: .leading, spacing: StoreSpacing.s4) {
                    Text(viewModel.createNameLabel())
                        .storeTextStyle(.bodyLarge.emphasized)
                        .foregroundStyle(.storeOnSurface)
                    metadata
                        .storeTextStyle(.labelMedium)
                        .foregroundStyle(.storeOnSurfaceVariant)
                        .accessibilityIdentifier("product-stock-status-\(viewModel.stockStatusKey)")
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, StorePadding.p5)
            .padding(.vertical, StorePadding.p4)
            .frame(minHeight: minHeight)

            if showsDivider {
                StoreDivider(variant: .inset)
            }
        }
        .background {
            Color.storeSurfaceBright
                .overlay(isSelected || isChecked == true ? Color.storeTintLayerPrimaryContainerOpacity16 : Color.clear)
        }
    }

    private var thumbnail: some View {
        ProductImageThumbnail(productImageURL: viewModel.imageUrl.flatMap(URL.init(string:)),
                              productImageSize: imageSize,
                              scale: 1,
                              productImageCornerRadius: StoreRadius.medium,
                              foregroundColor: .storeOnSurfaceVariant) {
            Image(uiImage: .productPlaceholderImage.withRenderingMode(.alwaysTemplate))
                .foregroundStyle(.storeOnSurfaceVariant)
        }
        .opacity(viewModel.hasPendingUploads ? Constants.uploadingThumbnailOpacity : 1)
        .overlay {
            if viewModel.hasPendingUploads {
                ProgressView()
                    .tint(.storeOnSurface)
            }
        }
    }

    /// Legacy cell composition: status • stock • price • variations, then the SKU on its own line.
    private var metadata: Text {
        var text = Text(verbatim: viewModel.detailsText)
        if let statusText = viewModel.statusText {
            text = Text(verbatim: statusText).foregroundStyle(statusColor) + Text(verbatim: " • ") + text
        }
        if let skuText = viewModel.skuText {
            text = text + Text(verbatim: "\n" + skuText)
        }
        return text
    }

    private var statusColor: Color {
        viewModel.productStatus == .pending ? .storeAlertOrange : .storeAlertBlue
    }
}

/// Loading placeholder with the row's geometry: shapes only, hidden from VoiceOver like Orders'.
struct StoreProductListSkeletonRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var imageSize = StoreSize.iconContainerSize
    @ScaledMetric(relativeTo: .body) private var minHeight = StoreProductListRow.Constants.minHeight

    var body: some View {
        VStack(spacing: StoreSpacing.s0) {
            HStack(alignment: .center, spacing: StoreSpacing.s5) {
                RoundedRectangle(cornerRadius: StoreRadius.medium).fill(.storeStateLayerOnSurfaceOpacity16)
                    .frame(width: imageSize, height: imageSize)
                VStack(alignment: .leading, spacing: StoreSpacing.s4) {
                    bar.frame(width: StoreSpacing.s12 * 3, height: StoreSpacing.s5)
                    bar.frame(width: StoreSpacing.s12 * 2, height: StoreSpacing.s4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, StorePadding.p5)
            .padding(.vertical, StorePadding.p4)
            .frame(minHeight: minHeight)

            StoreDivider(variant: .inset)
        }
        .background(.storeSurfaceBright)
        .shimmering(active: !reduceMotion)
        .accessibilityHidden(true)
    }

    private var bar: some View {
        RoundedRectangle(cornerRadius: StoreRadius.small).fill(.storeStateLayerOnSurfaceOpacity16)
    }
}

extension StoreProductListRow {
    enum Constants {
        static let minHeight: CGFloat = 92
        static let uploadingThumbnailOpacity = 0.3
    }
}

#if DEBUG
#Preview("Light") {
    StoreProductListRowPreview()
}

#Preview("Dark") {
    StoreProductListRowPreview()
        .preferredColorScheme(.dark)
}

private struct StoreProductListRowPreview: View {
    var body: some View {
        VStack(spacing: StoreSpacing.s0) {
            ForEach(ProductListItem.previewItems, id: \.productID) { item in
                StoreProductListRow(viewModel: .preview(item), isSelected: false, isChecked: nil, showsDivider: true)
            }
            StoreProductListRow(viewModel: .preview(.previewItem(id: 4, name: "Uploading an image"), hasPendingUploads: true),
                                isSelected: false,
                                isChecked: nil,
                                showsDivider: true)
            StoreProductListRow(viewModel: .preview(.previewItem(id: 5, name: "Selected")), isSelected: true, isChecked: nil, showsDivider: true)
            StoreProductListRow(viewModel: .preview(.previewItem(id: 6, name: "Checked")), isSelected: false, isChecked: true, showsDivider: true)
            StoreProductListRow(viewModel: .preview(.previewItem(id: 7, name: "Not checked")), isSelected: false, isChecked: false, showsDivider: false)
            StoreProductListSkeletonRow()
        }
    }
}

private extension ProductsTabProductViewModel {
    static func preview(_ product: ProductListItem, hasPendingUploads: Bool = false) -> ProductsTabProductViewModel {
        ProductsTabProductViewModel(product: product, hasPendingUploads: hasPendingUploads, isSKUShown: true, isPriceShown: true)
    }
}

private extension ProductListItem {
    static let previewItems: [ProductListItem] = [
        previewItem(id: 1, name: "Hoodie with a very long name that wraps onto two lines", sku: "HOODIE-1", price: "42"),
        previewItem(id: 2, name: "Beanie", status: .draft, stockStatus: .outOfStock),
        previewItem(id: 3, name: "Cap", status: .pending, price: "15", stockStatus: .onBackOrder)
    ]

    static func previewItem(id: Int64,
                            name: String,
                            status: ProductStatus = .published,
                            sku: String? = nil,
                            price: String = "",
                            stockStatus: ProductStockStatus = .inStock) -> ProductListItem {
        ProductListItem(siteID: 1, productID: id, name: name, productTypeKey: ProductType.simple.rawValue, statusKey: status.rawValue,
                        sku: sku, price: price, manageStock: false, stockQuantity: nil, stockStatusKey: stockStatus.rawValue,
                        imageURL: nil, variations: [], bundleStockStatus: nil, bundleStockQuantity: nil)
    }
}
#endif
