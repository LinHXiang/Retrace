import XCTest
@testable import Retrace

final class ZshIntegrationTests: XCTestCase {
  func testInstalledContentsForEmptyZshrc() {
    XCTAssertEqual(
      ZshIntegration.installedContents(from: ""),
      ZshIntegration.block + "\n"
    )
  }

  func testInstalledContentsAppendsBlockToZshrcWithoutExistingBlock() {
    let contents = "export EDITOR=vim\n"

    XCTAssertEqual(
      ZshIntegration.installedContents(from: contents),
      contents + "\n" + ZshIntegration.block + "\n"
    )
  }

  func testInstalledContentsAppendsBlockToZshrcWithoutTrailingNewline() {
    let contents = "export EDITOR=vim"

    XCTAssertEqual(
      ZshIntegration.installedContents(from: contents),
      contents + "\n\n" + ZshIntegration.block + "\n"
    )
  }

  func testInstalledContentsReplacesExistingBlock() {
    let contents = """
    export EDITOR=vim
    \(ZshIntegration.startMarker)
    old hook
    \(ZshIntegration.endMarker)
    alias gs='git status'
    """

    XCTAssertEqual(
      ZshIntegration.installedContents(from: contents),
      """
      export EDITOR=vim
      \(ZshIntegration.block)
      alias gs='git status'
      """
    )
  }

  func testIsInstalledRequiresCompleteMarkedBlock() {
    XCTAssertTrue(ZshIntegration.isInstalled(in: ZshIntegration.block))
    XCTAssertFalse(ZshIntegration.isInstalled(in: ZshIntegration.startMarker + "\nold hook\n"))
  }

  func testInstallCreatesZshrc() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let zshrc = directory.appendingPathComponent(".zshrc")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    try ZshIntegration.install(to: zshrc)

    let contents = try String(contentsOf: zshrc, encoding: .utf8)
    XCTAssertEqual(contents, ZshIntegration.block + "\n")
  }

  func testInstallAppendsBlockToExistingZshrc() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let zshrc = directory.appendingPathComponent(".zshrc")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    try "export EDITOR=vim".write(to: zshrc, atomically: true, encoding: .utf8)

    try ZshIntegration.install(to: zshrc)

    let contents = try String(contentsOf: zshrc, encoding: .utf8)
    XCTAssertEqual(contents, "export EDITOR=vim\n\n" + ZshIntegration.block + "\n")
  }

  func testClearRecordedHistoryCreatesEmptyFile() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let history = directory.appendingPathComponent("zsh_history")
    defer { try? FileManager.default.removeItem(at: directory) }

    try ZshIntegration.clearRecordedHistory(at: history)

    XCTAssertTrue(FileManager.default.fileExists(atPath: history.path))
    XCTAssertEqual(try Data(contentsOf: history), Data())
  }

  func testClearRecordedHistoryTruncatesExistingFile() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let history = directory.appendingPathComponent("zsh_history")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    try ": 1710000000:0;git status\n".write(to: history, atomically: true, encoding: .utf8)

    try ZshIntegration.clearRecordedHistory(at: history)

    XCTAssertEqual(try Data(contentsOf: history), Data())
  }

  func testDeleteRecordedHistoryRemovesOnlyRetraceFile() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let history = directory.appendingPathComponent("zsh_history")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    try ": 1710000000:0;git status\n".write(to: history, atomically: true, encoding: .utf8)

    try ZshIntegration.deleteRecordedHistory(at: history)

    XCTAssertFalse(FileManager.default.fileExists(atPath: history.path))
  }

  func testDeleteRecordedHistoryIgnoresMissingFile() throws {
    let history = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathComponent("zsh_history")

    XCTAssertNoThrow(try ZshIntegration.deleteRecordedHistory(at: history))
  }

  func testShouldPromptForLikelyZshUserWithoutBlock() {
    XCTAssertTrue(ZshIntegration.shouldPromptForInstall(
      loginShell: "/bin/zsh",
      zshHistoryExists: false,
      zshrcContents: "export EDITOR=vim\n",
      promptDismissed: false
    ))
  }

  func testShouldPromptForUserWithZshHistory() {
    XCTAssertTrue(ZshIntegration.shouldPromptForInstall(
      loginShell: "/bin/bash",
      zshHistoryExists: true,
      zshrcContents: nil,
      promptDismissed: false
    ))
  }

  func testShouldNotPromptWhenBlockIsInstalled() {
    XCTAssertFalse(ZshIntegration.shouldPromptForInstall(
      loginShell: "/bin/zsh",
      zshHistoryExists: false,
      zshrcContents: ZshIntegration.block,
      promptDismissed: false
    ))
  }

  func testShouldNotPromptWhenDismissed() {
    XCTAssertFalse(ZshIntegration.shouldPromptForInstall(
      loginShell: "/bin/zsh",
      zshHistoryExists: false,
      zshrcContents: nil,
      promptDismissed: true
    ))
  }

  func testShouldNotPromptDuringDeferredPeriod() {
    let now = Date(timeIntervalSince1970: 1_710_000_000)

    XCTAssertFalse(ZshIntegration.shouldPromptForInstall(
      loginShell: "/bin/zsh",
      zshHistoryExists: false,
      zshrcContents: nil,
      promptDismissed: false,
      promptDeferredUntil: now.addingTimeInterval(60),
      now: now
    ))
    XCTAssertTrue(ZshIntegration.shouldPromptForInstall(
      loginShell: "/bin/zsh",
      zshHistoryExists: false,
      zshrcContents: nil,
      promptDismissed: false,
      promptDeferredUntil: now.addingTimeInterval(-60),
      now: now
    ))
  }

  func testShouldNotPromptForNonZshUserWithoutZshHistory() {
    XCTAssertFalse(ZshIntegration.shouldPromptForInstall(
      loginShell: "/bin/bash",
      zshHistoryExists: false,
      zshrcContents: nil,
      promptDismissed: false
    ))
  }

  func testShouldNotPromptWithoutShellOrZshHistory() {
    XCTAssertFalse(ZshIntegration.shouldPromptForInstall(
      loginShell: nil,
      zshHistoryExists: false,
      zshrcContents: nil,
      promptDismissed: false
    ))
  }
}
