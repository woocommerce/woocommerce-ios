import Foundation
import SwiftUI

struct PermanentNoticeView: View {
    let message: String
    let callToActionTitle: String
    let callToActionHandler: () -> Void

    var body: some View {
        PermanentNoticeContentView(message: message,
                                   callToActionTitle: callToActionTitle,
                                   callToActionHandler: callToActionHandler)
            .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top)
                .foregroundColor(Color(.gray(.shade5))), alignment: .top)

    }
}

struct PermanentNoticeContentView: View {
    let message: String
    let callToActionTitle: String
    let callToActionHandler: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(uiImage: .infoOutlineImage)
                .foregroundColor(Color(.gray(.shade40)))

            VStack(alignment: .leading, spacing: 10) {
                Text(message)
                    .bodyStyle()
                Button(action: callToActionHandler, label: {
                    Text(callToActionTitle)
                        .underline()
                        .font(.body)
                        .foregroundColor(Color(.accent))
                })
            }.padding(.top, 2)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
        .padding(16)
    }
}

final class HostingController<Content: View>: UIHostingController<Content> {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        view.setNeedsUpdateConstraints()
    }
}
