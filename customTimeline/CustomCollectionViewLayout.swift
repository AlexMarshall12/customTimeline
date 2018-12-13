//
//  CustomCollectionViewLayout.swift
//  customTimeline
//
//  Created by Alex on 12/12/18.
//  Copyright © 2018 SweatNet. All rights reserved.
//

import UIKit

class CustomCollectionViewLayout: UICollectionViewLayout {
    
    private var cache = [IndexPath: UICollectionViewLayoutAttributes]()
    private var contentWidth = CGFloat()
    private var visibleLayoutAttributes = [UICollectionViewLayoutAttributes]()
    private var oldBounds = CGRect.zero
    private var cellWidth: CGFloat = 5
    private var collectionViewStartY: CGFloat {
        guard let collectionView = collectionView else {
            return 0
        }
        return collectionView.bounds.minY
    }
    private var collectionViewHeight: CGFloat {
        return collectionView!.frame.height
    }
    override public var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: collectionViewHeight)
    }
    
    override public func prepare() {
        print("calling prepare")
        guard let collectionView = collectionView,
            cache.isEmpty else {
                return
        }
        
        updateInsets()
        collectionView.decelerationRate = .fast
        cache.removeAll(keepingCapacity: true)
        cache = [IndexPath: UICollectionViewLayoutAttributes]()
        oldBounds = collectionView.bounds
        var xOffset: CGFloat = 0
        var cellWidth: CGFloat = 5
        
        for item in 0 ..< collectionView.numberOfItems(inSection: 0) {
            let cellIndexPath = IndexPath(item: item, section: 0)
            let cellattributes = UICollectionViewLayoutAttributes(forCellWith: cellIndexPath)
            cellattributes.frame = CGRect(x: xOffset, y: 0, width: cellWidth, height: collectionViewHeight)
            xOffset = xOffset + cellWidth
            contentWidth = max(contentWidth,xOffset)
            cache[cellIndexPath] = cellattributes
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        visibleLayoutAttributes.removeAll(keepingCapacity: true)

        for (_, attributes) in cache {
            visibleLayoutAttributes.append(self.shiftedAttributes(from: attributes))
        }
//        for (_, attributes) in cache {
//            visibleLayoutAttributes.append(attributes)
//        }
        return visibleLayoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = cache[indexPath] else { fatalError("No attributes cached") }
//        return attributes
        return shiftedAttributes(from: attributes)
    }
    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if oldBounds.size != newBounds.size {
            cache.removeAll(keepingCapacity: true)
        }
        return true
    }
    
    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        if context.invalidateDataSourceCounts { cache.removeAll(keepingCapacity: true) }
        super.invalidateLayout(with: context)
    }
}
extension CustomCollectionViewLayout {
    
    func updateInsets() {
        guard let collectionView = collectionView else { return }
        collectionView.contentInset.left = (collectionView.bounds.size.width - cellWidth) / 2
        collectionView.contentInset.right = (collectionView.bounds.size.width - cellWidth) / 2
    }
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return super.targetContentOffset(forProposedContentOffset: proposedContentOffset) }
        let midX: CGFloat = collectionView.bounds.size.width / 2
        guard let closestAttribute = findClosestAttributes(toXPosition: proposedContentOffset.x + midX) else { return super.targetContentOffset(forProposedContentOffset: proposedContentOffset) }
        return CGPoint(x: closestAttribute.center.x - midX, y: proposedContentOffset.y)
    }
    
    private func findClosestAttributes(toXPosition xPosition: CGFloat) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = collectionView else { return nil }
        let searchRect = CGRect(
            x: xPosition - collectionView.bounds.width, y: collectionView.bounds.minY,
            width: collectionView.bounds.width * 2, height: collectionView.bounds.height
        )
        let closestAttributes = layoutAttributesForElements(in: searchRect)?.min(by: { abs($0.center.x - xPosition) < abs($1.center.x - xPosition) })
        return closestAttributes
    }
    private var continuousFocusedIndex: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        let offset = collectionView.bounds.width / 2 + collectionView.contentOffset.x - cellWidth / 2
        return offset / cellWidth
    }
    private func shiftedAttributes(from attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        guard let attributes = attributes.copy() as? UICollectionViewLayoutAttributes else { fatalError("Couldn't copy attributes") }
        let roundedFocusedIndex = round(continuousFocusedIndex)
        let focusedItemWidth = CGFloat(20)
        if attributes.indexPath.item == Int(roundedFocusedIndex){
            attributes.transform = CGAffineTransform(scaleX: 10, y: 1)
        } else {
            let translationDirection: CGFloat = attributes.indexPath.item < Int(roundedFocusedIndex) ? -1 : 1
            attributes.transform = CGAffineTransform(translationX: translationDirection * 20, y: 0)
        }
        return attributes
    }
}

