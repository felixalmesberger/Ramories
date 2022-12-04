//
//  ContentView.swift
//  randomimage
//
//  Created by Felix Almesberger on 29.05.22.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject private var foto = RandomPhotoLibraryFoto()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            Image(uiImage: foto.current)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .statusBar(hidden: true)
                .clipped()
            
            if(foto.isLoading) {
                ProgressView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
