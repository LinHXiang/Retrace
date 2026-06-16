import XCTest
import Defaults
@testable import Retrace

class SearchTests: XCTestCase {
  let savedSearchMode = Defaults[.searchMode]
  var items: [Search.Searchable]!

  override func tearDown() {
    super.tearDown()
    Defaults[.searchMode] = savedSearchMode
  }

  func testTerminalCommandHistoryParsesExtendedZshHistory() {
    let entries = TerminalCommandHistory.parse("""
    : 1710000000:0;git status
    : 1710000002:0;git status
    : 1710000001:0;brew update
    """)

    XCTAssertEqual(entries.map(\.command), ["git status", "brew update"])
    XCTAssertEqual(entries[0].timestamp, Date(timeIntervalSince1970: 1710000002))
    XCTAssertEqual(entries[0].order, 1710000002)
  }

  func testTerminalCommandHistoryParsesPlainZshHistory() {
    let entries = TerminalCommandHistory.parse("""
    git status
    brew update
    git status
    """)

    XCTAssertEqual(entries.map(\.command), ["git status", "brew update"])
    XCTAssertNil(entries[0].timestamp)
    XCTAssertEqual(entries[0].order, 2)
  }

  @MainActor
  func testSimpleSearchMatchesCommonQueries() {
    Defaults[.searchMode] = Search.Mode.exact
    prepareSearchItems()

    XCTAssertEqual(search(""), [
      Search.SearchResult(score: nil, object: items[0], ranges: []),
      Search.SearchResult(score: nil, object: items[1], ranges: []),
      Search.SearchResult(score: nil, object: items[2], ranges: [])
    ])
    XCTAssertEqual(search("z"), [
      Search.SearchResult(
        score: nil,
        object: items[0],
        ranges: [range(startOffset: 10, endOffset: 10, in: items[0])]
      ),
      Search.SearchResult(
        score: nil,
        object: items[1],
        ranges: [range(startOffset: 8, endOffset: 8, in: items[1])]
      ),
      Search.SearchResult(
        score: nil,
        object: items[2],
        ranges: [range(startOffset: 8, endOffset: 8, in: items[2])]
      )
    ])
    XCTAssertEqual(search("foo"), [
      Search.SearchResult(
        score: nil,
        object: items[0],
        ranges: [range(startOffset: 0, endOffset: 2, in: items[0])]
      ),
      Search.SearchResult(
        score: nil,
        object: items[1],
        ranges: [range(startOffset: 0, endOffset: 2, in: items[1])]
      )
    ])
  }

  @MainActor
  func testSimpleSearchRejectsFuzzyQueries() {
    Defaults[.searchMode] = Search.Mode.exact
    prepareSearchItems()

    XCTAssertEqual(search("za"), [
      Search.SearchResult(
        score: nil,
        object: items[1],
        ranges: [range(startOffset: 8, endOffset: 9, in: items[1])]
      )
    ])
    XCTAssertEqual(search("yyy"), [
      Search.SearchResult(
        score: nil,
        object: items[2],
        ranges: [range(startOffset: 4, endOffset: 6, in: items[2])]
      )
    ])
    XCTAssertEqual(search("fbb"), [])
    XCTAssertEqual(search("m"), [])
  }

  @MainActor
  func testFuzzySearchMatchesCommonQueries() {
    Defaults[.searchMode] = Search.Mode.fuzzy
    prepareSearchItems()

    XCTAssertEqual(search(""), [
      Search.SearchResult(score: nil, object: items[0], ranges: []),
      Search.SearchResult(score: nil, object: items[1], ranges: []),
      Search.SearchResult(score: nil, object: items[2], ranges: [])
    ])
    XCTAssertEqual(search("z"), [
      Search.SearchResult(
        score: 0.08,
        object: items[1],
        ranges: [range(startOffset: 8, endOffset: 8, in: items[1]), range(startOffset: 10, endOffset: 10, in: items[1])]
      ),
      Search.SearchResult(
        score: 0.08,
        object: items[2],
        ranges: [range(startOffset: 8, endOffset: 10, in: items[2])]
      ),
      Search.SearchResult(
        score: 0.1,
        object: items[0],
        ranges: [range(startOffset: 10, endOffset: 10, in: items[0])]
      )
    ])
    XCTAssertEqual(search("foo"), [
      Search.SearchResult(
        score: 0.0,
        object: items[0],
        ranges: [range(startOffset: 0, endOffset: 2, in: items[0])]
      ),
      Search.SearchResult(
        score: 0.0,
        object: items[1],
        ranges: [range(startOffset: 0, endOffset: 2, in: items[1])]
      )
    ])
  }

  @MainActor
  func testFuzzySearchMatchesLooseQueries() {
    Defaults[.searchMode] = Search.Mode.fuzzy
    prepareSearchItems()

    XCTAssertEqual(search("za"), [
      Search.SearchResult(
        score: 0.08,
        object: items[1],
        ranges: [range(startOffset: 5, endOffset: 5, in: items[1]), range(startOffset: 8, endOffset: 9, in: items[1])]
      ),
      Search.SearchResult(
        score: 0.54,
        object: items[0],
        ranges: [range(startOffset: 5, endOffset: 5, in: items[0]), range(startOffset: 9, endOffset: 10, in: items[0])]
      ),
      Search.SearchResult(
        score: 0.58,
        object: items[2],
        ranges: [range(startOffset: 8, endOffset: 10, in: items[2])]
      )
    ])
    XCTAssertEqual(search("yyy"), [
      Search.SearchResult(
        score: 0.04,
        object: items[2],
        ranges: [range(startOffset: 4, endOffset: 6, in: items[2])]
      )
    ])
    XCTAssertEqual(search("fbb"), [
      Search.SearchResult(
        score: 0.6666666666666666,
        object: items[0],
        ranges: [
          range(startOffset: 0, endOffset: 0, in: items[0]),
          range(startOffset: 4, endOffset: 4, in: items[0]),
          range(startOffset: 8, endOffset: 8, in: items[0])
        ]
      ),
      Search.SearchResult(
        score: 0.6666666666666666,
        object: items[1],
        ranges: [range(startOffset: 0, endOffset: 0, in: items[1]), range(startOffset: 4, endOffset: 4, in: items[1])])
    ])
    XCTAssertEqual(search("m"), [])
  }

  @MainActor
  func testRegexpSearchMatchesQuantifiers() {
    Defaults[.searchMode] = Search.Mode.regexp
    prepareSearchItems()

    XCTAssertEqual(search(""), [
      Search.SearchResult(score: nil, object: items[0], ranges: []),
      Search.SearchResult(score: nil, object: items[1], ranges: []),
      Search.SearchResult(score: nil, object: items[2], ranges: [])
    ])
    XCTAssertEqual(search("z+"), [
      Search.SearchResult(
        score: nil,
        object: items[0],
        ranges: [range(startOffset: 10, endOffset: 10, in: items[0])]
      ),
      Search.SearchResult(
        score: nil,
        object: items[1],
        ranges: [range(startOffset: 8, endOffset: 8, in: items[1])]
      ),
      Search.SearchResult(
        score: nil,
        object: items[2],
        ranges: [range(startOffset: 8, endOffset: 10, in: items[2])]
      )
    ])
    XCTAssertEqual(search("z*"), [
      Search.SearchResult(
        score: nil,
        object: items[0],
        ranges: [range(startOffset: 0, endOffset: -1, in: items[0])]
      ),
      Search.SearchResult(
        score: nil,
        object: items[1],
        ranges: [range(startOffset: 0, endOffset: -1, in: items[1])]
      ),
      Search.SearchResult(
        score: nil,
        object: items[2],
        ranges: [range(startOffset: 0, endOffset: -1, in: items[2])]
      )
    ])
  }

  @MainActor
  func testRegexpSearchMatchesAnchorsAndCharacterClasses() {
    Defaults[.searchMode] = Search.Mode.regexp
    prepareSearchItems()

    XCTAssertEqual(search("^foo"), [
      Search.SearchResult(
        score: nil,
        object: items[0], ranges: [range(startOffset: 0, endOffset: 2, in: items[0])]
      ),
      Search.SearchResult(
        score: nil,
        object: items[1], ranges: [range(startOffset: 0, endOffset: 2, in: items[1])]
      )
    ])
    XCTAssertEqual(search(" za"), [
      Search.SearchResult(
        score: nil,
        object: items[1],
        ranges: [range(startOffset: 7, endOffset: 9, in: items[1])]
      )
    ])
    XCTAssertEqual(search("[y]+"), [
      Search.SearchResult(
        score: nil,
        object: items[2],
        ranges: [range(startOffset: 4, endOffset: 6, in: items[2])]
      )
    ])
    XCTAssertEqual(search("fbb"), [])
    XCTAssertEqual(search("m"), [])
  }

  private func search(_ string: String) -> [Search.SearchResult] {
    return Search().search(string: string, within: items)
  }

  @MainActor
  private func prepareSearchItems() {
    items = [
      CommandHistoryItemDecorator(commandHistoryItemWithTitle("foo bar baz")),
      CommandHistoryItemDecorator(commandHistoryItemWithTitle("foo bar zaz")),
      CommandHistoryItemDecorator(commandHistoryItemWithTitle("xxx yyy zzz"))
    ]
  }

  private func range(
    startOffset: Int,
    endOffset: Int,
    in item: CommandHistoryItemDecorator
  ) -> Range<String.Index> {
    let startIndex = item.title.startIndex
    let lowerBound = item.title.index(startIndex, offsetBy: startOffset)
    let upperBound = item.title.index(startIndex, offsetBy: endOffset + 1)

    return lowerBound..<upperBound
  }

  @MainActor
  private func commandHistoryItemWithTitle(_ value: String?) -> CommandHistoryItem {
    let item = CommandHistoryItem(command: value)
    item.title = item.generateTitle()

    return item
  }
}
