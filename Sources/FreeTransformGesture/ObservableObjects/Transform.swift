import SwiftUI
import MetalKit
import CGMath

struct Transform{
    var translation: CGSize = .zero
    var scale: CGFloat = 1
    var rotation: CGFloat = 0
    var centerPoint: CGPoint = .zero
    
    func matrix(centerTranslation: CGSize) -> simd_float3x3{
        var matrix = matrix_identity_float3x3

        matrix.scale(Float(self.scale))
        matrix.rotate(Float(self.rotation))
        
        matrix.translate([Float(self.translation.width),
                          Float(self.translation.height)])
        matrix.translate([Float(centerTranslation.width),
                          Float(centerTranslation.height)])
        return matrix
    }
}
