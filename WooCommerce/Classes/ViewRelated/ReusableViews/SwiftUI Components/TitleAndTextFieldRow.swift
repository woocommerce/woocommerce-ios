import SwiftUI

struct TitleAndTextFieldRow: View {
    let title: String
    let placeholder: String
    @State var text: String = ""
    let symbol: String?
    let keyboardType: UIKeyboardType

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .lineLimit(1)
                .fixedSize()
            Spacer()
            TextField(placeholder, text: $text)
                .multilineTextAlignment(.trailing)
                .font(.body)
                .keyboardType(keyboardType)
            if let symbol = symbol {
                Text(symbol).font(.body)
            }
        }
        .frame(height: 44)
        .padding([.leading, .trailing], 16)
    }
}

struct TitleAndTextFieldRow_Previews: PreviewProvider {
    static var previews: some View {
        TitleAndTextFieldRow(title: "Add your text",
                             placeholder: "Start typing",
                             text: "",
                             symbol: nil,
                             keyboardType: .default)
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("No text")

        TitleAndTextFieldRow(title: "Add your text",
                             placeholder: "Start typing",
                             text: "Hello",
                             symbol: nil,
                             keyboardType: .default)
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("With text")

        TitleAndTextFieldRow(title: "Total package weight",
                             placeholder: "Value",
                             text: "",
                             symbol: "oz",
                             keyboardType: .default)
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("With symbol")
    }
}
