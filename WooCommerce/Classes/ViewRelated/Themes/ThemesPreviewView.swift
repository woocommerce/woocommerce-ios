import SwiftUI
import struct Yosemite.WordPressTheme

/// View to preview the demo page of a WordPress theme.
/// It lets merchants to:
/// - Preview the layouts responsively between mobile, tablet, and desktop view.
/// - Activate the previewed theme on the current site.
///
struct ThemesPreviewView: View {
    enum PreviewDevice: CaseIterable {
        case mobile
        case tablet
        case desktop

        /// The initial layout used as preview.
        static var defaultDevice: PreviewDevice {
            return UIDevice.current.userInterfaceIdiom == .pad ? .tablet : .mobile
        }

        /// The width is used in the `viewportScript` JS to change the WebView's viewport.
        /// A theme's CSS will take into account this number to decide whether to responsively display its layout to be
        /// the mobile, tablet, or desktop layout.
        ///
        var browserWidth: CGFloat {
            switch self {
            case .mobile: return 400
            case .tablet: return 800
            case .desktop: return 1200
            }
        }

        /// This JavaScript forces the WebView's viewport to match the supplied width above. This allows the preview
        /// functionality to switch between a theme's mobile, tablet, or desktop layout.
        ///
        var viewportScript: String {
            let js = """
            // remove all existing viewport meta tags - some themes included multiple, which is invalid
            document.querySelectorAll("meta[name=viewport]").forEach( e => e.remove() );
            // create our new meta element
            const viewportMeta = document.createElement("meta");
            viewportMeta.name = "viewport";
            viewportMeta.content = "width=%1$d";
            // insert the correct viewport meta tag
            document.getElementsByTagName("head")[0].append(viewportMeta);
            """

            return String(format: js, NSInteger(browserWidth))
        }
    }

    @State private var selectedDevice: PreviewDevice = PreviewDevice.defaultDevice
    private let theme: WordPressTheme

    /// Triggered when "Start with this theme" button is tapped.
    var onStart: () -> Void

    init(theme: WordPressTheme, onStart: @escaping () -> Void) {
        self.theme = theme
        self.onStart = onStart
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let url = theme.themeThumbnailURL {
                    WebView(
                        isPresented: .constant(true),
                        url: url,
                        shouldReloadOnUpdate: true,
                        onCommit: { webView in
                            webView.evaluateJavaScript(self.selectedDevice.viewportScript)
                        }
                    )
                } else {
                    /* todo error view */
                }

                Divider()
                    .frame(height: Layout.dividerHeight)
                    .foregroundColor(Color(.divider))

                VStack {
                    Button(Localization.startWithThemeButton, action: onStart)
                    .buttonStyle(PrimaryButtonStyle())

                    Text(String(format: Localization.themeName, theme.name))
                        .secondaryBodyStyle()
                }.padding(Layout.footerPadding)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image(uiImage: .closeButton)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(PreviewDevice.allCases, id: \.self) { device in
                          menuItem(for: device)
                        }
                    } label: {
                         Image(systemName: "macbook.and.iphone")
                            .bodyStyle()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func menuItem(for device: PreviewDevice) -> some View {
        Button {
            self.selectedDevice = device
        } label: {
            Text(Localization.getMenuTitle(for: device))
            if self.selectedDevice == device {
                Image(systemName: "checkmark")
            }
        }
    }
}

private extension ThemesPreviewView {
    private enum Layout {
        static let toolbarPadding: CGFloat = 16
        static let dividerHeight: CGFloat = 1
        static let footerPadding: CGFloat = 16
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

        static func getMenuTitle(for device: PreviewDevice) -> String {
            switch device {
            case .desktop:
                return menuDesktop
            case .tablet:
                return menuTablet
            case .mobile:
                return menuMobile
            }
        }
    }
}

struct ThemesPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        ThemesPreviewView(
            theme: WordPressTheme(
                id: "123",
                description: "Woo Theme",
                name: "Woo",
                demoURI: "https://woo.com"
            ),
            onStart: { }
        )
    }
}
