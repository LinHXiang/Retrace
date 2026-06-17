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

enum ShellHistoryKind: String, CaseIterable, Identifiable, Codable, Defaults.Serializable {
  case zsh
  case bash
  case fish
  case plain

  var id: Self { self }

  var description: String {
    switch self {
    case .zsh:
      return "zsh"
    case .bash:
      return "bash"
    case .fish:
      return "fish"
    case .plain:
      return "Plain"
    }
  }

  static func infer(from url: URL) -> Self {
    switch url.lastPathComponent {
    case ".zsh_history":
      return .zsh
    case ".bash_history":
      return .bash
    case "fish_history":
      return .fish
    default:
      return .plain
    }
  }
}

struct HistorySource: Identifiable, Hashable, Codable, Defaults.Serializable {
  var id: UUID
  var kind: ShellHistoryKind
  var url: URL
  var isEnabled: Bool

  init(id: UUID = UUID(), kind: ShellHistoryKind, url: URL, isEnabled: Bool = true) {
    self.id = id
    self.kind = kind
    self.url = url
    self.isEnabled = isEnabled
  }

  static var defaultSources: [HistorySource] {
    let home = FileManager.default.homeDirectoryForCurrentUser
    return [
      HistorySource(kind: .zsh, url: home.appendingPathComponent(".zsh_history")),
      HistorySource(kind: .bash, url: home.appendingPathComponent(".bash_history")),
      HistorySource(kind: .fish, url: home.appendingPathComponent(".local/share/fish/fish_history"))
    ]
  }
}

struct TerminalCommandHistory {
  var sources: [HistorySource] = Defaults[.historySources]

  func load() throws -> [TerminalCommandHistoryEntry] {
    var entries: [TerminalCommandHistoryEntry] = []

    for source in readableSources {
      guard let data = try? Data(contentsOf: source.url) else { continue }

      let contents = String(decoding: data, as: UTF8.self)
      entries.append(contentsOf: Self.parse(contents, kind: source.kind))
    }

    return Self.deduplicate(entries)
  }

  func modificationDate() throws -> Date {
    readableSources
      .compactMap { source -> Date? in
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: source.url.path) else {
          return nil
        }

        return attributes[.modificationDate] as? Date
      }
      .max() ?? .distantPast
  }

  var readableSources: [HistorySource] {
    sources.filter {
      $0.isEnabled && FileManager.default.isReadableFile(atPath: $0.url.path)
    }
  }

  static func parse(_ contents: String, kind: ShellHistoryKind = .zsh) -> [TerminalCommandHistoryEntry] {
    switch kind {
    case .zsh:
      return parseZsh(contents)
    case .bash:
      return parseBash(contents)
    case .fish:
      return parseFish(contents)
    case .plain:
      return parsePlain(contents)
    }
  }

  private static func parseZsh(_ contents: String) -> [TerminalCommandHistoryEntry] {
    var entries: [TerminalCommandHistoryEntry] = []
    var pendingExtendedEntry: TerminalCommandHistoryEntry?
    var pendingPlainCommand: String?
    var pendingPlainOrder = 0

    func flushPendingExtendedEntry() {
      guard let entry = pendingExtendedEntry else { return }

      entries.append(entry)
      pendingExtendedEntry = nil
    }

    func flushPendingPlainCommand() {
      guard let command = normalizedCommand(pendingPlainCommand ?? "") else {
        pendingPlainCommand = nil
        return
      }

      entries.append(TerminalCommandHistoryEntry(
        command: command,
        timestamp: nil,
        order: TimeInterval(pendingPlainOrder)
      ))
      pendingPlainCommand = nil
    }

    var lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
    if lines.last?.isEmpty == true {
      lines.removeLast()
    }

    for (index, line) in lines.enumerated() {
      let line = String(line)

      if let entry = parseZshExtendedLine(line, fallbackOrder: index) {
        flushPendingExtendedEntry()
        flushPendingPlainCommand()
        pendingExtendedEntry = entry
        continue
      }

      if let entry = pendingExtendedEntry {
        pendingExtendedEntry = TerminalCommandHistoryEntry(
          command: "\(entry.command)\n\(line)",
          timestamp: entry.timestamp,
          order: entry.order
        )
        continue
      }

      if pendingPlainCommand != nil {
        pendingPlainCommand = "\(pendingPlainCommand ?? "")\n\(line)"
        if !hasLineContinuation(line) {
          flushPendingPlainCommand()
        }
        continue
      }

      guard normalizedCommand(line) != nil else { continue }

      if hasLineContinuation(line) {
        pendingPlainCommand = line
        pendingPlainOrder = index
      } else if let entry = plainEntry(line, fallbackOrder: index) {
        entries.append(entry)
      }
    }

    flushPendingExtendedEntry()
    flushPendingPlainCommand()
    return deduplicate(entries)
  }

  private static func parseBash(_ contents: String) -> [TerminalCommandHistoryEntry] {
    var entries: [TerminalCommandHistoryEntry] = []
    var pendingTimestamp: Date?

    for (index, line) in contents.split(separator: "\n", omittingEmptySubsequences: true).enumerated() {
      let line = String(line)
      if let timestamp = bashTimestamp(line) {
        pendingTimestamp = timestamp
        continue
      }

      guard let command = normalizedCommand(line) else { continue }
      entries.append(TerminalCommandHistoryEntry(
        command: command,
        timestamp: pendingTimestamp,
        order: pendingTimestamp?.timeIntervalSince1970 ?? TimeInterval(index)
      ))
      pendingTimestamp = nil
    }

    return deduplicate(entries)
  }

  private static func parseFish(_ contents: String) -> [TerminalCommandHistoryEntry] {
    var entries: [TerminalCommandHistoryEntry] = []
    var pendingCommand: String?
    var pendingTimestamp: Date?
    var pendingOrder = 0

    func flush() {
      guard let command = pendingCommand else { return }

      entries.append(TerminalCommandHistoryEntry(
        command: command,
        timestamp: pendingTimestamp,
        order: pendingTimestamp?.timeIntervalSince1970 ?? TimeInterval(pendingOrder)
      ))
      pendingCommand = nil
      pendingTimestamp = nil
    }

    for (index, line) in contents.split(separator: "\n", omittingEmptySubsequences: true).enumerated() {
      let line = String(line)

      if line.hasPrefix("- cmd: ") {
        flush()
        pendingCommand = normalizedCommand(String(line.dropFirst("- cmd: ".count)))?
          .replacingOccurrences(of: "\\n", with: "\n")
        pendingOrder = index
        continue
      }

      let trimmedLine = line.trimmingCharacters(in: .whitespaces)
      if trimmedLine.hasPrefix("when: "),
         let epoch = TimeInterval(String(trimmedLine.dropFirst("when: ".count))) {
        pendingTimestamp = Date(timeIntervalSince1970: epoch)
      }
    }

    flush()
    return deduplicate(entries)
  }

  private static func parsePlain(_ contents: String) -> [TerminalCommandHistoryEntry] {
    deduplicate(
      contents.split(separator: "\n", omittingEmptySubsequences: true).enumerated().compactMap {
        plainEntry(String($0.element), fallbackOrder: $0.offset)
      }
    )
  }

  private static func deduplicate(_ entries: [TerminalCommandHistoryEntry]) -> [TerminalCommandHistoryEntry] {
    var latestByCommand: [String: TerminalCommandHistoryEntry] = [:]

    for entry in entries {
      if let existing = latestByCommand[entry.command], existing.order >= entry.order {
        continue
      }

      latestByCommand[entry.command] = entry
    }

    return latestByCommand.values.sorted { $0.order > $1.order }
  }

  private static func parseZshLine(_ line: String, fallbackOrder: Int) -> TerminalCommandHistoryEntry? {
    guard line.hasPrefix(": ") else {
      return plainEntry(line, fallbackOrder: fallbackOrder)
    }

    return parseZshExtendedLine(line, fallbackOrder: fallbackOrder)
  }

  private static func parseZshExtendedLine(_ line: String, fallbackOrder: Int) -> TerminalCommandHistoryEntry? {
    guard line.hasPrefix(": ") else {
      return nil
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

  private static func plainEntry(_ line: String, fallbackOrder: Int) -> TerminalCommandHistoryEntry? {
    guard let command = normalizedCommand(line) else { return nil }

    return TerminalCommandHistoryEntry(
      command: command,
      timestamp: nil,
      order: TimeInterval(fallbackOrder)
    )
  }

  private static func normalizedCommand(_ line: String) -> String? {
    let command = line.trimmingCharacters(in: .whitespacesAndNewlines)
    return command.isEmpty ? nil : command
  }

  private static func hasLineContinuation(_ line: String) -> Bool {
    line.trimmingCharacters(in: .whitespaces).hasSuffix("\\")
  }

  private static func bashTimestamp(_ line: String) -> Date? {
    guard line.hasPrefix("#") else { return nil }

    let rawTimestamp = String(line.dropFirst())
    guard !rawTimestamp.isEmpty,
          rawTimestamp.allSatisfy(\.isNumber),
          let epoch = TimeInterval(rawTimestamp) else { return nil }

    return Date(timeIntervalSince1970: epoch)
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
  private var loadedHistoryModificationDate: Date?

  @ObservationIgnored
  private var fileMonitorSources: [DispatchSourceFileSystemObject] = []

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
    fileMonitorSources.forEach { $0.cancel() }
    fileMonitorSources = []

    for sourceURL in TerminalCommandHistory().readableSources.map(\.url) {
      let fd = open(sourceURL.path, O_EVTONLY)
      guard fd >= 0 else { continue }

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

      fileMonitorSources.append(source)
      source.resume()
    }
  }

  @MainActor
  func loadIfChanged() async throws {
    guard !isLoading else { return }
    isLoading = true
    defer { isLoading = false }

    let history = TerminalCommandHistory()
    let modificationDate = try await modificationDate(for: history)
    guard modificationDate != loadedHistoryModificationDate else { return }

    try await load(history: history, modificationDate: modificationDate)
  }

  @MainActor
  func load() async throws {
    let history = TerminalCommandHistory()
    try await load(history: history, modificationDate: try await modificationDate(for: history))
  }

  @MainActor
  private func load(history: TerminalCommandHistory, modificationDate: Date) async throws {
    let entries = try await entries(for: history)
    let pinnedCommands = Set(Defaults[.pinnedCommands])
    let visibleEntries = entries.enumerated().compactMap { index, entry in
      index < Defaults[.commandHistorySize] || pinnedCommands.contains(entry.command) ? entry : nil
    }

    all = visibleEntries.map { entry in
      let item = CommandHistoryItem(command: entry.command)
      if let timestamp = entry.timestamp {
        item.recordedAt = timestamp
      }
      item.title = item.generateTitle()
      let decorator = CommandHistoryItemDecorator(item, showsRecordedAt: entry.timestamp != nil)
      decorator.isPinned = isPinned(item)
      return decorator
    }
    all = sortPinnedFirst(all)
    items = all
    loadedHistoryModificationDate = modificationDate

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
  func reloadSources() async {
    loadedHistoryModificationDate = nil
    startFileMonitoring()
    try? await load()
  }

  private func modificationDate(for history: TerminalCommandHistory) async throws -> Date {
    try await Task.detached(priority: .userInitiated) {
      try history.modificationDate()
    }.value
  }

  private func entries(for history: TerminalCommandHistory) async throws -> [TerminalCommandHistoryEntry] {
    try await Task.detached(priority: .userInitiated) {
      try history.load()
    }.value
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
    items = sortPinnedFirst(newItems.map { result in
      let item = result.object
      item.highlight(searchQuery, result.ranges)

      return item
    })

    updateVisibleShortcuts()
    AppState.shared.appDelegate?.updateStatusItemTitle()
  }

  @MainActor
  func togglePinSelectedItem() {
    guard let selectedItem = AppState.shared.navigator.selectedCommandItem,
          let command = selectedItem.item.command else { return }

    var pinnedCommands = Defaults[.pinnedCommands]
    if let index = pinnedCommands.firstIndex(of: command) {
      pinnedCommands.remove(at: index)
    } else {
      pinnedCommands.insert(command, at: 0)
    }

    Defaults[.pinnedCommands] = pinnedCommands
    updatePinnedState()
    all = sortPinnedFirst(all)
    items = sortPinnedFirst(items)
    updateVisibleShortcuts()
    AppState.shared.navigator.select(item: selectedItem)
    AppState.shared.popup.needsResize = true
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

  private func updatePinnedState() {
    for item in all {
      item.isPinned = isPinned(item.item)
    }
  }

  private func sortPinnedFirst(_ items: [CommandHistoryItemDecorator]) -> [CommandHistoryItemDecorator] {
    let pinnedCommands = Defaults[.pinnedCommands]
    guard !pinnedCommands.isEmpty else { return items }

    let pinnedOrder = Dictionary(uniqueKeysWithValues: pinnedCommands.enumerated().map { ($1, $0) })
    return items.enumerated().sorted { lhs, rhs in
      let lhsOrder = lhs.element.item.command.flatMap { pinnedOrder[$0] }
      let rhsOrder = rhs.element.item.command.flatMap { pinnedOrder[$0] }

      switch (lhsOrder, rhsOrder) {
      case let (lhsOrder?, rhsOrder?):
        return lhsOrder < rhsOrder
      case (_?, nil):
        return true
      case (nil, _?):
        return false
      case (nil, nil):
        return lhs.offset < rhs.offset
      }
    }.map(\.element)
  }

  private func isPinned(_ item: CommandHistoryItem) -> Bool {
    guard let command = item.command else { return false }
    return Defaults[.pinnedCommands].contains(command)
  }
}
