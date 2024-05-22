import SwiftUI

/// View for the order detail
///
struct OrderDetailView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {

                HStack {
                    Text("25 Feb")
                    Spacer()
                    Text("12:14 pm")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                Divider()

                VStack(alignment: .leading, spacing: Layout.nameSectionSpacing) {
                    Text("Willem Dafoe")
                        .font(.title3)

                    Text("$149.50")
                        .font(.title2)
                        .bold()

                    Text("Pending payment")
                        .font(.footnote)
                        .foregroundStyle(Colors.gray5)
                }
                .padding(.bottom, Layout.mainSectionsPadding)

                Text("3 products")
                    .font(.caption2)
                    .padding(.bottom, Layout.mainSectionsPadding)

                VStack {
                    itemRow()
                    Divider()
                    itemRow()
                    Divider()
                    itemRow()
                }
            }
        }
        .padding(.horizontal)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Text("#1031")
                    .font(.body)
                    .foregroundStyle(Colors.wooPurple20)
            }
        }
        .background(
            LinearGradient(gradient: Gradient(colors: [Colors.wooPurpleBackground, .black]), startPoint: .top, endPoint: .bottom)
        )
    }

    @ViewBuilder private func itemRow() -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text("Little Nap Blend 250g")
                .font(.caption2)

            HStack {
                Text("$99.00")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("3")
                    .font(.caption2)
                    .foregroundStyle(Colors.wooPurple20)
                    .padding(Layout.itemCountPadding)
                    .background(Circle().fill(Colors.whiteTransparent))
            }
        }
    }
}

private extension OrderDetailView {
    enum Layout {
        static let nameSectionSpacing = 2.0
        static let mainSectionsPadding = 10.0
        static let itemCountPadding = 6.0
    }

    enum Colors {
        static let wooPurpleBackground = Color(red: 79/255.0, green: 54/255.0, blue: 125/255.0)
        static let gray5 = Color(red: 220/255.0, green: 220/255.0, blue: 222/255.0)
        static let wooPurple20 = Color(red: 190/255.0, green: 160/255.0, blue: 242/255.0)
        static let whiteTransparent = Color(white: 1.0, opacity: 0.12)
    }
}
