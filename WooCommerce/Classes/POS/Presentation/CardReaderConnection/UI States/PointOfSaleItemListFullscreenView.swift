import SwiftUI

struct PointOfSaleItemListFullscreenView<Content: View>: View {
    let content: () -> Content

    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: PointOfSaleItemListErrorLayout.headerSpacing) {
                POSHeaderTitleView(foregroundColor: .posSecondaryText)
                Spacer()
            }

            content()
                .zIndex(1)
        }
    }
}

#Preview {
    PointOfSaleItemListFullscreenView(
        content: {
            PointOfSaleItemListErrorView(
                error: .init(title: "Error", subtitle: "Something went wrong", buttonText: "Fix it"))
        })
}
