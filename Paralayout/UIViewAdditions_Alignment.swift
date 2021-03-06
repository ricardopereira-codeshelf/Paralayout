//
//  Copyright © 2017 Square, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit


/// Locations within a rectangle.
public enum Position {
    
    case topLeft, topCenter, topRight
    case leftCenter, center, rightCenter
    case bottomLeft, bottomCenter, bottomRight
    
    /// The "opposite" position.
    /// - parameter horizontally: Whether to reflect left and right positions (optional, defaults to `true`).
    /// - parameter vertically: Whether to reflect top and bottom positions (optional, defaults to `true`).
    /// - returns: A position on the opposite side/corner as specified.
    public func reflected(horizontally: Bool = true, vertically: Bool = true) -> Position {
        switch self {
        case .topLeft:
            if horizontally {
                return vertically ? .bottomRight : .topRight
            } else {
                return vertically ? .bottomLeft : .topLeft
            }
            
        case .topCenter:
            return vertically ? .bottomCenter : .topCenter
            
        case .topRight:
            if horizontally {
                return vertically ? .bottomLeft : .topLeft
            } else {
                return vertically ? .bottomRight : .topRight
            }
            
        case .leftCenter:
            return horizontally ? .rightCenter : .leftCenter
            
        case .center:
            return .center
            
        case .rightCenter:
            return horizontally ? .leftCenter : .rightCenter
            
        case .bottomLeft:
            if horizontally {
                return vertically ? .topRight : .bottomRight
            } else {
                return vertically ? .topLeft : .bottomLeft
            }
            
        case .bottomCenter:
            return vertically ? .topCenter : .bottomCenter
            
        case .bottomRight:
            if horizontally {
                return vertically ? .topLeft : .bottomLeft
            } else {
                return vertically ? .topRight : .bottomRight
            }
        }
    }
    
    /// The position in a specific rectangle.
    /// - parameter rect: The rect for which to interpret the position.
    /// - returns: The point within the rect at the specified position.
    public func point(in rect: CGRect) -> CGPoint {
        switch self {
        case .topLeft:
            return CGPoint(x: rect.minX, y: rect.minY)
        case .topCenter:
            return CGPoint(x: rect.midX, y: rect.minY)
        case .topRight:
            return CGPoint(x: rect.maxX, y: rect.minY)
            
        case .leftCenter:
            return CGPoint(x: rect.minX, y: rect.midY)
        case .center:
            return CGPoint(x: rect.midX, y: rect.midY)
        case .rightCenter:
            return CGPoint(x: rect.maxX, y: rect.midY)
            
        case .bottomLeft:
            return CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomCenter:
            return CGPoint(x: rect.midX, y: rect.maxY)
        case .bottomRight:
            return CGPoint(x: rect.maxX, y: rect.maxY)
        }
    }
    
}


// MARK: -


public extension UIView {
    
    // MARK: - View Alignment - Core
    
    /// The location of a position in the view's `bounds` (regardless of whether or not it conforms to `CustomPositionBounds`).
    /// - parameter position: The position to use.
    /// - returns: The point at the specified position.
    public func point(inBoundsAt position: Position) -> CGPoint {
        return position.point(in: bounds)
    }
    
    /// The location of a position in the view, either in `bounds`, or `customPositionBounds` if it conforms to `CustomPositionBounds`.
    /// - parameter position: The position to use.
    /// - returns: The point at the specified position.
    public func point(at position: Position) -> CGPoint {
        if let contentPositionInsets = (self as? ContentPositionInset)?.contentPositionInsets {
            return position.point(in: UIEdgeInsetsInsetRect(bounds, contentPositionInsets))
        } else {
            return point(inBoundsAt: position)
        }
    }
    
    /// The offset between two views' positions.
    /// - parameter position: The position in the receiving view's `bounds`.
    /// - parameter otherView: The other view for the measurement.
    /// - parameter otherPosition: The position in the `otherView` to use for the measurement.
    /// - returns: The distance between the two view's positions.
    public func frameOffset(from position: Position, to otherView: UIView, _ otherPosition: Position) -> UIOffset {
        // We can't be aligned to another view if we don't have a superview.
        guard let superview = superview else {
            return .zero
        }
        
        // Convert both points to the receiver's superview, since we are working with the frame (not the bounds).
        let srcPoint = superview.convert(point(at: position), from: self)
        let dstPoint = superview.convert(otherView.point(at: otherPosition), from: otherView)
        
        return dstPoint - srcPoint
    }
    
    /// Move the view to align it with another view.
    /// - parameter position: The position within the receiving view to use for alignment.
    /// - parameter otherView: The view to which the receiving view will be aligned.
    /// - parameter otherPosition: The position within `otherView` to use for alignment.
    /// - parameter offset: An additional offset to apply to the alignment, e.g. to leave a space between the two views.
    public func align(_ position: Position, with otherView: UIView, _ otherPosition: Position, offset: UIOffset) {
        let totalOffset = frameOffset(from: position, to: otherView, otherPosition) + offset
        
        // Apply the offset and round to the nearest pixel.
        frame.origin = (frame.origin + totalOffset).roundToPixel(self)
    }
    
    // MARK: - View Alignment - Convenience
    
    /// The insets of the view's positions relative to its superview's.
    public var positionInsetsFromSuperview: UIEdgeInsets {
        // We can't have margins if we don't have a superview.
        guard let superview = superview else {
            return .zero
        }
        
        let leadingOffset = frameOffset(from: .topLeft, to: superview, .topLeft)
        let trailingOffset = frameOffset(from: .bottomRight, to: superview, .bottomRight)
        
        return UIEdgeInsets(top: -leadingOffset.vertical,
                            left: -leadingOffset.horizontal,
                            bottom: trailingOffset.vertical,
                            right: trailingOffset.horizontal)
    }
    
    /// Move the view to align it with another view.
    /// - parameter position: The position within the receiving view to use for alignment.
    /// - parameter otherView: The view to which the receiving view will be aligned.
    /// - parameter otherPosition: The position within `otherView` to use for alignment.
    /// - parameter horizontalOffset: An additional horizontal offset to apply to the alignment (defaults to 0).
    /// - parameter verticalOffset: An additional vertical offset to apply to the alignment (defaults to 0).
    public func align(_ position: Position, with otherView: UIView, _ otherPosition: Position, horizontalOffset: CGFloat = 0, verticalOffset: CGFloat = 0) {
        align(position, with: otherView, otherPosition, offset: UIOffset(horizontal: horizontalOffset, vertical: verticalOffset))
    }
    
    /// Move the view to align it within its superview, based on position.
    /// - parameter position: The position within the receiving view to use for alignment.
    /// - parameter superviewPosition: The position within the view's `superview` to use for alignment.
    /// - parameter horizontalOffset: An additional horizontal offset to apply to the alignment (defaults to 0).
    /// - parameter verticalOffset: An additional vertical offset to apply to the alignment (defaults to 0).
    public func align(_ position: Position, withSuperviewPosition superviewPosition: Position, horizontalOffset: CGFloat = 0, verticalOffset: CGFloat = 0) {
        guard let superview = superview else {
            assertionFailure("Can't align view without a superview!")
            return
        }
        
        align(position, with: superview, superviewPosition, offset: UIOffset(horizontal: horizontalOffset, vertical: verticalOffset))
    }
    
    /// Move the view to align it within its superview, based on coordinate.
    /// - parameter position: The position within the receiving view to use for alignment.
    /// - parameter superviewPoint: The coordinate within the view's `superview` to use for alignment.
    /// - parameter horizontalOffset: An additional horizontal offset to apply to the alignment (defaults to 0).
    /// - parameter verticalOffset: An additional vertical offset to apply to the alignment (defaults to 0).
    public func align(_ position: Position, withSuperviewPoint superviewPoint: CGPoint, horizontalOffset: CGFloat = 0, verticalOffset: CGFloat = 0) {
        guard let superview = superview else {
            assertionFailure("Can't align view without a superview!")
            return
        }
        
        align(position, with: superview, .topLeft, offset: UIOffset(horizontal: superviewPoint.x + horizontalOffset, vertical: superviewPoint.x + verticalOffset))
    }
    
    /// Move the view to align it with another view.
    /// - parameter position: The position in both the receiving view and its `superview` to use for alignment.
    /// - parameter inset: An optional inset (horizontal, vertical, or diagonal based on the position) to apply. An inset on .center is interpreted as a vertical offset.
    func alignToSuperview(_ position: Position, inset: CGFloat = 0.0) {
        guard let superview = self.superview else {
            assertionFailure("Can't align view without a superview!")
            return
        }
        
        let offset: UIOffset
        switch position {
        case .topLeft:
            offset = UIOffset(horizontal: inset,    vertical: inset)
        case .topCenter:
            offset = UIOffset(horizontal: 0,        vertical: inset)
        case .topRight:
            offset = UIOffset(horizontal: -inset,   vertical: inset)
        case .leftCenter:
            offset = UIOffset(horizontal: inset,    vertical: 0)
        case .center:
            offset = UIOffset(horizontal: 0,        vertical: inset)
        case .rightCenter:
            offset = UIOffset(horizontal: -inset,   vertical: 0)
        case .bottomLeft:
            offset = UIOffset(horizontal: inset,    vertical: -inset)
        case .bottomCenter:
            offset = UIOffset(horizontal: 0,        vertical: -inset)
        case .bottomRight:
            offset = UIOffset(horizontal: -inset,   vertical: -inset)
        }
        
        self.align(position, with: superview, position, offset: offset)
    }
    
}


// MARK: -


/// A protocol to be adopted by views that should be aligned based on content inset from their `bounds`.
public protocol ContentPositionInset {
    
    /// An inset from the view's `bounds` for alignment.
    var contentPositionInsets: UIEdgeInsets { get }
    
}


public extension UIView {
    
    /// The hypothetical size that fits the view's content (inset from `bounds` if it conforms to `ContentPositionInset`).
    /// - parameter size: the size within which to fit, passed through to `frameSize(thatFits:)`.
    /// - parameter constraints: Limits on the returned size (optional, defaults to `.none`).
    /// - returns: A size for the view's *alignment* bounds, suitable for use in a superview's `sizeThatFits()` implementation.
    public func contentSize(thatFits size: CGSize, constraints: SizingConstraints = .none) -> CGSize {
        let sizeThatFits = frameSize(thatFits: size, constraints: constraints)
        
        if let insets = (self as? ContentPositionInset)?.contentPositionInsets {
            return CGSize(width: sizeThatFits.width - (insets.left + insets.right),
                          height: sizeThatFits.height - (insets.top + insets.bottom))
            
        } else {
            return sizeThatFits
        }
    }
    
    /// The size that fits the view's current content (inset from `frame` if it conforms to `ContentPositionInset`).
    public var frameContentSize: CGSize {
        if let insets = (self as? ContentPositionInset)?.contentPositionInsets {
            return frame.inset(by: insets).size
        } else {
            return frame.size
        }
    }
    
}


extension UILabel: ContentPositionInset {
    
    /// Adoption of the `CustomPosition` protocol for UILabels, insetting the top and bottom coordinates based on the label's font metrics.
    public var contentPositionInsets: UIEdgeInsets {
        let capInsets = font.labelCapInsets(in: self)
        return UIEdgeInsets(top: capInsets.top, left: 0, bottom: capInsets.bottom, right: 0)
    }
    
    /// The size that fits the label's text in `.wrap` mode,
    /// - parameter width: the width to fit the text, passed through to `frameSize(thatFits:)`.
    /// - parameter height: the maximum height for the text, passed through to `frameSize(thatFits:)` (optional, defaults to `greatestFiniteMagnitude`).
    /// - parameter constraints: Limits on the returned size (optional, defaults to `.wrap`).
    /// - returns: A size for the label's *alignment* bounds, suitable for use in a superview's `sizeThatFits()` implementation.
    public func textSize(thatFitsWidth width: CGFloat, height: CGFloat = .greatestFiniteMagnitude) -> CGSize {
        return contentSize(thatFits: CGSize(width: width, height: height), constraints: .wrap)
    }
    
}
