import Foundation
import SwiftUI
import Experiments
import protocol WooFoundation.Analytics


/// Displays the WooCommerce Prologue UI.
///
final class LoginPrologueViewController: UIHostingController<LoginPrologueView> {
    init() {
        super.init(rootView: LoginPrologueView())
        view.backgroundColor = .clear
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
}

extension LoginPrologueViewController {
    static let backgroundColor = UIColor(light: .wooCommercePurple(.shade70),
                                         dark: .systemBackground)

    static var backgroundImage: UIImage {
        .prologueBackgroundBubbles(tint: UIColor(light: .wooCommercePurple(.shade40),
                                                 dark: .init(fromHex: 0x2c2c2E)))
    }
}

struct LoginPrologueView: View {
    var body: some View {
        ScrollView(.vertical) {
            content
        }
        .frame(maxWidth: .infinity)
    }

    var content: some View {
        VStack {
            Image(uiImage: .wooLogoImage(withSize: Layout.wooLogoSize)!)
                .padding(.top, Layout.topPadding)

            VStack(spacing: Layout.stackSpacing) {
                Spacer(minLength: 2 * Layout.stackSpacing)

                Image(uiImage: .prologueWooMobileImage)
                    .padding(.bottom, 4 * Layout.stackSpacing)

                Text(Localization.title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .frame(maxWidth: Layout.textMaxWidth)

                Text(Localization.subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .frame(maxWidth: Layout.textMaxWidth)

                Spacer(minLength: 2 * Layout.stackSpacing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(16)
    }
}

private extension LoginPrologueView {
    enum Layout {
        static let wooLogoSize = CGSize(width: 100, height: 26)
        static let topPadding: CGFloat = 54
        static let stackSpacing: CGFloat = 8
        static let textMaxWidth: CGFloat = 333
    }

    enum Localization {
        static let title = NSLocalizedString("loginPrologue.title",
                                             value: "The ecommerce platform that grows with you",
                                             comment: "Caption displayed in the simplified prologue screen")

        static let subtitle = NSLocalizedString("loginPrologue.subtitle",
                                                value: "From your first sale to millions in revenue, Woo is with you. " +
                                                "See why merchants trust us to power 3.9 million stores.",
                                                comment: "Subtitle displayed in the prologue screen")
    }
}

#if DEBUG
struct LoginPrologueView_Previews: PreviewProvider {
    static var previews: some View {
        LoginPrologueView()
            .background {
                Image(uiImage: LoginPrologueViewController.backgroundImage)
                    .resizable()
            }
            .background(Color(LoginPrologueViewController.backgroundColor))
    }
}
#endif
