import SwiftUI

/// Shown when the site doesn't have any top performers for a time range.
/// Contains a placeholder image and text.
struct TopPerformersEmptyView: View {
    var body: some View {
        VStack(alignment: .center, spacing: Layout.spacing) {
            Image(uiImage: .magnifyingGlassNotFoundGrey)
            Text(Localization.text)
                .subheadlineStyle()
        }
        .padding(Layout.padding)
    }
}

private extension TopPerformersEmptyView {
    enum Localization {
        static let text = NSLocalizedString(
            "No activity this period",
            comment: "Default text for Top Performers section when no data exists for a given period."
        )
    }

    enum Layout {
        static let spacing: CGFloat = 24
        static let padding: EdgeInsets = .init(top: 0, leading: 10, bottom: 10, trailing: 10)
    }
}

struct TopPerformersEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        TopPerformersEmptyView()
    }
}
