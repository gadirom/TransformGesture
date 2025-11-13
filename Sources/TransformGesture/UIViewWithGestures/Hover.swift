//
//  Hover.swift
//  TransformGesture
//
//  Created by Roman Gaditskiy on 13. 11. 2025..
//

import UIKit
import CGMath

extension UIViewWithGestures{
    func processHover(recognizer: UIHoverGestureRecognizer){
        let location = recognizer.location(in: self)
        let point: CGPoint = location*contentScaleFactor
        
        if recognizer.state == .began || recognizer.state == .changed{
            self.hoverPoint = point
            //touchTransform.updateCenterPointFromHover(point: point)
        }else{
            self.hoverPoint = nil
        }
        
        touchDelegate?.onHover(point, state: recognizer.state)
    }
}
