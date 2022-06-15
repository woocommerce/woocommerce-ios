import SwiftUI

struct SingleStatView: View {

    let viewData: SingleStatViewModel


    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                FlexibleCard(axis: .vertical, title: viewData.widgetTitle, value: .description(viewData.siteName), lineLimit: 2)

                Spacer()
                VerticalCard(title: viewData.bottomTitle, value: viewData.bottomValue, largeText: true)
            }
            Spacer()
        }
    }
}
