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
    
    internal var pinchRecognizer: UIGestureRecognizer!
    internal var scrollRecognizer: UIGestureRecognizer!
    
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
        
        if checkIfOnMac(){
            setupGestureRecognizer()
        }
    
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
}

func checkIfOnMac() -> Bool{
    
    var isRunningOnMac: Bool = false

    if #available(iOS 14.0, *) {
        isRunningOnMac = ProcessInfo.processInfo.isiOSAppOnMac
    }
    
    return isRunningOnMac
}
