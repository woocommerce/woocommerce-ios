import SwiftUI

/// Renders a row with a title with optional details and subtitle.
///
struct TitleAndSubtitleAndDetailRow: View {
    let title: String
    var detail: String? = nil
    let subtitle: String?
    let subtitlePlaceholder: String

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
                if let subtitle {
                    Text(subtitle)
                        .captionStyle()
                } else {
                    Text(subtitlePlaceholder)
                        .font(.caption)
                        .foregroundColor(Color(.textSubtle))
                }
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
        TitleAndSubtitleAndDetailRow(title: "Title", subtitle: "My subtitle", subtitlePlaceholder: "Subtitle placeholder")
            .previewLayout(.fixed(width: 375, height: 100))
        TitleAndSubtitleAndDetailRow(title: "Title",
                                     detail: "Detail",
                                     subtitle: nil,
                                     subtitlePlaceholder: "Subtitle placeholder")
            .previewLayout(.fixed(width: 375, height: 100))
    }
}
