//
//  File.swift
//  
//
//  Created by Roman Gaditskiy on 02.02.2023.
//

import SwiftUI

struct ViewWithGestures: UIViewRepresentable {
    
    let transform: TouchTransform
    var draggingDisabled: Bool
    var transformDisabled: Bool
    //var frameSize: CGSize
    //var touchDelegate: TouchDelegate?
    var onTap: (CGPoint)->()
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        return coordinator
    }
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIViewWithGestures {
        let uiView = UIViewWithGestures(touchTransform: transform,
                                        draggingDisabled: draggingDisabled,
                                        transformDisabled: transformDisabled,
                                        onTap: onTap)
        uiView.draggingDisabled = draggingDisabled
        uiView.transformDisabled = transformDisabled
        //uiView.touchDelegate = touchDelegate
        return uiView
    }
    func updateUIView(_ uiView: UIViewWithGestures, context: UIViewRepresentableContext<Self>) {
        uiView.draggingDisabled = draggingDisabled
        uiView.transformDisabled = transformDisabled
        uiView.setFrameSize(transform.frameSize)
    }
}

final class Coordinator: NSObject{
    
    override init(){
        super.init()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
