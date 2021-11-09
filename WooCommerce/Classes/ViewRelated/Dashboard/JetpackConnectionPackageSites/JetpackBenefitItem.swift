import SwiftUI

/// Displays a Jetpack benefit with icon, title, and subtitle.
struct JetpackBenefitItem: View {
    let title: String
    let subtitle: String
    let icon: UIImage

    var body: some View {
        HStack(spacing: Layout.horizontalSpacing) {
            Circle()
                .frame(width: Layout.circleDimension, height: Layout.circleDimension, alignment: .center)
                .foregroundColor(Color(.gray(.shade0)))
                .overlay(
                    Image(uiImage: icon)
                        .resizable()
                        .frame(width: Layout.iconDimension, height: Layout.iconDimension, alignment: .center)
                )
            VStack(alignment: .leading) {
                Text(title).headlineStyle()
                Spacer().frame(height: Layout.verticalTextSpacing)
                Text(subtitle).subheadlineStyle()
            }
            Spacer()
        }
    }
}

private extension JetpackBenefitItem {
    enum Layout {
        static let circleDimension = CGFloat(40)
        static let iconDimension = CGFloat(20)
        static let horizontalSpacing = CGFloat(16)
        static let verticalTextSpacing = CGFloat(2)
    }
}

struct JetpackBenefitRow_Previews: PreviewProvider {
    static var previews: some View {
        JetpackBenefitItem(title: "Push Notifications with a longer title",
                           subtitle: "Get push notifications for new orders, reviews, etc. delivered to your device.",
                           icon: .cameraImage)
            .environment(\.sizeCategory, .extraExtraExtraLarge)
            .previewLayout(.sizeThatFits)
        JetpackBenefitItem(title: "Short",
                           subtitle: "Short subtitle.",
                           icon: .cameraImage)
            .previewLayout(.sizeThatFits)
    }
}
