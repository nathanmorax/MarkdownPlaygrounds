//
//  AppDelegate.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 21/07/25.
//

import Cocoa
import CommonMark
import Ccmark

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationWillFinishLaunching(_ notification: Notification) {
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

struct MarkdownError: Error {
    
}

@objc(MarkdownDocument)
class MarkdownDocument: NSDocument {
    
    let contentViewController = ViewController()
    
    override class var readableTypes: [String] {
        return ["public.text"]
    }
    
    override class func isNativeType(_ type: String) -> Bool {
        return true
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        guard let str = String(data: data, encoding: .utf8) else  {
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
    
    override func loadView() {
        
        let editorSV = editor.configureAndWrapInScrollView(isEditable: true, inset: CGSize(width: 30, height: 10))
        let outputSV = output.configureAndWrapInScrollView(isEditable: false, inset: CGSize(width: 10, height: 10))
        outputSV.widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true
        
        output.string = "output"
        editor.allowsUndo = true
        
        self.view = Boilerplate().splitView([editorSV, outputSV])
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: NSTextView.didChangeNotification, object: editor, queue: nil) { [unowned self] _ in
            print("change")
            self.parse()
        }
    }
    
    func parse() {
        guard let attributedString = editor.textStorage else { return }
        attributedString.highlightMarkdown()
    }
    
    deinit {
        if let t = observerToken { NotificationCenter.default.removeObserver(t) }
    }
    
}

extension NSMutableAttributedString {
    func highlightMarkdown() {
        guard let node = Node(markdown: string as! Decoder) else { return }
        
        let lineOffsets = string.lineOffsets
        func index(of pos: Position) -> String.Index {
            let lineStart = lineOffsets[Int(pos.line-1)]
            return string.index(lineStart, offsetBy: Int(pos.column-1))
        }
        
        let defaultAttributes = Attributes(family: "Helvetica", size: 16)
        setAttributes(defaultAttributes.atts, range: NSRange(location: 0, length: length))
        
        for c in node.children {
            let start = index(of: c.start)
            let end = index(of: c.end)
            let nsRange = NSRange(start...end, in: string)
            switch c.type {
            case CMARK_NODE_HEADING:
                addAttribute(.foregroundColor, value: NSColor.red, range: nsRange)
            case CMARK_NODE_BLOCK_QUOTE:
                addAttribute(.foregroundColor, value: NSColor.green, range: nsRange)
            case CMARK_NODE_CODE_BLOCK:
                var copy = defaultAttributes
                copy.family = "Monaco"
                addAttribute(.font, value: copy.font, range: nsRange)
            default:
                ()
            }
        }
    }
}



func markdownToHtml(string: String) -> String {
    let outString = cmark_markdown_to_html(string, string.utf8.count, 0)!
    defer { free(outString) }
    return String(cString: outString)
}

struct Markdown {
    var string: String
    
    init(_ string: String) {
        self.string = string
    }
    
    var html: String {
        let outString = cmark_markdown_to_html(string, string.utf8.count, 0)!
        return String(cString: outString)
    }
}

extension String {
    // We're going through Data instead of using init(cstring:) because that leaks memory on Linux.
    
    init?(unsafeCString: UnsafePointer<Int8>!) {
        guard let cString = unsafeCString else { return nil }
        let data = cString.withMemoryRebound(to: UInt8.self, capacity: strlen(cString), { p in
            return Data(UnsafeBufferPointer(start: p, count: strlen(cString)))
        })
        self.init(data: data, encoding: .utf8)
    }
    
    init?(freeingCString str: UnsafeMutablePointer<Int8>?) {
        guard let cString = str else { return nil }
        let data = cString.withMemoryRebound(to: UInt8.self, capacity: strlen(cString), { p in
            return Data(UnsafeBufferPointer(start: p, count: strlen(cString)))
        })
        str?.deallocate()
        self.init(data: data, encoding: .utf8)
    }
}

/// A position in a Markdown document. Note that both `line` and `column` are 1-based.
public struct Position {
    public var line: Int32
    public var column: Int32
}
