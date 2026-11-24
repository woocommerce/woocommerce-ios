import SwiftUI

struct StoreNoticeBannerActions: View {
    let actionTitle: String?
    let action: (() -> Void)?
    let prominentActionTitle: String?
    let prominentAction: (() -> Void)?
    let tone: StoreNoticeBannerTone

    var body: some View {
        if let actionTitle, let action {
            if let prominentActionTitle, let prominentAction {
                HStack(spacing: StoreSpacing.s3) {
                    StoreNoticeBannerActionButton(actionTitle,
                                                  isProminent: false,
                                                  tone: tone,
                                                  action: action)
                    StoreNoticeBannerActionButton(prominentActionTitle,
                                                  isProminent: true,
                                                  tone: tone,
                                                  action: prominentAction)
                }
            } else {
                Button(actionTitle, action: action)
                    .buttonStyle(.plain)
                    .storeTextStyle(.bodyMedium.emphasized)
                    .underline()
            }
        }
    }
}
