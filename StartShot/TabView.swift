//
//  SwiftUIView.swift
//  StartShot
//
//  Created by Keiju Hiramoto on 2026/03/05.
//

import SwiftUI

struct TabView: View {
    @State private var tab : Tab = .home
    enum Tab: Hashable{
        case home,camera, calendar
    }
    var body: some View {
        Tab("Received", systemImage: "tray.and.arrow.down.fill") {
            ReceivedView()
        }
        .badge(2)
        
        
        Tab("Sent", systemImage: "tray.and.arrow.up.fill") {
            SentView()
        }
        
        
        Tab("Calendar", systemImage: "calendar") {
            CalendarView()
        }
        .badge("!")
    }
}
#Preview {
    TabView()
}
