import SwiftUI

struct StoreNoticeBannerActionButton: View {
    private let title: String
    private let isProminent: Bool
    private let tone: StoreNoticeBannerTone
    private let action: () -> Void

    init(_ title: String,
         isProminent: Bool,
         tone: StoreNoticeBannerTone,
         action: @escaping () -> Void) {
        self.title = title
        self.isProminent = isProminent
        self.tone = tone
        self.action = action
    }

    var body: some View {
        StoreButton(
            title,
            variant: isProminent ? filledVariant : outlinedVariant,
            action: action
        )
    }

    private var filledVariant: StoreButtonVariant {
        .filled(background: tone.appearance.actionBackground,
                foreground: tone.appearance.actionForeground)
    }

    private var outlinedVariant: StoreButtonVariant {
        .outlined(foreground: tone.appearance.actionBackground,
                  border: tone.appearance.actionBackground)
    }
}
