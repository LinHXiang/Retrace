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
    defer { try? FileManager.default.removeItem(at: directory) }

    try ZshIntegration.install(to: zshrc)

    let contents = try String(contentsOf: zshrc, encoding: .utf8)
    XCTAssertEqual(contents, ZshIntegration.block + "\n")
  }
}
