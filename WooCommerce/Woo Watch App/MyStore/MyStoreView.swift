import SwiftUI
import NetworkingWatchOS

/// My Store Stats View
///
struct MyStoreView: View {

    @Environment(\.dependencies) private var dependencies

    // View Model to drive the view
    @StateObject var viewModel: MyStoreViewModel

    init(dependencies: WatchDependencies) {
        _viewModel = StateObject(wrappedValue: MyStoreViewModel(dependencies: dependencies))
    }

    var body: some View {
        VStack() {

            Text(dependencies.storeName)
                .font(.body)
                .foregroundStyle(Colors.wooPurple5)
                .padding(.bottom, Layout.storeNamePadding)

            Text(Localization.revenue)
                .font(.caption2)
                .foregroundStyle(Colors.wooPurple5)
                .padding(.bottom, Layout.revenueTitlePadding)

            Text("$4,321.90")
                .font(.title2)
                .bold()
                .padding(.bottom, Layout.revenueValuePadding)

            Divider()
                .padding(.bottom, Layout.dividerPadding)

            HStack {
                Text(Localization.today)
                Spacer()
                Text("As of 02:19")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.bottom, Layout.datePadding)

            HStack {

                Button(action: {
                    print("Order button pressed")
                }) {
                    HStack {
                        Images.document
                            .renderingMode(.original)
                            .foregroundStyle(Colors.wooPurple10)

                        Text("56")
                            .font(.caption)
                            .bold()
                    }
                    .padding(Layout.orderButtonPadding)
                }
                .buttonStyle(.plain)
                .background(Colors.wooPurple80)
                .cornerRadius(Layout.orderButtonCornerRadius)

                Spacer()

                VStack(spacing: Layout.iconsSpacing) {
                    HStack(spacing: Layout.iconsSpacing) {

                        Text("112")
                            .font(.caption)
                            .bold()

                        Images.person
                            .renderingMode(.original)
                            .foregroundStyle(Colors.wooPurple10)
                    }

                    HStack(spacing: Layout.iconsSpacing) {

                        Text("50%")
                            .font(.caption2)
                            .bold()

                        Images.zigzag
                            .renderingMode(.original)
                            .foregroundStyle(Colors.wooPurple10)
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: [Colors.wooPurpleBackground, .black]), startPoint: .top, endPoint: .bottom)
        )
        .task {
            await viewModel.fetchStats()
        }
    }
}

fileprivate extension MyStoreView {
    enum Colors {
        static let wooPurple5 = Color(red: 223/255.0, green: 209/255.0, blue: 251/255.0)
        static let wooPurple80 = Color(red: 60/255.0, green: 40/255.0, blue: 97/255.0)
        static let wooPurple10 = Color(red: 207/255.0, green: 185/255.0, blue: 246/255.0)
        static let wooPurpleBackground = Color(red: 79/255.0, green: 54/255.0, blue: 125/255.0)
        static let secondaryColor = Color(red: 79/255.0, green: 54/255.0, blue: 125/255.0)
    }

    enum Layout {
        static let storeNamePadding = 8.0
        static let revenueTitlePadding = 2.0
        static let revenueValuePadding = 4.0
        static let dividerPadding = 4.0
        static let datePadding = 12.0
        static let orderButtonPadding = 10.0
        static let orderButtonCornerRadius = 18.0
        static let iconsSpacing = 4.0
    }

    enum Localization {
        static let revenue = AppLocalizedString(
            "watch.mystore.revenue.title",
            value: "Revenue",
            comment: "Revenue title on the watch store stats screen."
        )
        static let today = AppLocalizedString(
            "watch.mystore.today.title",
            value: "Today",
            comment: "Today title on the watch store stats screen."
        )
    }

    enum Images {
        static let document = Image(systemName: "doc.text.fill")
        static let person = Image(systemName: "person.2.fill")
        static let zigzag = Image(systemName: "point.bottomleft.forward.to.point.topright.filled.scurvepath")
    }
}

#Preview {
    MyStoreView(dependencies: .fake())
}
