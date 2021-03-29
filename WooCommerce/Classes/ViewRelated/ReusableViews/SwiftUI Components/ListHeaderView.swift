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
                Text("Header")
                    .font(.footnote)
                    .accentColor(Color(.listIcon))
                if alignment == .left {
                    Spacer()
                }
            }.frame(minWidth: 0, maxWidth: .infinity)
        }
        .padding([.leading, .trailing], 16)
        .frame(height: 42)
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
    }
}
