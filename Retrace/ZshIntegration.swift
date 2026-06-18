import Darwin
import Foundation

enum ZshIntegration {
  static let startMarker = "# >>> Retrace zsh integration >>>"
  static let endMarker = "# <<< Retrace zsh integration <<<"
  static let displayHistoryPath = "~/Library/Application Support/Retrace/zsh_history"

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

  static var userZshHistoryURL: URL {
    FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".zsh_history")
  }

  static func isInstalled(in contents: String) -> Bool {
    markedBlockRange(in: contents) != nil
  }

  static func isInstalled(at url: URL = zshrcURL) -> Bool {
    guard let data = try? Data(contentsOf: url) else { return false }

    return isInstalled(in: String(decoding: data, as: UTF8.self))
  }

  static func shouldPromptForInstall(
    loginShell: String?,
    zshHistoryExists: Bool,
    zshrcContents: String?,
    promptDismissed: Bool,
    promptDeferredUntil: Date = .distantPast,
    now: Date = .now
  ) -> Bool {
    guard !promptDismissed else { return false }
    guard now >= promptDeferredUntil else { return false }
    guard loginShell?.hasSuffix("/zsh") == true || zshHistoryExists else { return false }

    if let zshrcContents {
      return !isInstalled(in: zshrcContents)
    }

    return true
  }

  static func shouldPromptForInstall(
    zshrcURL: URL = zshrcURL,
    userZshHistoryURL: URL = userZshHistoryURL,
    promptDismissed: Bool,
    promptDeferredUntil: Date
  ) -> Bool {
    let zshrcContents = (try? Data(contentsOf: zshrcURL)).map {
      String(decoding: $0, as: UTF8.self)
    }

    return shouldPromptForInstall(
      loginShell: loginShell(),
      zshHistoryExists: FileManager.default.fileExists(atPath: userZshHistoryURL.path),
      zshrcContents: zshrcContents,
      promptDismissed: promptDismissed,
      promptDeferredUntil: promptDeferredUntil
    )
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
    try updatedContents.write(to: url, atomically: true, encoding: .utf8)
  }

  private static func loginShell() -> String? {
    if let shell = ProcessInfo.processInfo.environment["SHELL"] {
      return shell
    }

    var password = passwd()
    var result: UnsafeMutablePointer<passwd>?
    let fallbackBufferSize = 16_384
    let suggestedBufferSize = sysconf(_SC_GETPW_R_SIZE_MAX)
    let bufferSize = suggestedBufferSize > 0 ? Int(suggestedBufferSize) : fallbackBufferSize
    var buffer = [CChar](repeating: 0, count: bufferSize)

    let status = getpwuid_r(getuid(), &password, &buffer, buffer.count, &result)
    if status == 0, let result, let shell = result.pointee.pw_shell {
      return String(cString: shell)
    }

    return nil
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
