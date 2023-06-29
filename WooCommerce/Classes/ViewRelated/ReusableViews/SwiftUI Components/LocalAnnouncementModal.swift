import SwiftUI

/// A modal to announcement a feature locally on the dashboard tab.
struct LocalAnnouncementModal: View {
    let viewModel: LocalAnnouncementViewModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: Layout.spacing) {
            Image(uiImage: viewModel.image)
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)

            Text(viewModel.title)
                .headlineStyle()
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(viewModel.message)
                .bodyStyle()
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let buttonTitle = viewModel.buttonTitle {
                Button(buttonTitle) {
                    // dismissal and async call to the viewModel are required for the webview presentation to work.
                    isPresented = false
                    viewModel.ctaTapped()
                }
                .buttonStyle(PrimaryButtonStyle())
                .foregroundColor(Color(uiColor: .primary))
            }

            Button(viewModel.dismissButtonTitle) {
                viewModel.dismissTapped()
                isPresented = false
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .onAppear() {
            viewModel.onAppear()
        }
    }
}

private extension LocalAnnouncementModal {
    enum Layout {
        static let padding: CGFloat = 24
        static let spacing: CGFloat = 16
    }
}

struct LocalAnnouncementModal_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Text("Modal test")
        }
        .modalOverlay(isPresented: .constant(true)) {
            LocalAnnouncementModal(
                viewModel: .init(announcement: .productDescriptionAI),
                isPresented: .constant(true))
        }
    }
}

/// This wrapper exists to avoid the need to init a Binding in UIKit (which we can't) but
/// retain the presentation/dismiss behaviour
struct LocalAnnouncementModal_UIKit: View {
    @State var isPresented: Bool = true
    let viewModel: LocalAnnouncementViewModel
    let onDismiss: (() -> Void)?

    init(onDismiss: (() -> Void)?, viewModel: LocalAnnouncementViewModel) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        ModalOverlay(isPresented: $isPresented, onDismiss: onDismiss) {
            LocalAnnouncementModal(viewModel: viewModel, isPresented: $isPresented)
        }
    }
}
