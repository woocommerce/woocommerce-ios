import SwiftUI

/// Renders a Section Header/Footer with a label [Left / Center/Right].
///
struct ListHeaderView: View {
    @State var text: String
    @State var alignment: TextAlignment

    var body: some View {
        Section() {
            HStack() {
                if alignment == .right {
                    Spacer()
                }
                Text(text)
                    .font(.footnote)
                    .foregroundColor(Color(.listIcon))
                if alignment == .left {
                    Spacer()
                }
            }.frame(minWidth: 0, maxWidth: .infinity)
        }
        .padding([.leading, .trailing], Constants.lateralPadding)
        .padding(.top, Constants.topPadding)
        .padding(.bottom, Constants.bottomPadding)
        .frame(minHeight: Constants.height)
    }

    init(text: String, alignment: TextAlignment) {
        _text = State(initialValue: text)
        _alignment = State(initialValue: alignment)
    }

    enum TextAlignment {
        case left
        case center
        case right
    }
}

private extension ListHeaderView {
    enum Constants {
        static let lateralPadding: CGFloat = 16
        static let topPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 8
        static let height: CGFloat = 42
    }
}

struct ListHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ListHeaderView(text: "Section", alignment: .left)
            .previewLayout(.fixed(width: 275, height: 50))
            .previewDisplayName("Header left alignment")

        ListHeaderView(text: "Section", alignment: .center)
            .previewLayout(.fixed(width: 275, height: 50))
            .previewDisplayName("Header center alignment")

        ListHeaderView(text: "Section", alignment: .right)
            .previewLayout(.fixed(width: 275, height: 50))
            .previewDisplayName("Header right alignment")

        ListHeaderView(text: "Section with a super long text that needs to go on two or more lines.", alignment: .right)
            .previewLayout(.fixed(width: 275, height: 80))
            .previewDisplayName("Header right alignment")
    }
}
