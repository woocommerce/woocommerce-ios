import SwiftUI

struct ToneOfVoiceView: View {
    @ObservedObject var viewModel: AIToneVoiceViewModel

    var body: some View {
        AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .center) {
            Text(Localization.title)
                .bodyStyle()

            Spacer()

            Menu {
                ForEach(viewModel.tones, id: \.self) { tone in
                    Button(tone.description) {
                        viewModel.onSelectTone(tone)
                    }
                }
            } label: {
                HStack(alignment: .center, spacing: Layout.hSpacing) {
                    Text(viewModel.selectedTone.description)
                        .foregroundStyle(Color.accentColor)
                        .bodyStyle()

                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(Color.accentColor)
                        .bodyStyle()
                }
            }
        }
    }
}

private extension ToneOfVoiceView {
    enum Layout {
        static let hSpacing: CGFloat = 4
    }

    enum Localization {
        static let title = NSLocalizedString(
            "toneOfVoiceView.title",
            value: "Tone of voice",
            comment: "Title of the AI tone selection button."
        )
    }
}
