import SwiftUI

/// Renders a row for validation error with error message in red.
///
struct ValidationErrorRow: View {
    let errorMessage: String

    var body: some View {
        Text(errorMessage)
            .errorStyle()
            .padding(.horizontal, Constants.horizontalSpacing)
            .frame(minHeight: Constants.rowHeight)
    }
}

private extension ValidationErrorRow {
    enum Constants {
        static let rowHeight: CGFloat = 44
        static let horizontalSpacing: CGFloat = 16
    }
}

struct ValidationErrorRow_Previews: PreviewProvider {
    static var previews: some View {
        ValidationErrorRow(errorMessage: "Description is required")
    }
}
