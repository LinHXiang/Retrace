import Foundation

enum ZshIntegration {
  static let startMarker = "# >>> Retrace zsh integration >>>"
  static let endMarker = "# <<< Retrace zsh integration <<<"

  static let block = """
  # >>> Retrace zsh integration >>>
  autoload -Uz add-zsh-hook
  zmodload zsh/datetime 2>/dev/null

  _retrace_preexec() {
    local dir="$HOME/Library/Application Support/Retrace"
    mkdir -p "$dir" || return
    print -r -- ": ${EPOCHSECONDS}:0;$1" >> "$dir/zsh_history"
  }

  add-zsh-hook preexec _retrace_preexec
  # <<< Retrace zsh integration <<<
  """

  static var zshrcURL: URL {
    FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".zshrc")
  }

  static func isInstalled(in contents: String) -> Bool {
    markedBlockRange(in: contents) != nil
  }

  static func installedContents(from contents: String) -> String {
    if let range = markedBlockRange(in: contents) {
      var result = contents
      result.replaceSubrange(range, with: block)
      return result
    }

    guard !contents.isEmpty else {
      return block + "\n"
    }

    let separator = contents.hasSuffix("\n") ? "\n" : "\n\n"
    return contents + separator + block + "\n"
  }

  static func install(to url: URL = zshrcURL) throws {
    let contents: String
    if FileManager.default.fileExists(atPath: url.path) {
      let data = try Data(contentsOf: url)
      contents = String(decoding: data, as: UTF8.self)
    } else {
      contents = ""
    }

    let updatedContents = installedContents(from: contents)
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try updatedContents.write(to: url, atomically: true, encoding: .utf8)
  }

  private static func markedBlockRange(in contents: String) -> Range<String.Index>? {
    guard let start = contents.range(of: startMarker),
          let end = contents.range(
            of: endMarker,
            range: start.upperBound..<contents.endIndex
          ) else {
      return nil
    }

    return start.lowerBound..<end.upperBound
  }
}
