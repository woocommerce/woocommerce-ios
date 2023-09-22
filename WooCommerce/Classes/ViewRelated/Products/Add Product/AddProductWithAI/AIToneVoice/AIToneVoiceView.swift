import SwiftUI

/// View to select AI tone and voice
///
struct AIToneVoiceView: View {
    @StateObject private var viewModel: AIToneVoiceViewModel

    @Environment(\.presentationMode) private var presentation

    init(viewModel: AIToneVoiceViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.blockVerticalSpacing) {
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
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        presentation.wrappedValue.dismiss()
                    }, label: {
                        Image(systemName: "chevron.backward")
                            .headlineLinkStyle()
                    })
                }
            })
            .navigationViewStyle(StackNavigationViewStyle())
            .wooNavigationBarStyle()
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
