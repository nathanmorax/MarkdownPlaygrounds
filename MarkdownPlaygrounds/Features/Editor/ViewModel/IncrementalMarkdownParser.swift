//
//  IncrementalMarkdownParser.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 31/07/25.
//
import Cocoa

// MARK: - IncrementalMarkdownParser (incluido aquí para tu referencia)
class IncrementalMarkdownParser {
    private var lastParsedText = ""
    private var lastElements: [MarkdownParser.MarkdownElement] = []
    
    func parseIfNeeded(_ text: String) -> [MarkdownParser.MarkdownElement] {
        // Solo re-parsear si el texto cambió
        if text != lastParsedText {
            let parser = MarkdownParser()
            lastElements = parser.parseElements(from: text)
            lastParsedText = text
        }
        return lastElements
    }
    
    func clearCache() {
        lastParsedText = ""
        lastElements = []
    }
}
