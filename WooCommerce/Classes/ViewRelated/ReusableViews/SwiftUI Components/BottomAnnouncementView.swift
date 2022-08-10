import SwiftUI

struct BottomAnnouncementView: View {
    @Environment(\.presentationMode) private var presentation
    var body: some View {
        Text(Localization.title)
        Text(Localization.message)
        Button(Localization.okButton) {
            presentation.wrappedValue.dismiss()
        }
    }
}

extension BottomAnnouncementView {
    enum Localization {
        static let title = NSLocalizedString("Payments from the Menu tab", comment: "Text comment")
        static let message = NSLocalizedString(" Now you can quickly access In-Person Payments and other features with ease.", comment: "Comment")
        static let okButton = NSLocalizedString("Got it!", comment: "comment")
    }
}
