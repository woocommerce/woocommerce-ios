import SwiftUI

/// Hosting controller for `ProductCreationAISurveyConfirmationView`.
///
final class ProductCreationAISurveyConfirmationHostingController: UIHostingController<ProductCreationAISurveyConfirmationView> {
    init(viewModel: ProductCreationAISurveyConfirmationViewModel) {
        super.init(rootView: ProductCreationAISurveyConfirmationView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Celebration view presented when AI generation is used for the first time
struct ProductCreationAISurveyConfirmationView: View {
    private let viewModel: ProductCreationAISurveyConfirmationViewModel

    init(viewModel: ProductCreationAISurveyConfirmationViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.verticalSpacing) {
                Image(uiImage: UIImage.productCreationAISurveyImage)

                Group {
                    Text(Localization.title)
                        .headlineStyle()
                        .multilineTextAlignment(.center)

                    Text(Localization.description)
                        .foregroundColor(Color(.text))
                        .subheadlineStyle()
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Layout.textHorizontalPadding)

                Button(Localization.startTheSurvey) {
                    viewModel.didTapStartTheSurvey()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Layout.buttonHorizontalPadding)

                Button(viewModel.skipButtonTitle) {
                    viewModel.didTapSkip()
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal, Layout.buttonHorizontalPadding)
            }
            .padding(insets: Layout.insets)
        }
    }
}

private extension ProductCreationAISurveyConfirmationView {
    enum Layout {
        static let verticalSpacing: CGFloat = 16
        static let textHorizontalPadding: CGFloat = 24
        static let buttonHorizontalPadding: CGFloat = 16
        static let insets: EdgeInsets = .init(top: 40, leading: 0, bottom: 16, trailing: 0)
    }

    enum Localization {
        static let title = NSLocalizedString("productCreationAISurveyConfirmationView.title",
                                             value: "We value your input!",
                                             comment: "Title in Product Creation AI survey confirmation view.")

        static let description = NSLocalizedString("productCreationAISurveyConfirmationView.description",
                                                   value: "Got a minute? Help us improve our AI-assisted features with your quick feedback.",
                                                   comment: "Description in Product Creation AI survey confirmation view.")

        static let startTheSurvey = NSLocalizedString("productCreationAISurveyConfirmationView.startTheSurvey",
                                                      value: "Start the Survey",
                                                      comment: "Start Survey button title in Product Creation AI survey confirmation view.")
    }
}

struct ProductCreationAISurveyConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        ProductCreationAISurveyConfirmationView(viewModel: .init(onStart: {}, onSkip: {}))

        ProductCreationAISurveyConfirmationView(viewModel: .init(onStart: {}, onSkip: {}))
            .preferredColorScheme(.dark)
    }
}
