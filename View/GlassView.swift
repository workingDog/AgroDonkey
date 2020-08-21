//
//  GlassView.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/07/22.
//

import Foundation
import SwiftUI
import Combine
import MapKit
import CoreLocation


struct GlassView: View {
    
    @EnvironmentObject var land: LandModel
    
    // because Color.clear lets tap events pass through 
    let clearColor = Color.white.opacity(0.01)
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(clearColor)
                .edgesIgnoringSafeArea(.all)
                .gesture(addMarkerGesture)
                .simultaneousGesture(
                    // to de-activate the editing of a polygon
                    TapGesture()
                        .onEnded { _ in
                            if land.isEditing {
                                land.polyIndexToEdit = nil
                                land.isEditing = false
                                land.allowEditing = false
                            }
                        })
            
            if land.isAdding {
                ForEach(land.points.indices, id: \.self) { i in
                    markerDot(i)
                }
                drawLines().stroke(land.mapPolyLineColor, style: StrokeStyle(lineWidth: 2, dash: [5]))
            }
            
            if land.isEditing {
                // show the handles and lines for this poly 
                if let ndx = land.polyIndexToEdit {
                    markerPolyDot(ndx)
                    drawPolyLines(land.agroPolyMapList[ndx].cgPoints)
                        .stroke(land.mapPolyLineColor, lineWidth: 2)
                } else {
                  //  showPolies
                }
            }
        }.edgesIgnoringSafeArea(.all)

    }

    // ----------------------------during editing------------------------------------
    
    var showPolies: some View {
        ForEach(land.agroPolyMapList.indices, id: \.self) { x in
            markerPolyDot(x)
            drawPolyLines(land.agroPolyMapList[x].cgPoints).stroke(land.mapPolyLineColor, lineWidth: 2)
        }
    }
    
    func markerPolyDot(_ x: Int) -> some View {
        ForEach(land.agroPolyMapList[x].cgPoints.indices, id: \.self) { i in
            Circle().overlay(Circle().stroke(land.mapPolyHandleColor, lineWidth: 5))
                .foregroundColor(clearColor)
                .frame(width: land.handleSize, height: land.handleSize).position(land.agroPolyMapList[x].cgPoints[i])
                .highPriorityGesture(dragGestureEdit(x, i))
        }
    }
    
    func drawPolyLines(_ points: [CGPoint]) -> Path {
        var path = Path()
        if points.count >= 2  {
            path.move(to: points.first!)
            path.addLines(points)
            // close the shape
            path.move(to: points.last!)
            path.addLine(to: points.first!)
        }
        return path
    }
    
    func dragGestureEdit(_ x: Int, _ i: Int) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged {
                if land.isEditing {
                    land.agroPolyMapList[x].changePoint(i, to: $0.location)
                    land.refresh.toggle()   // <--- important
                }
            }
    }
    
    // ------------------------during adding----------------------------------------
    
    func markerDot(_ i: Int) -> some View {
        Circle().overlay(Circle().stroke(land.mapPolyHandleColor, lineWidth: 5))
            .foregroundColor(clearColor)
            .frame(width: land.handleSize, height: land.handleSize).position(land.points[i])
            .highPriorityGesture(dragGestureAdd(i))
    }

    func drawLines() -> Path {
        var path = Path()
        if land.points.count >= 2  {
            path.move(to: land.points.first!)
            path.addLines(land.points)
      //      path.closeSubpath()
        }
        return path
    }
    
    func dragGestureAdd(_ i: Int) -> some Gesture {
        DragGesture(minimumDistance: 5, coordinateSpace: .global)
            .onChanged {
                if land.isAdding { land.points[i] = $0.location }
            }
    }
    
    private var addMarkerGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onEnded { p in
                if land.isAdding {
                    land.points.append(p.location)
                }
            }
    }
 
}
