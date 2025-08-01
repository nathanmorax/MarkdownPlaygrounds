//
//  NSMutableAttributedString.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 31/07/25.
//
import Cocoa

// MARK: - Enhanced Styling
extension NSMutableAttributedString {
    
    func applyMarkdownStyling(elements: [MarkdownParser.MarkdownElement]) {
        // Aplicar estilo base
        let fullRange = NSRange(location: 0, length: self.length)
        addAttributes([
            .foregroundColor: NSColor.labelColor,
            .font: NSFont.systemFont(ofSize: 14),
            .backgroundColor: NSColor.clear
        ], range: fullRange)
        
        // Aplicar estilos específicos
        for element in elements {
            guard element.range.location + element.range.length <= self.length else { continue }
            applyStyle(for: element)
        }
    }
    
    private func applyStyle(for element: MarkdownParser.MarkdownElement) {
          // Validación de seguridad: verificar que el rango esté dentro de los límites
          guard element.range.location >= 0,
                element.range.location + element.range.length <= self.length,
                element.range.length > 0 else {
              print("⚠️ Rango inválido para elemento: \(element.type), rango: \(element.range), longitud del texto: \(self.length)")
              return
          }
          
          switch element.type {
          case .header(let level):
              applyHeaderStyle(level: level, range: element.range)
          case .bold:
              applyBoldStyle(range: element.range)
          case .italic:
              applyItalicStyle(range: element.range)
          case .code:
              applyInlineCodeStyle(range: element.range)
          case .codeBlock:
              applyCodeBlockStyle(range: element.range)
          case .link:
              applyLinkStyle(range: element.range)
          case .list:
              applyListStyle(range: element.range)
          case .quote:
              applyQuoteStyle(range: element.range)
          case .strikethrough:
              applyStrikethroughStyle(range: element.range)
          }
      }
    
    private func applyHeaderStyle(level: Int, range: NSRange) {
        let fontSize: CGFloat = max(24 - CGFloat(level * 2), 16)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 8
        
        addAttributes([
            .font: NSFont.boldSystemFont(ofSize: fontSize),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ], range: range)
    }
    
    private func applyBoldStyle(range: NSRange) {
        // Verificar que el rango sea válido
        guard range.location + range.length <= self.length,
              range.length >= 4 else { return } // Mínimo para **x**
        
        // Ocultar los marcadores ** pero mantener el contenido
        let contentRange = NSRange(location: range.location + 2, length: range.length - 4)
        
        // Verificar que el contentRange sea válido
        guard contentRange.location + contentRange.length <= self.length else { return }
        
        addAttributes([
            .font: NSFont.boldSystemFont(ofSize: 14)
        ], range: contentRange)
        
        // Hacer los marcadores casi invisibles
        let startMarkerRange = NSRange(location: range.location, length: 2)
        let endMarkerRange = NSRange(location: range.location + range.length - 2, length: 2)
        
        if startMarkerRange.location + startMarkerRange.length <= self.length {
            addAttributes([
                .foregroundColor: NSColor.tertiaryLabelColor,
                .font: NSFont.systemFont(ofSize: 8)
            ], range: startMarkerRange)
        }
        
        if endMarkerRange.location + endMarkerRange.length <= self.length {
            addAttributes([
                .foregroundColor: NSColor.tertiaryLabelColor,
                .font: NSFont.systemFont(ofSize: 8)
            ], range: endMarkerRange)
        }
    }
    
    private func applyItalicStyle(range: NSRange) {
        // Verificar que el rango sea válido
        guard range.location + range.length <= self.length,
              range.length >= 2 else { return } // Mínimo para *x*
        
        let contentRange = NSRange(location: range.location + 1, length: range.length - 2)
        
        // Verificar que el contentRange sea válido
        guard contentRange.location + contentRange.length <= self.length else { return }
        
        addAttributes([
            .font: NSFont.systemFont(ofSize: 14).italic()
        ], range: contentRange)
        
        // Hacer los marcadores menos visibles
        let startMarkerRange = NSRange(location: range.location, length: 1)
        let endMarkerRange = NSRange(location: range.location + range.length - 1, length: 1)
        
        if startMarkerRange.location + startMarkerRange.length <= self.length {
            addAttributes([
                .foregroundColor: NSColor.tertiaryLabelColor
            ], range: startMarkerRange)
        }
        
        if endMarkerRange.location + endMarkerRange.length <= self.length {
            addAttributes([
                .foregroundColor: NSColor.tertiaryLabelColor
            ], range: endMarkerRange)
        }
    }
    
    private func applyInlineCodeStyle(range: NSRange) {
        let contentRange = NSRange(location: range.location + 1, length: range.length - 2)
        
        addAttributes([
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.systemPurple,
            .backgroundColor: NSColor.controlBackgroundColor
        ], range: contentRange)
        
        // Ocultar backticks
        addAttributes([
            .foregroundColor: NSColor.tertiaryLabelColor,
            .font: NSFont.systemFont(ofSize: 8)
        ], range: NSRange(location: range.location, length: 1))
        
        addAttributes([
            .foregroundColor: NSColor.tertiaryLabelColor,
            .font: NSFont.systemFont(ofSize: 8)
        ], range: NSRange(location: range.location + range.length - 1, length: 1))
    }
    
    private func applyCodeBlockStyle(range: NSRange) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacingBefore = 8
        paragraphStyle.paragraphSpacing = 8
        paragraphStyle.headIndent = 16
        paragraphStyle.firstLineHeadIndent = 16
        
        addAttributes([
            .backgroundColor: NSColor.controlBackgroundColor,
            .foregroundColor: NSColor.controlAccentColor,
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            .paragraphStyle: paragraphStyle
        ], range: range)
    }
    
    private func applyLinkStyle(range: NSRange) {
        addAttributes([
            .foregroundColor: NSColor.systemBlue,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ], range: range)
    }
    
    private func applyListStyle(range: NSRange) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 20
        paragraphStyle.firstLineHeadIndent = 0
        
        addAttributes([
            .paragraphStyle: paragraphStyle
        ], range: range)
    }
    
    private func applyQuoteStyle(range: NSRange) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 20
        paragraphStyle.firstLineHeadIndent = 20
        
        addAttributes([
            .foregroundColor: NSColor.secondaryLabelColor,
            .font: NSFont.systemFont(ofSize: 14, weight: .light),
            .paragraphStyle: paragraphStyle
        ], range: range)
    }
    
    private func applyStrikethroughStyle(range: NSRange) {
        addAttributes([
            .strikethroughStyle: NSUnderlineStyle.single.rawValue,
            .strikethroughColor: NSColor.labelColor
        ], range: range)
    }
}
