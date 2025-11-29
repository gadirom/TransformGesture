//
//  Logic.swift
//  TransformGesture
//
//  Created by Roman Gaditskiy on 12. 10. 2025..
//

import UIKit

//Logic
extension UIViewWithGestures{
    //Began
    func touchesBeganLogicForTransform(touches: Set<UITouch>){
        if previousTouches.isEmpty{
            if touches.count>1{//first doubletouch
                moved = true
                let twoTouches = [touches.first!, touches.dropFirst().first!]
                startTransform(twoTouches)
                previousTouches = twoTouches
                //print("touches:", touches)
                return
            }else{//first single touch possible transform
                if let touch = touches.first{//singletouch possible transform
//                    if draggingDisabled{
//                        startTransform([touch, touch])
//                    }
                    startSingleTouch(touch)
                    previousTouches.append(touch)
                    moved = false
                    return
                }
            }
        }
        if previousTouches.count == 1 && !dragging{
            if let touch = touches.first(where: {$0 !== previousTouches.first!}) {
                moved = true
                previousTouches.append(touch)
                //add second finger
                continueTransform(previousTouches)
            }
        }
    }
    func touchesBeganLogicForSingleTouch(touches: Set<UITouch>){
        if previousTouches.isEmpty{//first single touch, no transform
            if let touch = touches.first{
                previousTouches.append(touch)
                startSingleTouch(touch)
            }
        }
    }
    
    //Ended
    func touchesEndedLogic(_ touches: Set<UITouch>){
        if !dragging{//transforming, one finger up
            if let touch = previousTouches.first, let touch1 = previousTouches.last{
                if touches.contains(touch) || touches.contains(touch1){
                    previousTouches = []
                    if !moved{
                        tapped(touch)
                    }else{
                        endTransform()
                    }
                }
            }else{
                //last finger up
                endTransform()
            }
        }else{
            if let touch = previousTouches.first{
                if touches.contains(touch){
                    previousTouches = []
                    endSingleTouch()
                }
            }
            if let touch = previousTouches.last{
                if touches.contains(touch){
                    previousTouches = []
                    endSingleTouch()
                }
            }
        }
    }
}
