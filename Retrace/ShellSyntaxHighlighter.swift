import SwiftUI

struct ShellSyntaxHighlighter {
  static func apply(_ attr: inout AttributedString, for command: String) {
    let chars = Array(command)
    var i = 0
    var isFirstWord = true

    func color(_ range: Range<String.Index>, _ color: Color, italic: Bool = false) {
      guard let lo = AttributedString.Index(range.lowerBound, within: attr),
            let hi = AttributedString.Index(range.upperBound, within: attr) else { return }
      attr[lo..<hi].foregroundColor = color
      if italic { attr[lo..<hi].font = Font.body.italic() }
    }

    while i < chars.count {
      let ch = chars[i]
      let startPos = command.index(command.startIndex, offsetBy: i)

      if ch.isWhitespace { i += 1; continue }

      // comment  # ...
      if ch == "#" {
        color(startPos..<command.endIndex, .secondary, italic: true)
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
        color(startPos..<command.index(command.startIndex, offsetBy: i), .orange)
        continue
      }

      // single-quoted string '...'
      if ch == "'" {
        i += 1
        while i < chars.count && chars[i] != "'" { i += 1 }
        if i < chars.count { i += 1 }
        color(startPos..<command.index(command.startIndex, offsetBy: i), .orange)
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
        color(startPos..<command.index(command.startIndex, offsetBy: i), .purple)
        continue
      }

      // operator  |  >  <  &  ;
      if "|><&;".contains(ch) {
        var end = i + 1
        if (ch == "|" || ch == "&" || ch == ">") && i + 1 < chars.count && chars[i + 1] == ch {
          end = i + 2
        }
        color(startPos..<command.index(command.startIndex, offsetBy: end), .secondary)
        i = end
        isFirstWord = true
        continue
      }

      // flag  -x  --xxx
      if ch == "-" && i + 1 < chars.count && !chars[i + 1].isWhitespace && chars[i + 1] != "-" {
        i += 1
        while i < chars.count && !chars[i].isWhitespace && !"|><&;#".contains(chars[i]) { i += 1 }
        color(startPos..<command.index(command.startIndex, offsetBy: i), .teal)
        continue
      }
      if ch == "-" && i + 1 < chars.count && chars[i + 1] == "-" {
        i += 2
        while i < chars.count && !chars[i].isWhitespace && !"|><&;#".contains(chars[i]) { i += 1 }
        color(startPos..<command.index(command.startIndex, offsetBy: i), .teal)
        continue
      }

      // regular word — first one is the command
      i += 1
      while i < chars.count && !chars[i].isWhitespace && !"|><&;#".contains(chars[i]) { i += 1 }
      if isFirstWord {
        color(startPos..<command.index(command.startIndex, offsetBy: i), .green)
        isFirstWord = false
      }
    }
  }
}
