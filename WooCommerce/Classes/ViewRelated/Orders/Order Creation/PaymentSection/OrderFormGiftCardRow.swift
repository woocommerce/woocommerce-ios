import SwiftUI

/// Gift card entered by the user in the order form.
struct OrderFormGiftCardRow: View {
    let code: String

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: Constants.horizontalSpacing) {
                Text(Localization.giftCard)
                    .foregroundColor(.init(uiColor: .accent))
                    .bodyStyle()
                Image(systemName: "pencil")
            }
            .foregroundColor(.init(uiColor: .accent))

            Text(code)
                .footnoteStyle()
        }
    }
}

private extension OrderFormGiftCardRow {
    enum Localization {
        static let giftCard = NSLocalizedString("Gift Card", comment: "Label for the the row showing the gift card to apply to the order")
    }

    enum Constants {
        static let horizontalSpacing: CGFloat = 4
    }
}

struct OrderFormGiftCardRow_Previews: PreviewProvider {
    static var previews: some View {
        OrderFormGiftCardRow(code: "UU35-T3RE-BSWK-36J4")
    }
}
