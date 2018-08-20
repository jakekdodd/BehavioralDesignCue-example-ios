//
//  CueCategory.swift
//  BehavioralDesignCue
//
//  Created by Akash Desai on 8/14/18.
//

import Foundation

/// In order to build a successful and user motivated reinforcement strategy, we should distinguish
/// between action cues when scheduling reinforcements.
///
/// - `internal`: An internal cue is something that people sense inside themselves; their internal feelings and
///                 thoughts. Internal cues can be feelings and thoughts like hunger, boredom, thinking about a
///                 loved one, anxiety, or recalling someone you used to go out drinking with. Unlike external
///                 cues, internal cues are ‘inner’ events that are private to a person’s brain.
/// - external: An external cue is anything that someone senses from their immediate surroundings that causes
///                 them to perform a habit. When most people think of cues, they’re really thinking of
///                 external cues. External cues can be the sight of an ad, the sound of police sirens, or
///                 seeing a nearby bakery. Anything in a person’s environment can be an external cue.
/// - synthetic: A synthetic cue is anything that has been intentionally constructed to perform a habit.
///                 Similar to external cues they are in a person's environment, but unlike external cues
///                 they are intentionally presented to a person. Synthetic cues can be the vibration of
///                 a push notification, the sight of a promotional email, or the distinct smell of Cinnabon.
public enum CueCategory: String {
    case `internal`, external, synthetic
}

/// App Open actions provide crucial information about the user’s journey, such as motivation and cue,
/// that  we can use to design good habits.
/// This struct stores the action and also its cue.
/// A reward can then adjust according to what cued the user to open the app.
///
public struct AppOpenAction {

    public enum Source {
        case  `default`, shortcut, deepLink, notification

        public var cueCategory: CueCategory {
            switch self {
            case .default, .shortcut:
                return .internal

            case .deepLink:
                return .external

            case .notification:
                return .synthetic
            }
        }
    }

    public let date: Date
    public let source: Source
    public var cue: CueCategory {
        return source.cueCategory
    }

    public init(source: Source, date: Date = Date()) {
        self.source = source
        self.date = date
    }

}
