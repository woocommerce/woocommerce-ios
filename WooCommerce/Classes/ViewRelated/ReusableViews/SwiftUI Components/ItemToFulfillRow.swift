import SwiftUI

/// Represent a row of a Product Item that should be fulfilled
///
struct ItemToFulfillRow: View, Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            VStack(alignment: .leading,
                   spacing: 8) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(Color(.textSubtle))
            }.padding([.leading, .trailing], Constants.vStackPadding)
            Spacer()
        }
        .padding([.top, .bottom], Constants.hStackPadding)
        .frame(minHeight: Constants.height)
    }
}

private extension ItemToFulfillRow {
    enum Constants {
        static let vStackPadding: CGFloat = 16
        static let hStackPadding: CGFloat = 10
        static let height: CGFloat = 64
    }
}

struct ItemToFulfillRow_Previews: PreviewProvider {
    static var previews: some View {
        ItemToFulfillRow(title: "Title", subtitle: "My subtitle")
            .previewLayout(.fixed(width: 375, height: 100))
    }
}
