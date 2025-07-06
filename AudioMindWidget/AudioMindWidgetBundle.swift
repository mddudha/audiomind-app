//
//  AudioMindWidgetBundle.swift
//  AudioMindWidget
//
//  Created by Mirvaben Dudhagara on 7/6/25.
//

import WidgetKit
import SwiftUI

@main
struct AudioMindWidgetBundle: WidgetBundle {
    var body: some Widget {
        AudioMindWidget()
        AudioMindWidgetControl()
        AudioMindWidgetLiveActivity()
    }
}
