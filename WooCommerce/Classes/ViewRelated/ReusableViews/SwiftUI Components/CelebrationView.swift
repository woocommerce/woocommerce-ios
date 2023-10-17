import SwiftUI

/// Hosting controller for `CelebrationView`.
///
final class CelebrationHostingController: UIHostingController<CelebrationView> {
    init(title: String,
         subtitle: String,
         closeButtonTitle: String,
         image: UIImage = .checkSuccessImage,
         onTappingDone: @escaping () -> Void) {
        super.init(rootView: CelebrationView(title: title,
                                             subtitle: subtitle,
                                             closeButtonTitle: closeButtonTitle,
                                             image: image,
                                             onTappingDone: onTappingDone))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Celebration view presented after a successful task.
struct CelebrationView: View {
    private let title: String
    private let subtitle: String
    private let closeButtonTitle: String
    private let image: UIImage
    private let onTappingDone: () -> Void

    init(title: String,
         subtitle: String,
         closeButtonTitle: String,
         image: UIImage = .checkSuccessImage,
         onTappingDone: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.closeButtonTitle = closeButtonTitle
        self.image = image
        self.onTappingDone = onTappingDone
    }

    var body: some View {
        ScrollableVStack(spacing: Layout.verticalSpacing) {
            Image(uiImage: image)
                .padding(.vertical, Layout.imageVerticalPadding)

            Group {
                Text(title)
                    .headlineStyle()
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .foregroundColor(Color(.text))
                    .subheadlineStyle()
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Layout.textHorizontalPadding)

            Button(closeButtonTitle) {
                onTappingDone()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Layout.buttonHorizontalPadding)
        }
        .padding(insets: Layout.insets)
    }
}

private extension CelebrationView {
    enum Layout {
        static let verticalSpacing: CGFloat = 16
        static let imageVerticalPadding: CGFloat = 18
        static let textHorizontalPadding: CGFloat = 24
        static let buttonHorizontalPadding: CGFloat = 16
        static let insets: EdgeInsets = .init(top: 40, leading: 0, bottom: 16, trailing: 0)
    }
}

struct CelebrationView_Previews: PreviewProvider {
    static var previews: some View {
        CelebrationView(title: "Success!",
                        subtitle: "You did it!",
                        closeButtonTitle: "Done",
                        onTappingDone: {})

        CelebrationView(title: "Success!",
                        subtitle: "You did it!",
                        closeButtonTitle: "Done",
                        onTappingDone: {})
            .preferredColorScheme(.dark)
    }
}
