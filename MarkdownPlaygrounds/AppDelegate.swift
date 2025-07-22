//
//  AppDelegate.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 21/07/25.
//

import Cocoa

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
        
        for i in unicodeScalars {
            if self[i] == "\n" {
                result.append(index(after: i))
            }
        }
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
        guard let node = Node(markdown: editor.string) else { return }
        
        let lineOffsets = editor.string.lineOffsets
        
        for c in node.children {
            switch c.type {
            case CMARK_NODE_HEADING:
                let lineStart = lineOffsets[Int(c.start.line-1)]
                let startIndex = editor.string.index(lineStart, offsetBy:
                    Int(c.start.column-1))
                let lineEnd = lineOffsets[Int(c.end.line-1)]
                let endIndex = editor.string.index(lineEnd, offsetBy:
                    Int(c.end.column-1))
                let range = startIndex..<endIndex
                print(editor.string[range])
            default:
                ()
            }
        }
    }
    
    deinit {
        if let t = observerToken { NotificationCenter.default.removeObserver(t) }
    }
    
}
