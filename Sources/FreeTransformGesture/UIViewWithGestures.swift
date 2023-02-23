import MetalKit
import SwiftUI
import CGMath

final class UIViewWithGestures: UIView{
    
    let touchTransform: TouchTransform
    var draggingDisabled: Bool
    {
        didSet{
            if oldValue && !draggingDisabled{
                if transforming{
                    DispatchQueue.main.async {
                        if let touch = self.previousTouches.first{
                            self.transforming = false
                            self.touchTransform.endTransform()
                            self.touchTransform.isTouching = true
                            //self.touchTransform.current = nil
                            //self.touchTransform.isTransforming = false
                            self.touchesBeganLogicForSingleTouch(touches: [touch])
                        }
                    }
                }
            }
        }
    }
    var transformDisabled: Bool
    
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
         draggingDisabled: Bool,
         transformDisabled: Bool,
         onTap: @escaping (CGPoint)->()){
        self.touchTransform = touchTransform
        self.draggingDisabled = draggingDisabled
        self.transformDisabled = transformDisabled
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
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?){
        touchesEndedLogic(touches)
    }
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEndedLogic(touches)
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
