import SwiftUI

struct ScenarioPickerView: View {
    let scenarios: [any POSPrototypeScenario]

    @State private var selectedScenarioID: String?

    var body: some View {
        NavigationStack {
            List(scenarios, id: \.id) { scenario in
                Button {
                    selectScenario(scenario.id)
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: scenario.icon)
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 40, height: 40)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(scenario.name)
                                .font(.headline)
                            Text(scenario.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("POS Lab")
            .fullScreenCover(isPresented: showCoverBinding) {
                if let scenario = selectedScenario {
                    PrototypeContainerView(scenario: scenario)
                }
            }
            .onAppear {
                // Auto-restore last scenario on launch
                if PrototypeStateRestoration.isAutoRestoreEnabled,
                   let savedID = PrototypeStateRestoration.savedScenarioID,
                   scenarios.contains(where: { $0.id == savedID }) {
                    selectedScenarioID = savedID
                }
            }
        }
    }

    private func selectScenario(_ id: String) {
        selectedScenarioID = id
        PrototypeStateRestoration.savedScenarioID = id
    }

    private var showCoverBinding: Binding<Bool> {
        Binding(
            get: { selectedScenarioID != nil },
            set: { isPresented in
                if !isPresented {
                    selectedScenarioID = nil
                }
            }
        )
    }

    private var selectedScenario: (any POSPrototypeScenario)? {
        scenarios.first { $0.id == selectedScenarioID }
    }
}
