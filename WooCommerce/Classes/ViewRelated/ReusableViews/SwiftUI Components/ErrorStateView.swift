import SwiftUI

/// Reusable view for error state
struct ErrorStateView: View {
    let title: String
    var subtitle: String?
    var image: UIImage?
    let actionTitle: String
    let actionHandler: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Text(title)
                .headlineStyle()

            if let subtitle {
                Text(subtitle)
                    .secondaryBodyStyle()
            }

            if let image {
                Image(uiImage: image)
            }

            Button(actionTitle, action: actionHandler)
        }
        .padding()
    }
}

struct ErrorStateView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorStateView(title: "Error loading data",
                       subtitle: "Something went wrong. Please try again.",
                       image: .errorImage,
                       actionTitle: "Try again",
                       actionHandler: {})
    }
}
