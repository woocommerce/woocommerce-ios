import SwiftUI

struct InProgressView: UIViewControllerRepresentable {
    let viewProperties: InProgressViewProperties

    func makeUIViewController(context: UIViewControllerRepresentableContext<InProgressView>) -> InProgressViewController {
        let controller = InProgressViewController(viewProperties: viewProperties)
        return controller
    }

    func updateUIViewController(_ uiViewController: InProgressViewController, context: UIViewControllerRepresentableContext<InProgressView>) {}
}
