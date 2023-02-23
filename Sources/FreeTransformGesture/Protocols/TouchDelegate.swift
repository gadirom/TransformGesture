import SwiftUI

public protocol TouchDelegate: AnyObject{
    
    func startTransform()
    func changeTransform(_ transform: TouchTransform)
    func endTransform(_ transform: TouchTransform)
    
    func touched(_ point: CGPoint)
    func moveDragging(_ point: CGPoint)
    func endDragging()
    
    func tap(_ point: CGPoint)
}
