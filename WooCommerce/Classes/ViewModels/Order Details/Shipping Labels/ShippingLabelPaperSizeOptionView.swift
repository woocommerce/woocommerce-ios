import SwiftUI

/// Displays a title and image for a shipping label paper size option (e.g. legal, label, letter).
struct ShippingLabelPaperSizeOptionView: View {
    struct ViewModel {
        let title: String
        let image: Image
    }

    private let viewModel: ViewModel

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading) {
            Spacer().frame(height: 25)
            Text(viewModel.title)
            viewModel.image
        }
    }
}

// MARK: - Previews

#if DEBUG

struct ShippingLabelPaperSizeOptionView_Previews: PreviewProvider {
    static var previews: some View {
        ShippingLabelPaperSizeOptionView(viewModel: .init(title: "Legal paper size", image: Image("shipping-label-paper-size-legal")))
    }
}

#endif
