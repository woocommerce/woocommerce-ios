import SwiftUI
import Kingfisher
import struct Yosemite.WordPressTheme

/// View for picking themes in the store creation flow.
struct ProfilerThemesPickerView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    private let carouselViewModel: ThemesCarouselViewModel
    private let onSelectedTheme: (WordPressTheme) -> Void
    private let onSkip: () -> Void

    init(carouselViewModel: ThemesCarouselViewModel,
         onSelectedTheme: @escaping (WordPressTheme) -> Void,
         onSkip: @escaping () -> Void) {
        self.carouselViewModel = carouselViewModel
        self.onSelectedTheme = onSelectedTheme
        self.onSkip = onSkip
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

                ThemesCarouselView(viewModel: carouselViewModel, onSelectedTheme: onSelectedTheme)

                Spacer()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(Localization.skipButtonTitle, action: onSkip)
            }
        }
        // Disables large title to avoid a large gap below the navigation bar.
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            carouselViewModel.trackViewAppear()
        }
    }
}

struct ProfilerThemesPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilerThemesPickerView(carouselViewModel: .init(siteID: 123, mode: .storeCreationProfiler), onSelectedTheme: { _ in }, onSkip: {})
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
