import SwiftUI

struct JustInTimeMessageModal: View {
    let viewModel: JustInTimeMessageViewModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: Layout.spacing) {
            if let imageUrl = viewModel.imageUrl {
                AdaptiveAsyncImage(lightUrl: imageUrl, darkUrl: viewModel.imageDarkUrl, scale: 3) { imagePhase in
                    switch imagePhase {
                    case .failure:
                        Image(uiImage: viewModel.image)
                            .accessibilityHidden(true)
                    case .success(let image):
                        image.resizable()
                            .scaledToFit()
                            .accessibilityHidden(true)
                    case .empty:
                        AnimatedPlaceholder()
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(uiImage: viewModel.image)
                    .accessibilityHidden(true)
            }

            Text(viewModel.title)
                .headlineStyle()

            Text(viewModel.message)
                .bodyStyle()
                .fixedSize(horizontal: false, vertical: true)

            if let buttonTitle = viewModel.buttonTitle {
                Button(buttonTitle) {
                    // dismissal and async call to the viewModel are required for the webview presentation to work.
                    isPresented = false
                    Task {
                        viewModel.ctaTapped()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .foregroundColor(Color(uiColor: .primary))
            }

            Button(viewModel.dismissAlertTitle) {
                viewModel.dismissTapped()
                isPresented = false
            }
            .padding(.bottom, Layout.padding)
        }
    }

    enum Layout {
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 16
    }
}

#if DEBUG // to avoid importing things we don't need in the implementation
import Yosemite

struct JustInTimeMessageModal_Previews: PreviewProvider {
    private static let message = Yosemite.JustInTimeMessage(
        siteID: 0,
        messageID: "messageID",
        featureClass: "new–feature",
        title: "Hey merchants!",
        detail: "Take a look at this new feature...",
        buttonTitle: "Try it out",
        url: "https://woocommerce.com/mobile/payments",
        backgroundImageUrl: nil,
        backgroundImageDarkUrl: nil,
        badgeImageUrl: nil,
        badgeImageDarkUrl: nil,
        template: .modal)

    private static let viewModel: JustInTimeMessageViewModel = .init(
        justInTimeMessage: message,
        screenName: "preview",
        siteID: 0)

    static var previews: some View {
        ZStack {
            Text("Modal test")
        }
        .modalOverlay(isPresented: .constant(true)) {
            JustInTimeMessageModal(viewModel: viewModel, isPresented: .constant(true))
        }
    }
}
#endif

/// This wrapper exists to avoid the need to init a Binding in UIKit (which we can't) but
/// retain the presentation/dismiss behaviour
struct JustInTimeMessageModal_UIKit: View {
    @State var isPresented: Bool = true
    let viewModel: JustInTimeMessageViewModel
    let onDismiss: (() -> Void)?

    init(onDismiss: (() -> Void)?, viewModel: JustInTimeMessageViewModel) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        ModalOverlay(isPresented: $isPresented, onDismiss: onDismiss) {
            JustInTimeMessageModal(viewModel: viewModel, isPresented: $isPresented)
        }
    }
}
