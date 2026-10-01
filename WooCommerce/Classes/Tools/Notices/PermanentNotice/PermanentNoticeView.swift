import Foundation
import SwiftUI

/// Renders a permanent notice with a separator line on top
///
struct PermanentNoticeView: View {
    let notice: PermanentNotice

    var body: some View {
        PermanentNoticeContentView(notice: notice)
            .background(Color(.listForeground(modal: false)))
            .overlay(Rectangle()
                .frame(width: nil, height: 0.5, alignment: .top)
                .foregroundColor(Color(UIColor.systemColor(.separator))), alignment: .top)
    }
}

private struct PermanentNoticeContentView: View {
    let notice: PermanentNotice

    var body: some View {
        HStack(alignment: .top, spacing: Layout.hStackSpacing) {
            Image(uiImage: .infoOutlineImage)
                .foregroundColor(Color(.gray(.shade40)))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Layout.vStackSpacing) {
                Text(notice.message)
                    .bodyStyle()
                Button(action: notice.callToActionHandler, label: {
                    Text(notice.callToActionTitle)
                        .font(.body)
                        .foregroundColor(Color(.accent))
                })
            }.padding(.top, Layout.vStackTopPadding)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(Layout.hStackPadding)
        .accessibilityElement(children: .combine)
    }
}

private extension PermanentNoticeContentView {
    typealias Layout = NoticeCardLayout
}

/// Shared card chrome metrics for the permanent notice and its loading counterpart.
///
private enum NoticeCardLayout {
    static let hStackSpacing: CGFloat = 15
    static let hStackPadding: CGFloat = 10
    static let vStackSpacing: CGFloat = 10
    static let vStackTopPadding: CGFloat = 2
}

/// Renders a loading indicator in the same card chrome as `PermanentNoticeView`,
/// for states that resolve into a permanent notice (e.g. payment country recovery).
/// Kept as a separate view because loading is transient: unlike `PermanentNotice`
/// it carries no call to action.
///
struct LoadingNoticeView: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: NoticeCardLayout.hStackSpacing) {
            ProgressView()
                .accessibilityHidden(true)

            Text(message)
                .bodyStyle()
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(NoticeCardLayout.hStackPadding)
        .accessibilityElement(children: .combine)
        .background(Color(.listForeground(modal: false)))
        .overlay(Rectangle()
            .frame(width: nil, height: 0.5, alignment: .top)
            .foregroundColor(Color(UIColor.systemColor(.separator))), alignment: .top)
    }
}

#Preview {
    VStack(spacing: 0) {
        LoadingNoticeView(message: "Checking card payment availability…")
        PermanentNoticeView(notice: .init(message: "We couldn’t load your store settings to check card payment availability.",
                                          callToActionTitle: "Retry",
                                          callToActionHandler: {}))
    }
}
