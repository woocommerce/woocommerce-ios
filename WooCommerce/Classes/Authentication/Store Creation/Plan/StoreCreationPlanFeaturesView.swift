import SwiftUI

/// Displays a vertical list of features included in the WPCOM plan during the store creation flow.
struct StoreCreationPlanFeaturesView: View {
    /// Features to show in a vertical list.
    let features: [StoreCreationPlanViewModel.Feature]

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(features, id: \.title) { feature in
                HStack(spacing: 12) {
                    Image(uiImage: feature.icon)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color(.wooCommercePurple(.shade90)))
                        .frame(width: 18 * scale, height: 18 * scale)
                    Text(feature.title)
                        .foregroundColor(Color(.label))
                        .bodyStyle()
                }
            }
        }
    }
}

struct StoreCreationPlanFeaturesView_Previews: PreviewProvider {
    static var previews: some View {
        StoreCreationPlanFeaturesView(features: [.init(icon: .megaphoneIcon, title: "Get updates!")])
    }
}
