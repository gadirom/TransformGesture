import SwiftUI

public protocol TouchDelegate: AnyObject{
    
    func startTransform()
    func moveTransform(_ transform: TouchTransform)
    func endTransform(_ transform: TouchTransform)
    
    func startSingleTouch(_ point: CGPoint)
    func moveSingleTouch(_ point: CGPoint)
    func endSingleTouch()
    
    func tap(_ point: CGPoint)
}

class MyTouchDelegate: TouchDelegate{
    
    func startTransform() {
        print("start transform")
    }
    func moveTransform(_ transform: TouchTransform) {
        print("move transform")
    }
    func endTransform(_ transform: TouchTransform) {
        print("end transform")
    }
    
    func startSingleTouch(_ point: CGPoint) {
        print("start single touch")
    }
    
    func moveSingleTouch(_ point: CGPoint) {
        print("move single touch")
    }
    
    func endSingleTouch() {
        print("end single touch")
    }
    
    func tap(_ point: CGPoint) {
        print("tap")
    }
}
