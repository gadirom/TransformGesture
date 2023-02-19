//
//  File.swift
//  
//
//  Created by Roman Gaditskiy on 02.02.2023.
//

import SwiftUI

struct ViewWithGestures: UIViewRepresentable {
    
    let transform: TouchTransform
    var transformMode: TransformMode
    var frameSize: CGSize
    var onTap: (CGPoint)->()
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        return coordinator
    }
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIViewWithGestures {
        let uiView = UIViewWithGestures(touchTransform: transform,
                                        transformMode: transformMode,
                                        onTap: onTap)
        uiView.transformMode = transformMode
        return uiView
    }
    func updateUIView(_ uiView: UIViewWithGestures, context: UIViewRepresentableContext<Self>) {
        uiView.transformMode = transformMode
        uiView.setFrameSize(frameSize)
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
