import SwiftUI
import Yosemite

struct WooPlanFeatureBenefitsView: View {
    let wooPlanFeatureGroup: WooPlanFeatureGroup

    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16)
                .frame(height: 164)
                .foregroundColor(wooPlanFeatureGroup.imageCardColor)
                .overlay(
                    Image(wooPlanFeatureGroup.imageFilename)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 120)
                )

            Text(wooPlanFeatureGroup.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(wooPlanFeatureGroup.features, id: \.title) { feature in
                WooPlanFeatureBenefitRow(feature: feature)
            }

            Spacer()
        }
        .scrollVerticallyIfNeeded()
        .padding()
        .navigationTitle(wooPlanFeatureGroup.title)
    }
}

struct WooPlanFeatureBenefitRow: View {
    let feature: WooPlanFeature

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(uiImage: .checkmarkImage)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24)
                .foregroundColor(.init(red: 0, green: 163/255, blue: 42/255))

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.body)

                Text(feature.description)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

struct WooPlanFeatureBenefitsView_Previews: PreviewProvider {
    static let featureGroup: WooPlanFeatureGroup = WooPlan()!.planFeatureGroups[0]
    static var previews: some View {
        WooPlanFeatureBenefitsView(wooPlanFeatureGroup: featureGroup)
    }
}
