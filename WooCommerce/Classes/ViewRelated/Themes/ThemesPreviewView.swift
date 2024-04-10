import SwiftUI
import struct Yosemite.WordPressPage
import struct Yosemite.WordPressTheme

/// View to preview the demo page of a WordPress theme.
/// It lets merchants to:
/// - Preview the layouts responsively between mobile, tablet, and desktop view.
/// - Activate the previewed theme on the current site.
///
struct ThemesPreviewView: View {
    enum PreviewDevice: String, CaseIterable, Identifiable {
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

    @Environment(\.dismiss) var dismiss

    @ObservedObject private var viewModel: ThemesPreviewViewModel

    @State private var selectedDevice: PreviewDevice = PreviewDevice.defaultDevice
    @State private var showPagesMenu: Bool = false

    /// Triggered when the primary CTA button for selecting the theme is tapped.
    /// On Store creation, this is "Start with This Theme", while on Settings, this is "Use This Theme".
    var onSelectedTheme: () -> Void

    init(viewModel: ThemesPreviewViewModel,
         onSelectedTheme: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onSelectedTheme = onSelectedTheme
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let url = viewModel.selectedPageUrl {
                    WebView(
                        isPresented: .constant(true),
                        url: url,
                        disableLinkClicking: true,
                        onCommit: { webView in
                            webView.evaluateJavaScript(self.selectedDevice.viewportScript)
                        }
                    )

                    Divider()
                        .frame(height: Layout.dividerHeight)
                        .foregroundColor(Color(.divider))

                    VStack {
                        Button(viewModel.primaryButtonTitle) {
                            Task { @MainActor in
                                do {
                                    try await viewModel.confirmThemeSelection()
                                    onSelectedTheme()
                                    dismiss()
                                } catch {
                                    DDLogError("⛔️ ThemesPreviewView - Theme installation failed.")
                                }
                            }
                        }
                        .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.installingTheme))

                    }.padding(Layout.footerPadding)

                } else {
                    errorView
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Image(uiImage: .closeButton)
                            .secondaryBodyStyle()
                    })
                }

                ToolbarItem(placement: .principal) {
                    pageSelector
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
        .sheet(isPresented: $showPagesMenu) {
            if #available(iOS 16, *) {
                pagesListSheet
                    .presentationDetents([.medium, .large])
            } else {
                pagesListSheet
            }
        }
        .notice($viewModel.notice)
        .onAppear {
            viewModel.trackViewAppear()
        }
    }

    @ViewBuilder
    private var pageSelector: some View {

        // Here we show only a "Preview" label with no selector, both for loading and error cases.
        // In the case of page loading error, the home page is still usable, so showing "Preview" is better than nothing.
        Button(action: { showPagesMenu = true }) {
            VStack(spacing: 0) {
                Text(Localization.preview)
                    .fontWeight(.semibold)
                    .headlineStyle()
                if case .pagesContent = viewModel.state {
                    HStack {
                        Text(viewModel.selectedPage.title)
                            .foregroundColor(Color(.text))
                            .footnoteStyle()
                        Image(uiImage: .chevronDownImage)
                            .captionStyle()
                    }
                }
            }
        }
    }

    private var pagesListSheet: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(Localization.pagesSheetHeading)
                    .subheadlineStyle()
                    .padding(Layout.pagesSheetPadding)
                ForEach(viewModel.pages) { page in
                    Button(action: {
                        viewModel.setSelectedPage(page: page)
                        showPagesMenu = false
                    }, label: {
                        Text(page.title)
                            .bodyStyle()
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    })
                    .padding(Layout.contentPadding)
                }
                Spacer()
            }
        }
    }

    private func menuItem(for device: PreviewDevice) -> some View {
        Button {
            selectedDevice = device
            viewModel.trackLayoutSwitch(layout: device)
        } label: {
            Text(device.menuTitle)
            if selectedDevice == device {
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
        static let dividerHeight: CGFloat = 1
        static let footerPadding: CGFloat = 16
        static let contentPadding: CGFloat = 16
        static let pagesSheetPadding: EdgeInsets = .init(top: 40, leading: 16, bottom: 12, trailing: 16)
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

        static let errorLoadingThemeDemo = NSLocalizedString(
            "ThemesPreviewView.errorLoadingThemeDemo",
            value: "Unable to render the demo for this theme. Please try another theme.",
            comment: "The error message shown if the app can't show a theme demo."
        )

        static let pagesSheetHeading = NSLocalizedString(
            "themesPreviewView.pagesSheetHeading",
            value: "View other store pages on this theme",
            comment: "Heading for sheet displaying list of pages"
        )
    }
}

struct ThemesPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        ThemesPreviewView(
            viewModel: .init(siteID: 123,
                             mode: .storeCreationProfiler,
                             theme: WordPressTheme(
                                id: "123",
                                description: "Woo Theme",
                                name: "Woo",
                                demoURI: "https://woocommerce.com")),
            onSelectedTheme: { })
    }
}
