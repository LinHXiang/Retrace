import Defaults
import XCTest
@testable import Retrace

final class FavoriteTests: XCTestCase {
  let command = "printf '%s' \\\n   '你好'  "

  func testSnapshotSurvivesHistoryReplacementAndSerialization() throws {
    let favorite = FavoriteCommand(command: command, alias: "  部署预览  ")
    let restored = try JSONDecoder().decode(FavoriteCommand.self, from: JSONEncoder().encode(favorite))
    XCTAssertEqual(restored.alias, "部署预览")
    let entries = FavoriteCommand.entries(history: [], favorites: [restored], pins: [], limit: 0)
    XCTAssertEqual(entries.map(\.command), [command])
    XCTAssertNil(entries.first?.timestamp)
  }

  func testLimitAndPinsDoNotDuplicateFavorites() {
    let favorite = FavoriteCommand(command: command, alias: "")
    let history = ["git status", command, "date"].map { TerminalCommandHistoryEntry(command: $0, timestamp: nil, order: 0) }
    XCTAssertEqual(FavoriteCommand.entries(history: history, favorites: [favorite], pins: [command], limit: 1).map(\.command), ["git status", command])
  }

  func testAliasAndOriginalSearchInEveryMode() {
    let saved = Defaults[.searchMode]
    defer { Defaults[.searchMode] = saved }
    let item = CommandHistoryItem(command: command)
    item.title = item.generateTitle()
    let row = CommandHistoryItemDecorator(item)
    row.favorite = .init(command: command, alias: "部署预览")
    for mode in Search.Mode.allCases {
      Defaults[.searchMode] = mode
      let alias = Search().search(string: "部署", within: [row])
      XCTAssertEqual(alias.first?.aliasMatch, true)
      XCTAssertEqual(Search().search(string: "printf", within: [row]).first?.object.item.command, command)
    }
  }

  func testFavoriteKeysPreservePinShortcut() {
    XCTAssertEqual(KeyChord(.d, [.command]), .editFavorite)
    XCTAssertEqual(KeyChord(.f, [.command, .shift]), .toggleFavorites)
    XCTAssertEqual(KeyChord(.p, [.command]), .togglePin)
  }
}
