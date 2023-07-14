import SwiftUI
import Yosemite

struct WooPlanFeatureBenefitsView: View {
    let wooPlanFeatureGroup: WooPlanFeatureGroup

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack {
                RoundedRectangle(cornerRadius: Layout.imageCardCornerRadius)
                    .frame(height: Layout.imageCardHeight)
                    .foregroundColor(wooPlanFeatureGroup.imageCardColor)
                    .overlay(
                        Image(wooPlanFeatureGroup.imageFilename)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(.vertical, Layout.imageCardImageVerticalPadding)
                    )
                    .accessibilityHidden(true)

                Text(wooPlanFeatureGroup.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)

                ForEach(wooPlanFeatureGroup.features, id: \.title) { feature in
                    WooPlanFeatureBenefitRow(feature: feature)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.clear)
            .padding()
        }
        .navigationTitle(wooPlanFeatureGroup.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            ServiceLocator.analytics.track(.planUpgradeDetailsScreenLoaded)
        }
    }

    private enum Layout {
        static let imageCardCornerRadius: CGFloat = 16
        static let imageCardHeight: CGFloat = 164
        static let imageCardImageVerticalPadding: CGFloat = 22
    }
}

struct WooPlanFeatureBenefitRow: View {
    let feature: WooPlanFeature

    var body: some View {
        HStack(alignment: .top) {
            Image(uiImage: .checkmarkImage)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Layout.checkmarkWidth)
                .foregroundColor(.withColorStudio(name: .green, shade: .shade40))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Layout.titleDescriptionVerticalSpacing) {
                Text(feature.title)
                    .font(.body)
                    .accessibilityAddTraits(.isHeader)

                Text(feature.description)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Layout.verticalPadding)
    }

    private enum Layout {
        static let verticalPadding: CGFloat = 4
        static let checkmarkWidth: CGFloat = 24
        static let titleDescriptionVerticalSpacing: CGFloat = 2
        static let checkmarkToTextHorizontalSpacing: CGFloat = 8
    }
}

struct WooPlanFeatureBenefitsView_Previews: PreviewProvider {
    static let featureGroup: WooPlanFeatureGroup = LegacyWooPlan.loadHardcodedPlan().planFeatureGroups[0]
    static var previews: some View {
        WooPlanFeatureBenefitsView(wooPlanFeatureGroup: featureGroup)
    }
}
