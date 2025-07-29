//
//  CodeBlock.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 22/07/25.
//


import AppKit

extension NSMutableAttributedString {
    func highlightMarkdownHeaders() {
        let text = self.string
        let lines = text.components(separatedBy: .newlines)
        var currentIndex = 0
        
        for line in lines {
            let lineLength = line.count
            
            if line.hasPrefix("#") {
                let headerLevel = line.prefix(while: { $0 == "#" }).count
                let fontSize: CGFloat = max(18, 28 - CGFloat(headerLevel * 2))
                
                if let rangeOfHashes = line.range(of: "^#+", options: .regularExpression) {
                    let prefixLength = line.distance(from: line.startIndex, to: rangeOfHashes.upperBound)
                    let styledTextStart = currentIndex + prefixLength + 1 
                    let styledTextLength = lineLength - prefixLength - 1
                    
                    if styledTextLength > 0 {
                        let styledRange = NSRange(location: styledTextStart, length: styledTextLength)
                        self.addAttributes([
                            .font: NSFont.boldSystemFont(ofSize: fontSize),
                            .foregroundColor: NSColor.white
                        ], range: styledRange)
                    }
                    
                    let prefixRange = NSRange(location: currentIndex, length: prefixLength)
                    self.addAttributes([
                        .font: NSFont.systemFont(ofSize: fontSize - 4),
                        .foregroundColor: NSColor.gray
                    ], range: prefixRange)
                }
            }
            
            currentIndex += lineLength + 1 // +1 for \n
        }
    }
}


