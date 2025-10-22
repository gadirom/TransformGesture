
import SwiftUI

public extension View{
    /// View modifier that transforms a view according to the given ``TouchTransform`` object.
    /// - Parameter transform: transformation information.
    /// - Returns: a view with the added transformation.
    func transformEffect(_ transform: Binding<TouchTransform>) -> some View{
        self.modifier(TransformEffect(transform: transform))
    }
}

struct TransformEffect: ViewModifier {
    
    @Binding var transform: TouchTransform
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(transform.scale)
            .rotationEffect(Angle(radians: transform.rotation))
            .offset(transform.translation)
    }
}
