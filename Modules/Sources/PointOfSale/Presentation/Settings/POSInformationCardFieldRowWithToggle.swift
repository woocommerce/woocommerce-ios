import SwiftUI

struct POSInformationCardFieldRowWithToggle: View {
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
        VStack(alignment: .leading, spacing: POSPadding.small) {
            HStack(alignment: .center, spacing: POSSpacing.medium) {
                VStack(alignment: .leading, spacing: POSPadding.small) {
                    Text(label)
                        .font(.posBodyMediumBold)
                    Text(value)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: $isOn)
                    .toggleStyle(SwitchToggleStyle())
                    .tint(Color.posPrimaryContainer)
            }

            if showSeparator {
                Divider()
                    .padding(.top, POSPadding.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
