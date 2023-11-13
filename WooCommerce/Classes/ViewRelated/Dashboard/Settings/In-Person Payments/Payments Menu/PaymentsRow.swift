import SwiftUI

struct PaymentsRow: View {
    let image: Image
    let title: String

    var body: some View {
        HStack {
            image
            Text(title)
        }
    }
}

struct PaymentsRow_Previews: PreviewProvider {
    static var previews: some View {
        PaymentsRow(image: Image(uiImage: .creditCardIcon),
                    title: "Payments Row")
        .previewLayout(.sizeThatFits)
    }
}
