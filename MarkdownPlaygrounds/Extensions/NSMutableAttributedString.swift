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
        case .boldItalic:
            applyBoldItalicStyle(range: element.range)
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
        case .highlighted:
            applyHighlightedStyle(range: element.range)
        }
    }
    
    private func hideMarkersCompletely(range: NSRange) {
        guard range.location + range.length <= self.length else { return }
        
        addAttributes([
            .foregroundColor: NSColor.clear,           // Color transparente
            .font: NSFont.systemFont(ofSize: 0.01),    // Tamaño mínimo
            .kern: -1000,                              // Kern negativo para comprimir
            .baselineOffset: -1000                     // Offset para mover fuera de vista
        ], range: range)
    }
    
    private func applyHeaderStyle(level: Int, range: NSRange) {
        let fontSize: CGFloat = max(24 - CGFloat(level * 2), 16)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 8
        
        // Determinar la longitud de los marcadores # (level + posible espacio)
        let text = self.attributedSubstring(from: range).string
        var markerLength = level // Número de #
        
        // Verificar si hay un espacio después de los #
        if text.count > level && text[text.index(text.startIndex, offsetBy: level)] == " " {
            markerLength += 1 // Incluir el espacio
        }
        
        // Verificar que tenemos suficiente texto para tener marcadores
        guard range.length > markerLength else {
            // Si no hay marcadores detectables, aplicar estilo a todo el rango
            addAttributes([
                .font: NSFont.boldSystemFont(ofSize: fontSize),
                .foregroundColor: NSColor.markdownHeadingColor,
                .paragraphStyle: paragraphStyle
            ], range: range)
            return
        }
        
        // Aplicar estilo al contenido (sin los marcadores)
        let contentRange = NSRange(location: range.location + markerLength, length: range.length - markerLength)
        
        if contentRange.location + contentRange.length <= self.length && contentRange.length > 0 {
            addAttributes([
                .font: NSFont.boldSystemFont(ofSize: fontSize),
                .foregroundColor: NSColor.markdownHeadingColor,
                .paragraphStyle: paragraphStyle
            ], range: contentRange)
            
            // Ocultar los marcadores del inicio con tamaño de fuente normal para no afectar el cursor
            let startMarkerRange = NSRange(location: range.location, length: markerLength)
            addAttributes([
                .foregroundColor: NSColor.clear,
                .font: NSFont.systemFont(ofSize: 14), // Usar tamaño normal, no mínimo
                .kern: -1000,
                .baselineOffset: 0 // Sin offset para no afectar la línea del cursor
            ], range: startMarkerRange)
        } else {
            // Fallback: aplicar estilo a todo el rango
            addAttributes([
                .font: NSFont.boldSystemFont(ofSize: fontSize),
                .foregroundColor: NSColor.markdownHeadingColor,
                .paragraphStyle: paragraphStyle
            ], range: range)
        }
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
                .foregroundColor: NSColor.clear,
                .font: NSFont.systemFont(ofSize: 4)
            ], range: startMarkerRange)
        }
        
        if endMarkerRange.location + endMarkerRange.length <= self.length {
            addAttributes([
                .foregroundColor: NSColor.clear,
                .font: NSFont.systemFont(ofSize: 4)
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
                .foregroundColor: NSColor.clear,
                .font: NSFont.systemFont(ofSize: 1)
            ], range: startMarkerRange)
        }
        
        if endMarkerRange.location + endMarkerRange.length <= self.length {
            addAttributes([
                .foregroundColor: NSColor.clear,
                .font: NSFont.systemFont(ofSize: 1)
            ], range: endMarkerRange)
        }
    }
    
    private func applyBoldItalicStyle(range: NSRange) {
        // Verificar que el rango sea válido
        guard range.location + range.length <= self.length,
              range.length >= 6 else { return } // Mínimo para ***x***
        
        // Ocultar los marcadores *** pero mantener el contenido
        let contentRange = NSRange(location: range.location + 3, length: range.length - 6)
        
        // Verificar que el contentRange sea válido
        guard contentRange.location + contentRange.length <= self.length else { return }
        
        // Aplicar ambos estilos: bold + italic
        addAttributes([
            .font: NSFont.systemFont(ofSize: 14).boldItalic()
        ], range: contentRange)
        
        // Hacer los marcadores casi invisibles
        let startMarkerRange = NSRange(location: range.location, length: 3)
        let endMarkerRange = NSRange(location: range.location + range.length - 3, length: 3)
        
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
        
        let text = self.attributedSubstring(from: range).string
        
        let listMarkers = ["* ", "- ", "*", "-"]
        
        for marker in listMarkers {
            if text.hasPrefix(marker) {
                let bulletRange = NSRange(location: range.location, length: marker.count)
                let replacement = marker.hasSuffix(" ") ? "• " : "•"
                
                guard bulletRange.location + bulletRange.length <= self.length else { continue }
                
                //replaceCharacters(in: bulletRange, with: replacement)
                break
            }
        }
        
        addAttributes([
            .paragraphStyle: paragraphStyle,
            .foregroundColor: NSColor.markdonwListColor
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
    
    private func applyHighlightedStyle(range: NSRange) {
        guard range.length > 4 else { return }

        let contentRange = NSRange(location: range.location + 2, length: range.length - 4)
        let content = (self.string as NSString).substring(with: contentRange)

        // Crear el attachment
        let attachment = RoundedBackgroundTextAttachment(text: content)
        let attributedAttachment = NSAttributedString(attachment: attachment)

        // Reemplazar todo el rango ==texto== con el attachment
        self.replaceCharacters(in: range, with: attributedAttachment)
    }
}

final class RoundedBackgroundTextAttachment: NSTextAttachment {
    let text: String
    
    init(text: String) {
        self.text = text
        super.init(data: nil, ofType: nil)
        self.image = renderTextAsImage()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func renderTextAsImage() -> NSImage? {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.labelColor,
            .font: NSFont.systemFont(ofSize: 14, weight: .regular)
        ]
        
        let textSize = text.size(withAttributes: attributes)
        let padding: CGFloat = 6
        let size = NSSize(width: textSize.width + padding * 2, height: textSize.height + padding)

        let image = NSImage(size: size)
        image.lockFocus()

        let rect = NSRect(origin: .zero, size: size)
        let path = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
        NSColor.colorHighlighted.setFill()
        path.fill()

        (text as NSString).draw(at: NSPoint(x: padding, y: padding / 2), withAttributes: attributes)

        image.unlockFocus()
        return image
    }
}
