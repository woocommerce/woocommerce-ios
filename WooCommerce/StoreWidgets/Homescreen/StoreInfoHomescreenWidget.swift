import SwiftUI
import WidgetKit

/// Entry point for StoreInfo Home Screen Widget
///
struct StoreInfoHomescreenWidget: View {
    let entry: StoreInfoEntry

    var body: some View {
        switch entry {
        case .notConnected:
            NotLoggedInView()
                .widgetAccentable()
        case .error:
            UnableToFetchView()
                .widgetAccentable()
        case .data(let data):
            StoreInfoMetricsView(entryData: data)
                .widgetAccentable()
        }
    }
}

private struct NotLoggedInView: View {
    var body: some View {
        VStack {
            Image(uiImage: .wooLogo)
                .resizable()
                .scaledToFit()
                .frame(width: Layout.logoWidth)

            Spacer()

            Text(Localization.notLoggedIn)
                .statTextStyle()

            Spacer()

            Text(Localization.login)
                .statButtonStyle()
        }
        .padding(.vertical, Layout.cardVerticalPadding)
        .widgetBackground(backgroundView: StoreWidgetHomeScreenBackground())
    }
}

private struct UnableToFetchView: View {
    var body: some View {
        VStack {
            Image(uiImage: .wooLogo)
                .resizable()
                .scaledToFit()
                .frame(width: Layout.logoWidth)

            Spacer()

            Text(Localization.unableToFetch)
                .statTextStyle()

            Spacer()
        }
        .padding(.vertical, Layout.cardVerticalPadding)
        .widgetBackground(backgroundView: StoreWidgetHomeScreenBackground())
    }
}

// MARK: - Constants

private extension NotLoggedInView {
    enum Localization {
        static let notLoggedIn = AppLocalizedString(
            "storeWidgets.notLoggedInView.notLoggedIn",
            value: "Log in to see today’s stats.",
            comment: "Title label when the widget does not have a logged-in store."
        )
        static let login = AppLocalizedString(
            "storeWidgets.notLoggedInView.login",
            value: "Log in",
            comment: "Title label for the login button on the store info widget."
        )
    }

    enum Layout {
        static let cardVerticalPadding = 22.0
        static let logoWidth = 32.0
    }
}

private extension UnableToFetchView {
    enum Localization {
        static let unableToFetch = AppLocalizedString(
            "storeWidgets.unableToFetchView.unableToFetchStats",
            value: "Unable to fetch stats",
            comment: "Title label when the home-screen stats widget can't fetch data."
        )
    }

    enum Layout {
        static let cardVerticalPadding = 22.0
        static let logoWidth = 32.0
    }
}

// MARK: - Previews
#if DEBUG

struct StoreInfoHomescreenWidget_Previews: PreviewProvider {
    static var previews: some View {
        NotLoggedInView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Not logged in")

        UnableToFetchView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Unable to fetch data")
    }
}
#endif
