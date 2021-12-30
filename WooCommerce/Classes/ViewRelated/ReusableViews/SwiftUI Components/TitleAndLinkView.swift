import SwiftUI

struct TitleAndLinkView: View {
    let title: String
    let link: String

    var body: some View {
        Link(destination: URL(string: link)!) {
            VStack(alignment: .center, spacing: 0, content: {
                Divider()
                HStack(alignment: .center, spacing: 0, content: {
                    Text(title)
                        .font(Font.system(size: Constants.titleFontSize))
                        .frame(maxHeight: .infinity)
                        .foregroundColor(Color(.text))
                    Spacer()
                    Image(uiImage: .chevronImage)
                        .flipsForRightToLeftLayoutDirection(true)
                        .frame(width: Constants.imageSize, height: Constants.imageSize)
                        .foregroundColor(Color(.text.withAlphaComponent(Constants.chevronImageAlpha)))
                })
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.vertical, Constants.verticalPadding)
                Divider()
            })
            .background(Color(.listForeground))
            .frame(height: Constants.cellHeight)
        }
        .buttonStyle(PlainButtonStyle()) // Removes the fade hightlight.
    }
}

private extension TitleAndLinkView {
    enum Constants {
        static let imageSize: CGFloat = 22
        static let horizontalPadding: CGFloat = 15
        static let verticalPadding: CGFloat = 13
        static let titleFontSize: CGFloat = 17
        static let cellHeight: CGFloat = 44
        static let chevronImageAlpha: CGFloat = 0.6
    }
}

struct TitleAndLinkView_Previews: PreviewProvider {
    static var previews: some View {
        TitleAndLinkView(title: "Title", link: "")
            .preferredColorScheme(.light)
            .previewLayout(.fixed(width: 375, height: 44))
        TitleAndLinkView(title: "Title", link: "")
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 375, height: 44))
    }
}
