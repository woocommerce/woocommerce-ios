import Networking
import SwiftUI

/// Displays a grid view of all available paper size options for printing a shipping label.
struct ShippingLabelPaperSizeOptionListView: View {
    private let paperSizeOptions: [ShippingLabelPaperSize]
    private let numberOfColumnsPerRow = 2
    private let numberOfRows: Int

    init(paperSizeOptions: [ShippingLabelPaperSize]) {
        self.paperSizeOptions = paperSizeOptions
        self.numberOfRows = Int(ceil(Double(paperSizeOptions.count) / Double(numberOfColumnsPerRow)))
    }

    var body: some View {
        ScrollView {
            GridStackView(rows: numberOfRows, columns: numberOfColumnsPerRow) { row, col in
                let index = row * numberOfColumnsPerRow + col
                if let paperSize = paperSizeOptions[safe: index] {
                    ShippingLabelPaperSizeOptionView(paperSize: paperSize)
                        .frame(maxWidth: .infinity)
                } else {
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
            }
        }.background(Color(UIColor.basicBackground))
    }
}

// MARK: - Previews

#if DEBUG

struct ShippingLabelPaperSizeOptionListView_Previews: PreviewProvider {
    private static let paperSizeOptions: [ShippingLabelPaperSize] = [.legal, .letter, .letter]
    static var previews: some View {
        ShippingLabelPaperSizeOptionListView(paperSizeOptions: paperSizeOptions)
            .environment(\.colorScheme, .light)
        ShippingLabelPaperSizeOptionListView(paperSizeOptions: paperSizeOptions)
            .environment(\.colorScheme, .dark)
        ShippingLabelPaperSizeOptionListView(paperSizeOptions: paperSizeOptions)
            .previewLayout(.fixed(width: 1024, height: 768))
        ShippingLabelPaperSizeOptionListView(paperSizeOptions: [.legal, .letter])
            .environment(\.colorScheme, .dark)
        ShippingLabelPaperSizeOptionListView(paperSizeOptions: [.label])
        ShippingLabelPaperSizeOptionListView(paperSizeOptions: [])
    }
}

#endif
