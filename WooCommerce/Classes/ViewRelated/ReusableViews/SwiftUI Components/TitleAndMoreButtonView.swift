import SwiftUI

struct TitleAndMoreButtonView: View {
    let title: String
    let moreButton: (() -> Void)?

    var body: some View {
        ZStack {
            HStack(alignment: .center, spacing: 0, content: {
                Text(title)
                    .font(Font.system(size: Constants.titleFontSize))
                    .foregroundColor(Color(.text))
                Spacer()
                Button(action: { moreButton!() }) {
                    Image(systemName: "ellipsis.circle")
                }
                .accentColor(Color(.text))
            })
            .padding(EdgeInsets(top: Constants.contentInsetTop,
                                leading: Constants.contentInsetLeading,
                                bottom: Constants.contentInsetBottom,
                                trailing: Constants.contentInsetTrailing))
        }
        .background(Color(.listForeground))
    }
}

struct TitleAndMoreButtonView_Previews: PreviewProvider {
    static var previews: some View {
        TitleAndMoreButtonView(title: "Title", moreButton: {})
            .preferredColorScheme(.light)
            .previewLayout(.fixed(width: 375, height: 50))
        TitleAndMoreButtonView(title: "Title", moreButton: {})
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 375, height: 50))
    }
}

extension TitleAndMoreButtonView {
    private enum Constants {
        static let titleFontSize: CGFloat = 13
        static let contentInsetTop: CGFloat = 16
        static let contentInsetLeading: CGFloat = 16
        static let contentInsetBottom: CGFloat = 7
        static let contentInsetTrailing: CGFloat = 16
    }
}
