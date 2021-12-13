import SwiftUI

struct BottomButtonView<Style>: View where Style: ButtonStyle {
    let style: Style
    let title: String
    let image: UIImage?
    let onButtonTapped: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: { onButtonTapped() }) {
                HStack {
                    if let image = image {
                        Image(uiImage: image)
                    }
                    Text(title)
                    Spacer()
                }
            }
            .buttonStyle(style)
        }
    }
}

struct BottomButtonView_Previews: PreviewProvider {
    static var previews: some View {
        BottomButtonView(style: LinkButtonStyle(),
                         title: "Bottom Button",
                         image: .plusImage,
                         onButtonTapped: {})
            .previewLayout(.sizeThatFits)

        BottomButtonView(style: LinkButtonStyle(),
                         title: "Bottom Button",
                         image: .plusImage,
                         onButtonTapped: {})
            .previewLayout(.sizeThatFits)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewDisplayName("Large font")

        BottomButtonView(style: LinkButtonStyle(),
                         title: "Bottom Button",
                         image: .plusImage,
                         onButtonTapped: {})
            .previewLayout(.sizeThatFits)
            .environment(\.layoutDirection, .rightToLeft)
            .previewDisplayName("Right to left")
    }
}
