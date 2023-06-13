import SwiftUI

/// Hosting controller for `ProductDescriptionGenerationCelebrationView`.
///
final class ProductDescriptionGenerationCelebrationHostingController: UIHostingController<ProductDescriptionGenerationCelebrationView> {
    init(viewModel: ProductDescriptionGenerationCelebrationViewModel) {
        super.init(rootView: ProductDescriptionGenerationCelebrationView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Celebration view presented when AI generation is used for the first time
struct ProductDescriptionGenerationCelebrationView: View {
    private var viewModel: ProductDescriptionGenerationCelebrationViewModel

    init(viewModel: ProductDescriptionGenerationCelebrationViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: Constants.verticalSpacing) {
            Image(uiImage: viewModel.celebrationImage)

            Text(viewModel.greatStartLabel)
                .headlineStyle()
                .multilineTextAlignment(.center)

            Text(viewModel.instructionsLabel)
                .foregroundColor(Color(.text))
                .subheadlineStyle()
                .multilineTextAlignment(.center)

            Button(viewModel.gotItButtonTitle) {
                viewModel.didTapGotIt()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, Constants.horizontalPadding)
    }
}

private extension ProductDescriptionGenerationCelebrationView {
    enum Constants {
        static let verticalSpacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 16
    }
}

struct ProductDescriptionGenerationCelebrationView_Previews: PreviewProvider {
    static var previews: some View {
        ProductDescriptionGenerationCelebrationView(viewModel: .init(onTappingGotIt: {}))
    }
}
