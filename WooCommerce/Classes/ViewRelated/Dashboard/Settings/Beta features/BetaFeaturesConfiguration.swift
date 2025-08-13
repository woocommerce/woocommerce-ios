import SwiftUI
import Yosemite

final class BetaFeaturesConfigurationViewController: UIHostingController<BetaFeaturesConfiguration> {

    init() {
        super.init(rootView: BetaFeaturesConfiguration(viewModel: .init()))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct BetaFeaturesConfiguration: View {
    @StateObject private var viewModel: BetaFeaturesConfigurationViewModel

    init(viewModel: BetaFeaturesConfigurationViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            ForEach(viewModel.availableFeatures) { feature in
                Section(footer: Text(feature.description)) {
                    TitleAndToggleRow(title: feature.title, isOn: viewModel.isOn(feature: feature))
                }
            }

#if DEBUG
            Section(footer: Text(Localization.posSyncTestingDescription)) {
                Button(action: {
                    viewModel.triggerPOSFullSync()
                }) {
                    HStack {
                        Text(Localization.triggerFullSync)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.down.circle")
                            .foregroundColor(.blue)
                    }
                }

                Button(action: {
                    viewModel.triggerPOSIncrementalSync()
                }) {
                    HStack {
                        Text(Localization.triggerIncrementalSync)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.clockwise.circle")
                            .foregroundColor(.blue)
                    }
                }

                Button(action: {
                    viewModel.logPOSSyncStatus()
                }) {
                    HStack {
                        Text(Localization.logSyncStatus)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "info.circle")
                            .foregroundColor(.green)
                    }
                }

                Button(action: {
                    viewModel.forceScheduleFullSync()
                }) {
                    HStack {
                        Text(Localization.forceScheduleFullSync)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "calendar.badge.plus")
                            .foregroundColor(.orange)
                    }
                }

                Button(action: {
                    viewModel.forceScheduleIncrementalSync()
                }) {
                    HStack {
                        Text(Localization.forceScheduleIncrementalSync)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.orange)
                    }
                }

                Button(action: {
                    viewModel.forceScheduleMainAppRefresh()
                }) {
                    HStack {
                        Text(Localization.forceScheduleMainAppRefresh)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "calendar.circle")
                            .foregroundColor(.orange)
                    }
                }

                Button(action: {
                    viewModel.forceScheduleAllTasks()
                }) {
                    HStack {
                        Text(Localization.forceScheduleAllTasks)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "calendar.badge.exclamationmark")
                            .foregroundColor(.red)
                    }
                }
            }

            Section(footer: Text(Localization.cancelTasksDescription)) {
                Button(action: {
                    viewModel.cancelAllBackgroundTasks()
                }) {
                    HStack {
                        Text(Localization.cancelAllTasks)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }

                Button(action: {
                    viewModel.cancelFullSyncTask()
                }) {
                    HStack {
                        Text(Localization.cancelFullSyncTask)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.orange)
                    }
                }

                Button(action: {
                    viewModel.cancelIncrementalSyncTask()
                }) {
                    HStack {
                        Text(Localization.cancelIncrementalSyncTask)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.orange)
                    }
                }

                Button(action: {
                    viewModel.cancelMainAppRefreshTask()
                }) {
                    HStack {
                        Text(Localization.cancelMainAppRefreshTask)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.orange)
                    }
                }
            }
#endif
        }
        .background(Color(.listForeground(modal: false)))
        .listStyle(.grouped)
        .navigationTitle(Localization.title)
    }
}

private enum Localization {
    static let title = NSLocalizedString("Experimental Features", comment: "Experimental features navigation title")

#if DEBUG
    static let posSyncTestingDescription = NSLocalizedString(
        "POS Catalog Sync Testing - Trigger background sync operations and view detailed logs to understand timing and behavior.",
        comment: "Description for POS catalog sync testing section in beta features")

    static let triggerFullSync = NSLocalizedString(
        "Trigger Full Catalog Sync",
        comment: "Button to trigger a full POS catalog sync for testing")

    static let triggerIncrementalSync = NSLocalizedString(
        "Trigger Incremental Sync",
        comment: "Button to trigger an incremental POS catalog sync for testing")

    static let logSyncStatus = NSLocalizedString(
        "Log Current Sync Status",
        comment: "Button to log current POS sync status for debugging")

    static let forceScheduleFullSync = NSLocalizedString(
        "Force Schedule Full Sync",
        comment: "Button to force schedule full catalog sync task for debugging")

    static let forceScheduleIncrementalSync = NSLocalizedString(
        "Force Schedule Incremental Sync",
        comment: "Button to force schedule incremental catalog sync task for debugging")

    static let forceScheduleMainAppRefresh = NSLocalizedString(
        "Force Schedule Main App Refresh",
        comment: "Button to force schedule main app refresh task for debugging")

    static let forceScheduleAllTasks = NSLocalizedString(
        "Force Schedule ALL Tasks",
        comment: "Button to force schedule all background tasks at once for debugging")

    static let cancelTasksDescription = NSLocalizedString(
        "Cancel Background Tasks - Remove scheduled tasks from the iOS background task queue for testing purposes.",
        comment: "Description for cancel background tasks section in beta features")

    static let cancelAllTasks = NSLocalizedString(
        "Cancel ALL Tasks",
        comment: "Button to cancel all scheduled background tasks")

    static let cancelFullSyncTask = NSLocalizedString(
        "Cancel Full Sync Task",
        comment: "Button to cancel full catalog sync background task")

    static let cancelIncrementalSyncTask = NSLocalizedString(
        "Cancel Incremental Sync Task",
        comment: "Button to cancel incremental sync background task")

    static let cancelMainAppRefreshTask = NSLocalizedString(
        "Cancel Main App Refresh Task",
        comment: "Button to cancel main app refresh background task")
#endif
}

struct BetaFeaturesConfiguration_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BetaFeaturesConfiguration(viewModel: .init())
        }
    }
}
