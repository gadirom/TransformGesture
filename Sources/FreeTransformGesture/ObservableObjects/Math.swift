import SwiftUI
import MetalKit

public extension matrix_float3x3{
    static var identity: Self{
        matrix_float3x3(diagonal: [1,1,1])
    }
    mutating func translate(_ d: simd_float2){
        var transform = matrix_identity_float3x3
        transform[0,2] = d.x
        transform[1,2] = d.y
        self = matrix_multiply(self, transform)
    }
    mutating func scale(_ s: Float){
        var transform = matrix_identity_float3x3
        transform[0,0] = s
        transform[1,1] = s
        self = matrix_multiply(self, transform)
    }
    mutating func rotate(_ a: Float){
        var sin: Float = 0
        var cos: Float = 0
        __sincosf(a, &sin, &cos)
        let transform = matrix_float3x3.init(rows:[
        [cos,-sin,0],
        [sin,cos,0],
        [0,0,1]
        ])
        self = matrix_multiply(self, transform)
    }
    func transformed2D(_ coord: simd_float2)->simd_float2{
        let coord1: simd_float3 = [coord.x, coord.y, 1]*self
        return [coord1.x, coord1.y]
    }
}

public extension CGFloat{
    /// Snaps a value to the given value.
    /// - Parameters:
    ///   - value: Value to snap.
    ///   - distance: Snap distance.
    /// - Returns: Tuple with the snapped value and a Bool which is `true` if the original value was changed.
    func snappedTo(_ value: CGFloat, distance: CGFloat)->(CGFloat, Bool){
        if abs(self-value)<distance{
            return (value, true)
        }else{
            return (self, false)
        }
    }
    /// Snaps a value to the given ratio.
    /// - Parameters:
    ///   - ratio: Ratio to snap.
    ///   - distance: Snap distance.
    /// - Returns: Tuple with the snapped value and a Bool which is `true` if the original value was changed.
    func snappedTo(ratio: CGFloat, distance: CGFloat)->(CGFloat, Bool){
        if abs(fmod(self, ratio))<distance{
            return ((self / ratio).rounded(.towardZero)*ratio, true)
        }else{
            return (self, false)
        }
    }
}

public extension ClosedRange{
    /// Clamps a value to the bounds of the range.
    /// - Parameter value: Value to clamp
    /// - Returns: Tuple with the clamped value and a Bool value which is `false` if the value stayed the same.
    func clamp(value: Self.Bound) -> (Self.Bound, Bool){
        let clampedValue = Swift.max(self.lowerBound, Swift.min(self.upperBound, value))
        return (clampedValue, value != clampedValue)
    }
}

public extension CGPoint{
    var simd_float2: simd_float2{
        [Float(self.x), Float(self.y)]
    }
    var simd_float3: simd_float2{
        [Float(self.x), Float(self.y), 1]
    }
}

public extension CGSize{
    var simd_float2: simd_float2{
        [Float(self.width), Float(self.height)]
    }
    var simd_float3: simd_float2{
        [Float(self.width), Float(self.height), 1]
    }
}

public extension CGSize{
    mutating func rotate(center: CGPoint, angle: CGFloat){
        let s = sin(-angle)
        let c = cos(-angle)

        // translate point to origin:
        width -= center.x
        height -= center.y

        // rotate point
        let xnew = width * c - height * s;
        let ynew = width * s + height * c;

        // translate point back:
        width = xnew + center.x
        height = ynew + center.y
    }
}
