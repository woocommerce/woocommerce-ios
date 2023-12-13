import SwiftUI
import Kingfisher

/// View for picking themes in the store creation flow.
struct ProfilerThemesPickerView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    private let carouselViewModel: ThemesCarouselViewModel

    init(carouselViewModel: ThemesCarouselViewModel) {
        self.carouselViewModel = carouselViewModel
    }

    var body: some View {

        ScrollView {
            VStack(alignment: .leading) {
                Text(Localization.chooseThemeHeading)
                    .bold()
                    .largeTitleStyle()
                    .padding(.horizontal, Layout.contentPadding)
                    .padding(.top, Layout.contentVerticalSpacing)
                    .padding(.bottom, Layout.contentPadding)

                Text(Localization.chooseThemeSubtitle)
                    .subheadlineStyle()
                    .padding(.horizontal, Layout.contentPadding)

                Spacer()

                ThemesCarouselView(viewModel: carouselViewModel)

                Spacer()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(Localization.skipButtonTitle) {
                    // TODO: Setup toolbar.
                }
            }
        }
        // Disables large title to avoid a large gap below the navigation bar.
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfilerThemesPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilerThemesPickerView(carouselViewModel: .init(mode: .storeCreationProfiler))
    }
}

private extension ProfilerThemesPickerView {
    private enum Layout {
        static let contentPadding: CGFloat = 16
        static let contentVerticalSpacing: CGFloat = 40
    }

    private enum Localization {
        static let skipButtonTitle = NSLocalizedString(
            "themesPickerView.skipButtonTitle",
            value: "Skip",
            comment: "Title of the button to skip theme carousel screen."
        )

        static let chooseThemeHeading = NSLocalizedString(
            "themesPickerView.chooseThemeHeading",
            value: "Choose a theme",
            comment: "Main heading on the theme carousel screen."
        )

        static let chooseThemeSubtitle = NSLocalizedString(
            "themesPickerView.chooseThemeSubtitle",
            value: "You can always change it later in the settings.",
            comment: "Subtitle on the theme carousel screen."
        )
    }
}
