import SwiftUI

struct TitleAndValueRow: View {
    let title: String
    let value: String
    let selectable: Bool
    var action: () -> Void

    var body: some View {
        HStack {
            Text(title).font(.body)
            Spacer()
            Text(value).font(.footnote).foregroundColor(Color(.textSubtle))

            if selectable {
                Image(uiImage: .chevronImage)
                    .frame(width: 22.0, height: 22.0)
                    .foregroundColor(Color(UIColor.gray(.shade30)))
            }
        }
        .onTapGesture {
            guard selectable else {
                return
            }
            action()
         }
        .frame(height: 44)
        .padding([.leading, .trailing], 16)
    }
}

struct TitleAndValueRow_Previews: PreviewProvider {
    static var previews: some View {
        TitleAndValueRow(title: "Package selected", value: "Small package 1", selectable: true, action: {
        })
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("Row Selectable")

        TitleAndValueRow(title: "Package selected", value: "Small package 2", selectable: false, action: {
        })
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("Row Not Selectable")
    }
}
