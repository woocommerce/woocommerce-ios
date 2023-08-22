import SwiftUI

struct TitleSubtitleAndValuesRow: View {
    let title: String
    let titleValue: String

    let subtitle: String
    let subtitleValue: String

    var body: some View {
        VStack(alignment: .leading,
               spacing: 8) {
            AdaptiveStack(horizontalAlignment: .leading, spacing: Constants.spacing) {
                Text(title)
                    .bodyStyle()
                    .multilineTextAlignment(.leading)
                    .modifier(MaxWidthModifier())
                    .frame(width: nil, alignment: .leading)

                Text(titleValue)
                    .bodyStyle()
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.vertical, Constants.verticalPadding)
            }

            AdaptiveStack(horizontalAlignment: .leading, spacing: Constants.spacing) {
                Text(subtitle)
                    .footnoteStyle()
                    .multilineTextAlignment(.leading)
                    .modifier(MaxWidthModifier())
                    .frame(width: nil, alignment: .leading)

                Text(subtitleValue)
                    .footnoteStyle()
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.vertical, Constants.verticalPadding)
            }
        }.padding([.leading, .trailing], 16)
    }
}

extension TitleSubtitleAndValuesRow {
    enum Constants {
        static let spacing: CGFloat = 20
        static let verticalPadding: CGFloat = 4
    }
}
