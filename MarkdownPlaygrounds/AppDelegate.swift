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

@objc(MarkdownDocument)
class MarkdownDocument: NSDocument {
    
    let contentViewController = ViewController()
    
    override func makeWindowControllers() {
        let window = NSWindow(contentViewController: contentViewController)
        window.setContentSize(NSSize(width: 800, height: 800))
        
        let wc = NSWindowController(window: window)
        wc.contentViewController = contentViewController
        addWindowController(wc)
        
        window.setFrameAutosaveName("windowFrame")
        
        window.makeKeyAndOrderFront(nil)
        
    }
    
}

final class ViewController: NSViewController {
    
    let editor = NSTextView()
    let output = NSTextView()
    
    override func loadView() {
        
        let editorSV = editor.configureAndWrapInScrollView(isEditable: true, inset: CGSize(width: 30, height: 10))
        let outputSV = output.configureAndWrapInScrollView(isEditable: false, inset: CGSize(width: 10, height: 10))
        
        output.string = "output"
        
        self.view = splitView([editorSV, outputSV])
        
        
    }
    
    func splitView(_ views: [NSView]) -> NSSplitView {
        let splitView = NSSplitView()
        splitView.dividerStyle = .thin
        splitView.isVertical = true
        splitView.translatesAutoresizingMaskIntoConstraints = false

        for view in views {
            splitView.addArrangedSubview(view)
        }

        return splitView
    }

    
}

extension NSTextView {
    func configureAndWrapInScrollView(isEditable: Bool = true, inset: CGSize = .zero) -> NSScrollView {
        self.isEditable = isEditable
        self.drawsBackground = true
        self.backgroundColor = .textBackgroundColor
        self.isVerticallyResizable = true
        self.isHorizontallyResizable = false
        self.textContainerInset = NSSize(width: inset.width, height: inset.height)
        self.autoresizingMask = [.width]
        self.textContainer?.widthTracksTextView = true

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.documentView = self
        scrollView.borderType = .noBorder
        scrollView.autoresizingMask = [.width, .height]
        
        return scrollView
    }
}
