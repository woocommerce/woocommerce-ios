import Foundation

// MARK: - DomainAction: Defines all of the Actions supported by the DomainStore.
//
public enum DomainAction: Action {
    case loadFreeDomainSuggestions(query: String, completion: (Result<[FreeDomainSuggestion], Error>) -> Void)
}
