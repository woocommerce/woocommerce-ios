import SwiftUI

struct PointOfSaleOrderDetailsEmptyView: View {
    var body: some View {
        // TODO: WOOMOB-1136
        VStack(spacing: 0) {
            POSPageHeaderView(
                title: "Orders",
                backButtonConfiguration: nil
            )

            VStack {
                Spacer()
                Text("No Orders Loaded")
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                Spacer()
            }
        }
        .background(Color.posSurface)
        .navigationBarHidden(true)
    }
}

#if DEBUG
#Preview {
    PointOfSaleOrderDetailsEmptyView()
}
#endif
