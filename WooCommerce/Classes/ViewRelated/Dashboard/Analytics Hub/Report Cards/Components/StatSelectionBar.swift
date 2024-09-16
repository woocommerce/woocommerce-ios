import SwiftUI

struct StatSelectionBar<Stat: Hashable>: View {

    /// List of all available stats
    let allStats: [Stat]

    /// Key path to find the stat title to be displayed
    let titleKeyPath: KeyPath<Stat, String>

    /// Callback for selection
    let onSelection: ((Stat) -> Void)?

    /// Currently selected stat
    @Binding var selectedStat: Stat

    var body: some View {
        HStack {
            AdaptiveStack(horizontalAlignment: .leading) {
                Text(Localization.metric)
                    .foregroundStyle(Color.primary)
                    .subheadlineStyle()
                Text(selectedStat[keyPath: titleKeyPath])
                    .subheadlineStyle()
            }
            Spacer()
            Menu {
                ForEach(allStats, id: \.self) { stat in
                    Button {
                        selectedStat = stat
                        onSelection?(stat)
                    } label: {
                        SelectableItemRow(title: stat[keyPath: titleKeyPath], selected: stat == selectedStat)
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .foregroundStyle(Color(.secondaryLabel))
            }

        }
    }
}

private enum Localization {
    static let metric = NSLocalizedString("analyticsHub.statSelectionBar.metricLabel",
                                          value: "Metric",
                                          comment: "Label for the selected metric on an analytics card in the Analytics Hub.")
}

#Preview {
    StatSelectionBar<String>(allStats: ["Total Sales", "Spend", "Clicks", "Conversions"],
                             titleKeyPath: \.self,
                             onSelection: nil,
                             selectedStat: .constant("Total Sales"))
}
