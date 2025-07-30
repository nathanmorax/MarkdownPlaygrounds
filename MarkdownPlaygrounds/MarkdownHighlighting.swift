//
//  MarkdownHighlighting.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 22/07/25.
//

import AppKit

// MARK: - Markdown Highlighter
final class MarkdownHighlighter {
    
    // MARK: - Constants
    private struct Style {
        static let headerSizes: [Int: CGFloat] = [1: 28, 2: 24, 3: 20, 4: 18, 5: 16, 6: 14]
        static let textColor = NSColor.white
        static let highlightColor = NSColor.systemGreen
        static let defaultFont = NSFont.systemFont(ofSize: 14)
        static let listIndent: CGFloat = 20
    }
    
    // MARK: - Public Methods
    func applyHighlighting(to textStorage: NSMutableAttributedString) {
        let lines = textStorage.string.components(separatedBy: .newlines)
        var location = 0
        
        for line in lines {
            let range = NSRange(location: location, length: line.count)
            
            applyHighlight(line: line, textStorage: textStorage, location: location)
            applyHeading(line: line, textStorage: textStorage, range: range)
            applyBulletList(line: line, textStorage: textStorage, range: range, location: location)
            
            location += line.count + 1
        }
    }
    
    // MARK: - Private Methods
    private func applyHighlight(line: String, textStorage: NSMutableAttributedString, location: Int) {
        guard let match = line.range(of: #"==(.+?)=="#, options: .regularExpression) else { return }
        
        let nsRange = NSRange(match, in: line)
        let highlightRange = NSRange(
            location: location + nsRange.location + 2,
            length: nsRange.length - 4
        )
        
        textStorage.addAttributes([
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: Style.textColor,
            .backgroundColor: Style.highlightColor
        ], range: highlightRange)
    }
    
    private func applyHeading(line: String, textStorage: NSMutableAttributedString, range: NSRange) {
        guard let headingMatch = line.range(of: #"^(#{1,6})\s"#, options: .regularExpression) else { return }
        
        let hashes = line[headingMatch].trimmingCharacters(in: .whitespaces)
        let level = hashes.count
        let fontSize = Style.headerSizes[level] ?? 12
        
        textStorage.addAttributes([
            .font: NSFont.boldSystemFont(ofSize: fontSize),
            .foregroundColor: Style.textColor
        ], range: range)
    }
    
    private func applyBulletList(line: String, textStorage: NSMutableAttributedString, range: NSRange, location: Int) {
        guard line.hasPrefix("- ") || line.hasPrefix("* ") else { return }
        
        // Replace with bullet
        textStorage.replaceCharacters(in: NSRange(location: location, length: 2), with: "• ")
        
        // Apply list styling
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = Style.listIndent
        paragraphStyle.firstLineHeadIndent = Style.listIndent
        paragraphStyle.paragraphSpacing = 4
        
        textStorage.addAttributes([
            .paragraphStyle: paragraphStyle,
            .foregroundColor: Style.textColor,
            .font: Style.defaultFont
        ], range: range)
    }
}

// MARK: - NSMutableAttributedString Extension
extension NSMutableAttributedString {
    func applyBasicMarkdown() {
        let highlighter = MarkdownHighlighter()
        highlighter.applyHighlighting(to: self)
    }
    
    // Mantener compatibilidad con el método original
    func applyBasicMarkdown(to textStorage: NSMutableAttributedString) {
        textStorage.applyBasicMarkdown()
    }
}
