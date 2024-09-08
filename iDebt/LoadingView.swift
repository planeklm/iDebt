//
//  LoadingView.swift
//  iDebt
//
//  Created by klm on 08/09/2024.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
        }
    }
}

#Preview {
    LoadingView()
}
