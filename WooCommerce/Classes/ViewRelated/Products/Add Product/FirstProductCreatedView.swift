import ConfettiSwiftUI
import SwiftUI

/// Celebratory screen after creating the first product 🎉
///
struct FirstProductCreatedView: View {
    @State private var confettiCounter: Int = 0

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: Constants.verticalSpacing) {
                Spacer()
                Text(Localization.title)
                    .titleStyle()
                Image(uiImage: .welcomeImage)
                Text(Localization.message)
                    .secondaryBodyStyle()
                    .multilineTextAlignment(.center)
                Button(Localization.shareAction) {
                    // TODO
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal)
                Spacer()
            }
            .padding()
            .scrollVerticallyIfNeeded()
            .confettiCannon(counter: $confettiCounter,
                            num: Constants.confettiCount,
                            rainHeight: proxy.size.height,
                            radius: proxy.size.width)
        }
        .onAppear {
            confettiCounter += 1
        }
        .background(Color(uiColor: .systemBackground))
    }
}

private extension FirstProductCreatedView {
    enum Constants {
        static let verticalSpacing: CGFloat = 40
        static let confettiCount: Int = 100
    }
    enum Localization {
        static let title = NSLocalizedString(
            "First product created 🎉",
            comment: "Title of the celebratory screen after creating the first product"
        )
        static let message = NSLocalizedString(
            "Congratulations! You're one step closer to get the new store ready.",
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
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
