import SwiftUI

/// Renders a row with a title with optional details and subtitle.
///
struct TitleAndSubtitleAndDetailRow: View {
    let title: String
    var detail: String? = nil
    let subtitle: String

    var body: some View {
        HStack {
            VStack(alignment: .leading,
                   spacing: Constants.spacing) {
                HStack {
                    Text(title)
                        .font(.callout)
                        .fontWeight(.medium)
                    if let detail {
                        Group {
                            Text("•")
                            Text(detail)
                        }
                        .font(.callout)
                        .foregroundColor(Color(.textSubtle))
                    }
                }
                Text(subtitle)
                    .captionStyle()
            }
            Spacer()
        }
    }
}

private extension TitleAndSubtitleAndDetailRow {
    enum Constants {
        static let spacing: CGFloat = 8
    }
}

struct TitleAndSubtitleAndDetailRow_Previews: PreviewProvider {
    static var previews: some View {
        TitleAndSubtitleAndDetailRow(title: "Title", subtitle: "My subtitle")
            .previewLayout(.fixed(width: 375, height: 100))
        TitleAndSubtitleAndDetailRow(title: "Title", detail: "Detail", subtitle: "My subtitle")
            .previewLayout(.fixed(width: 375, height: 100))
    }
}
