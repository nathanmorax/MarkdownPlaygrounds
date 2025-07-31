//
//  ViewController.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 28/07/25.
//
import Cocoa

final class ViewController: NSViewController {
    let editor = NSTextView()
    let output = NSTextView()
    var observerToken: Any?
    var codeBlocks: [CodeBlock] = []
    var repl: REPL!
    
    
    override func loadView() {
        let editorSV = editor.configureAndWrapInScrollView(isEditable: true, inset: CGSize(width: 20, height: 15))
        let outputSV = output.configureAndWrapInScrollView(isEditable: false, inset: CGSize(width: 15, height: 15))
        outputSV.widthAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true
        editor.allowsUndo = true
        
        // Configurar colores y fuentes
        editor.backgroundColor = NSColor.controlBackgroundColor
        output.backgroundColor = NSColor.controlBackgroundColor
        
        self.view = Boilerplate().splitView([editorSV, outputSV])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        repl = REPL(onStdOut: { [weak self] text in
            DispatchQueue.main.async {
                self?.output.textStorage?.append(NSAttributedString(string: text, attributes: [
                    .foregroundColor: NSColor.labelColor,
                    .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
                ]))
                self?.output.scrollToEndOfDocument(nil)
            }
        }, onStdErr: { [weak self] text in
            DispatchQueue.main.async {
                self?.output.textStorage?.append(NSAttributedString(string: text, attributes: [
                    .foregroundColor: NSColor.systemRed,
                    .font: NSFont.monospacedSystemFont(ofSize: 16, weight: .regular)
                ]))
                self?.output.scrollToEndOfDocument(nil)
            }
        })
        
        observerToken = NotificationCenter.default.addObserver(
            forName: NSTextView.didChangeNotification,
            object: editor,
            queue: nil
        ) { [weak self] _ in
            self?.parse()
        }
        
        parse()
    }

    func parse() {
        guard let textStorage = editor.textStorage else { return }

        let rawText = textStorage.string
        let fixedText = prepareMarkdownText(rawText)

        //textStorage.setAttributedString(NSAttributedString(string: fixedText))

        codeBlocks = extractCodeBlocks(from: fixedText)

        // Aplicar highlighting al editor
        highlightMarkdown(in: textStorage, with: codeBlocks)
    }
    
    private func prepareMarkdownText(_ raw: String) -> String {
        // Inserta saltos de línea antes de cada `*` o `-` cuando están en medio del texto
        raw.replacingOccurrences(
            of: #"(?<=\S)\s+(\*|\-)\s"#,
            with: "\n$1 ",
            options: .regularExpression
        )
    }


    
    func applyHighlighting() {
        guard let textStorage = editor.textStorage else { return }
        let mutableString = NSMutableAttributedString(attributedString: textStorage)
        
        // Extraemos bloques y aplicamos estilos con highlightMarkdown
        codeBlocks = extractCodeBlocks(from: mutableString.string)
        highlightMarkdown(in: mutableString, with: codeBlocks)
        
        let selectedRange = editor.selectedRange()
        textStorage.setAttributedString(mutableString)
        editor.setSelectedRange(selectedRange)
        
        parse()

    }
    
    
    private func extractCodeBlocks(from markdown: String) -> [CodeBlock] {
        var blocks: [CodeBlock] = []
        let text = markdown as NSString
        
        let pattern = "```(?:swift)?\\n([\\s\\S]*?)\\n```"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: markdown, options: [], range: NSRange(location: 0, length: text.length))
            
            for match in matches {
                if match.numberOfRanges >= 2 {
                    let contentRange = match.range(at: 1)
                    let content = text.substring(with: contentRange)
                    blocks.append(CodeBlock(text: content, range: contentRange))
                }
            }
        } catch {
            print("Error en regex: \(error)")
            return extractCodeBlocksManually(from: markdown)
        }
        
        return blocks
    }
    
    private func extractCodeBlocksManually(from markdown: String) -> [CodeBlock] {
        var blocks: [CodeBlock] = []
        let lines = markdown.components(separatedBy: .newlines)
        var currentBlockLines: [String] = []
        var inCodeBlock = false
        var blockStartIndex = 0
        
        for (lineIndex, line) in lines.enumerated() {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                if inCodeBlock {
                    // Fin del bloque
                    let blockContent = currentBlockLines.joined(separator: "\n")
                    let range = calculateRangeForLines(from: blockStartIndex, to: lineIndex - 1, in: markdown)
                    blocks.append(CodeBlock(text: blockContent, range: range))
                    currentBlockLines = []
                    inCodeBlock = false
                } else {
                    // Inicio del bloque
                    inCodeBlock = true
                    blockStartIndex = lineIndex + 1
                    currentBlockLines = []
                }
            } else if inCodeBlock {
                currentBlockLines.append(line)
            }
        }
        
        return blocks
    }
    
    private func calculateRangeForLines(from startLine: Int, to endLine: Int, in text: String) -> NSRange {
        let lines = text.components(separatedBy: .newlines)
        guard startLine < lines.count && endLine < lines.count else {
            return NSRange(location: 0, length: 0)
        }
        
        let beforeLines = Array(lines[0..<startLine])
        let targetLines = Array(lines[startLine...endLine])
        
        let startOffset = beforeLines.joined(separator: "\n").count + (startLine > 0 ? 1 : 0)
        let length = targetLines.joined(separator: "\n").count
        
        return NSRange(location: startOffset, length: length)
    }
    
    private func highlightMarkdown(in textStorage: NSMutableAttributedString, with codeBlocks: [CodeBlock]) {
        let fullRange = NSRange(location: 0, length: textStorage.length)
        
        
        // Aplicar estilo base
        textStorage.addAttributes([
            .foregroundColor: NSColor.labelColor,
            .font: NSFont.systemFont(ofSize: 14),
            .backgroundColor: NSColor.clear
        ], range: fullRange)
        
        
        textStorage.applyBasicMarkdown(to: textStorage)
        
        // Highlight para bloques de código
        for block in codeBlocks {
            guard block.range.location + block.range.length <= textStorage.length else { continue }
            
            textStorage.addAttributes([
                .backgroundColor: NSColor.controlColor,
                .foregroundColor: NSColor.controlAccentColor,
                .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .medium)
            ], range: block.range)
        }
    }
    
    func attributedString(from html: String) -> NSAttributedString {
        guard let data = html.data(using: .utf8) else { return NSAttributedString() }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        do {
            return try NSAttributedString(data: data, options: options, documentAttributes: nil)
        } catch {
            return NSAttributedString(string: "Error al renderizar HTML: \(error.localizedDescription)")
        }
    }
    
    @objc func execute() {
        let cursorPosition = editor.selectedRange().location
        
        
        guard let block = codeBlocks.first(where: { $0.range.contains(cursorPosition) }) else {
            output.textStorage?.setAttributedString(NSAttributedString(string: "❌ Coloca el cursor dentro de un bloque de código Swift\n\n", attributes: [
                .foregroundColor: NSColor.systemOrange,
                .font: NSFont.boldSystemFont(ofSize: 12)
            ]))
            return
        }
        
        output.textStorage?.mutableString.setString("")
        output.textStorage?.append(NSAttributedString(string: "🚀 Ejecutando código...\n\n", attributes: [
            .foregroundColor: NSColor.systemGreen,
            .font: NSFont.boldSystemFont(ofSize: 12)
        ]))
        
        repl.execute(block.text)
    }
    
    deinit {
        if let t = observerToken {
            NotificationCenter.default.removeObserver(t)
        }
    }
}


final class RoundedTextView: NSTextView {
    override func drawBackground(in dirtyRect: NSRect) {
        super.drawBackground(in: dirtyRect)

        let path = NSBezierPath(roundedRect: dirtyRect.insetBy(dx: 10, dy: 10), xRadius: 10, yRadius: 10)
        NSColor.systemGreen.setFill()
        path.fill()
    }

}
