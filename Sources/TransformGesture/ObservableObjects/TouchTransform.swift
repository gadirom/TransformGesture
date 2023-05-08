
import SwiftUI
import MetalKit
import CGMath

@MainActor
/// Use this observable object to get touch information from ``freeTransformGesture`` view modifier,
/// pass it to ``transformEffect`` modifier to accordingly transform your views.
/// This object should be created with `@ObservedObject` attribute in your view hierarchy.
public class TouchTransform: ObservableObject{
    /// Creates an instance of ``TouchTransform``.
    /// - Parameters:
    ///   - translation: initial translation.
    ///   - scale: initial scale.
    ///   - rotation: initial rotation.
    ///   - scaleRange: range for scale.
    ///   - rotationRange: range for rotation.
    ///   - translationRangeX: range for translation along the X axis.
    ///   - translationRangeY: range for translation along the Y axis.
    ///   - translationXSnapDistance: max translational deviation along the X axis for snapping to zero.
    ///   - translationYSnapDistance: max translational deviation along the Y axis for snapping to zero.
    ///   - rotationSnapPeriod: period for rotation snapping in radians.
    ///   - rotationSnapDistance: max rotational deviation for snapping.
    ///   - scaleSnapDistance: max zooming deviation from 1 for snapping to 1.
    ///   - disableRelativeRotationAndScale: rotation andd scale is performed with center axis instead of using the centerpoint between two fingers
    public init(translation: CGSize = .zero,
                scale: CGFloat = 1,
                rotation: CGFloat = 0,
                scaleRange: ClosedRange<CGFloat> = 0...CGFloat.greatestFiniteMagnitude,
                rotationRange: ClosedRange<CGFloat> = -CGFloat.greatestFiniteMagnitude...CGFloat.greatestFiniteMagnitude,
                translationRangeX: ClosedRange<CGFloat> = -CGFloat.greatestFiniteMagnitude...CGFloat.greatestFiniteMagnitude,
                translationRangeY: ClosedRange<CGFloat> = -CGFloat.greatestFiniteMagnitude...CGFloat.greatestFiniteMagnitude,
                translationXSnapDistance: CGFloat = 0,
                translationYSnapDistance: CGFloat = 0,
                rotationSnapPeriod: CGFloat = .greatestFiniteMagnitude,
                rotationSnapDistance: CGFloat = 0,
                scaleSnapDistance: CGFloat = 0,
                disableRelativeRotationAndScale: Bool = false) {
        self.resulting.translation = translation
        self.resulting.scale = scale
        self.resulting.rotation = rotation
        self.resulting.centerPoint = .zero
        
        self.translationRangeX = translationRangeX
        self.translationRangeY = translationRangeY
        self.rotationRange = rotationRange
        self.scaleRange = scaleRange
        
        self.translation = resulting.translation
        self.scale = resulting.scale
        self.rotation = -resulting.rotation
        
        self.translationXSnapDistance = translationXSnapDistance
        self.translationYSnapDistance = translationYSnapDistance
        
        self.rotationSnapDistance = rotationSnapDistance
        self.rotationSnapPeriod = rotationSnapPeriod
        
        self.scaleSnapDistance = scaleSnapDistance
        
        self.disableRelativeRotationAndScale = disableRelativeRotationAndScale
    }
    
    //Published Dragging Values
    
    /// Indicates whether the view is being touched
    @Published public var isTouching = false
    /// Indicates whether a dragging gesture is performed inside the view.
    @Published public var isDragging = false
    
    /// Coordinates of the first touch in the view.
    @Published public var firstTouch: CGPoint = .zero
    /// Coordinates of the current touch in the view when dragging is performed.
    @Published public var currentTouch: CGPoint = .zero
    /// Coordinates offset when dragging is performed.
    @Published public var offset: CGSize = .zero
    
    @Published public var floatFirstTouch: simd_float2 = [0,0]
    @Published public var floatCurrentTouch: simd_float2 = [0,0]
    @Published public var floatOffset: simd_float2 = [0,0]
    
    //Published Transform Values
    
    /// Indicates whether a transforming with two fingers is performed inside the view.
    @Published public var isTransforming = false
    
    /// The current transformation matrix.
    @Published public var matrix = matrix_float3x3()
    /// The current inverse transformation matrix. Use it to find e.g. canvas coordinates of the touched point in the view.
    @Published public var matrixInveresed = matrix_float3x3()
    
    @Published public var translation: CGSize = .zero
    @Published public var scale: CGFloat = 1
    @Published public var rotation: CGFloat = 0
    
    /// The center point between the two fingers that sets the axis for rotation and scaling.
    @Published public var centerPoint: CGPoint = .zero
    
    @Published public var floatTranslation: simd_float2 = [0,0]
    @Published public var floatScale: Float = 1
    @Published public var floatRotation: Float = 0
    @Published public var floatCenterPoint: simd_float2 = [0,0]
    
    /// Is `true` if the translation along the X axis is currently out of bounds of ``translationRangeX``.
    @Published public var translationXOutOfBounds = false
    /// Is `true` if the translation along the Y axis is currently out of bounds ``translationRangeY``.
    @Published public var translationYOutOfBounds = false
    /// Is `true` if the scaling is currently out of bounds of ``scaleRange``.
    @Published public var scaleOutOfBounds = false
    /// Is `true` if the rotation is currently out of bounds of ``rotationRange``.
    @Published public var rotationOutOfBounds = false
    
    /// Is `true` if the translation along the X axis is currently being snapped.
    @Published public var translationXSnapped = false
    /// Is `true` if the translation along the Y axis is currently being snapped.
    @Published public var translationYSnapped = false
    /// Is `true` if the scaling is currently being snapped.
    @Published public var scaleSnapped = false
    /// Is `true` if the rotation is currently being snapped.
    @Published public var rotationSnapped = false
    
    //Public Properties
    public var translationRangeX: ClosedRange<CGFloat>
    public var translationRangeY: ClosedRange<CGFloat>
    public var scaleRange: ClosedRange<CGFloat>
    public var rotationRange: ClosedRange<CGFloat>
    
    public var translationXSnapDistance: CGFloat
    public var translationYSnapDistance: CGFloat
    public var scaleSnapDistance: CGFloat
    public var rotationSnapDistance: CGFloat
    public var rotationSnapPeriod: CGFloat
    
    //Private properties
    var current: Transform!
    var previous = Transform()
    var resulting = Transform()
    
    var centerTranslation: CGSize = .zero
    
    let disableRelativeRotationAndScale: Bool
}

// Public functions
public extension TouchTransform{
    /// Resets transformation to identity.
    func reset(){
        resulting = Transform()
        current = Transform()
        updatePublishedTransformValues()
        current = nil
    }
}

// Helper Functions
extension TouchTransform{
    func updateMatrix(){
        matrix = resulting.matrix(centerTranslation: centerTranslation)
        matrixInveresed = matrix.inverse
    }
    
    func updatePublishedTransformValues(){
        updateMatrix()
        
        translation = resulting.translation
        scale = resulting.scale
        rotation = -resulting.rotation
        centerPoint = resulting.centerPoint+current.translation
        
        floatTranslation = translation.simd_float2
        floatScale = Float(scale)
        floatRotation = Float(rotation)
        floatCenterPoint = centerPoint.simd_float2
    }
    
    func setFrameSize(_ size: CGSize){
        let newCenterTranslation: CGSize = size * 0.5
        if newCenterTranslation != centerTranslation{
            DispatchQueue.main.async {
                self.centerTranslation = size * 0.5
                self.updateMatrix()
            }
        }
    }
    func updateCenterPoint(doubleTouch:  [CGPoint]){
        self.resulting.centerPoint = median(doubleTouch[0], doubleTouch[1])
        - centerTranslation
        
        updatePublishedTransformValues()
    }
}

//Handle dragging
extension TouchTransform{
    func startSingleTouch(_ touch: CGPoint){
        firstTouch = touch
        currentTouch = touch
        offset = .zero
        floatFirstTouch = touch.simd_float2
        floatCurrentTouch = floatFirstTouch
        floatOffset = [0,0]
        
        isTouching = true
    }
    
    func moveSingleTouch(_ touch: CGPoint){
        currentTouch = touch
        offset = touch-firstTouch
        floatCurrentTouch = touch.simd_float2
        floatOffset = offset.simd_float2
        
        isDragging = true
    }
    
    func endSingleTouch(){
        isDragging = false
        isTouching = false
    }
}

// Handle Transform
extension TouchTransform{
    
    func initTransform(){
        if current==nil{
            current = Transform()
            previous = resulting
        }
        isTransforming = true
    }
    func endTransform(){
        current = nil
        isTransforming = false
        isTouching = false
    }
    
    func updateTransform(prev: [CGPoint], curr: [CGPoint]){
        
        guard current != nil else { return }
        
        if prev.count==2&&curr.count==2{
            
            let currDist = distance(curr[0], curr[1])
            let prevDist = distance(prev[0], prev[1])
            let scale: CGFloat
            if prevDist>0{
                scale = currDist/prevDist
            }else{
                scale = 1
            }
            let currMedian = median(curr[0], curr[1])
            let prevMedian = median(prev[0], prev[1])
            let translation: CGSize = currMedian - prevMedian
            
            let v1 = CGPoint(x: curr[0].x-curr[1].x, y: curr[0].y - curr[1].y)
            let v2 = CGPoint(x: prev[0].x-prev[1].x, y: prev[0].y - prev[1].y)
            var angle = atan2(v1.y, v1.x) - atan2(v2.y, v2.x)
            if angle>CGFloat.pi{
                angle -= 2*CGFloat.pi
            }
            if angle < -CGFloat.pi{
                angle += 2*CGFloat.pi
            }
            var scale1 = previous.scale * current.scale * scale
            (scale1, scaleOutOfBounds) = scaleRange.clamp(value: scale1)
            current.scale = scale1/previous.scale
            
            var angle1 = previous.rotation + current.rotation - angle
            (angle1, rotationOutOfBounds) = rotationRange.clamp(value: angle1)
            current.rotation = angle1 - previous.rotation
            
            var newTranslation: CGSize = previous.translation
            
            if !disableRelativeRotationAndScale{
                var scaleVector: CGPoint = newTranslation - resulting.centerPoint
                scaleVector = scaleVector * (current.scale-1)
                newTranslation += scaleVector
                
                newTranslation.rotate(center: resulting.centerPoint, angle: current.rotation)
            }
            
            var translation1: CGSize = previous.translation + current.translation + translation
            (translation1.width, translationXOutOfBounds) = translationRangeX.clamp(value: translation1.width)
            (translation1.height, translationYOutOfBounds) = translationRangeY.clamp(value: translation1.height)
            
            current.translation = translation1 - previous.translation
            
            var snappedTranslation: CGSize = newTranslation + current.translation
            (snappedTranslation.width, translationXSnapped) = snappedTranslation.width.snappedTo(0, distance: translationXSnapDistance)
            (snappedTranslation.height, translationYSnapped) = snappedTranslation.height.snappedTo(0, distance: translationYSnapDistance)
            
            resulting.translation = snappedTranslation
            
            var snappedRotation = previous.rotation + current.rotation
            (snappedRotation, rotationSnapped) = snappedRotation.snappedTo(ratio: rotationSnapPeriod, distance: rotationSnapDistance)
            
            resulting.rotation = snappedRotation
            
            var snappedScale = previous.scale * current.scale
            (snappedScale, scaleSnapped) = snappedScale.snappedTo(1, distance: scaleSnapDistance)
            
            resulting.scale = snappedScale
            
        }else{
            resulting.centerPoint = curr[0]
        }
        updatePublishedTransformValues()
    }
}
