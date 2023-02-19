
import SwiftUI
import MetalKit
import CGMath

@MainActor
public class TouchTransform: ObservableObject{
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
                scaleSnapDistance: CGFloat = 0) {
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
    }
    
    //Published Dragging Values
    @Published public var isTouching = false
    @Published public var isDragging = false
    
    @Published public var firstTouch: CGPoint = .zero
    @Published public var currentTouch: CGPoint = .zero
    @Published public var offset: CGSize = .zero
    
    @Published public var floatFirstTouch: simd_float2 = [0,0]
    @Published public var floatCurrentTouch: simd_float2 = [0,0]
    @Published public var floatOffset: simd_float2 = [0,0]
    
    //Published Transform Values
    @Published public var isTransforming = false
    
    @Published public var matrix = matrix_float3x3()
    @Published public var matrixInveresed = matrix_float3x3()
    
    @Published public var translation: CGSize = .zero
    @Published public var scale: CGFloat = 1
    @Published public var rotation: CGFloat = 0
    @Published public var centerPoint: CGPoint = .zero
    
    @Published public var floatTranslation: simd_float2 = [0,0]
    @Published public var floatScale: Float = 1
    @Published public var floatRotation: Float = 0
    @Published public var floatCenterPoint: simd_float2 = [0,0]
    
    @Published public var translationXOutOfBounds = false
    @Published public var translationYOutOfBounds = false
    @Published public var scaleOutOfBounds = false
    @Published public var rotationOutOfBounds = false
    
    @Published public var translationXSnapped = false
    @Published public var translationYSnapped = false
    @Published public var scaleSnapped = false
    @Published public var rotationSnapped = false
    
    public var translationRangeX: ClosedRange<CGFloat>
    public var translationRangeY: ClosedRange<CGFloat>
    public var scaleRange: ClosedRange<CGFloat>
    public var rotationRange: ClosedRange<CGFloat>
    
    public var translationXSnapDistance: CGFloat
    public var translationYSnapDistance: CGFloat
    public var scaleSnapDistance: CGFloat
    public var rotationSnapDistance: CGFloat
    public var rotationSnapPeriod: CGFloat
    
//    func singleTouch(_ point: CGPoint){
//        
//    }
    
    func startSingleTouch(_ touch: CGPoint){
        firstTouch = touch
        offset = .zero
        floatFirstTouch = touch.simd_float2
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
    
    func updateMatrix(centerTranslation: CGSize){
        matrix = resulting.matrix(centerTranslation: centerTranslation)
        matrixInveresed = matrix.inverse
    }
    
    func updatePublishedTransformValues(){
        updateMatrix(centerTranslation: centerTranslation)
        
        translation = resulting.translation
        scale = resulting.scale
        rotation = -resulting.rotation
        centerPoint = resulting.centerPoint+current.translation
        
        floatTranslation = translation.simd_float2
        floatScale = Float(scale)
        floatRotation = Float(rotation)
        floatCenterPoint = centerPoint.simd_float2
    }
    
    var current: Transform!
    var previous = Transform()
    var resulting = Transform()
    
    var centerTranslation: CGSize = .zero
    
    func setFrameSize(_ size: CGSize){
        centerTranslation = size * 0.5
        DispatchQueue.main.async {
            self.updateMatrix(centerTranslation: self.centerTranslation)
        }
    }
    
    func updateCenterPoint(doubleTouch:  [CGPoint]){
        self.resulting.centerPoint = median(doubleTouch[0], doubleTouch[1])
        - centerTranslation
        
        updatePublishedTransformValues()
    }
    
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
            print(angle, angle1, rotationOutOfBounds)
            
            var newTranslation: CGSize = previous.translation
            
            var scaleVector: CGPoint = newTranslation - resulting.centerPoint
            scaleVector = scaleVector * (current.scale-1)
            newTranslation += scaleVector
            
            newTranslation.rotate(center: resulting.centerPoint, angle: current.rotation)
            
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
