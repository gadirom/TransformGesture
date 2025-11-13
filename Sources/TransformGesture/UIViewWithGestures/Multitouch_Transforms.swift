//
//  Transforms.swift
//  TransformGesture
//
//  Created by Roman Gaditskiy on 12. 10. 2025..
//

import UIKit
import CGMath

//transforms
extension UIViewWithGestures{
    func getDoubleTouch(_ touches: [UITouch]) -> [CGPoint]{
        touches.map{
            $0.location(in: self) * contentScaleFactor
        }
    }
    func startTransform(_ touches: [UITouch]){
        transforming = true
        print("start transform")
        
        let doubleTouch = getDoubleTouch(touches)
        //print("first doubleTouch:", doubleTouch)
        touchTransform.initTransform()
        
        touchTransform.updateCenterPoint(doubleTouch: doubleTouch)
        
        previousPoints = doubleTouch
        
        touchDelegate?.startTransform()
    }
    //when it was one touch, but now its two
    func continueTransform(_ touches: [UITouch]){
        transforming = true
        print("continue transform")
        
        let doubleTouch = getDoubleTouch(touches)
        
        touchTransform.endSingleTouch()
        
        touchTransform.endTransform()
        touchTransform.initTransform()

        touchTransform.updateCenterPoint(doubleTouch: doubleTouch)
        
        previousPoints = doubleTouch
        
        //touchDelegate.moveTransform(currentTransform)
    }
    func moveTransform(_ touches: [UITouch]){
        transforming = true
        //print("move transform")
        
        let doubleTouch = getDoubleTouch(touches)
        //print("doubleTouch:", doubleTouch)
       
        touchTransform.updateTransform(prev: previousPoints,
                                       curr: doubleTouch)
        
        previousPoints = doubleTouch
        
        touchDelegate?.changeTransform(touchTransform)
    }
    func endTransform(){
        transforming = false
        print("end transform")
        touchTransform.endTransform()
        touchDelegate?.endTransform(touchTransform)
    }
}
