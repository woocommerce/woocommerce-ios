import SwiftUI

/// Renders a row with a title and subtitle.
///
struct TitleAndSubtitleRow: View {
    let title: String
    let subtitle: String
    var isError: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading,
                   spacing: 8) {
                Text(title)
                    .bodyStyle()
                Text(subtitle)
                    .footnoteStyle(isError: isError)
            }.padding([.leading, .trailing], Constants.vStackPadding)
            Spacer()
        }
        .padding([.top, .bottom], Constants.hStackPadding)
        .frame(minHeight: Constants.height)
    }
}

private extension TitleAndSubtitleRow {
    enum Constants {
        static let vStackPadding: CGFloat = 16
        static let hStackPadding: CGFloat = 10
        static let height: CGFloat = 64
    }
}

struct TitleAndSubtitleRow_Previews: PreviewProvider {
    static var previews: some View {
        TitleAndSubtitleRow(title: "Title", subtitle: "My subtitle")
            .previewLayout(.fixed(width: 375, height: 100))
    }
}
