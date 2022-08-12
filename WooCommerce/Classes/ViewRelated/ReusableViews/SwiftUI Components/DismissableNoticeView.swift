import SwiftUI

/// A generic View that shows a dismissable Notice.
/// This contains a title, left-side message, right-side icon, and a button that dismisses the View when tapped.
///
/// - Parameters:
///     - buttonTapped: The callback to dismiss the View.
///     - title: Title to be displayed on the top of the View.
///     - message: Left-side message to be displayed.
///     - confirmationButtonMessage: The text inside the button component.
///     - icon: Right-side icon to be displayed.
///
struct DismissableNoticeView: View {
    @Environment(\.presentationMode) private var presentation
    @ScaledMetric private var scale: CGFloat = 1.0

    var buttonTapped: (() -> Void)?
    var title: String
    var message: String
    var confirmationButtonMessage: String
    var icon: UIImage

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            Text(title)
                .font(.headline)
                .padding(.bottom, Layout.verticalPadding)
            HStack(alignment: .center, spacing: 16.0) {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Layout.iconSize * scale, height: Layout.iconSize * scale)
                Spacer()
            }
            .padding(.bottom, Layout.verticalPadding)
            Button(confirmationButtonMessage) {
                if let completionHandler = buttonTapped {
                    completionHandler()
                }
                presentation.wrappedValue.dismiss()
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.bottom, Layout.verticalPadding)
        }
        .padding(.leading, Layout.horizontalPadding)
        .padding(.trailing, Layout.horizontalPadding)
        .padding(.top, Layout.verticalPadding)
        .padding(.bottom, Layout.verticalPadding)
    }
}

extension DismissableNoticeView {
    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 12
        static let iconSize: CGFloat = 32
    }
}
