import SwiftUI

struct ThemesPreviewView: View {
    var body: some View {

        NavigationView {
            VStack(spacing: 0) {
                WebView(
                    isPresented: .constant(true),
                    url: URL(string: "https://woo.com")!
                )

                Divider()
                    .frame(height: Layout.dividerHeight)
                    .foregroundColor(Color(.divider))

                VStack {
                    Button(Localization.startWithThemeButton) {
                        /* todo */
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(Layout.startButtonPadding)

                    Text(String(format: Localization.themeName, "Tsubaki"))
                        .secondaryBodyStyle()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image(uiImage: .closeButton)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Text(Localization.menuMobile)
                        Text(Localization.menuTablet)
                        Text(Localization.menuDesktop)
                    } label: {
                        Image(systemName: "macbook.and.iphone")
                            .secondaryBodyStyle()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private extension ThemesPreviewView {
    private enum Layout {
        static let toolbarPadding: CGFloat = 16
        static let dividerHeight: CGFloat = 1
        static let startButtonPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 0, trailing: 16)
        static let themeLabelSpacing: CGFloat = 16
    }

    private enum Localization {
        static let menuMobile = NSLocalizedString(
            "themesPreviewView.menuMobile",
            value: "Mobile",
            comment: "Menu item: mobile"
        )
        static let menuTablet = NSLocalizedString(
            "themesPreviewView.menuTablet",
            value: "Tablet",
            comment: "Menu item: tablet"
        )

        static let menuDesktop = NSLocalizedString(
            "themesPreviewView.menuMobile",
            value: "Desktop",
            comment: "Menu item: desktop"
        )
        static let startWithThemeButton = NSLocalizedString(
            "themesPreviewView.startWithThemeButton",
            value: "Start with This Theme",
            comment: "Button in theme preview screen to pick a theme."
        )
        static let themeName = NSLocalizedString(
            "themesPreviewView.themeName",
            value: "Theme: %@",
            comment: "Name of the theme being previewed."
        )
    }
}

struct ThemesPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        ThemesPreviewView()
    }
}
