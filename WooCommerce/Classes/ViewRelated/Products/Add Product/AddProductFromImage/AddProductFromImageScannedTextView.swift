import SwiftUI

/// Selectable and editable scanned text for generating product details in the "add product from image" flow in `AddProductFromImageView`.
struct AddProductFromImageScannedTextView: View {
    @ObservedObject private var viewModel: AddProductFromImageViewModel.ScannedTextViewModel

    init(viewModel: AddProductFromImageViewModel.ScannedTextViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack(spacing: Layout.horizontalPadding) {
            TextField("", text: $viewModel.text)
                .font(.body)
            Spacer()
            Button(action: {
                viewModel.isSelected.toggle()
            }) {
                Image(systemName: viewModel.isSelected ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(TextButtonStyle())
        }
        .padding(.vertical, Layout.verticalPadding)
    }
}

private extension AddProductFromImageScannedTextView {
    enum Layout {
        static let verticalPadding: CGFloat = 8
        static let horizontalPadding: CGFloat = 6
    }
}

struct AddProductFromImageScannedTextView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            AddProductFromImageScannedTextView(viewModel: .init(text: "Parmesan", isSelected: true))
            AddProductFromImageScannedTextView(viewModel: .init(text: "Looking for a healthy snack option that's both delicious and convenient?",
                                                                isSelected: false))
        }
    }
}
