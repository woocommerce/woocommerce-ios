import Yosemite
import SwiftUI

/// Row for a selectable shipment item to ship with the Woo Shipping extension.
struct SelectableShipmentRow: View {
    @ObservedObject private var viewModel: SelectableShipmentItemRowViewModel

    init(viewModel: SelectableShipmentItemRowViewModel) {
        self.viewModel = viewModel
    }

    @ScaledMetric private var scale: CGFloat = 1

    var body: some View {
        AdaptiveStack(spacing: Layout.horizontalSpacing) {
            if viewModel.isSelectable {
                selectionCircle(selected: viewModel.selected)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.handleTap()
                    }
            }

            ProductImageThumbnail(productImageURL: viewModel.item.imageUrl,
                                  productImageSize: Layout.imageSize,
                                  scale: scale,
                                  productImageCornerRadius: Layout.imageCornerRadius,
                                  foregroundColor: Color(UIColor.listSmallIcon))
            .overlay(alignment: .topTrailing) {
                if viewModel.showQuantity {
                    BadgeView(text: viewModel.item.quantityLabel,
                              customizations: .init(textColor: .white, backgroundColor: .black),
                              backgroundShape: badgeStyle)
                    .offset(x: Layout.badgeOffset, y: -Layout.badgeOffset)
                }
            }
            VStack(alignment: .leading) {
                Text(viewModel.item.name)
                    .bodyStyle()
                Text(viewModel.item.detailsLabel)
                    .subheadlineStyle()
                AdaptiveStack(verticalAlignment: .lastTextBaseline) {
                    Text(viewModel.item.weightLabel)
                        .subheadlineStyle()
                    Spacer()
                    Text(viewModel.item.priceLabel)
                        .font(.subheadline)
                        .foregroundStyle(Color(.text))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private extension SelectableShipmentRow {
    @ViewBuilder
    func selectionCircle(selected: Bool) -> some View {
        if selected {
            Image(uiImage: .checkCircleImage.withRenderingMode(.alwaysTemplate))
                .foregroundStyle(Color(.primary))
        } else {
            Image(uiImage: .checkEmptyCircleImage)
        }
    }

    /// Displays a different badge background shape based on the item quantity
    /// Circular for 2-character quantities, rounded for 3-character quantities or more
    var badgeStyle: BadgeView.BackgroundShape {
        if viewModel.item.quantityLabel.count < 3 {
            return .circle
        } else {
            return .roundedRectangle(cornerRadius: Layout.badgeOffset)
        }
    }
}

private extension SelectableShipmentRow {
    enum Layout {
        static let horizontalSpacing: CGFloat = 16
        static let imageSize: CGFloat = 56.0
        static let imageCornerRadius: CGFloat = 4.0
        static let badgeOffset: CGFloat = 8.0
    }
}

#Preview {
    SelectableShipmentRow(viewModel: SelectableShipmentItemRowViewModel(itemID: "123",
                                                                        isSelectable: false,
                                                                        item: WooShippingItemRowViewModel(imageUrl: nil,
                                                                                                          quantityLabel: "3",
                                                                                                          name: "Little Nap Brazil 250g",
                                                                                                          detailsLabel: "15×10×8cm • Espresso",
                                                                                                          weightLabel: "275g",
                                                                                                          priceLabel: "$60.00")))
}
