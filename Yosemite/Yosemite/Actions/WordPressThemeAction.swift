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

    /// Retrieves the current theme for a site.
    /// - `siteID`: ID of the current site.
    /// - `onCompletion`: invoked when the sync operation finishes.
    ///     - `result.success(WordPressTheme)`: the current theme's details.
    ///     - `result.failure(Error)`: error indicates issues loading themes.
    ///
    case loadCurrentTheme(siteID: Int64, onCompletion: (Result<WordPressTheme, Error>) -> Void)
}
