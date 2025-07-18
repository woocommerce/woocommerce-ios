import SwiftUI

struct PointOfSaleLoadingView: View {
    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center) {
                Spacer()
                ProgressView()
                    .progressViewStyle(POSProgressViewStyle())
                Spacer()
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
        .background(Color.posSurface)
    }
}

#Preview {
    PointOfSaleLoadingView()
}
