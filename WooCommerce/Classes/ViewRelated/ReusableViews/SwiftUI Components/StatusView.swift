import SwiftUI

/// A view to display a status label accompanied with a background color
///
struct StatusView: View {
    /// The label on the status view
    private let label: String

    /// The background color of the view
    private let backgroundColor: UIColor

    init(label: String, backgroundColor: UIColor) {
        self.label = label
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        Text(label)
            .font(.caption)
            .padding(.vertical, Constants.verticalMargin)
            .padding(.horizontal, Constants.horizontalMargin)
            .background(Color(backgroundColor))
            .cornerRadius(Constants.cornerRadius)
    }
}

private extension StatusView {
    enum Constants {
        static let horizontalMargin: CGFloat = 8
        static let verticalMargin: CGFloat = 4
        static let cornerRadius: CGFloat = 4
    }
}

struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        StatusView(label: "Active", backgroundColor: .withColorStudio(.celadon, shade: .shade5))
    }
}
