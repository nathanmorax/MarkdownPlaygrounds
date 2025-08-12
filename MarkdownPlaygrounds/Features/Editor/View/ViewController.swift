//
//  ViewController.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 28/07/25.
//
import Cocoa


final class ViewController: NSViewController {
    let editor = MarkdownTextView()
    let output = NSTextView()
    var observerToken: Any?
    var codeBlocks: [CodeBlock] = []
    var repl: REPL!
    var outputScrollView: NSScrollView!

    
    // Sistema de parsing incremental para mejor performance
    private let incrementalParser = IncrementalMarkdownParser()
    private var isUpdatingText = false // Evitar loops infinitos
    
    override func loadView() {
        let editorSV = editor.configureAndWrapInScrollView(isEditable: true, inset: CGSize(width: 20, height: 15))
        
        outputScrollView = output.configureAndWrapInScrollView(isEditable: false, inset: CGSize(width: 15, height: 15))
        outputScrollView.widthAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true
        
        editor.allowsUndo = true
        editor.backgroundColor = .backgroundEditorColor
        output.backgroundColor = .backgroundOutputColor
        
        editor.isAutomaticQuoteSubstitutionEnabled = false
        editor.isAutomaticDashSubstitutionEnabled = false
        editor.isAutomaticTextReplacementEnabled = false
        
        self.view = Boilerplate().splitView([editorSV, outputScrollView])
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupREPL()
        setupTextChangeObserver()
        
        
        //editor.string = initialContent
        parse()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        setupBarAccessory()

    }
    
    private func setupREPL() {
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
    }
    
    private func setupTextChangeObserver() {
        observerToken = NotificationCenter.default.addObserver(
            forName: NSTextView.didChangeNotification,
            object: editor,
            queue: nil
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.parse()
            }
        }
    }
    
    @objc func toggleInspector() {
        outputScrollView.isHidden.toggle()

    }
    
    @objc func newFile() {
    }

    // MARK: - Parsing y Rendering Principal
    func parse() {
        
        guard let textStorage = editor.textStorage,
              !isUpdatingText else { return }
        
        isUpdatingText = true
        defer { isUpdatingText = false }
        
        let currentText = textStorage.string
        let selectedRange = editor.selectedRange()
        
        // Usar el parser incremental para mejor performance
        let elements = incrementalParser.parseIfNeeded(currentText)
        
        // Crear una copia mutable para aplicar estilos
        let mutableString = NSMutableAttributedString(string: currentText)
        mutableString.applyMarkdownStyling(elements: elements)
        
        // Actualizar el textStorage preservando la selección
        textStorage.setAttributedString(mutableString)
        
        // Restaurar la posición del cursor de manera segura
        let safeRange = NSRange(
            location: min(selectedRange.location, textStorage.length),
            length: min(selectedRange.length, textStorage.length - min(selectedRange.location, textStorage.length))
        )
        editor.setSelectedRange(safeRange)
        
        // Actualizar code blocks para ejecución
        updateCodeBlocks(from: elements)
    }
    
    
    private func updateCodeBlocks(from elements: [MarkdownParser.MarkdownElement]) {
        codeBlocks = elements.compactMap { element in
            if case .codeBlock = element.type {
                return CodeBlock(text: element.content, range: element.range)
            }
            return nil
        }
    }
    
    // MARK: - Métodos legacy (mantenidos para compatibilidad)
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
    
    // MARK: - Ejecución de código
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
