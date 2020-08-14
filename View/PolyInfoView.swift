//
//  PolyInfoView.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/08/02.
//

import SwiftUI
import AgroAPI


struct PolyInfoView: View {
    
    @EnvironmentObject var land: LandModel
    
    @State var showsAlert = false
    @State var theIndexSet: IndexSet = IndexSet()
    @State var dailyWeather = [Current]()
    // timezone offset and zone of the selected polygon
    @State var tzOffset = 0
    @State var timeZone = TimeZone.current

    var body: some View {
        VStack (spacing: 10) {
            ScrollView {
                if DonkeyUtils.isiPhone {
                    VStack {
                        fieldView
                        imageryView
                    }
                } else {
                    HStack {
                        fieldView
                        imageryView
                    }
                }
            }
            forecastView
        }
        .onAppear(perform: {land.agroPolyMapList.forEach {$0.selected = false}})
        .alert(isPresented: self.$showsAlert) {
            Alert(title: Text("Delete field?"),
                  message: Text("This action cannot be undone"),
                  primaryButton: .destructive(Text("Delete")) { self.doDelete() },
                  secondaryButton: .cancel())
        }
    }
    
    var imageryView: some View {
        VStack {
            Text("Imagery").font(.title).padding(.top, 40)
            satView
            List {
                ForEach(land.imagery, id: \.imagery.dt) { imgry in
                    ImageryRow(polyImagery: imgry)
                }
            }.frame(height: 200)
        }
    }
    
    var satView: some View {
        Picker("", selection: $land.satType) {
            ForEach(0 ..< land.satTypes.count) {
                Text(self.land.satTypes[$0])
            }
        }.pickerStyle(SegmentedPickerStyle())
        .frame(width: 220, height: 50)
        .padding(5)
        .clipped()
    }
    
    var forecastView: some View {
        VStack {
            Text("Forecast").font(.title)
            List {
                // today plus the 5-day forecast with weather data every 3 hours.
                ForEach(shiftedDays().dropLast(), id: \.self) { day in
                    forecaster(day)
                }
            }
        }
    }
    
    // return the sorted names of all week days, starting with today at the poly location
    func shiftedDays() -> [String] {
        // find the date at the poly location
        let tz1 = TimeZone.current  // timezone here
        let tz2 = timeZone          // timezone at the poly location
        let dx = TimeInterval(tz2.secondsFromGMT() - tz1.secondsFromGMT())
        let today = Date().addingTimeInterval(dx).dayName()
        let days = [String] (DonkeyUtils.weekDayNumbers.keys)
        // get the number of today at the poly location
        let offset = DonkeyUtils.weekDayNumbers[today] ?? 7
        // shiftRight
        return DonkeyUtils.sortedDays(days).shiftRight(offset)
    }
    
    var fieldView: some View {
        VStack {
            Text("Fields").font(.title).padding(.top, 40)
            List {
                ForEach(land.agroPolyMapList, id: \.id) { poly in
                    PolyListRow(thePoly: poly).tag(poly.id)
                        .onTapGesture {
                                getTimezoneAndOffsetFor(poly)
                                land.agroPolyMapList.forEach {$0.selected = false}
                                poly.selected = true
                                dailyWeather.removeAll()
                                land.agroProvider.getForecastWeather(id: poly.id, reponse: $dailyWeather)
                                getImagery(poly)
                                land.refresh.toggle()
                            }
                }
                .onDelete(perform: delete)
            }.frame(height: 200)
        }
    }
    
    func getImagery(_ thePoly: AgroPolyMap) {
        land.imagery.removeAll()
        if let satimg = thePoly.images.first {
            // the array of url
            var arr = satimg.agroImagery
            // sort by time
            arr.sort(by: {$0.imagery.dt ?? 0 < $1.imagery.dt ?? 0 })
            land.imagery.append(contentsOf: arr)
        }
        land.refresh.toggle()
    }
    
    // return the 3-hourly temperature kelvin and utc, for the specified day 
    func hourlyTemps(for dayName: String) -> [Int:Double] {
        var temps = [Int:Double]()
        for weather in dailyWeather {
            // the date/time at the poly location
            if dateAtPoly(utc: weather.dt).dayName() == dayName {
                if let tempK = weather.main?.temp {
                    temps[weather.dt] = tempK
                }
            }
        }
        return temps
    }
    
    func dateAtPoly(utc: Int) -> Date {
        let tz1 = TimeZone.current  // timezone here
        let tz2 = timeZone          // timezone at the poly location
        let dx = TimeInterval(tz2.secondsFromGMT() - tz1.secondsFromGMT())
        return Date(utc: utc).addingTimeInterval(dx)
    }
    
    private func hourlyIconName(_ utc: Int) -> String {
        if let current = dailyWeather.first(where: {$0.dt == utc}) {
            return current.weather.first != nil ? current.weather.first!.iconNameFromId : "smiley"
        } else {
            return "smiley"
        }
    }
    
    // today plus the 5-day forecast with weather data every 3 hours
    func forecaster(_ day: String) -> some View {
        VStack (alignment: .leading, spacing: 20) {
            Text(day).foregroundColor(.blue)
            ScrollView(.horizontal) {
                HStack(spacing: 25) {
                    ForEach(hourlyTemps(for: day).sorted(by: <), id: \.key) { key, temp in
                        VStack {
                            Text(DonkeyUtils.hourFormattedDate(utc: key, offset: tzOffset)).font(.footnote)
                            Image(systemName: hourlyIconName(key))
                                .resizable()
                                .frame(width: 35, height: 30)
                                .foregroundColor(Color.green)
                            Text(DonkeyUtils.toCelsius(temp))
                        }
                    }
                }
            }
        }
    }
    
    
    private func getTimezoneAndOffsetFor(_ poly: AgroPolyMap) {
        // offset at the poly location
        DonkeyUtils.timezoneOffset(at: poly) { offset in
            self.tzOffset = offset
        }
        // timezone at the poly location
        DonkeyUtils.timezone(at: poly) { tz in
            self.timeZone = tz
        }
    }
    
    private func doDelete() {
        if let ndx = theIndexSet.first {
            let thePolyId = land.agroPolyMapList[ndx].id
            land.agroPolyMapList.remove(at: ndx)
            print("\n----> PolyInfoView doDelete FAKE deleting server poly: \(thePolyId)")
            // land.agroProvider.deletePoly(id: thePolyId) { _ in }
        }
    }
    
    private func delete(with indexSet: IndexSet) {
        theIndexSet = indexSet
        showsAlert = true
    }
    
}

