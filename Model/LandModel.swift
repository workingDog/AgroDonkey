//
//  LandModel.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/07/19.
//

import Foundation
import SwiftUI
import Combine
import CoreLocation
import MapKit
import AgroAPI


class LandModel: ObservableObject {
    
    var agroProvider = AgroProvider(apiKey: "your key")
    
    @Published var mapType = MKMapType.standard
    // initial map region, read from defaults by StoreService
    @Published var region = StoreService.getRegion()

    // satellite imagery type selection
    @Published var satImgType = 3 {
        didSet {
            self.getAllImages()
        }
    }
    // satellite imagery types
    let satImgTypes = ["None", "True color", "False color", "NDVI", "EVI", "DSWI", "NDWI", "NRI", "EVI2"]
    // the start date to search for satellite images
    @Published var startImageSearch = Date().addingTimeInterval(-60*60*24*30)  // days in the past
    // the end date to search for satellite images
    @Published var endImageSearch = Date()    // today
    // selected satellite type, Sentinel-2 or Lansat-8
    @Published var satType = 0 {
        didSet {
            self.getAllImages()
        }
    }
    let satTypes = ["Sentinel-2", "Landsat-8"]  // s2 or l8  (elle not eye)
    // working temp imagery set, for imagery selection see PolyInfoView
    @Published var imagery = [PolyImagery]()
    
    // the main list of all agro polygons
    @Published var agroPolyMapList: [AgroPolyMap] = []
    
    // for poly editing
    @Published var allowEditing = false
    @Published var isEditing = false
    @Published var isAdding = false
    @Published var polyIndexToEdit: Int? = nil
    // working temporary points when adding a new polygon
    @Published var points = [CGPoint]()
    
    // the id of the polygon touched on the Map
    @Published var touchedPolyId = "" {
        didSet {
            // update the touchedPolyName
            if let poly = agroPolyMapList.first(where: {$0.id == touchedPolyId}) {
                self.touchedPolyName = poly.agroPoly.name
            }
        }
    }
    // convenience, the name of the polygon touched
    @Published var touchedPolyName = ""
    
    // to force a refresh of the screen
    @Published var refresh: Bool = false
    
    @Published var mapPolyHandleColor = UIColor.red.withAlphaComponent(0.9)
    @Published var mapPolyLineColor = UIColor.red.withAlphaComponent(0.9)
    @Published var mapPolyFillColor = UIColor.magenta.withAlphaComponent(0.9)
    @Published var handleSize = CGFloat(30)
    
    var cancellables = Set<AnyCancellable>()
    
    
    init() {
        // to receive all messages
        NotificationCenter.default.publisher(for: Messenger.agroNotification)
            .compactMap{$0.object as? Messenger}
            .map{ $0 }
            .sink() { messenger in
                if messenger.actionType == .editPoly {
                    if let ndx = self.agroPolyMapList.firstIndex(where: {$0.id == messenger.polyId}) {
                        self.polyIndexToEdit = ndx
                    }
                } else {
                    self.processMessage(messenger)
                }
            }
            .store(in: &cancellables)
    }
    
    func getAllAgroPoly() {
        agroProvider.getPolyList { response in
            if let polyArr = response {
                self.agroPolyMapList = polyArr.map{AgroPolyMap(id: $0.id, name: $0.name, area: $0.area, feature: $0.geo_json)}
                self.getAllImages()
     //           self.showPolyInfo()  // for testing
     //           self.getAllImageryMeta()  // for testing
            }
        }
    }
    
    // for testing
    func showPolyInfo() {
        for agroPoly in self.agroPolyMapList {
            print("\n---> LandModel name: \(agroPoly.agroPoly.name) id: \(agroPoly.id)  area: \(agroPoly.mkPoly.area) coords: \(agroPoly.agroPoly.geo_json.geometry.coordinates)")
        }
    }

    func processMessage(_ msnger: Messenger) {
        // do nothing here while editing
        if !isEditing {
            if msnger.actionType == .addPoly {
                // adding a new polygon to the server
                addPoly(msnger.polyId)
            }
            
            if msnger.actionType == .adjustAll {
                // adjusting an existing poygon
                updateServerPoly()
            }
        }
    }
    
    // todo should use publisher composition somehow
    func updateServerPoly() {
        // for all polygons that have changes, ie some points have been edited
        for poly in agroPolyMapList.filter({ $0.hasChanged }) {
            // first remove the poly on the server
            agroProvider.deletePoly(id: poly.id) { _ in
                // then add the updated poly to the server
                self.agroProvider.createPoly(poly: poly.agroPoly) { resp in
                    if let response = resp {
                        // update our agroPoly id to match the id given by the server
                        poly.id = response.id
                        // is now up to date
                        poly.hasChanged = false
                    }
                }
            }
        }
    }
    
    private func addPoly(_ id: String) {
        if let agropoly = agroPolyMapList.first(where: {$0.id == id}) {
            addPoly(agroPoly: agropoly)
        }
    }
    
    private func addPoly(agroPoly: AgroPolyMap) {
        // add to the Agro server
        agroProvider.createPoly(poly: agroPoly.agroPoly) { resp in
            if let response = resp {
                // change the agroPoly to match the id given by the server
                agroPoly.id = response.id  // <--- here the id is made the same as the agroPoly on the Agro API server id
            }
        }
    }
    
    func getAllImages() {
        for agroPoly in self.agroPolyMapList {
            self.getImages(for: agroPoly)
        }
    }
    
    func getImages(for poly: AgroPolyMap) {
        let stype = satType == 0 ? "s2" : "l8"
        let options = AgroOptions(polygon_id: poly.id, start: startImageSearch, end: endImageSearch, type: stype)

        agroProvider.getImagery(options: options) { imagery in
            if let agroImgry = imagery {

                // if we have selected some imagery from the PolyInfoView, use that, otherwise use the first set we find
                var resp: AgroImagery
                if let imgry = self.getSelectedImagery(for: poly) {
                    resp = imgry.imagery
                } else {
                    if agroImgry.first == nil { return }
                    resp = agroImgry.first!
                }

                if let saturl = resp.image {
                    // get the png image
                    if let theUrl = self.getUrl(satUrl: saturl) {
                        self.agroProvider.getPngUIImage(urlString: theUrl, paletteid: 1) { img in
                            if let theImage = img {
                                poly.images.removeAll()
                                let satImg = SatImage(agroImagery: agroImgry,
                                                      image: theImage,
                                                      coord: poly.mkPoly.coordinate,
                                                      rect: poly.mkPoly.boundingMapRect)
                                poly.images.append(satImg)
                                self.refresh.toggle()       // <--- todo how to refresh the views
                            }
                        }
                    }
                    // get the ndvi stats for this image
                    if let statUrl = resp.stats?.ndvi {
                        self.agroProvider.getStatsInfo(urlString: statUrl) { statInfo in
                            if let theStats = statInfo {
                                poly.stats.append(theStats)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // there should be at most 1 selected imagery for this polygon
    func getSelectedImagery(for poly: AgroPolyMap) -> PolyImagery? {
        for img in poly.images {
            for imgry in img.agroImagery {
                if imgry.selected {
                    return imgry
                }
            }
        }
        return nil
    }
    
    func deselectAllImagery() {
        if let poly = agroPolyMapList.first(where: {$0.selected}) {
            for img in poly.images {
                for pol in img.agroImagery {
                    pol.selected = false
                }
            }
        }
    }

    // for testing
    func getAllImageryMeta() {
        for agroPoly in agroPolyMapList {
            getImageryMeta(for: agroPoly)
        }
    }
    
    // for testing
    func getImageryMeta(for poly: AgroPolyMap) {
        let stype = satType == 0 ? "s2" : "l8"
        let options = AgroOptions(polygon_id: poly.id, start: startImageSearch, end: endImageSearch, type: stype)
        agroProvider.getImagery(options: options) { imagery in
            if let agroImgry = imagery {
                poly.images.append(SatImage(agroImagery: agroImgry))
            }
        }
    }
    
    func getUrl(satUrl: AgroSatUrl) -> String? {
        switch satImgType {
        case 1: return satUrl.truecolor
        case 2: return satUrl.falsecolor
        case 3: return satUrl.ndvi
        case 4: return satUrl.evi
        case 5: return satUrl.dswi
        case 6: return satUrl.dswi
        case 7: return satUrl.nri
        case 8: return satUrl.evi2
        default: return satUrl.truecolor
        }
    }
    
    // returns the polygon if the coordinate is inside it
    func findAgroAt(_ coordinate: CLLocationCoordinate2D) -> AgroPolyMap? {
        return agroPolyMapList.first(where:{$0.mkPoly.isInside(coord: coordinate)})
    }

}


