import SwiftUI

struct ShellSyntaxHighlighter {
  private enum Palette {
    static let command = color(0x40d080)
    static let string = color(0xe09040)
    static let variable = color(0x801070)
    static let flag = color(0x20b0c0)
    static let operatorToken = color(0xdbded8)
    static let comment = color(0x685656)

    private static func color(_ hex: Int) -> Color {
      Color(
        red: Double((hex >> 16) & 0xff) / 255,
        green: Double((hex >> 8) & 0xff) / 255,
        blue: Double(hex & 0xff) / 255
      )
    }
  }

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
        color(sPos..<command.endIndex, Palette.comment, italic: true)
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
        color(sPos..<endPos(i), Palette.string)
        continue
      }

      // single-quoted string '...'
      if ch == "'" {
        i += 1
        while i < chars.count && chars[i] != "'" { i += 1 }
        if i < chars.count { i += 1 }
        color(sPos..<endPos(i), Palette.string)
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
        color(sPos..<endPos(i), Palette.variable)
        continue
      }

      // operator  |  >  <  &  ;
      if "|><&;".contains(ch) {
        var end = i + 1
        if (ch == "|" || ch == "&" || ch == ">") && i + 1 < chars.count && chars[i + 1] == ch {
          end = i + 2
        }
        color(sPos..<endPos(end), Palette.operatorToken)
        i = end
        isFirstWord = true
        continue
      }

      // flag  -x  --xxx
      if ch == "-" && i + 1 < chars.count && !chars[i + 1].isWhitespace && chars[i + 1] != "-" {
        i += 1
        while i < chars.count && !chars[i].isWhitespace && !"|><&;#".contains(chars[i]) { i += 1 }
        color(sPos..<endPos(i), Palette.flag)
        continue
      }
      if ch == "-" && i + 1 < chars.count && chars[i + 1] == "-" {
        i += 2
        while i < chars.count && !chars[i].isWhitespace && !"|><&;#".contains(chars[i]) { i += 1 }
        color(sPos..<endPos(i), Palette.flag)
        continue
      }

      // regular word — first one is the command
      i += 1
      while i < chars.count && !chars[i].isWhitespace && !"|><&;#".contains(chars[i]) { i += 1 }
      if isFirstWord {
        color(sPos..<endPos(i), Palette.command)
        isFirstWord = false
      }
    }
  }
}
