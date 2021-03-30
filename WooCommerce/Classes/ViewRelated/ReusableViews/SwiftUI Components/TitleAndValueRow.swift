import SwiftUI

/// Renders a row with a label on the left side, a value on the right side and a disclosure indicator if selectable
///
struct TitleAndValueRow: View {
    let title: String
    let value: String
    let selectable: Bool
    var action: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(Color(.textSubtle))

            if selectable {
                Image(uiImage: .chevronImage)
                    .frame(width: Constants.imageSize, height: Constants.imageSize)
                    .foregroundColor(Color(UIColor.gray(.shade30)))
            }
        }
        .onTapGesture {
            guard selectable else {
                return
            }
            action()
         }
        .frame(height: Constants.height)
        .padding([.leading, .trailing], Constants.padding)
    }
}

private extension TitleAndValueRow {
    enum Constants {
        static let imageSize: CGFloat = 22
        static let height: CGFloat = 44
        static let padding: CGFloat = 16
    }
}

struct TitleAndValueRow_Previews: PreviewProvider {
    static var previews: some View {
        TitleAndValueRow(title: "Package selected", value: "Small package 1", selectable: true, action: { })
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("Row Selectable")

        TitleAndValueRow(title: "Package selected", value: "Small package 2", selectable: false, action: { })
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("Row Not Selectable")
    }
}
