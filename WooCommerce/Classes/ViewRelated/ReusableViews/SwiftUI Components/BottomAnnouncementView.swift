import SwiftUI

struct BottomAnnouncementView: View {
    var body: some View {
        Text(Localization.title)
    }
}

extension BottomAnnouncementView {
    enum Localization {
        static let title = NSLocalizedString("Text title", comment: "Text comment")
    }
}
