//
//  SingleTouch.swift
//  TransformGesture
//
//  Created by Roman Gaditskiy on 12. 10. 2025..
//

import UIKit
import CGMath

//Taps
extension UIViewWithGestures{
    func tapped(_ touch: UITouch){
        let touchPoint = touch.location(in: self)
        let point: CGPoint = touchPoint*contentScaleFactor
        touchTransform.endSingleTouch()
        onTap(touchPoint)
        touchDelegate?.tap(point)
    }
}

//Single Touches
extension UIViewWithGestures{
    
    func getSingleTouchPoint(touch: UITouch) -> CGPoint {
        let touchPoint = touch.location(in: self)
        let point: CGPoint = touchPoint*contentScaleFactor
        return point
    }
    
    func startSingleTouch(_ touch: UITouch){
        let point = getSingleTouchPoint(touch: touch)
        previousPoint = point
        touchTransform.startSingleTouch(point)
        touchDelegate?.touched(point)
    }
    func moveSingleTouch(_ touch: UITouch){
        let point = getSingleTouchPoint(touch: touch)
        let length = distance(previousPoint, point)
        if length>=minimumDrawDistance{
            dragging = true
            //previousPoint = point
        }
        if dragging{
            touchTransform.moveSingleTouch(point)
            touchDelegate?.moveDragging(point)
        }
    }
    func endSingleTouch(){
        dragging = false
        touchTransform.endSingleTouch()
        touchDelegate?.endDragging()
    }
}
