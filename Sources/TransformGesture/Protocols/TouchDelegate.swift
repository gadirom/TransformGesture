import SwiftUI

/// Pass the object complying to this protocol to the ``freeTransformGesture`` view modifier to additionally handle touch events.
///
/// The callbacks are called after the published values of the corresponding ``TouchTransform`` object are changed.
public protocol TouchDelegate: AnyObject{
    
    func startTransform()
    func changeTransform(_ transform: TouchTransform)
    func endTransform(_ transform: TouchTransform)
    
    /// Fires when the view is touched.
    /// - Parameter point: the coordinates of the touch.
    ///
    /// This function is called when the view is first touched.
    /// At this time it is not known whether the gesture that is about to be performed will be a dragging, a transforming with two or one fingures, or just a tap.
    func touched(_ point: CGPoint)
    func moveDragging(_ point: CGPoint)
    func endDragging()
    
    func tap(_ point: CGPoint)
    
    func onFrameChange(frameSize: CGSize)
    
    func onHover(_ point: CGPoint, state: UIGestureRecognizer.State)
    
    var centerOnHover: Bool{ get }
}

public extension TouchDelegate{
    func startTransform() {
    }
    
    func changeTransform(_ transform: TouchTransform) {
    }
    
    func endTransform(_ transform: TouchTransform) {
    }
    
    func touched(_ point: CGPoint) {
    }
    
    func moveDragging(_ point: CGPoint) {
    }
    
    func endDragging() {
    }
    
    func tap(_ point: CGPoint) {
    }
    
    func onFrameChange(frameSize: CGSize) {
    }
    
    func onHover(_ point: CGPoint, state: UIGestureRecognizer.State) {
    }
    
    var centerOnHover: Bool{
        true
    }
}
