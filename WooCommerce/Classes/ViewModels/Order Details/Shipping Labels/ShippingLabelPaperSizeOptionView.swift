import Networking
import SwiftUI

/// Displays a title and image for a shipping label paper size option (e.g. legal, label, letter).
struct ShippingLabelPaperSizeOptionView: View {
    private let title: String
    private let image: Image

    init(paperSize: ShippingLabelPaperSize) {
        switch paperSize {
        case .label:
            title = Localization.labelSizeTitle
            image = PaperSizeImage.label
        case .legal:
            title = Localization.legalSizeTitle
            image = PaperSizeImage.legal
        case .letter:
            title = Localization.letterSizeTitle
            image = PaperSizeImage.letter
        default:
            fatalError("Unexpected paper size: \(paperSize)")
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Spacer().frame(height: 25)
            Text(title)
                .fixedSize(horizontal: false, vertical: true)
            image
        }
    }
}

private extension ShippingLabelPaperSizeOptionView {
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

struct ShippingLabelPaperSizeOptionView_Previews: PreviewProvider {
    static var previews: some View {
        ShippingLabelPaperSizeOptionView(paperSize: .legal)
    }
}

#endif
