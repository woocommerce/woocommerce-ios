import SwiftUI
import struct Yosemite.WordPressTheme

/// View to preview the demo page of a WordPress theme.
/// It lets merchants to:
/// - Preview the layouts responsively between mobile, tablet, and desktop view.
/// - Activate the previewed theme on the current site.
///
struct ThemesPreviewView: View {
    enum PreviewDevice: CaseIterable, Identifiable {
        var id: PreviewDevice { self }

        case mobile
        case tablet
        case desktop


        var menuTitle: String {
            switch self {
            case .desktop:
                return ThemesPreviewView.Localization.menuDesktop
            case .tablet:
                return ThemesPreviewView.Localization.menuTablet
            case .mobile:
                return ThemesPreviewView.Localization.menuMobile
            }
        }

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

    @Environment(\.presentationMode) var presentationMode

    @ObservedObject private var viewModel: ThemesPreviewViewModel

    @State private var selectedDevice: PreviewDevice = PreviewDevice.defaultDevice
    @State private var showPagesMenu: Bool = false

    private let theme: WordPressTheme

    /// Triggered when "Start with this theme" button is tapped.
    var onStart: () -> Void

    init(viewModel: ThemesPreviewViewModel,
         theme: WordPressTheme,
         onStart: @escaping () -> Void) {
        self.viewModel = viewModel
        self.theme = theme
        self.onStart = onStart
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let url = URL(string: theme.demoURI) {
                    WebView(
                        isPresented: .constant(true),
                        url: url,
                        shouldReloadOnUpdate: true,
                        disableLinkClicking: true,
                        onCommit: { webView in
                            webView.evaluateJavaScript(self.selectedDevice.viewportScript)
                        }
                    )

                    Divider()
                        .frame(height: Layout.dividerHeight)
                        .foregroundColor(Color(.divider))

                    VStack {
                        Button(Localization.startWithThemeButton, action: onStart)
                        .buttonStyle(PrimaryButtonStyle())

                        Text(String(format: Localization.themeName, theme.name))
                            .secondaryBodyStyle()
                    }.padding(Layout.footerPadding)

                } else {
                    errorView
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Image(uiImage: .closeButton)
                    })
                }

                ToolbarItem(placement: .principal) {
                    pageSelector(state: viewModel.state)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(PreviewDevice.allCases) { device in
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
        .task { await viewModel.fetchPages() }
        .sheet(isPresented: $showPagesMenu) { /* todo show sheet */ }
    }

    private func pageSelector(state: ThemesPreviewViewModel.State) -> some View {
        switch state {
        case .pagesLoading:
            return AnyView(Text(Localization.preview))

        case .pagesContent:
            return AnyView(
                Button(action: { showPagesMenu = true },
                       label: {
                           HStack {
                               Text("Home").secondaryBodyStyle()
                               Image(uiImage: .chevronDownImage).fixedSize()
                           }
                       })
            )

        case .pagesLoadingError:
            return AnyView(Text(Localization.preview))
        }
    }

    private func menuItem(for device: PreviewDevice) -> some View {
        Button {
            self.selectedDevice = device
        } label: {
            Text(device.menuTitle)
            if self.selectedDevice == device {
                Image(systemName: "checkmark")
            }
        }
    }
}

private extension ThemesPreviewView {
    var errorView: some View {
        VStack(spacing: Layout.contentPadding) {
            Spacer()
            Text(Localization.errorLoadingThemeDemo)
                .secondaryBodyStyle()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private extension ThemesPreviewView {
    private enum Layout {
        static let toolbarPadding: CGFloat = 16
        static let dividerHeight: CGFloat = 1
        static let footerPadding: CGFloat = 16
        static let contentPadding: CGFloat = 16
    }

    private enum Localization {
        static let preview = NSLocalizedString(
            "themesPreviewView.preview",
            value: "Preview",
            comment: "Title of the preview screen"
        )

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

        static let errorLoadingThemeDemo = NSLocalizedString(
            "ThemesPreviewView.errorLoadingThemeDemo",
            value: "Unable to render the demo for this theme. Please try another theme.",
            comment: "The error message shown if the app can't show a theme demo."
        )
    }
}

struct ThemesPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        ThemesPreviewView(
            viewModel: .init(themeDemoURL: "https://woo.com"),
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
