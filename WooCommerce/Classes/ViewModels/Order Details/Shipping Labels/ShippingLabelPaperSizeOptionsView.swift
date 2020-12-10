import SwiftUI

/// Displays a grid view of all available paper size options for printing a shipping label.
struct ShippingLabelPaperSizeOptionsView: View {
    var body: some View {
        ScrollView {
            GridStack(rows: 2, columns: 2) { row, col in
                switch (row, col) {
                case (0, 0):
                    ShippingLabelPaperSizeOptionView(viewModel: .init(title: Localization.legalSizeTitle,
                                                                      image: PaperSizeImage.legal))
                        .frame(maxWidth: .infinity)
                case (0, 1):
                    ShippingLabelPaperSizeOptionView(viewModel: .init(title: Localization.letterSizeTitle,
                                                                      image: PaperSizeImage.letter))
                        .frame(maxWidth: .infinity)
                case (1, 0):
                    ShippingLabelPaperSizeOptionView(viewModel: .init(title: Localization.labelSizeTitle,
                                                                      image: PaperSizeImage.label))
                        .frame(maxWidth: .infinity)
                default:
                    Spacer()
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
            }
        }.background(Color(UIColor.basicBackground))
    }
}

private extension ShippingLabelPaperSizeOptionsView {
    enum Localization {
        static let labelSizeTitle = NSLocalizedString("Label (4 x 6 in)", comment: "Title of label paper size option for printing a shipping label")
        static let legalSizeTitle = NSLocalizedString("Legal (8.5 x 14 in)", comment: "Title of legal paper size option for printing a shipping label")
        static let letterSizeTitle = NSLocalizedString("Letter (8.5 x 11 in)", comment: "Title of letter paper size option for printing a shipping label")
    }

    enum PaperSizeImage {
        static let label = Image("shipping-label-paper-size-label")
        static let legal = Image("shipping-label-paper-size-legal")
        static let letter = Image("shipping-label-paper-size-letter")
    }
}

// MARK: - Previews

#if DEBUG

struct ShippingLabelPaperSizeOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        ShippingLabelPaperSizeOptionsView()
            .environment(\.colorScheme, .light)
        ShippingLabelPaperSizeOptionsView()
            .environment(\.colorScheme, .dark)
        ShippingLabelPaperSizeOptionsView()
            .previewLayout(.fixed(width: 1024, height: 768))
    }
}

#endif
