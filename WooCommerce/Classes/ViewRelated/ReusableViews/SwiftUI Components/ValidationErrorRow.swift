import SwiftUI

/// Renders a row for validation error with error message in red.
///
struct ValidationErrorRow: View {
    private let errorMessage: String
    private let minHeight: CGFloat
    private let horizontalPadding: CGFloat

    init(errorMessage: String,
         minHeight: CGFloat = Constants.rowHeight,
         horizontalPadding: CGFloat = Constants.horizontalSpacing) {
        self.errorMessage = errorMessage
        self.minHeight = minHeight
        self.horizontalPadding = horizontalPadding
    }

    var body: some View {
        Text(errorMessage)
            .errorStyle()
            .padding(.vertical, Constants.verticalSpacing)
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: .infinity, minHeight: Constants.rowHeight, alignment: .leading)
    }
}

private extension ValidationErrorRow {
    enum Constants {
        static let rowHeight: CGFloat = 44
        static let horizontalSpacing: CGFloat = 16
        static let verticalSpacing: CGFloat = 8
    }
}

struct ValidationErrorRow_Previews: PreviewProvider {
    static var previews: some View {
        ValidationErrorRow(errorMessage: "Description is required")
    }
}
