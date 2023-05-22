import SwiftUI

/// Celebratory screen after creating the first product 🎉
///
struct FirstProductCreatedView: View {
    var body: some View {
        VStack(spacing: Layout.verticalSpacing) {
            Spacer()
            VStack {
                Text(Localization.title)
                    .titleStyle()
                Text(Localization.message)
                    .secondaryBodyStyle()
            }
            Image(uiImage: .welcomeImage)
            Button(Localization.shareAction) {
                // TODO
            }
            .buttonStyle(PrimaryButtonStyle())
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
    }
}

private extension FirstProductCreatedView {
    enum Layout {
        static let verticalSpacing: CGFloat = 32
    }
    enum Localization {
        static let title = NSLocalizedString(
            "Congratulations 🎉",
            comment: "Title of the celebratory screen after creating the first product"
        )
        static let message = NSLocalizedString(
            "Great work on your first product!",
            comment: "Message on the celebratory screen after creating first product"
        )
        static let shareAction = NSLocalizedString(
            "Spread the word",
            comment: "Title of the action button to share the first created product"
        )
    }
}

struct FirstProductCreatedView_Previews: PreviewProvider {
    static var previews: some View {
        FirstProductCreatedView()
            .environment(\.colorScheme, .light)
        FirstProductCreatedView()
            .environment(\.colorScheme, .dark)
    }
}
