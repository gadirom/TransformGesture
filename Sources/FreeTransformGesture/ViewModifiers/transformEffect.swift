
import SwiftUI

struct TransformEffect: ViewModifier {
    
    @ObservedObject var transform: TouchTransform
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(transform.scale)
            .rotationEffect(Angle(radians: transform.rotation))
            .offset(transform.translation)
    }
}

public extension View{
    func transformEffect(_ transform: TouchTransform) -> some View{
        self.modifier(TransformEffect(transform: transform))
    }
}
