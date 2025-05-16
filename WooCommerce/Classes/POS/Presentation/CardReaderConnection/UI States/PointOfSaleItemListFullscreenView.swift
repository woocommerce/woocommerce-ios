import SwiftUI

struct PointOfSaleItemListFullscreenView<Content: View>: View {
    let content: () -> Content

    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: PointOfSaleItemListErrorLayout.headerSpacing) {
                POSHeaderTitleView(
                    title: Localization.title,
                    foregroundColor: .posOnSurfaceVariantHighest
                )
                Spacer()
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

@available(iOS 17.0, *)
#Preview {
    PointOfSaleItemListFullscreenView(
        content: {
            PointOfSaleItemListErrorView(
                error: .init(errorType: .productsLoadError, title: "Error", subtitle: "Something went wrong", buttonText: "Fix it"))
        })
}
