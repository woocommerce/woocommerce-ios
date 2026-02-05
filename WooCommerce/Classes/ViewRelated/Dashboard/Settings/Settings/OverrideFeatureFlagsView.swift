import SwiftUI
import Experiments
import Networking
import Yosemite

struct OverrideFeatureFlagsView: View {
    @State private var refreshID = UUID()
    @State private var searchText = ""
    private let defaultFeatureFlagService = DefaultFeatureFlagService()

    private var filteredFeatureFlags: [FeatureFlag] {
        let allFlags = FeatureFlag.allCases
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return allFlags
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allFlags.filter { $0.title.lowercased().contains(query) }
    }

    private var filteredRemoteFeatureFlags: [RemoteFeatureFlag] {
        let allFlags = RemoteFeatureFlag.allCases
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return allFlags
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allFlags.filter { $0.title.lowercased().contains(query) }
    }

    var body: some View {
        List {
            Section("Remote Feature Flags") {
                ForEach(filteredRemoteFeatureFlags, id: \.self) { flag in
                    RemoteFeatureFlagRow(featureFlag: flag)
                }
            }

            Section("Local Feature Flags") {
                ForEach(filteredFeatureFlags, id: \.self) { flag in
                    FeatureFlagRow(
                        featureFlag: flag,
                        defaultFeatureFlagService: defaultFeatureFlagService
                    )
                }
            }
        }
        .contentMargins(20)
        .id(refreshID)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search feature flags")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    ServiceLocator.featureFlagOverrideStore.removeAllOverrides()
                    refreshID = UUID()
                } label: {
                    Text("Reset All")
                }
            }
        }
        .navigationTitle("Override Feature Flags")
    }
}

#Preview {
    OverrideFeatureFlagsView()
}

fileprivate struct FeatureFlagRow: View {
    let featureFlag: FeatureFlag
    private let defaultFeatureFlagService: DefaultFeatureFlagService

    init(featureFlag: FeatureFlag,
         defaultFeatureFlagService: DefaultFeatureFlagService) {
        self.featureFlag = featureFlag
        self.defaultFeatureFlagService = defaultFeatureFlagService
        _overrideValue = State(initialValue: ServiceLocator.featureFlagOverrideStore.overrideValue(for: featureFlag))
    }

    @State private var overrideValue: Bool?

    private var defaultValue: Bool {
        defaultFeatureFlagService.isFeatureFlagEnabled(featureFlag)
    }

    private var effectiveValue: Bool {
        overrideValue ?? defaultValue
    }

    private var isOverridden: Bool {
        overrideValue != nil
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(featureFlag.title)
                        .font(.body)
                }

                Text("Default: \(defaultValue ? "Enabled" : "Disabled")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if isOverridden {
                    Button("Reset") {
                        resetValue()
                    }
                    .disabled(!isOverridden)
                    .font(.caption)
                }
            }

            Spacer()

            Toggle(isOn: Binding(
                get: { effectiveValue },
                set: { newValue in
                    if newValue == defaultValue {
                        resetValue()
                    } else {
                        overrideValue = newValue
                        ServiceLocator.featureFlagOverrideStore.setOverrideValue(newValue, for: featureFlag)
                    }
                }
            )) { EmptyView() }
        }
    }

    private func resetValue() {
            overrideValue = nil
            ServiceLocator.featureFlagOverrideStore.setOverrideValue(nil, for: featureFlag)
    }
}

fileprivate struct RemoteFeatureFlagRow: View {
    let featureFlag: RemoteFeatureFlag
    let stores: StoresManager

    init(featureFlag: RemoteFeatureFlag,
         stores: StoresManager = ServiceLocator.stores) {
        self.featureFlag = featureFlag
        self.stores = stores
        _overrideValue = State(initialValue: ServiceLocator.remoteFeatureFlagOverrideStore?.overrideValue(for: featureFlag))
    }

    @State private var overrideValue: Bool?
    @State private var remoteValue: Bool?

    private var effectiveValue: Bool {
        overrideValue ?? remoteValue ?? false
    }

    private var isOverridden: Bool {
        overrideValue != nil
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(featureFlag.title)
                        .font(.body)
                }

                if isOverridden {
                    Text("Overridden")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if let remoteValue {
                    Text("Remote: \(remoteValue ? "Enabled" : "Disabled")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Remote: Loading...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if isOverridden {
                    Button("Reset") {
                        resetValue()
                    }
                    .font(.caption)
                }
            }

            Spacer()

            Toggle(isOn: Binding(
                get: { effectiveValue },
                set: { newValue in
                    overrideValue = newValue
                    ServiceLocator.remoteFeatureFlagOverrideStore?.setOverrideValue(newValue, for: featureFlag)
                }
            )) { EmptyView() }
        }
        .onAppear {
            fetchRemoteValueIfNeeded()
        }
    }

    private func fetchRemoteValueIfNeeded() {
        // Only fetch if no override is set, since the store returns override value when set
        guard overrideValue == nil else { return }

        let action = FeatureFlagAction.isRemoteFeatureFlagEnabled(featureFlag, defaultValue: false, useCache: true) { value in
            self.remoteValue = value
        }
        stores.dispatch(action)
    }

    private func resetValue() {
        overrideValue = nil
        ServiceLocator.remoteFeatureFlagOverrideStore?.setOverrideValue(nil, for: featureFlag)
        // Fetch remote value now that override is cleared
        fetchRemoteValueIfNeeded()
    }
}

fileprivate extension FeatureFlag {
    var title: String {
        return String(describing: self)
    }
}

fileprivate extension RemoteFeatureFlag {
    var title: String {
        return String(describing: self)
    }
}
