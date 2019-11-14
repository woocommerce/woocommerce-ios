import WordPressUI

/// Style for ghosting that does not show calles with a white background.
///
extension GhostStyle {
    static var wooDefaultGhostStyle: Self {
        return GhostStyle(beatDuration: Defaults.beatDuration,
                          beatStartColor: .listForeground,
                          beatEndColor: .textTertiary)
    }
}
