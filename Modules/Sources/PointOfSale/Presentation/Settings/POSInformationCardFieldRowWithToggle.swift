import SwiftUI

/// A row with a label, a description and a trailing switch. Tapping anywhere on the row toggles the switch,
/// and the row is presented to accessibility as a single switch.
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
            Button {
                isOn.toggle()
            } label: {
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
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle())
                        .tint(Color.posPrimaryContainer)
                        // The row handles the tap, so the switch must not toggle a second time.
                        .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityRepresentation {
                Toggle(isOn: $isOn) {
                    Text(label)
                    Text(value)
                }
            }

            if showSeparator {
                Divider()
                    .padding(.top, POSPadding.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
