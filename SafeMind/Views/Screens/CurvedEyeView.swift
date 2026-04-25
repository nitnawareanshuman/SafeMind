//
//  CurvedEyeView.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 15/04/26.
//


import SwiftUI

struct CurvedEyeView: View {
    var width: CGFloat = 120
    var height: CGFloat = 30
    var curveAmount: CGFloat = 50   // how deep the curve is
    var angle: Double = 180           // rotation
    var lineWidth: CGFloat = 5
    var color: Color = .black
    
    var body: some View {
        
        Path { path in
            
            let start = CGPoint(x: 0, y: height)
            let end = CGPoint(x: width, y: height)
            let control = CGPoint(x: width / 2,
                                  y: height - curveAmount)
            
            path.move(to: start)
            path.addQuadCurve(to: end, control: control)
        }
        .stroke(color,
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round
                ))
        .frame(width: width, height: height)
        .rotationEffect(.degrees(angle))
    }
}


#Preview {
    CurvedEyeView()
}
