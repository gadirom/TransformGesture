//
//  Touches.swift
//  TransformGesture
//
//  Created by Roman Gaditskiy on 12. 10. 2025..
//

import UIKit

extension UIViewWithGestures{
    public override func touchesBegan(_ touches: Set<UITouch>,
                                     with event: UIEvent?){
        if transformDisabled{
            if !draggingDisabled{
                touchesBeganLogicForSingleTouch(touches: touches)
            }
        }else{
            touchesBeganLogicForTransform(touches: touches)
        }
    }
    //Move
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if transforming || draggingDisabled{
            if previousTouches.count == 1{
                let touch = previousTouches.first!
                if !moved{
                    moved = true
                    startTransform([touch, touch])
                }
                moveTransform([touch, touch])
            }else{
                moveTransform(previousTouches)
            }
        }else{
            if let touch = previousTouches.first{
                moveSingleTouch(touch)
            }
        }
    }
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?){
        touchesEndedLogic(touches)
    }
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEndedLogic(touches)
    }
}
