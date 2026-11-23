import Defaults
import Foundation

struct FavoriteCommand: Codable, Equatable, Defaults.Serializable {
  let command: String
  var alias: String
  let savedAt: Date

  init(command: String, alias: String, savedAt: Date = Date()) {
    self.command = command
    self.alias = alias.trimmingCharacters(in: .whitespacesAndNewlines)
    self.savedAt = savedAt
  }

  static func entries(history: [TerminalCommandHistoryEntry], favorites: [Self], pins: Set<String>, limit: Int) -> [TerminalCommandHistoryEntry] {
    let kept = pins.union(favorites.map(\.command))
    var entries = history.enumerated().compactMap { index, entry in
      index < limit || kept.contains(entry.command) ? entry : nil
    }
    var seen = Set(entries.map(\.command))
    for favorite in favorites where seen.insert(favorite.command).inserted {
      entries.append(.init(command: favorite.command, timestamp: nil, order: 0))
    }
    return entries
  }
}

extension Defaults.Keys {
  static let favorites = Key<[FavoriteCommand]>("favorites", default: [])
}
