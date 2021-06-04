import SwiftUI

struct SelectableItemRow: View {
    let id = UUID()
    let title: String
    let subtitle: String
    let selected: Bool
    @Environment(\.isEnabled) var isEnabled

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                if selected, isEnabled {
                    Image(uiImage: .checkmarkStyledImage).frame(width: Constants.imageSize, height: Constants.imageSize)
                }
            }.frame(width: Constants.zStackWidth)
            VStack(alignment: .leading,
                   spacing: 8) {
                Text(title)
                    .bodyStyle(isEnabled)
                Text(subtitle)
                    .footnoteStyle(isEnabled)
            }.padding([.trailing], Constants.vStackPadding)
            Spacer()
        }
        .padding([.top, .bottom], Constants.hStackPadding)
        .frame(minHeight: Constants.height)
        .contentShape(Rectangle())
    }
}

private extension SelectableItemRow {
    enum Constants {
        static let zStackWidth: CGFloat = 48
        static let vStackPadding: CGFloat = 16
        static let hStackPadding: CGFloat = 10
        static let height: CGFloat = 60
        static let imageSize: CGFloat = 22
    }
}

struct SelectableItemRow_Previews: PreviewProvider {
    static var previews: some View {
        SelectableItemRow(title: "Title", subtitle: "My subtitle", selected: true)
            .previewLayout(.fixed(width: 375, height: 100))

        SelectableItemRow(title: "Title", subtitle: "My subtitle", selected: false)
            .previewLayout(.fixed(width: 375, height: 100))

        SelectableItemRow(title: "Title", subtitle: "My subtitle", selected: true)
            .disabled(true)
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("Disabled state")
    }
}
