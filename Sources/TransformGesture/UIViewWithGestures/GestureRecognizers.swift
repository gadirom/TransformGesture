//
//  GestureRecognizers.swift
//  TransformGesture
//
//  Created by Roman Gaditskiy on 12. 10. 2025..
//

import UIKit

//Gesture recognisers (only for touchpad support)
extension UIViewWithGestures: UIGestureRecognizerDelegate{
    func setupGestureRecognizer() {
        
        let pinch = UIPinchGestureRecognizer(target: self,
                                             action: #selector(pinch))
        
        let scroll = UIPanGestureRecognizer(target: self,
                                            action: #selector(scroll))
        scroll.minimumNumberOfTouches = 2
        scroll.maximumNumberOfTouches = 2
        scroll.allowedScrollTypesMask = .all
        
        //pinch.numberOfTouches = 2
        //pinch.buttonMask = .
        
        scroll.delegate = self
        pinch.delegate = self
        
        addGestureRecognizer(pinch)
        addGestureRecognizer(scroll)
        
        self.pinchRecognizer = pinch
        self.scrollRecognizer = scroll
        
        let hover = UIHoverGestureRecognizer(target: self,
                                             action: #selector(hovering))
        
        addGestureRecognizer(hover)
        
        //
        
//        let pan = UIPanGestureRecognizer(target: self,
//                                         action: #selector(pan))
//        
//        pan.maximumNumberOfTouches = 1
//        pan.minimumNumberOfTouches = 1
//        
//        addGestureRecognizer(pan)
        
//        let doubleTap = UITapGestureRecognizer(target: self,
//                                               action: #selector(doubleTap))
//        doubleTap.numberOfTapsRequired = 2
//        doubleTap.numberOfTouchesRequired = 1
//        addGestureRecognizer(doubleTap)
//
//        let tap = UITapGestureRecognizer(target: self,
//                                       action: #selector(tap))
//        tap.numberOfTapsRequired = 1
//        tap.numberOfTouchesRequired = 1
//        addGestureRecognizer(tap)
            
    }
//    public func gestureRecognizer(
//        _ gestureRecognizer: UIGestureRecognizer,
//        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
//    ) -> Bool {
//            gestureRecognizer === pinchRecognizer
//    && otherGestureRecognizer === scrollRecognizer
//    }
    @objc func pinch(recognizer: UIPinchGestureRecognizer) {
        
        guard previousTouches.isEmpty
        else{ return }
        
        print("pinch")
        switch recognizer.state {
        case .began:
            touchTransform.initTransform()
        case .changed:
            
            if let _ = touchTransform.current{
                
                if let hoverPoint, touchTransform.delegate?.centerOnHover ?? true{
                    touchTransform._updateCenterPoint(point: hoverPoint)
                }
                
                touchTransform.clampAndSnap(
                    scale: pow(recognizer.scale, 0.5),
                    angle: 0,
                    translation: .zero)
                touchTransform.updatePublishedTransformValues()
            
                recognizer.scale = 1.0
            }
            
            
        case .ended, .cancelled:
            print("transform ended in pinch")
            //touchTransform.current = nil
            endTransform()
            
        default: break
        }
    }
//    @objc func pan(recognizer: UIPanGestureRecognizer) {
//        print("pan")
//        switch recognizer.state {
//            case .changed, .ended:
//            
////            delegate?.onPan(
////                translation: recognizer.translation(in: recognizer.view)
////            )
//            
//            recognizer.setTranslation(.zero, in: recognizer.view)
//           
//            default: break
//        }
//    }
    
    @objc func scroll(recognizer: UIPanGestureRecognizer) {
        print("scroll")
        switch recognizer.state {
        case .began:
            touchTransform.initTransform()
            
        case .changed:
            
            if let _ = touchTransform.current{
                
                let translation = CGSize(
                    width:  recognizer.translation(in: self).x,
                    height: recognizer.translation(in: self).y
                )
                
                touchTransform.clampAndSnap(
                    scale: 1,
                    angle: 0,
                    translation: translation)
                touchTransform.updatePublishedTransformValues()
                
                recognizer.setTranslation(.zero, in: recognizer.view)
            }
            
        case .ended, .cancelled:
            print("transform ended in scroll")
            endTransform()
            //touchTransform.current = nil
            
        default: break
        }
    }
    
    @objc func hovering(recognizer: UIHoverGestureRecognizer) {
        processHover(recognizer: recognizer)
    }
}
