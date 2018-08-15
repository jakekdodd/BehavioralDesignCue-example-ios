//
//  BDCue.swift
//  BehavioralDesignCue
//
//  Created by Akash Desai on 8/14/18.
//


import UIKit

/// In order to build a successful and user motivated reinforcement strategy, we need to be able to distinguish between App Open cues.
/// App Open cues provide crucial information about the user’s journey, such as motivation and availability, that  we can use to design good habits.
/// This struct stores the cue source and the cue date. The UI can then adjust according to what cued the user to open the app.
///
public struct BDCue {
    
    public enum Source {
        case `internal`(Internal), external(External), synthetic(Synthetic)
        
        public enum Internal {
            case `default`, shortcut
        }
        
        public enum External {
            case deepLink
        }
        
        public enum Synthetic {
            case notification
        }
    }
    
    public let source: Source
    public let date: Date
    
    public init(source: Source, date: Date = Date()) {
        self.source = source
        self.date = date
    }
    
}

public extension BDCue.Source {
    
    /// Simple description of the cue source
    public var description: String {
        switch(self) {
        case .internal(.default):
            return "Internal.default"
        case .internal(.shortcut):
            return "Internal.shortcut"
        case .external(.deepLink):
            return "External.deepLink"
        case .synthetic(.notification):
            return "Synthetic.notification"
        }
    }
}
