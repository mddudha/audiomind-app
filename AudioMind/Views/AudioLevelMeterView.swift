//
//  AudioLevelMeterView.swift
//  AudioMind
//
//  Created by Mirvaben Dudhagara on 7/2/25.
//

import SwiftUI

struct AudioLevelMeterView: View {
    var levels: [Float]
    
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let width = size.width
                let height = size.height
                let midY = height / 2
                let count = levels.count
                guard count > 1 else { return }
                let step = width / CGFloat(count - 1)
                var path = Path()
                path.move(to: CGPoint(x: 0, y: midY))
                for (i, level) in levels.enumerated() {
                    let x = CGFloat(i) * step
                    let y = midY - CGFloat(level) * (height / 2 - 2)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                context.stroke(path, with: .color(Color("DarkMossGreen")), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: 60)
        .background(Color("MossGreen").opacity(0.10))
        .cornerRadius(16)
    }
}

#Preview {
    let N = 50
    let sine: [Float] = (0..<N).map { i in
        let t = Float(i) / Float(N-1)
        return 0.5 + 0.5 * sin(t * .pi * 2 * 2)
    }
    return AudioLevelMeterView(levels: sine)
        .padding()
        .background(Color("MossGreen"))
} 
