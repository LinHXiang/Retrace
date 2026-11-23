import Foundation
import Defaults
import Fuse

class Search {
  enum Mode: String, CaseIterable, Identifiable, CustomStringConvertible, Defaults.Serializable {
    case exact
    case fuzzy
    case regexp
    case mixed

    var id: Self { self }

    var description: String {
      switch self {
      case .exact:
        return NSLocalizedString("Exact", tableName: "GeneralSettings", comment: "")
      case .fuzzy:
        return NSLocalizedString("Fuzzy", tableName: "GeneralSettings", comment: "")
      case .regexp:
        return NSLocalizedString("Regex", tableName: "GeneralSettings", comment: "")
      case .mixed:
        return NSLocalizedString("Mixed", tableName: "GeneralSettings", comment: "")
      }
    }
  }

  struct SearchResult: Equatable {
    var score: Double?
    var object: Searchable
    var aliasMatch = false
    var ranges: [Range<String.Index>] = []
  }

  typealias Searchable = CommandHistoryItemDecorator

  private let fuse = Fuse(threshold: 0.7) // threshold found by trial-and-error
  private let fuzzySearchLimit = 5_000

  func search(string: String, within: [Searchable]) -> [SearchResult] {
    guard !string.isEmpty else {
      return within.map { SearchResult(object: $0) }
    }

    switch Defaults[.searchMode] {
    case .mixed:
      return mixedSearch(string: string, within: within)
    case .regexp:
      return simpleSearch(string: string, within: within, options: .regularExpression)
    case .fuzzy:
      return fuzzySearch(string: string, within: within)
    default:
      return simpleSearch(string: string, within: within, options: .caseInsensitive)
    }
  }

  private func fuzzySearch(string: String, within: [Searchable]) -> [SearchResult] {
    let pattern = fuse.createPattern(from: string)
    let searchResults: [SearchResult] = within.compactMap { item in
      let command = fuzzySearch(for: pattern, in: item.title, of: item)
      guard let alias = item.favorite?.alias, !alias.isEmpty,
            var result = fuzzySearch(for: pattern, in: alias, of: item) else { return command }
      result.aliasMatch = true
      return (result.score ?? 0) <= (command?.score ?? .infinity) ? result : command
    }
    let sortedResults = searchResults.sorted(by: { ($0.score ?? 0) < ($1.score ?? 0) })
    return sortedResults
  }

  private func fuzzySearch(
    for pattern: Fuse.Pattern?,
    in searchString: String,
    of item: Searchable
  ) -> SearchResult? {
    var searchString = searchString
    if searchString.count > fuzzySearchLimit {
      // shortcut to avoid slow search
      let stopIndex = searchString.index(searchString.startIndex, offsetBy: fuzzySearchLimit)
      searchString = "\(searchString[...stopIndex])"
    }

    if let fuzzyResult = fuse.search(pattern, in: searchString) {
      return SearchResult(
        score: fuzzyResult.score,
        object: item,
        ranges: fuzzyResult.ranges.map {
          let startIndex = searchString.startIndex
          let lowerBound = searchString.index(startIndex, offsetBy: $0.lowerBound)
          let upperBound = searchString.index(startIndex, offsetBy: $0.upperBound + 1)

          return lowerBound..<upperBound
        }
      )
    } else {
      return nil
    }
  }

  private func simpleSearch(
    string: String,
    within: [Searchable],
    options: NSString.CompareOptions
  ) -> [SearchResult] {
    within.compactMap { item in
      if let alias = item.favorite?.alias, !alias.isEmpty,
         var result = simpleSearch(for: string, in: alias, of: item, options: options) {
        result.aliasMatch = true
        return result
      }
      if let result = simpleSearch(for: string, in: item.title, of: item, options: options) { return result }
      // Search the original command even when its list title is shortened or escaped.
      if let raw = item.item.command, raw != item.title, raw.range(of: string, options: options) != nil {
        return SearchResult(object: item)
      }
      return nil
    }
  }

  private func simpleSearch(
    for string: String,
    in searchString: String,
    of item: Searchable,
    options: NSString.CompareOptions
  ) -> SearchResult? {
    if let range = searchString.range(of: string, options: options, range: nil, locale: nil) {
      return SearchResult(object: item, ranges: [range])
    } else {
      return nil
    }
  }

  private func mixedSearch(string: String, within: [Searchable]) -> [SearchResult] {
    var results = simpleSearch(string: string, within: within, options: .caseInsensitive)
    guard results.isEmpty else {
      return results
    }

    results = simpleSearch(string: string, within: within, options: [.regularExpression, .caseInsensitive])
    guard results.isEmpty else {
      return results
    }

    results = fuzzySearch(string: string, within: within)
    guard results.isEmpty else {
      return results
    }

    return []
  }
}
