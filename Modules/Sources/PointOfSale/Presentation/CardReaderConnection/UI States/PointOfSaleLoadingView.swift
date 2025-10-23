import SwiftUI

struct POSLoadingAnimation {
    let namespace: Namespace.ID
    let progressTransitionId: String = "pos_card_present_payment_payment_alert_icon_matched_geometry_id"
}

struct PointOfSaleLoadingView: View {
    private let animation: POSLoadingAnimation

    init(animation: POSLoadingAnimation) {
        self.animation = animation
    }

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center) {
                Spacer()
                ProgressView()
                    .progressViewStyle(POSProgressViewStyle())
                    .matchedGeometryEffect(id: animation.progressTransitionId, in: animation.namespace, properties: .position)
                Spacer()
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
        .background(Color.posSurface)
    }
}

#Preview {
    @Previewable @Namespace var namespace
    PointOfSaleLoadingView(animation: .init(namespace: namespace))
}
