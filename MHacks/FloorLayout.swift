//
//  FloorLayout.swift
//  MHacks
//
//  Created by Russell Ladd on 10/1/16.
//  Copyright © 2016 MHacks. All rights reserved.
//

import UIKit

protocol FloorLayoutDelegate: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, floorLayout: FloorLayout, offsetFractionForItemAt indexPath: IndexPath) -> CGFloat
    func collectionView(_ collectionView: UICollectionView, floorLayout: FloorLayout, aspectRatioForItemAt indexPath: IndexPath) -> CGFloat
}

final class FloorLayout: UICollectionViewLayout {
    
    private var delegate: FloorLayoutDelegate? {
        return collectionView?.delegate as? FloorLayoutDelegate
    }
    
    private var contentSize = CGSize.zero
    
    private var offsetFractions = [CGFloat]()
    private var aspectRatios = [CGFloat]()
    
    let sectionInsets = UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)
    
    var sectionSize: CGSize {
        return CGSize(width: contentSize.width - sectionInsets.left - sectionInsets.left,
                      height: contentSize.height - sectionInsets.top - sectionInsets.bottom)
    }
    
    var verticalCompressionFactor: CGFloat = 1.0
    
    override func prepare() {
        super.prepare()
        
        guard  let collectionView = collectionView, let delegate = delegate else {
            return
        }
        
        contentSize = UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.contentInset).size
        
        let numberOfFloors = collectionView.numberOfItems(inSection: 0)
        
        offsetFractions = (0..<numberOfFloors).map { item in
            return delegate.collectionView(collectionView, floorLayout: self, offsetFractionForItemAt: [0, item])
        }
        
        aspectRatios = (0..<numberOfFloors).map { item in
            return delegate.collectionView(collectionView, floorLayout: self, aspectRatioForItemAt: [0, item])
        }
        
        if let lastFraction = offsetFractions.last, let lastRatio = aspectRatios.last {
            
            let lastTop = sectionSize.height * lastFraction
            
            let maxHeight = lastTop + sectionSize.width / lastRatio
            
            let overshoot = maxHeight - sectionSize.height
            
            verticalCompressionFactor = (lastTop - overshoot) / lastTop
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        return (0..<collectionView!.numberOfItems(inSection: 0)).map { item in
            return layoutAttributesForItem(at: IndexPath(item: item, section: 0))!
        }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        let layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        
        let offsetFraction = offsetFractions[indexPath.item]
        let aspectRatio = aspectRatios[indexPath.item]
        
        layoutAttributes.frame = CGRect(x: sectionInsets.left, y: sectionInsets.top + sectionSize.height * offsetFraction * verticalCompressionFactor, width: sectionSize.width, height: sectionSize.width / aspectRatio)
        
        print(layoutAttributes.frame)
        
        // Lower rows should appear underneath higher rows
        layoutAttributes.zIndex = -indexPath.item
        
        return layoutAttributes
    }
}
