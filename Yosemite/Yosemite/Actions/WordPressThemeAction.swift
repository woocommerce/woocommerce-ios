import Foundation
import struct Networking.WordPressTheme

// MARK: - WordPressThemeAction: Defines all of the Actions supported by the WordPressThemeStore.
//
public enum WordPressThemeAction: Action {

    /// Retrieves the suggested themes for a site.
    ///
    /// - `onCompletion`: invoked when the sync operation finishes.
    ///     - `result.success(Bool)`: value indicates whether there are further pages to retrieve.
    ///     - `result.failure(Error)`: error indicates issues syncing the specified page.
    ///
    case fetchSuggestedThemes(onCompletion: (Result<[WordPressTheme], Error>) -> Void)
}
