import SwiftUI
import NetworkingWatchOS

/// My Store Stats View
///
struct MyStoreView: View {

    @Environment(\.dependencies) private var dependencies

    @Environment(\.appBindings) private var appBindings

    @EnvironmentObject private var tracksProvider: WatchTracksProvider

    // View Model to drive the view
    @StateObject var viewModel: MyStoreViewModel

    // Used to changed the tab programmatically
    @Binding var watchTab: WooWatchTab

    init(dependencies: WatchDependencies, watchTab: Binding<WooWatchTab>) {
        _viewModel = StateObject(wrappedValue: MyStoreViewModel(dependencies: dependencies))
        self._watchTab = watchTab
    }

    var body: some View {
        HStack {
            // Draw the view that corresponds to the view state.
            switch viewModel.viewState {
            case .idle:
                Rectangle().hidden()
                    .task {
                        await viewModel.fetchAndBindRefreshTrigger(trigger: appBindings.refreshData.eraseToAnyPublisher())
                    }
            case .loading:
                dataView(revenue: "------", orders: "--", visitors: "--", conversion: "--", time: "00:00 AM")
                    .padding(.horizontal)
                    .redacted(reason: .placeholder)
                    .scrollDisabled(true)
            case .error:
                errorView
            case let .loaded(revenue, totalOrders, totalVisitors, conversion, time):
                dataView(revenue: revenue, orders: totalOrders, visitors: totalVisitors, conversion: conversion, time: time)
                    .padding(.horizontal)

            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle {
            Text(dependencies.storeName)
                .foregroundStyle(Colors.wooPurple5)
        }
        .background(
            LinearGradient(gradient: Gradient(colors: [Colors.wooPurpleBackground, .black]), startPoint: .top, endPoint: .bottom)
        )
        .onAppear() {
            Task {
                tracksProvider.sendTracksEvent(.watchMyStoreOpened)
            }
        }
    }

    /// Error View with a retry button
    ///
    @ViewBuilder var errorView: some View {
        VStack {
            ScrollView {
                Text(Localization.errorTitle)
                    .font(.caption)

                Spacer()

                Text(Localization.errorDescription)
                    .font(.footnote)

                Spacer()

            }
            .multilineTextAlignment(.center)

            Button(Localization.retry) {
                Task {
                    appBindings.refreshData.send()
                }
            }
            .padding(.bottom, -16)
        }
    }

    /// My Store Stats data view.
    ///
    @ViewBuilder func dataView(revenue: String, orders: String, visitors: String, conversion: String, time: String) -> some View {
        ScrollView {
            VStack {
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
                        self.watchTab = .ordersList
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

                    VStack(alignment: .trailing, spacing: Layout.iconsSpacing) {
                        HStack(spacing: Layout.iconsSpacing) {

                            Text(visitors)
                                .font(.caption)

                            Images.person
                                .resizable()
                                .renderingMode(.original)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: Layout.iconWidth, height: Layout.iconWidth)
                                .foregroundStyle(Colors.wooPurple10)
                        }
                        .bold()

                        HStack(spacing: Layout.iconsSpacing) {

                            Text(conversion)
                                .font(.caption2)

                            Images.zigzag
                                .resizable()
                                .renderingMode(.original)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: Layout.iconWidth, height: Layout.iconWidth)
                                .foregroundStyle(Colors.wooPurple10)
                        }
                        .bold()
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
        static let revenueTitlePadding = 1.0
        static let revenueValuePadding = 4.0
        static let dividerPadding = 4.0
        static let datePadding = 12.0
        static let orderButtonPadding = 10.0
        static let orderButtonCornerRadius = 18.0
        static let iconsSpacing = 4.0
        static let iconWidth = 24.0
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
        static let errorTitle = AppLocalizedString(
            "watch.mystore.error.title",
            value: "Failed to load store data",
            comment: "Error title on the watch store stats screen."
        )
        static let errorDescription = AppLocalizedString(
            "watch.mystore.error.description",
            value: "Make sure your watch is connected to the internet and your phone is nearby.",
            comment: "Error description on the watch store stats screen."
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
