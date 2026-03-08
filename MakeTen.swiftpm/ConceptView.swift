//
//  SwiftUIView.swift
//  MakeTen
//
//  Created by 梶原景介 on 2026/02/22.
//

import SwiftUI

struct ConceptView: View {
    
    let bgGradient = LinearGradient(
        colors: [
            Color(red: 0.62, green: 0.88, blue: 0.95),
            Color(red: 0.85, green: 0.95, blue: 0.98)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                
                // MARK: - Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Different Cities")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Different Plates.")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("License plate designs vary across cities and cultures.")
                        .font(.body)
                        .padding(.top, 4)
                }
                
                // MARK: - City Cards
                CityCard(
                    city: "France　🇫🇷",
                    imageName: "france_plate",
                    description: "French license plates are characterized by three-digit numbers flanked by two letters on each side."
                )
                
                CityCard(
                    city: "Japan　🇯🇵",
                    imageName: "tokyo_plate",
                    description: "Japanese license plates consist of four-digit numbers, with a single Japanese Hiragana character written to the left."
                )
                
                CityCard(
                    city: "America　🇺🇸",
                    imageName: "newyork_plate",
                    description: "American license plates consist of seven characters combining numbers and letters. Older plates may have fewer characters."
                )
                
            }
            .padding(24)
        }
        .background(bgGradient.ignoresSafeArea())
    }
}

// MARK: - Reusable Card View
struct CityCard: View {
    let city: String
    let imageName: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            Text(city.uppercased())
                .font(.caption)
                .fontWeight(.bold)
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .cornerRadius(14)
            
            Text(description)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
        )
    }
}

#Preview {
    ConceptView()
}
