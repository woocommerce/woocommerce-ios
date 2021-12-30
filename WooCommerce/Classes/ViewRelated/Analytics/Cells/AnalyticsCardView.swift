import SwiftUI

/// Renders a card showing analytics stats or a list of products that have been sold.
///
struct AnalyticsCardView<Main: View>: View {
    private let topBarTitle: String
    private let mainView: Main
    private let bottomBarTitle: String
    private let bottomBarLink: String

    init(topBarTitle: String, @ViewBuilder content: () -> Main, bottomBarTitle: String, bottomBarLink: String) {
        self.topBarTitle = topBarTitle
        self.mainView = content()
        self.bottomBarTitle = bottomBarTitle
        self.bottomBarLink = bottomBarLink
    }

    /// We render cards with the same top and bottom bar and changing the main content.
    ///
    var body: some View {
        TitleAndMoreButtonView(title: topBarTitle, moreButton: {
            // Open action sheet
        })
        mainView
        TitleAndLinkView(title: bottomBarTitle, link: bottomBarLink)
    }
}

struct AnalyticsCardView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsCardView(topBarTitle: "REVENUE", content: {
            VStack {
                Text("Roses are red")
                Divider()
                Text("Violets are blue")
            }
        }, bottomBarTitle: "See Report", bottomBarLink: "https://github.com/woocommerce/woocommerce-ios")
    }
}
