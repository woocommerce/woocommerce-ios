import SwiftUI

struct FootnoteAndValueRow: View {
    let footnote: String
    let value: String

    var body: some View {
        HStack {
            AdaptiveStack(horizontalAlignment: .leading, spacing: Constants.horizontalSpacing) {
                Text(footnote)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(value)
                    .footnoteStyle()
                    .multilineTextAlignment(.trailing)
                    .frame(width: nil, alignment: .trailing)
            }
        }
        .padding([.leading, .trailing], Constants.horizontalPadding)
        .padding([.top, .bottom], Constants.verticalPadding)
    }
}

extension FootnoteAndValueRow {
    enum Constants {
        static let horizontalSpacing: CGFloat = 4
        static let verticalPadding: CGFloat = 4
        static let horizontalPadding: CGFloat = 16
    }
}
