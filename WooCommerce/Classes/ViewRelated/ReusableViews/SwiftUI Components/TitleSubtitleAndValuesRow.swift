import SwiftUI

struct TitleSubtitleAndValuesRow: View {
    let title: String
    let titleValue: String

    let subtitle: String
    let subtitleValue: String

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
            AdaptiveStack(horizontalAlignment: .leading, spacing: Constants.horizontalSpacing) {
                Text(title)
                    .bodyStyle()
                    .multilineTextAlignment(.leading)
                    .modifier(MaxWidthModifier())
                    .frame(width: nil, alignment: .leading)

                Text(titleValue)
                    .bodyStyle()
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            AdaptiveStack(horizontalAlignment: .leading, spacing: Constants.horizontalSpacing) {
                Text(subtitle)
                    .footnoteStyle()
                    .multilineTextAlignment(.leading)
                    .modifier(MaxWidthModifier())
                    .frame(width: nil, alignment: .leading)

                Text(subtitleValue)
                    .footnoteStyle()
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }.padding(Constants.defaultPadding)
    }
}

extension TitleSubtitleAndValuesRow {
    enum Constants {
        static let horizontalSpacing: CGFloat = 20
        static let verticalSpacing: CGFloat = 4
        static let defaultPadding: CGFloat = 16
    }
}
