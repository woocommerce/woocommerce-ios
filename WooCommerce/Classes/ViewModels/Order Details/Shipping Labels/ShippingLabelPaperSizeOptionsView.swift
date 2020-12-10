import Networking
import SwiftUI

/// Displays a grid view of all available paper size options for printing a shipping label.
struct ShippingLabelPaperSizeOptionsView: View {
    private let paperSizeOptions: [ShippingLabelPaperSize]
    private let numberOfColumnsPerRow = 2
    private let numberOfRows: Int

    init(paperSizeOptions: [ShippingLabelPaperSize]) {
        self.paperSizeOptions = paperSizeOptions
        self.numberOfRows = Int(ceil(Double(paperSizeOptions.count) * 1.0 / Double(numberOfColumnsPerRow)))
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
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
            }
        }.background(Color(UIColor.basicBackground))
    }
}

// MARK: - Previews

#if DEBUG

struct ShippingLabelPaperSizeOptionsView_Previews: PreviewProvider {
    private static let paperSizeOptions: [ShippingLabelPaperSize] = [.legal, .letter, .letter]
    static var previews: some View {
        ShippingLabelPaperSizeOptionsView(paperSizeOptions: paperSizeOptions)
            .environment(\.colorScheme, .light)
        ShippingLabelPaperSizeOptionsView(paperSizeOptions: paperSizeOptions)
            .environment(\.colorScheme, .dark)
        ShippingLabelPaperSizeOptionsView(paperSizeOptions: paperSizeOptions)
            .previewLayout(.fixed(width: 1024, height: 768))
        ShippingLabelPaperSizeOptionsView(paperSizeOptions: [.legal, .letter])
            .environment(\.colorScheme, .dark)
        ShippingLabelPaperSizeOptionsView(paperSizeOptions: [.label])
        ShippingLabelPaperSizeOptionsView(paperSizeOptions: [])
    }
}

#endif
