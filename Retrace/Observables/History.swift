import AppKit
import Defaults
import Foundation
import Observation
import Sauce

struct TerminalCommandHistoryEntry: Equatable {
  let command: String
  let timestamp: Date?
  let order: TimeInterval
}

struct TerminalCommandHistory {
  var historyFileURL: URL = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".zsh_history")

  func load() throws -> [TerminalCommandHistoryEntry] {
    let data = try Data(contentsOf: historyFileURL)
    let contents = String(decoding: data, as: UTF8.self)
    return Self.parse(contents)
  }

  func modificationDate() throws -> Date {
    let attributes = try FileManager.default.attributesOfItem(atPath: historyFileURL.path)
    return attributes[.modificationDate] as? Date ?? .distantPast
  }

  static func parse(_ contents: String) -> [TerminalCommandHistoryEntry] {
    var latestByCommand: [String: TerminalCommandHistoryEntry] = [:]

    for (index, line) in contents.split(separator: "\n", omittingEmptySubsequences: true).enumerated() {
      guard let entry = parseLine(String(line), fallbackOrder: index) else {
        continue
      }

      if let existing = latestByCommand[entry.command], existing.order >= entry.order {
        continue
      }

      latestByCommand[entry.command] = entry
    }

    return latestByCommand.values.sorted { $0.order > $1.order }
  }

  private static func parseLine(_ line: String, fallbackOrder: Int) -> TerminalCommandHistoryEntry? {
    guard line.hasPrefix(": ") else {
      let command = line.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !command.isEmpty else { return nil }

      return TerminalCommandHistoryEntry(
        command: command,
        timestamp: nil,
        order: TimeInterval(fallbackOrder)
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

    let timestamp = Date(timeIntervalSince1970: epoch)
    return TerminalCommandHistoryEntry(
      command: command,
      timestamp: timestamp,
      order: epoch
    )
  }
}

@Observable
class History: ItemsContainer {
  static let shared = History()

  var items: [HistoryItemDecorator] = []
  var searchQuery: String = "" {
    didSet {
      throttler.throttle { [self] in
        updateItems(search.search(string: searchQuery, within: all))

        if searchQuery.isEmpty {
          AppState.shared.navigator.select(item: visibleItems.first)
        } else {
          AppState.shared.navigator.highlightFirst()
        }

        AppState.shared.popup.needsResize = true
      }
    }
  }

  var pressedShortcutItem: HistoryItemDecorator? {
    guard let event = NSApp.currentEvent else {
      return nil
    }

    let modifierFlags = event.modifierFlags
      .intersection(.deviceIndependentFlagsMask)
      .subtracting(.capsLock)

    guard modifierFlags == .command else {
      return nil
    }

    let key = Sauce.shared.key(for: Int(event.keyCode))
    return items.first { $0.shortcuts.contains(where: { $0.key == key }) }
  }

  private let search = Search()
  private let throttler = Throttler(minimumDelay: 0.2)

  @ObservationIgnored
  var all: [HistoryItemDecorator] = []

  @ObservationIgnored
  private var loadedHistoryFileModificationDate: Date?

  init() {
    Task {
      for await _ in Defaults.updates(.showSpecialSymbols, initial: false) {
        for item in items {
          await updateTitle(item: item, title: item.item.generateTitle())
        }
        AppState.shared.appDelegate?.updateStatusItemTitle()
      }
    }
  }

  @MainActor
  func loadIfChanged() async throws {
    let history = TerminalCommandHistory()
    let modificationDate = try history.modificationDate()
    guard modificationDate != loadedHistoryFileModificationDate else { return }

    try await load(history: history, modificationDate: modificationDate)
  }

  @MainActor
  func load() async throws {
    let history = TerminalCommandHistory()
    try await load(history: history, modificationDate: try history.modificationDate())
  }

  @MainActor
  private func load(history: TerminalCommandHistory, modificationDate: Date) async throws {
    let entries = try history.load()
    all = entries.prefix(Defaults[.size]).map { entry in
      let item = HistoryItem(command: entry.command)
      if let timestamp = entry.timestamp {
        item.recordedAt = timestamp
      }
      item.title = item.generateTitle()
      return HistoryItemDecorator(item, showsRecordedAt: entry.timestamp != nil)
    }
    items = all
    loadedHistoryFileModificationDate = modificationDate

    updateVisibleShortcuts()
    AppState.shared.appDelegate?.updateStatusItemTitle()
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

    updateVisibleShortcuts()
    AppState.shared.appDelegate?.updateStatusItemTitle()
  }

  @MainActor
  private func updateTitle(item: HistoryItemDecorator, title: String) {
    item.title = title
    item.item.title = title
  }

  private func updateVisibleShortcuts() {
    let visibleHistoryItems = visibleItems
    for item in visibleHistoryItems {
      item.shortcuts = []
    }

    var index = 1
    for item in visibleHistoryItems.prefix(9) {
      item.shortcuts = KeyShortcut.create(character: String(index))
      index += 1
    }
  }
}
