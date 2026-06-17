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
class CommandHistory: ItemsContainer {
  static let shared = CommandHistory()

  var items: [CommandHistoryItemDecorator] = []
  var searchQuery: String = "" {
    didSet {
      throttler.throttle { [self] in
        Task { @MainActor in
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
  }

  var pressedShortcutItem: CommandHistoryItemDecorator? {
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
  var all: [CommandHistoryItemDecorator] = []

  @ObservationIgnored
  private var loadedHistoryFileModificationDate: Date?

  @ObservationIgnored
  private var fileMonitorSource: DispatchSourceFileSystemObject?

  @ObservationIgnored
  private var isLoading = false

  init() {
    Task {
      for await _ in Defaults.updates(.showSpecialSymbols, initial: false) {
        for item in items {
          await updateTitle(item: item, title: item.item.generateTitle())
        }
        await AppState.shared.appDelegate?.updateStatusItemTitle()
      }
    }
    startFileMonitoring()
  }

  private func startFileMonitoring() {
    let fd = open(TerminalCommandHistory().historyFileURL.path, O_EVTONLY)
    guard fd >= 0 else { return }

    let source = DispatchSource.makeFileSystemObjectSource(
      fileDescriptor: fd,
      eventMask: [.write, .extend],
      queue: .main
    )

    source.setEventHandler { [weak self] in
      guard let self else { return }
      Task { @MainActor in
        try? await self.loadIfChanged()
      }
    }

    source.setCancelHandler { close(fd) }

    fileMonitorSource?.cancel()
    fileMonitorSource = source
    source.resume()
  }

  @MainActor
  func loadIfChanged() async throws {
    guard !isLoading else { return }
    isLoading = true
    defer { isLoading = false }

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
    all = entries.prefix(Defaults[.commandHistorySize]).map { entry in
      let item = CommandHistoryItem(command: entry.command)
      if let timestamp = entry.timestamp {
        item.recordedAt = timestamp
      }
      item.title = item.generateTitle()
      return CommandHistoryItemDecorator(item, showsRecordedAt: entry.timestamp != nil)
    }
    items = all
    loadedHistoryFileModificationDate = modificationDate

    for item in items {
      item.highlight("", [])
    }

    updateVisibleShortcuts()
    AppState.shared.appDelegate?.updateStatusItemTitle()
    Task {
      AppState.shared.popup.needsResize = true
    }
  }

  @MainActor
  func select(_ item: CommandHistoryItemDecorator?) {
    guard let item else {
      return
    }

    AppState.shared.popup.close()
    CommandPasteboard.shared.copy(item.item)

    Task {
      searchQuery = ""
    }
  }

  @MainActor
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
  private func updateTitle(item: CommandHistoryItemDecorator, title: String) {
    item.title = title
    item.item.title = title
  }

  private func updateVisibleShortcuts() {
    let visibleCommandItems = visibleItems
    for item in visibleCommandItems {
      item.shortcuts = []
    }

    var index = 1
    for item in visibleCommandItems.prefix(9) {
      item.shortcuts = KeyShortcut.create(character: String(index))
      index += 1
    }
  }
}
