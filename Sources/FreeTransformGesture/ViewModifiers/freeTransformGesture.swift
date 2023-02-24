
import SwiftUI

public extension View{
    /// View Modifier that adds a specific gesture recognizer to a SwiftUI view.
    /// - Parameters:
    ///   - transform: ``TouchTransform`` object created with `@ObservedObject` modifier.
    ///   - draggingDisabled: specifies if the dragging feature should be disabled.
    ///   It is possible to change it from `true` to `false` "on the fly" while handling ``isTouching`` published value of the ``TouchTransform`` object (see Example app).
    ///   - transformDisabled: specifies if the transforming feature should be disabled.
    ///   - touchDelegate: ``TouchDelegate`` object that contains callbacks for handling touch events.
    ///   - active: turns the modifier on and off.
    ///   - onTap: the callback for handling tapping gestures.
    /// - Returns: returns a view with the added gesture recognizer.
    func freeTransformGesture(transform: TouchTransform,
                              draggingDisabled: Bool = false,
                              transformDisabled: Bool = false,
                              touchDelegate: TouchDelegate? = nil,
                              active: Bool = true,
                              onTap: @escaping (CGPoint)->() = {_ in }) -> some View{
        self.modifier(FreeTransformGestureModifier(transform: transform,
                                                   draggingDisabled: draggingDisabled,
                                                   transformDisabled: transformDisabled,
                                                   touchDelegate: touchDelegate,
                                                   active: active,
                                                   onTap: onTap))
    }
}

struct FreeTransformGestureModifier: ViewModifier {
    
    let transform: TouchTransform
    var draggingDisabled: Bool
    var transformDisabled: Bool
    let touchDelegate: TouchDelegate?
    var active: Bool
    var onTap: (CGPoint)->()
    
    @State var frameSize = CGSize()
    
    func body(content: Content) -> some View {
        ZStack{
            ViewWithGestures(transform: transform,
                             draggingDisabled: draggingDisabled,
                             transformDisabled: transformDisabled,
                             frameSize: frameSize,
                             touchDelegate: touchDelegate,
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

struct FramePreferenceKey: PreferenceKey {
   static var defaultValue = CGRect()
   
   static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
       value = nextValue()
   }
}
