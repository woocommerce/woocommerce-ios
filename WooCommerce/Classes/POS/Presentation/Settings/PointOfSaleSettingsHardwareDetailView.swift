import SwiftUI

struct PointOfSaleSettingsHardwareDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var navigationPath: [PointOfSaleSettingsView.HardwareDestination] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List(PointOfSaleSettingsView.HardwareDestination.allCases) { destination in
                NavigationLink(value: destination) {
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: destination.icon)
                            .font(.posBodyLargeRegular())
                        VStack(alignment: .leading, spacing: POSPadding.xSmall) {
                            Text(destination.title)
                                .font(.posBodyLargeRegular())
                            Text(destination.subtitle)
                                .font(.posBodyMediumRegular())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationDestination(for: PointOfSaleSettingsView.HardwareDestination.self) { destination in
                VStack(spacing: POSSpacing.medium) {
                    Image(systemName: destination.icon).font(.largeTitle)
                        .font(.posBodyLargeRegular())
                    Text("\(destination.title) settings")
                        .font(.posBodyMediumRegular())
                    Text("Some placeholder")
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(.secondary)
                }
                .padding()
                .navigationTitle(destination.title)
            }
        }
    }
}
