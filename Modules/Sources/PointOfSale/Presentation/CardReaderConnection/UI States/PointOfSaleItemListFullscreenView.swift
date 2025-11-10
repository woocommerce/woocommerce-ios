import SwiftUI

struct PointOfSaleItemListFullscreenView<Content: View>: View {
    let showTitle: Bool
    let content: () -> Content

    init(showTitle: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.showTitle = showTitle
        self.content = content
    }

    var body: some View {
        ZStack {
            // TODO: WOOMOB-1692 remove specialisation of errors if possible
            if showTitle {
                VStack(alignment: .center, spacing: PointOfSaleItemListErrorLayout.headerSpacing) {
                    POSHeaderTitleView(
                        title: Localization.title,
                        foregroundColor: .posOnSurfaceVariantHighest
                    )
                    Spacer()
                }
            }

            content()
                .zIndex(1)
        }
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "pos.itemListFullscreen.title",
        value: "Products",
        comment: "Title at the top of the Point of Sale item list full screen."
    )
}

#Preview {
    PointOfSaleItemListFullscreenView(
        content: {
            POSListErrorView(
                error: .init(errorType: .productsLoadError, title: "Error", subtitle: "Something went wrong", buttonText: "Fix it"))
        })
}
