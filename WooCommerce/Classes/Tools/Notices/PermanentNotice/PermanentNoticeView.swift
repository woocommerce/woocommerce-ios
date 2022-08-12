import Foundation
import SwiftUI

/// Renders a permanent notice with a separator line on top
///
struct PermanentNoticeView: View {
    let notice: PermanentNotice

    var body: some View {
        PermanentNoticeContentView(notice: notice)
            .overlay(Rectangle()
                .frame(width: nil, height: 1, alignment: .top)
                .foregroundColor(Color(.gray(.shade5))), alignment: .top)
    }
}

private struct PermanentNoticeContentView: View {
    let notice: PermanentNotice

    var body: some View {
        HStack(alignment: .top, spacing: Layout.hStackSpacing) {
            Image(uiImage: .infoOutlineImage)
                .foregroundColor(Color(.gray(.shade40)))

            VStack(alignment: .leading, spacing: Layout.vStackSpacing) {
                Text(notice.message)
                    .bodyStyle()
                Button(action: notice.callToActionHandler, label: {
                    Text(notice.callToActionTitle)
                        .underline()
                        .font(.body)
                        .foregroundColor(Color(.accent))
                })
            }.padding(.top, Layout.vStackTopPadding)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(Layout.hStackPadding)
    }
}

private extension PermanentNoticeContentView {
    enum Layout {
        static let hStackSpacing: CGFloat = 15
        static let hStackPadding: CGFloat = 10
        static let vStackSpacing: CGFloat = 10
        static let vStackTopPadding: CGFloat = 2
    }
}
