import SwiftUI

/// Renders a row for validation error with error message in red.
///
struct ValidationErrorRow: View {
    let errorMessage: String

    var body: some View {
        Text(errorMessage)
            .errorStyle()
            .padding(.vertical, Constants.verticalSpacing)
            .padding(.horizontal, Constants.horizontalSpacing)
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
