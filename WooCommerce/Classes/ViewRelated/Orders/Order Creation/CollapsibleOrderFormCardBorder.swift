import SwiftUI

/// Border of a collapsible card that is shown in the order form, like the product card.
struct CollapsibleOrderFormCardBorder: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: Layout.frameCornerRadius)
            .inset(by: 0.25)
            .stroke(color, lineWidth: Layout.borderLineWidth)
    }
}

private extension CollapsibleOrderFormCardBorder {
    enum Layout {
        static let frameCornerRadius: CGFloat = 4
        static let borderLineWidth: CGFloat = 1
    }
}

struct CollapsibleOrderFormCardBorder_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CollapsibleOrderFormCardBorder(color: .init(uiColor: .text))
            CollapsibleOrderFormCardBorder(color: .init(uiColor: .separator))
        }
        .padding()
    }
}
