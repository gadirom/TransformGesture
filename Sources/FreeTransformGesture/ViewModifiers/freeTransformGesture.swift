
import SwiftUI

struct FreeTransformGestureModifier: ViewModifier {
    
    let transform: TouchTransform
    var transformMode: TransformMode
    var active: Bool
    var onTap: (CGPoint)->()
    
    @State var frameSize = CGSize()
    
    func body(content: Content) -> some View {
        ZStack{
            ViewWithGestures(transform: transform,
                             transformMode: transformMode,
                             frameSize: frameSize,
                             onTap: onTap)
            content
                .allowsHitTesting(!active)
        }.overlay(
            GeometryReader { geo in
                Color.clear
                    .preference(key: FramePreferenceKey.self, value: geo.frame(in:.global))
            }.onPreferenceChange(FramePreferenceKey.self){
                self.frameSize = $0.size
            }
        )
    }
}

public extension View{
    func freeTransformGesture(transform: TouchTransform,
                              transformMode: TransformMode = .auto,
                              active: Bool = true,
                              onTap: @escaping (CGPoint)->() = {_ in }) -> some View{
        self.modifier(FreeTransformGestureModifier(transform: transform,
                                                   transformMode: transformMode,
                                                   active: active,
                                                   onTap: onTap))
    }
}

struct FramePreferenceKey: PreferenceKey {
   static var defaultValue = CGRect()
   
   static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
       value = nextValue()
   }
}
