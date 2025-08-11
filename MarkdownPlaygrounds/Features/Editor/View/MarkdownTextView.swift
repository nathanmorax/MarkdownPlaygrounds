//
//  MarkdownTextView.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 02/08/25.
//
import Cocoa

final class MarkdownTextView: NSTextView {
    
    // Sobrescribir shouldChangeText para preservar los marcadores
    override func shouldChangeText(in affectedCharRange: NSRange, replacementString: String?) -> Bool {
        let result = super.shouldChangeText(in: affectedCharRange, replacementString: replacementString)
        
        // Si estamos insertando texto, verificar si hay elementos markdown cercanos que necesiten preservación
        if let replacement = replacementString, !replacement.isEmpty {
            preserveMarkdownElements(around: affectedCharRange)
        }
        
        return result
    }
    
    private func preserveMarkdownElements(around range: NSRange) {
        guard let textStorage = textStorage else { return }
        
        let text = textStorage.string as NSString
        let _ = NSRange(location: 0, length: text.length)
        
        let extendedRange = NSRange(
            location: max(0, range.location - 10),
            length: min(text.length - max(0, range.location - 10), range.length + 20)
        )
        
        // Encontrar patrones == alrededor del área de edición
        let pattern = "==([^=]+)=="
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: text as String, options: [], range: extendedRange)
            
            for match in matches {
                // Re-aplicar el estilo de resaltado si es necesario
                DispatchQueue.main.async { [weak self] in
                    self?.reapplyHighlightStyle(in: match.range)
                }
            }
        } catch {
            print("Error en regex: \(error)")
        }
    }
    
    private func reapplyHighlightStyle(in range: NSRange) {
        guard let textStorage = textStorage,
              range.location + range.length <= textStorage.length,
              range.length > 4 else { return }
        
        let startMarkerRange = NSRange(location: range.location, length: 2)
        let endMarkerRange = NSRange(location: range.location + range.length - 2, length: 2)
        let contentRange = NSRange(location: range.location + 2, length: range.length - 4)
        
        textStorage.addAttributes([
            .backgroundColor: NSColor.colorHighlighted,
            .foregroundColor: NSColor.labelColor,
            .font: NSFont.systemFont(ofSize: 14, weight: .regular)
        ], range: contentRange)
        
        textStorage.addAttributes([
            .foregroundColor: NSColor.clear,
            .font: NSFont.systemFont(ofSize: 1)
        ], range: startMarkerRange)
        
        textStorage.addAttributes([
            .foregroundColor: NSColor.clear,
            .font: NSFont.systemFont(ofSize: 1)
        ], range: endMarkerRange)
    }
    
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
