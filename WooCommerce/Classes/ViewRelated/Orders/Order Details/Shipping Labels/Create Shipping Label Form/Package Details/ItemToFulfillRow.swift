import SwiftUI

/// Represent a row of a Product Item that should be fulfilled
///
struct ItemToFulfillRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            VStack(alignment: .leading,
                   spacing: 8) {
                Text(title).font(.body)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(Color(.textSubtle))
            }.padding([.leading, .trailing], 16)
            Spacer()
        }.padding([.top, .bottom], 10)
        .frame(minHeight: 64)
    }
}

struct ItemToFulfillRow_Previews: PreviewProvider {
    static var previews: some View {
        ItemToFulfillRow(title: "Title", subtitle: "My subtitle")
            .previewLayout(.fixed(width: 375, height: 100))
    }
}
