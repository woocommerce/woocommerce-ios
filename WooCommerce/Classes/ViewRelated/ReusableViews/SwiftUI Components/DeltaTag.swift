import SwiftUI

/// Reusable tag view.
/// Useful to indicate growth rates.
///
struct DeltaTag: View {

    /// Value to display. Needs to be already formatted
    ///
    let value: String

    /// Tag color.
    ///
    let backgroundColor: UIColor

    var body: some View {
        Text(value)
            .padding(Layout.backgroundPadding)
            .foregroundColor(Color(.textInverted))
            .captionStyle()
            .background(Color(backgroundColor))
            .cornerRadius(Layout.cornerRadius)
    }
}

// MARK: Constants
private extension DeltaTag {
    enum Layout {
        static let backgroundPadding = EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8)
        static let cornerRadius: CGFloat = 4.0
    }
}

// MARK: Peviews
struct DeltaTagPreviews: PreviewProvider {
    static var previews: some View {
        VStack {
            DeltaTag(value: "+3.23%", backgroundColor: .systemGreen)

            DeltaTag(value: "-3.23%", backgroundColor: .systemRed)
        }
        .previewLayout(.sizeThatFits)
    }
}
