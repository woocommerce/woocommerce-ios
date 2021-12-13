import SwiftUI

/// Displays a grid view where the caller generates a view for each coordinate.
struct GridStackView<Content: View>: View {
    private let rows: Int
    private let columns: Int
    private let spacingBetweenColumns: CGFloat
    private let content: (Int, Int) -> Content

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(0 ..< rows, id: \.self) { row in
                HStack(alignment: .top, spacing: spacingBetweenColumns) {
                    ForEach(0 ..< columns, id: \.self) { column in
                        content(row, column)
                    }
                }.frame(maxHeight: .infinity)
            }
        }
    }

    /// - Parameters:
    ///   - rows: Number of rows in the grid.
    ///   - columns: Number of columns in the grid.
    ///   - spacingBetweenColumns: Spacing between columns in the same row.
    ///   - content: Provides the view for a given coordinate `(row, column)`.
    init(rows: Int, columns: Int, spacingBetweenColumns: CGFloat = 0, @ViewBuilder content: @escaping (Int, Int) -> Content) {
        self.rows = rows
        self.columns = columns
        self.spacingBetweenColumns = spacingBetweenColumns
        self.content = content
    }
}

// MARK: - Previews

#if DEBUG

struct GridStackView_Previews: PreviewProvider {
    static var previews: some View {
        GridStackView(rows: 4, columns: 4) { row, col in
            Image(systemName: "\(row * 4 + col).circle")
            Text("Row \(row) Col \(col)")
        }
    }
}

#endif
