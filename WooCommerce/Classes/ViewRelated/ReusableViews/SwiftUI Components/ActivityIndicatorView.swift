import SwiftUI

/// This is a wrapper view for using the UIActivityIndicator in SwiftUI. The native progress indicator is not available under iOS 13.
///
struct ActivityIndicatorView: UIViewRepresentable {
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicatorView>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicatorView>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

struct ActivityIndicatorView_Previews: PreviewProvider {

    static var previews: some View {
        ActivityIndicatorView(isAnimating: .constant(true), style: .large)
            .previewLayout(.fixed(width: 100, height: 100))
    }
}
