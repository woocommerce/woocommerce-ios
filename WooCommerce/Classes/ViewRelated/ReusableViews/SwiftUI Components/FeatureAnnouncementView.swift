import Foundation
import SwiftUI

struct FeatureAnnouncementView: View {
    let title: String
    let message: String
    let buttonTitle: String
    let image: UIImage

    let dismiss: (() -> Void)
    let callToAction: (() -> Void)

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                NewBadgeView()
                    .padding(.leading, Layout.padding)
                Spacer()
                Button(action: dismiss) {
                            Image(systemName: "xmark")
                                .foregroundColor(Color(.withColorStudio(.gray)))
                }.padding(.trailing, Layout.padding)
            }
            .padding(.top, Layout.padding)

            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .headlineStyle()
                        .padding(.bottom, Layout.smallSpacing)
                    Text(message)
                        .bodyStyle()
                        .padding(.bottom, Layout.largeSpacing)
                    Button(buttonTitle, action: callToAction)
                        .padding(.bottom, Layout.bottomButtonPadding)
                }
                Spacer()
                Image(uiImage: image)
            }
            .padding(.top, Layout.smallSpacing)
            .padding(.leading, Layout.padding)
        }.background(Color(.listForeground))
    }
}

extension FeatureAnnouncementView {
    enum Layout {
        static let padding: CGFloat = 16
        static let bottomButtonPadding: CGFloat = 23.5
        static let smallSpacing: CGFloat = 8
        static let largeSpacing: CGFloat = 16
    }
}
