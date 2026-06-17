import SwiftUI

struct ShellSyntaxHighlighter {
  static func apply(_ attr: inout AttributedString, for command: String) {
    let chars = Array(command)
    var i = 0
    var isFirstWord = true

    func endPos(_ offset: Int) -> String.Index {
      command.index(command.startIndex, offsetBy: min(offset, command.count))
    }

    func color(_ range: Range<String.Index>, _ color: Color, italic: Bool = false) {
      guard let lo = AttributedString.Index(range.lowerBound, within: attr),
            let hi = AttributedString.Index(range.upperBound, within: attr) else { return }
      attr[lo..<hi].foregroundColor = color
      if italic { attr[lo..<hi].font = Font.body.italic() }
    }

    while i < chars.count {
      let ch = chars[i]
      let sPos = command.index(command.startIndex, offsetBy: i)

      if ch.isWhitespace { i += 1; continue }

      // comment  # ...
      if ch == "#" {
        color(sPos..<command.endIndex, .secondary, italic: true)
        break
      }

      // double-quoted string "..."
      if ch == "\"" {
        i += 1
        while i < chars.count {
          if chars[i] == "\"" { i += 1; break }
          if chars[i] == "\\" { i += 1 }
          i += 1
        }
        color(sPos..<endPos(i), .orange)
        continue
      }

      // single-quoted string '...'
      if ch == "'" {
        i += 1
        while i < chars.count && chars[i] != "'" { i += 1 }
        if i < chars.count { i += 1 }
        color(sPos..<endPos(i), .orange)
        continue
      }

      // variable  $VAR  ${VAR}
      if ch == "$" {
        i += 1
        if i < chars.count && chars[i] == "{" {
          i += 1
          while i < chars.count && chars[i] != "}" { i += 1 }
          if i < chars.count { i += 1 }
        } else {
          while i < chars.count && (chars[i].isLetter || chars[i].isNumber || chars[i] == "_") { i += 1 }
        }
        color(sPos..<endPos(i), .purple)
        continue
      }

      // operator  |  >  <  &  ;
      if "|><&;".contains(ch) {
        var end = i + 1
        if (ch == "|" || ch == "&" || ch == ">") && i + 1 < chars.count && chars[i + 1] == ch {
          end = i + 2
        }
        color(sPos..<endPos(end), .secondary)
        i = end
        isFirstWord = true
        continue
      }

      // flag  -x  --xxx
      if ch == "-" && i + 1 < chars.count && !chars[i + 1].isWhitespace && chars[i + 1] != "-" {
        i += 1
        while i < chars.count && !chars[i].isWhitespace && !"|><&;#".contains(chars[i]) { i += 1 }
        color(sPos..<endPos(i), .teal)
        continue
      }
      if ch == "-" && i + 1 < chars.count && chars[i + 1] == "-" {
        i += 2
        while i < chars.count && !chars[i].isWhitespace && !"|><&;#".contains(chars[i]) { i += 1 }
        color(sPos..<endPos(i), .teal)
        continue
      }

      // regular word — first one is the command
      i += 1
      while i < chars.count && !chars[i].isWhitespace && !"|><&;#".contains(chars[i]) { i += 1 }
      if isFirstWord {
        color(sPos..<endPos(i), .green)
        isFirstWord = false
      }
    }
  }
}
