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
        // This VStack is needed so the `onAppear` task is properly executed.
        VStack {
            // Draw the view that corresponds to the view state.
            switch viewModel.viewState {
            case .idle:
                EmptyView()
            case .loading:
                dataView(revenue: "------", orders: "--", visitors: "--", conversion: "--", time: "00:00 AM")
                    .redacted(reason: .placeholder)
            case .error:
                errorView
            case let .loaded(revenue, totalOrders, totalVisitors, conversion, time):
                dataView(revenue: revenue, orders: totalOrders, visitors: totalVisitors, conversion: conversion, time: time)
            }
        }
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: [Colors.wooPurpleBackground, .black]), startPoint: .top, endPoint: .bottom)
        )
        .onAppear() {
            Task {
                await viewModel.fetchStats()
            }
        }
    }

    /// Error View with a retry button
    ///
    @ViewBuilder var errorView: some View {
        VStack {
            Spacer()
            Text(Localization.error)
            Spacer()
            Button(Localization.retry) {
                Task {
                    await viewModel.fetchStats()
                }
            }
        }
    }

    /// My Store Stats data view.
    ///
    @ViewBuilder func dataView(revenue: String, orders: String, visitors: String, conversion: String, time: String) -> some View {
        VStack {
            Text(dependencies.storeName)
                .font(.body)
                .foregroundStyle(Colors.wooPurple5)
                .padding(.bottom, Layout.storeNamePadding)

            Text(Localization.revenue)
                .font(.caption2)
                .foregroundStyle(Colors.wooPurple5)
                .padding(.bottom, Layout.revenueTitlePadding)

            Text(revenue)
                .font(.title2)
                .bold()
                .padding(.bottom, Layout.revenueValuePadding)

            Divider()
                .padding(.bottom, Layout.dividerPadding)

            HStack {
                Text(Localization.today)
                Spacer()
                Text(Localization.time(time))
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

                        Text(orders)
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

                        Text(visitors)
                            .font(.caption)
                            .bold()

                        Images.person
                            .renderingMode(.original)
                            .foregroundStyle(Colors.wooPurple10)
                    }

                    HStack(spacing: Layout.iconsSpacing) {

                        Text(conversion)
                            .font(.caption2)
                            .bold()

                        Images.zigzag
                            .renderingMode(.original)
                            .foregroundStyle(Colors.wooPurple10)
                    }
                }
            }
        }
    }
}

/// Constants
///
fileprivate extension MyStoreView {
    // TODO: Move this to a shared resource
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
        static let error = AppLocalizedString(
            "watch.mystore.error.title",
            value: "There was an error loading the store's data",
            comment: "Loading title on the watch store stats screen."
        )
        static let retry = AppLocalizedString(
            "watch.mystore.retry.title",
            value: "Retry",
            comment: "Retry on the watch store stats screen."
        )
        static func time(_ time: String) -> LocalizedString {
            let format = AppLocalizedString(
                "watch.mystore.time.format",
                value: "As of %@",
                comment: "Format of the updated time in the watch store stats screen."
            )
            return LocalizedString(format: format, time)
        }
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
