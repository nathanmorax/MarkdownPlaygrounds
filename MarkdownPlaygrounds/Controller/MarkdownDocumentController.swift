//
//  MarkdownDocumentController.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 28/07/25.
//
import Cocoa

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
