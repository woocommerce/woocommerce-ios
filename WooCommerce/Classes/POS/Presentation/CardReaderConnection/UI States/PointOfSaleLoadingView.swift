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
    }
}

private extension PointOfSaleLoadingView {
    enum Layout {
        static let textSpacing: CGFloat = 16
        static let progressViewSpacing: CGFloat = 72
    }
}

#Preview {
    PointOfSaleLoadingView()
}
