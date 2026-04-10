import SwiftUI

/// A reusable page indicator view showing dots for each page.
///
struct PageIndicatorView: View {
    /// The index of the currently selected page (0-indexed).
    let currentPage: Int

    /// The total number of pages.
    let totalPages: Int

    var body: some View {
        HStack(spacing: Layout.dotSpacing) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color(.accent) : Color(.systemGray4))
                    .frame(width: Layout.dotSize, height: Layout.dotSize)
            }
        }
    }
}

// MARK: - Layout Constants

private enum Layout {
    static let dotSize: CGFloat = 8
    static let dotSpacing: CGFloat = 8
}

// MARK: - Previews

#Preview {
    VStack(spacing: 20) {
        PageIndicatorView(currentPage: 0, totalPages: 5)
        PageIndicatorView(currentPage: 2, totalPages: 5)
        PageIndicatorView(currentPage: 4, totalPages: 5)
    }
}
