import SwiftUI
import Experiments

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

    var body: some View {
        List {
            ForEach(filteredFeatureFlags, id: \.self) { flag in
                FeatureFlagRow(
                    featureFlag: flag,
                    defaultFeatureFlagService: defaultFeatureFlagService
                )
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

fileprivate extension FeatureFlag {
    var title: String {
        return String(describing: self)
    }
}
