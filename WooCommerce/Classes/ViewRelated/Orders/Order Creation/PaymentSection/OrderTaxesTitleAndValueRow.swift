import SwiftUI

struct OrderTaxesTitleAndValueRow: View {
    let title: String
    let suffix: String
    let value: String

    var body: some View {
        HStack {
            AdaptiveStack(horizontalAlignment: .leading, spacing: Constants.horizontalSpacing) {
                Text(title)
                    .bodyStyle()

                Text(suffix)
                    .secondaryBodyStyle()

                Spacer()

                Text(value)
                    .bodyStyle()
                    .frame(width: nil, alignment: .trailing)
            }
        }
        .padding([.leading, .trailing], Constants.horizontalPadding)
        .padding([.top, .bottom], Constants.verticalPadding)
    }
}

extension OrderTaxesTitleAndValueRow {
    enum Constants {
        static let horizontalSpacing: CGFloat = 4
        static let verticalPadding: CGFloat = 4
        static let horizontalPadding: CGFloat = 16
    }
}
