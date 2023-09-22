import SwiftUI

/// View to select AI tone and voice
///
struct AIToneVoiceView: View {
    @ObservedObject private var viewModel: AIToneVoiceViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: AIToneVoiceViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.blockVerticalSpacing) {
                titleBlock

                // Subtitle label.
                Text(Localization.subtitle)
                    .foregroundColor(Color(.secondaryLabel))
                    .bodyStyle()
                    .padding(.horizontal, Layout.subtitleExtraHorizontalPadding)

                // List of AI tones.
                ForEach(viewModel.tones, id: \.self) { tone in
                    VStack(alignment: .leading, spacing: 0) {
                        SelectableItemRow(
                            title: tone.rawValue,
                            selected: tone == viewModel.selectedTone,
                            displayMode: .compact,
                            alignment: .trailing)
                        .onTapGesture {
                            viewModel.onSelectTone(tone)
                        }

                        Divider()
                    }
                }

                Spacer()
            }
            .padding(Layout.defaultPadding)
        }
    }
}

private extension AIToneVoiceView {
    var titleBlock: some View {
        ZStack {
            HStack {
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "chevron.backward")
                        .headlineLinkStyle()
                })

                Spacer()
            }
            .padding(.horizontal, Layout.backButtonHorizontalPadding)

            VStack(spacing: 0) {
                HStack {
                    Spacer()

                    Text(Localization.title)
                        .fontWeight(.semibold)
                        .headlineStyle()

                    Spacer()
                }
                .padding(.vertical, Layout.titleVerticalPadding)

                Divider()
            }
        }
    }
}

private extension AIToneVoiceView {
    enum Localization {
        static let title = NSLocalizedString("Tone and voice",
                                             comment: "Title of the AI tone and voice selection sheet.")

        static let subtitle = NSLocalizedString("Set the tone and voice to shape your product's presentation that aligns with your brand.",
                                                comment: "Subtitle of the AI tone and voice selection sheet.")
    }

    enum Layout {
        static let backButtonHorizontalPadding: CGFloat = 16
        static let titleVerticalPadding: CGFloat = 16
        static let blockVerticalSpacing: CGFloat = 16
        static let defaultPadding: EdgeInsets = .init(top: 16, leading: 8, bottom: 16, trailing: 8)
        static let subtitleExtraHorizontalPadding: CGFloat = 8
    }
}

struct AIToneVoiceView_Previews: PreviewProvider {
    static var previews: some View {
        AIToneVoiceView(viewModel: .init(siteID: 123))
    }
}
