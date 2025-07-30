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
            var length = line.count
            var range = NSRange(location: location, length: length)

            // Detectar encabezados del H1 al H6 (uno o más # seguidos de espacio)
            if let headingMatch = line.range(of: #"^(#{1,6})\s"#, options: .regularExpression) {
                // Extraer el prefijo con hashes + espacio
                let hashesAndSpace = line[headingMatch]
                let level = hashesAndSpace.filter { $0 == "#" }.count

                // Nuevo texto sin los hashes y espacio
                let newLine = line.replacingOccurrences(of: hashesAndSpace, with: "")

                // Remplazar el texto en textStorage con la línea sin #
                let replaceRange = NSRange(location: location, length: length)
                textStorage.replaceCharacters(in: replaceRange, with: newLine)

                // Actualizar length y range después del reemplazo
                length = newLine.count
                range = NSRange(location: location, length: length)

                // Definir tamaño de fuente según nivel
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

                // Aplicar atributos al rango modificado
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
