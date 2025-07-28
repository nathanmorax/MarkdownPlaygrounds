//
//  AppDelegate.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 21/07/25.
//

import Cocoa
import Ink

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // First instance becomes the shared document controller
        _ = MarkdownDocumentController()
    }
}

class MarkdownDocumentController: NSDocumentController {
    override var documentClassNames: [String] {
        return ["MarkdownDocument"]
    }
    
    override var defaultType: String? {
        return "MarkdownDocument"
    }
    
    override func documentClass(forType typeName: String) -> AnyClass? {
        return MarkdownDocument.self
    }
}

struct MarkdownError: Error { }

@objc(MarkdownDocument)
class MarkdownDocument: NSDocument {
    let contentViewController = ViewController()
    
    override class var readableTypes: [String] {
        return ["public.text"]
    }
    
    override class func isNativeType(_ name: String) -> Bool {
        return true
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        guard let str = String(data: data, encoding: .utf8) else {
            throw MarkdownError()
        }
        contentViewController.editor.string = str
    }
    
    override func data(ofType typeName: String) throws -> Data {
        contentViewController.editor.breakUndoCoalescing()
        return contentViewController.editor.string.data(using: .utf8)!
    }
    
    override func makeWindowControllers() {
        let window = NSWindow(contentViewController: contentViewController)
        window.setContentSize(NSSize(width: 800, height: 600))
        let wc = NSWindowController(window: window)
        wc.contentViewController = contentViewController
        addWindowController(wc)
        window.setFrameAutosaveName("windowFrame")
        window.makeKeyAndOrderFront(nil)
    }
}

extension String {
    var lineOffsets: [String.Index] {
        var result = [startIndex]
        for i in indices {
            if self[i] == "\n" { // todo check if we also need \r and \r\n
                result.append(index(after: i))
            }
        }
        return result
    }
}

final class ViewController: NSViewController {
    let editor = NSTextView()
    let output = NSTextView()
    var observerToken: Any?
    var codeBlocks: [CodeBlock] = []
    var repl: REPL!
    private var markdownParser = MarkdownParser()
    
    override func loadView() {
        let editorSV = editor.configureAndWrapInScrollView(isEditable: true, inset: CGSize(width: 30, height: 10))
        let outputSV = output.configureAndWrapInScrollView(isEditable: false, inset: CGSize(width: 10, height: 10))
        outputSV.widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true
        editor.allowsUndo = true
        
        self.view = Boilerplate().splitView([editorSV, outputSV])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configurar el parser de Ink con modificadores para detectar bloques de código
        setupMarkdownParser()
        
        repl = REPL(onStdOut: { [unowned output] text in
            output.textStorage?.append(NSAttributedString(string: text, attributes: [
                .foregroundColor: NSColor.textColor
            ]))
        }, onStdErr: { [unowned output] text in
            output.textStorage?.append(NSAttributedString(string: text, attributes: [
                .foregroundColor: NSColor.red
            ]))
        })
        observerToken = NotificationCenter.default.addObserver(forName: NSTextView.didChangeNotification, object: editor, queue: nil) { [unowned self] _ in
            self.parse()
        }
    }
    
    private func setupMarkdownParser() {
        // Modificador para capturar bloques de código
        let codeBlockModifier = Modifier(target: .codeBlocks) { [weak self] html, markdown in
            // Aquí podemos procesar el bloque de código detectado por Ink
            self?.processCodeBlock(markdown: String(markdown))
            return html
        }
        
        markdownParser.addModifier(codeBlockModifier)
    }
    
    private func processCodeBlock(markdown: String) {
        // Procesar el bloque de código detectado por Ink
        // Este método se llamará cada vez que Ink encuentre un bloque de código
        print("Bloque de código encontrado: \(markdown)")
    }
    
    func parse() {
        guard let attributedString = editor.textStorage else { return }
        
        // Usar Ink para parsear el markdown y extraer bloques de código
        let markdownText = attributedString.string
        codeBlocks = extractCodeBlocks(from: markdownText)
        
        // Aplicar sintaxis highlighting
        highlightMarkdown(in: attributedString, with: codeBlocks)
    }
    
    private func extractCodeBlocks(from markdown: String) -> [CodeBlock] {
        var blocks: [CodeBlock] = []
        let lines = markdown.components(separatedBy: .newlines)
        var currentBlock: String?
        var startLine = 0
        var inCodeBlock = false
        
        for (index, line) in lines.enumerated() {
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // Fin del bloque de código
                    if let blockContent = currentBlock {
                        let range = calculateRange(for: startLine, endLine: index, in: markdown)
                        blocks.append(CodeBlock(text: blockContent, range: range))
                    }
                    currentBlock = nil
                    inCodeBlock = false
                } else {
                    // Inicio del bloque de código
                    currentBlock = ""
                    startLine = index + 1
                    inCodeBlock = true
                }
            } else if inCodeBlock {
                if currentBlock == nil {
                    currentBlock = line
                } else {
                    currentBlock! += "\n" + line
                }
            }
        }
        
        return blocks
    }
    
    private func calculateRange(for startLine: Int, endLine: Int, in text: String) -> NSRange {
        let lines = text.components(separatedBy: .newlines)
        let beforeLines = Array(lines[0..<startLine])
        let codeLines = Array(lines[startLine..<endLine])
        
        let startOffset = beforeLines.joined(separator: "\n").count + (startLine > 0 ? 1 : 0)
        let length = codeLines.joined(separator: "\n").count
        
        return NSRange(location: startOffset, length: length)
    }
    
    private func highlightMarkdown(in attributedString: NSMutableAttributedString, with codeBlocks: [CodeBlock]) {
        // Aplicar estilo base
        attributedString.addAttributes([
            .foregroundColor: NSColor.textColor,
            .font: NSFont.systemFont(ofSize: 12)
        ], range: NSRange(location: 0, length: attributedString.length))
        
        // Resaltar bloques de código
        for block in codeBlocks {
            attributedString.addAttributes([
                .backgroundColor: NSColor.controlBackgroundColor,
                .foregroundColor: NSColor.systemBlue,
                .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
            ], range: block.range)
        }
        
        // Usar Ink para generar HTML y extraer información adicional si es necesario
        let htmlOutput = markdownParser.html(from: attributedString.string)
        // Puedes usar htmlOutput para otros propósitos si lo necesitas
    }
    
    @objc func execute() {
        let pos = editor.selectedRange().location
        guard let block = codeBlocks.first(where: { $0.range.contains(pos) }) else { return }
        repl.execute(block.text)
    }
    
    deinit {
        if let t = observerToken { NotificationCenter.default.removeObserver(t) }
    }
}

// Estructura para representar bloques de código
struct CodeBlock {
    let text: String
    let range: NSRange
}

final class REPL {
    private let process = Process()
    private let stdIn = Pipe()
    private let stdErr = Pipe()
    private let stdOut = Pipe()
    
    private var stdOutToken: Any?
    private var stdErrToken: Any?

    init(onStdOut: @escaping (String) -> (), onStdErr: @escaping (String) -> ()) {
        process.launchPath = "/usr/bin/swift"
        process.standardInput = stdIn.fileHandleForReading
        process.standardOutput = stdOut.fileHandleForWriting
        process.standardError = stdErr.fileHandleForWriting
        
        stdOutToken = NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: stdOut.fileHandleForReading, queue: nil, using: { [unowned self] note in
            let data = self.stdOut.fileHandleForReading.availableData
            let string = String(data: data, encoding: .utf8)!
            onStdOut(string)
            self.stdOut.fileHandleForReading.waitForDataInBackgroundAndNotify()
        })

        stdErrToken = NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: stdErr.fileHandleForReading, queue: nil, using: { [unowned self] note in
            let data = self.stdErr.fileHandleForReading.availableData
            let string = String(data: data, encoding: .utf8)!
            onStdErr(string)
            self.stdErr.fileHandleForReading.waitForDataInBackgroundAndNotify()
        })

        process.launch()
        stdOut.fileHandleForReading.waitForDataInBackgroundAndNotify()
        stdErr.fileHandleForReading.waitForDataInBackgroundAndNotify()
    }
    
    func execute(_ code: String) {
        stdIn.fileHandleForWriting.write(code.data(using: .utf8)!)
    }
}
