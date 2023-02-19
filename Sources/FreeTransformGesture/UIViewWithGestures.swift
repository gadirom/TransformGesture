import MetalKit
import SwiftUI
import CGMath

public enum TransformMode{
    case off, on, auto
}

public final class UIViewWithGestures: UIView{
    
    let touchTransform: TouchTransform
    var transformMode: TransformMode
    
    let minimumDrawDistance: CGFloat = 3
    let minimumTransform: CGFloat = 3
    
    var onTap: (CGPoint)->()
    
    weak var touchDelegate: TouchDelegate?
    
    var previousTouches: [UITouch] = []
    
    var previousPoints: [CGPoint] = []
    
    var previousPoint: CGPoint = CGPoint()
    
    var moved = false
    
    var dragging = false
    var transforming = false
    
    init(touchTransform: TouchTransform,
         transformMode: TransformMode,
         onTap: @escaping (CGPoint)->()){
        self.touchTransform = touchTransform
        self.transformMode = transformMode
        self.onTap = onTap
        super.init(frame: CGRect())
        
        self.isMultipleTouchEnabled = true
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setFrameSize(_ size: CGSize){
        self.touchTransform.setFrameSize(size)
    }
    
//    public override func willMove(toWindow newWindow: UIWindow?) {
//        super.willMove(toWindow: newWindow)
//
//        if newWindow == nil {
//            // UIView disappear
//        } else {
//            // UIView appear
//            //setFrameSize()
//        }
//    }
   
    //Began
    public override func touchesBegan(_ touches: Set<UITouch>,
                                     with event: UIEvent?){
        
        if transformMode == .on || transformMode == .auto{
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
                        startSingleTouch(touch)
                        previousTouches.append(touch)
                        moved = false
    //                    startTransform([touch, touch])
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
        }else{
            if previousTouches.isEmpty{//first single touch, no transform
                if let touch = touches.first{
                    previousTouches.append(touch)
                    startSingleTouch(touch)
                }
            }
        }
    }
    
    //Move
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if transforming{
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
    
    //Ended
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?){
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
            }
        }else{
            if let touch = previousTouches.first{
                if touches.contains(touch){
                    previousTouches = []
                    endSingleTouch()
                }
            }
        }
    }
}

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
        print("move transform")
        
        let doubleTouch = getDoubleTouch(touches)
        //print("doubleTouch:", doubleTouch)
       
        touchTransform.updateTransform(prev: previousPoints,
                              curr: doubleTouch)
        
        previousPoints = doubleTouch
        
        touchDelegate?.moveTransform(touchTransform)
    }
    func endTransform(){
        transforming = false
        print("end transform")
        touchTransform.endTransform()
        touchDelegate?.endTransform(touchTransform)
    }
}

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
    func startSingleTouch(_ touch: UITouch){
        let touchPoint = touch.location(in: self)
        let point: CGPoint = touchPoint*contentScaleFactor
        previousPoint = point
        touchTransform.startSingleTouch(point)
        touchDelegate?.startSingleTouch(point)
    }
    func moveSingleTouch(_ touch: UITouch){
        let touchPoint = touch.location(in: self)
        let point: CGPoint = touchPoint*contentScaleFactor
        let length = distance(previousPoint, point)
        if length>=minimumDrawDistance{
            dragging = true
            //previousPoint = point
        }
        if dragging{
            touchTransform.moveSingleTouch(point)
            touchDelegate?.moveSingleTouch(point)
        }
    }
    func endSingleTouch(){
        dragging = false
        touchTransform.endSingleTouch()
        touchDelegate?.endSingleTouch()
    }
}
