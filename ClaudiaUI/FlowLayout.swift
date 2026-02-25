//
//  FlowLayout.swift
//  Claudia
//
//  Created by Sherlock LUK on 25/02/2026.
//

import SwiftUI

/// A wrapping flow layout that places inline content on the same line,
/// breaking to the next line when the available width is exceeded.
struct FlowLayout: Layout {
    
    var spacing: CGFloat = 4
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        
        // First pass: assign rows and compute row heights
        struct RowItem {
            var x: CGFloat
            var rowIndex: Int
            var size: CGSize
        }
        
        var items: [RowItem] = []
        var rowHeights: [CGFloat] = []
        var x: CGFloat = 0
        var rowIndex = 0
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > maxWidth && x > 0 {
                rowHeights.append(currentRowHeight)
                x = 0
                rowIndex += 1
                currentRowHeight = 0
            }
            
            items.append(RowItem(x: x, rowIndex: rowIndex, size: size))
            currentRowHeight = max(currentRowHeight, size.height)
            x += size.width + spacing
        }
        rowHeights.append(currentRowHeight)
        
        // Second pass: compute y positions with vertical centering within each row
        var positions: [CGPoint] = []
        var rowY: [CGFloat] = [0]
        for i in 1..<rowHeights.count {
            rowY.append(rowY[i - 1] + rowHeights[i - 1] + spacing)
        }
        
        var totalWidth: CGFloat = 0
        for item in items {
            let yOffset = (rowHeights[item.rowIndex] - item.size.height) / 2
            positions.append(CGPoint(x: item.x, y: rowY[item.rowIndex] + yOffset))
            totalWidth = max(totalWidth, item.x + item.size.width)
        }
        
        let totalHeight = rowY.last.map { $0 + rowHeights.last! } ?? 0
        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}
