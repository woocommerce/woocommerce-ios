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
    private let viewModel: ProductDescriptionGenerationCelebrationViewModel

    init(viewModel: ProductDescriptionGenerationCelebrationViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: Layout.verticalSpacing) {
            Image(uiImage: viewModel.celebrationImage)

            Group {
                Text(viewModel.greatStartLabel)
                    .headlineStyle()
                    .multilineTextAlignment(.center)

                Text(viewModel.instructionsLabel)
                    .foregroundColor(Color(.text))
                    .subheadlineStyle()
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Layout.textHorizontalPadding)

            Button(viewModel.gotItButtonTitle) {
                viewModel.didTapGotIt()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Layout.buttonHorizontalPadding)
        }
        .padding(insets: Layout.insets)
    }
}

private extension ProductDescriptionGenerationCelebrationView {
    enum Layout {
        static let verticalSpacing: CGFloat = 16
        static let textHorizontalPadding: CGFloat = 24
        static let buttonHorizontalPadding: CGFloat = 16
        static let insets: EdgeInsets = .init(top: 40, leading: 0, bottom: 16, trailing: 0)
    }
}

struct ProductDescriptionGenerationCelebrationView_Previews: PreviewProvider {
    static var previews: some View {
        ProductDescriptionGenerationCelebrationView(viewModel: .init(onTappingGotIt: {}))

        ProductDescriptionGenerationCelebrationView(viewModel: .init(onTappingGotIt: {}))
            .preferredColorScheme(.dark)
    }
}
