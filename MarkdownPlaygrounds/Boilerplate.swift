//
//  Boilerplate.swift
//  MarkdownPlaygrounds
//
//  Created by Jonathan Mora on 21/07/25.
//

import Cocoa

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
        textContainerInset = inset
        autoresizingMask = [.width]
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        scrollView.documentView = self
        return scrollView
    }
}
