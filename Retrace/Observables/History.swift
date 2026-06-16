import AppKit
import Defaults
import Foundation
import Logging
import Observation
import Sauce

struct TerminalCommandHistoryEntry: Equatable {
  let command: String
  let timestamp: Date
}

struct TerminalCommandHistory {
  var historyFileURL: URL = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".zsh_history")

  func load() throws -> [TerminalCommandHistoryEntry] {
    let data = try Data(contentsOf: historyFileURL)
    let contents = String(decoding: data, as: UTF8.self)
    return Self.parse(contents)
  }

  static func parse(_ contents: String) -> [TerminalCommandHistoryEntry] {
    var latestByCommand: [String: TerminalCommandHistoryEntry] = [:]

    for (index, line) in contents.split(separator: "\n", omittingEmptySubsequences: true).enumerated() {
      guard let entry = parseLine(String(line), fallbackOrder: index) else {
        continue
      }

      if let existing = latestByCommand[entry.command], existing.timestamp >= entry.timestamp {
        continue
      }

      latestByCommand[entry.command] = entry
    }

    return latestByCommand.values.sorted { $0.timestamp > $1.timestamp }
  }

  private static func parseLine(_ line: String, fallbackOrder: Int) -> TerminalCommandHistoryEntry? {
    guard line.hasPrefix(": ") else {
      let command = line.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !command.isEmpty else { return nil }

      return TerminalCommandHistoryEntry(
        command: command,
        timestamp: Date(timeIntervalSince1970: TimeInterval(fallbackOrder))
      )
    }

    let body = line.dropFirst(2)
    guard let timestampEnd = body.firstIndex(of: ":"),
          let commandStart = body[timestampEnd...].firstIndex(of: ";"),
          let epoch = TimeInterval(String(body[..<timestampEnd])) else {
      return nil
    }

    let command = body[body.index(after: commandStart)...]
      .trimmingCharacters(in: .whitespacesAndNewlines)
    guard !command.isEmpty else { return nil }

    return TerminalCommandHistoryEntry(
      command: command,
      timestamp: Date(timeIntervalSince1970: epoch)
    )
  }
}

@Observable
class History: ItemsContainer {
  static let shared = History()
  let logger = Logger(label: "com.freeorz.retrace")

  var items: [HistoryItemDecorator] = []
  var searchQuery: String = "" {
    didSet {
      throttler.throttle { [self] in
        updateItems(search.search(string: searchQuery, within: all))

        if searchQuery.isEmpty {
          AppState.shared.navigator.select(item: unpinnedItems.first)
        } else {
          AppState.shared.navigator.highlightFirst()
        }

        AppState.shared.popup.needsResize = true
      }
    }
  }

  var pinnedItems: [HistoryItemDecorator] { [] }
  var unpinnedItems: [HistoryItemDecorator] { items }

  var pressedShortcutItem: HistoryItemDecorator? {
    guard let event = NSApp.currentEvent else {
      return nil
    }

    let modifierFlags = event.modifierFlags
      .intersection(.deviceIndependentFlagsMask)
      .subtracting(.capsLock)

    guard HistoryItemAction(modifierFlags) != .unknown else {
      return nil
    }

    let key = Sauce.shared.key(for: Int(event.keyCode))
    return items.first { $0.shortcuts.contains(where: { $0.key == key }) }
  }

  private let search = Search()
  private let throttler = Throttler(minimumDelay: 0.2)

  @ObservationIgnored
  var all: [HistoryItemDecorator] = []

  init() {
    Task {
      for await _ in Defaults.updates(.pasteByDefault, initial: false) {
        updateShortcuts()
      }
    }

    Task {
      for await _ in Defaults.updates(.showSpecialSymbols, initial: false) {
        for item in items {
          await updateTitle(item: item, title: item.item.generateTitle())
        }
      }
    }
  }

  @MainActor
  func load() async throws {
    let entries = try TerminalCommandHistory().load()
    all = entries.prefix(Defaults[.size]).map { entry in
      let item = HistoryItem(contents: [
        HistoryItemContent(
          type: NSPasteboard.PasteboardType.string.rawValue,
          value: entry.command.data(using: .utf8)
        )
      ])
      item.firstCopiedAt = entry.timestamp
      item.lastCopiedAt = entry.timestamp
      item.title = item.generateTitle()
      return HistoryItemDecorator(item)
    }
    items = all

    updateShortcuts()
    Task {
      AppState.shared.popup.needsResize = true
    }
  }

  @MainActor
  func clear() {
    all.removeAll()
    items.removeAll()

    AppState.shared.popup.close()
    Task {
      AppState.shared.popup.needsResize = true
    }
  }

  @MainActor
  func clearAll() {
    clear()
  }

  @MainActor
  func delete(_ item: HistoryItemDecorator?) {
    guard let item else { return }

    all.removeAll { $0 == item }
    items.removeAll { $0 == item }

    updateUnpinnedShortcuts()
    Task {
      AppState.shared.popup.needsResize = true
    }
  }

  @MainActor
  func select(_ item: HistoryItemDecorator?) {
    guard let item else {
      return
    }

    AppState.shared.popup.close()
    Clipboard.shared.copy(item.item)

    Task {
      searchQuery = ""
    }
  }

  private func updateItems(_ newItems: [Search.SearchResult]) {
    items = newItems.map { result in
      let item = result.object
      item.highlight(searchQuery, result.ranges)

      return item
    }

    updateUnpinnedShortcuts()
  }

  private func updateShortcuts() {
    updateUnpinnedShortcuts()
  }

  @MainActor
  private func updateTitle(item: HistoryItemDecorator, title: String) {
    item.title = title
    item.item.title = title
  }

  private func updateUnpinnedShortcuts() {
    let visibleUnpinnedItems = unpinnedItems.filter(\.isVisible)
    for item in visibleUnpinnedItems {
      item.shortcuts = []
    }

    var index = 1
    for item in visibleUnpinnedItems.prefix(9) {
      item.shortcuts = KeyShortcut.create(character: String(index))
      index += 1
    }
  }
}
