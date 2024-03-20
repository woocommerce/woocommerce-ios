import SwiftUI

/// Renders a row with a title with optional details and subtitle.
///
struct TitleAndSubtitleAndDetailRow: View {
    let title: String
    let detail: String?
    let subtitle: String?
    let subtitlePlaceholder: String

    var body: some View {
        HStack {
            VStack(alignment: .leading,
                   spacing: Constants.spacing) {
                HStack {
                    Text(title)
                        .font(.callout)
                        .foregroundColor(Color(.text))
                        .fontWeight(.medium)
                        .layoutPriority(1)
                    if let detail {
                        Group {
                            Text("•")
                            Text(detail)
                        }
                        .font(.callout)
                        .foregroundColor(Color(.textSubtle))
                        .lineLimit(1)
                    }
                }
                if let subtitle {
                    Text(subtitle)
                        .captionStyle()
                        .lineLimit(1)
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
        TitleAndSubtitleAndDetailRow(title: "Title",
                                     detail: "Detail",
                                     subtitle: "My subtitle",
                                     subtitlePlaceholder: "Subtitle placeholder")
        .previewDisplayName("All fields")

        TitleAndSubtitleAndDetailRow(title: "This is a long title with a lot of text",
                                     detail: "With some detail",
                                     subtitle: "And a really very long subtitle with quite a lot of text in it so we can see what happens",
                                     subtitlePlaceholder: "Subtitle placeholder")
        .previewDisplayName("Long strings")

        TitleAndSubtitleAndDetailRow(title: "Title",
                                     detail: nil,
                                     subtitle: nil,
                                     subtitlePlaceholder: "Subtitle placeholder")
        .previewDisplayName("Title only")
    }
}
