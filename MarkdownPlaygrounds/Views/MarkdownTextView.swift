//
//  MarkdownTextView.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 02/08/25.
//
import Cocoa

final class MarkdownTextView: NSTextView {
    override func insertNewline(_ sender: Any?) {
        let selectedRange = self.selectedRange()
        let nsText = self.string as NSString

        let currentLineRange = nsText.lineRange(for: NSRange(location: max(0, selectedRange.location - 1), length: 0))
        let currentLine = nsText.substring(with: currentLineRange)

        let listPrefixes = ["- ", "* ", "+ "]
        for prefix in listPrefixes {
            if currentLine.trimmingCharacters(in: .whitespaces).hasPrefix(prefix) {
                let lineWithoutWhitespace = currentLine.trimmingCharacters(in: .whitespacesAndNewlines)
                if lineWithoutWhitespace == prefix.trimmingCharacters(in: .whitespaces) {
                    self.setSelectedRange(currentLineRange)
                    self.insertText("", replacementRange: currentLineRange)
                    return
                }

                super.insertNewline(sender)

                let leadingWhitespace = currentLine.prefix { $0 == " " || $0 == "\t" }
                let insertion = "\(leadingWhitespace)\(prefix)"
                self.insertText(insertion, replacementRange: self.selectedRange())
                return
            }
        }

        super.insertNewline(sender)
    }
}
