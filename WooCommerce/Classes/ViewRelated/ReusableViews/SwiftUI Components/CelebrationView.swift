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
        ScrollableVStack(padding: Layout.contentPadding, spacing: Layout.contentPadding) {
            Spacer()

            Image(uiImage: image)
                .padding(.bottom, Layout.imageExtraBottomPadding)

            Group {
                Text(title)
                    .fontWeight(.semibold)
                    .secondaryTitleStyle()
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .foregroundColor(Color(.text))
                    .bodyStyle()
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(closeButtonTitle) {
                onTappingDone()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private extension CelebrationView {
    enum Layout {
        static let contentPadding: CGFloat = 16
        static let imageExtraBottomPadding: CGFloat = 8
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
