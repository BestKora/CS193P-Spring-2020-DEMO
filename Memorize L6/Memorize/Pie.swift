//
//  Pie.swift
//  Memorize
//
//  Created by CS193P Instructor on 04/06/2020.
//  Copyright © 2020 cs193p instructor.
//

import SwiftUI

struct Pie: Shape, Animatable {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool = false
    
    var animatableData: AnimatablePair<Double,Double> {
        get {
            AnimatablePair(startAngle.radians,endAngle.radians)
        }
        set{
            startAngle = Angle.radians(newValue.first)
            endAngle = Angle.radians(newValue.second)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width,rect.height) / 2
        let start = CGPoint(
            x:   center.x + radius * cos(CGFloat(startAngle.radians)),
            y:   center.x + radius * sin(CGFloat(startAngle.radians))
        )
        
        var p = Path ()
        p.move(to: center)
        p.addLine(to: start)
        p.addArc(center: center,
                 radius: radius,
                 startAngle: startAngle,
                 endAngle: endAngle,
                 clockwise: clockwise)
        p.addLine(to: center)
        
        return p
    }
}
