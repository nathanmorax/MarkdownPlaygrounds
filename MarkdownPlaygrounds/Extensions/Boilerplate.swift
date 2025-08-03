//
//  Boilerplate.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 21/07/25.
//

import Cocoa


// Estructura para representar bloques de código
struct CodeBlock {
    let text: String
    let range: NSRange
}

class Boilerplate {
    
    func splitView(_ views: [NSView]) -> NSSplitView {
        let sv = NSSplitView()
        sv.isVertical = true
        sv.dividerStyle = .thin
        for v in views {
            sv.addArrangedSubview(v)
        }
        sv.setHoldingPriority(.defaultLow - 1, forSubviewAt: 0)
        sv.autoresizingMask = [.width, .height]
        sv.autosaveName = "SplitView"
        return sv

    }
    
}

extension NSTextView {
    func configureAndWrapInScrollView(isEditable editable: Bool, inset: CGSize) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        
        isEditable = editable
        isRichText = true
        textContainerInset = inset
        autoresizingMask = [.width]
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        scrollView.documentView = self
        return scrollView
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


