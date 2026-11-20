import SwiftUI

struct POSInformationCardFieldRowWithToggle: View {
    @Environment(\.posMetrics) private var metrics
    let label: String
    let value: String
    let showSeparator: Bool
    @Binding var isOn: Bool

    init(label: String,
         value: String,
         showSeparator: Bool = true,
         isOn: Binding<Bool>) {
        self.label = label
        self.value = value
        self.showSeparator = showSeparator
        self._isOn = isOn
    }

    var body: some View {
        VStack(alignment: .leading, spacing: metrics.padding.small) {
            HStack(alignment: .center, spacing: metrics.spacing.medium) {
                VStack(alignment: .leading, spacing: metrics.padding.small) {
                    Text(label)
                        .font(.posBodyMediumBold)
                    Text(value)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle(label, isOn: $isOn)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle())
                    .tint(Color.posPrimaryContainer)
            }

            if showSeparator {
                Divider()
                    .padding(.top, metrics.padding.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
