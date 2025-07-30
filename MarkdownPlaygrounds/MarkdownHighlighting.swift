//
//  CodeBlock.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 22/07/25.
//


import AppKit

extension NSMutableAttributedString {
    func applyBasicMarkdown(to textStorage: NSMutableAttributedString) {
        let fullText = textStorage.string as NSString
        let lines = fullText.components(separatedBy: .newlines)
        var location = 0

        for line in lines {
            let length = line.count
            let range = NSRange(location: location, length: length)

            // Detectar encabezados del H1 al H6
            if let headingMatch = line.range(of: #"^(#{1,6})\s"#, options: .regularExpression) {
                let hashes = line[headingMatch].trimmingCharacters(in: .whitespaces)
                let level = hashes.count
                let fontSize: CGFloat

                switch level {
                    case 1: fontSize = 28
                    case 2: fontSize = 24
                    case 3: fontSize = 20
                    case 4: fontSize = 18
                    case 5: fontSize = 16
                    case 6: fontSize = 14
                    default: fontSize = 12
                }

                textStorage.addAttributes([
                    .font: NSFont.boldSystemFont(ofSize: fontSize),
                    .foregroundColor: NSColor.white
                ], range: range)
                

            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                // Lista
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.headIndent = 20
                paragraphStyle.firstLineHeadIndent = 20

                textStorage.addAttributes([
                    .paragraphStyle: paragraphStyle,
                    .foregroundColor: NSColor.white
                ], range: range)
            }

            location += length + 1
        }
    }
}


