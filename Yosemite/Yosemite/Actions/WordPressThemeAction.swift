import Foundation
import struct Networking.WordPressTheme

// MARK: - WordPressThemeAction: Defines all of the Actions supported by the WordPressThemeStore.
//
public enum WordPressThemeAction: Action {

    /// Retrieves the suggested themes for a site.
    ///
    /// - `onCompletion`: invoked when the sync operation finishes.
    ///     - `result.success([WordPressTheme])`: list of suggested themes.
    ///     - `result.failure(Error)`: error indicates issues loading themes.
    ///
    case loadSuggestedThemes(onCompletion: (Result<[WordPressTheme], Error>) -> Void)
}
