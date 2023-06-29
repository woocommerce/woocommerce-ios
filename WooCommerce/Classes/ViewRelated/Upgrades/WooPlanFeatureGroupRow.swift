import SwiftUI
import Yosemite

struct WooPlanFeatureGroupRow: View {
    let featureGroup: WooPlanFeatureGroup

    var body: some View {
        HStack {
            // Feature group image
            RoundedRectangle(cornerRadius: 6)
                .fill(featureGroup.imageCardColor)
                .frame(width: 46, height: 46)
                .overlay(
                    Image(featureGroup.imageFilename)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(featureGroup.title)
                    .font(.headline)

                Text(featureGroup.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct WooPlanFeatureGroupRow_Previews: PreviewProvider {
    static let featureGroup = WooPlanFeatureGroup(title: "Test general features",
                                                  description: "Everything you need to grow your business.",
                                                  imageFilename: "express-plans-homepage",
                                                  imageCardColor: Color(red: 240/255, green: 246/255, blue: 252/255, opacity: 1),
                                                  features: [])
    static var previews: some View {
        WooPlanFeatureGroupRow(featureGroup: featureGroup)
    }
}
