// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 

@import UIKit;
@import Foundation;

#import "MediaPlayer.h"

@protocol AudioTrack;

NS_ASSUME_NONNULL_BEGIN

@interface AudioTrackPlayer : NSObject <MediaPlayer>

- (void)loadTrack:(NSObject<AudioTrack> *)track sourceMessage:(id<ZMConversationMessage>)sourceMessage completionHandler:( void(^ _Nullable )(BOOL loaded, NSError *error))completionHandler;

@property (nonatomic, readonly) NSObject<AudioTrack> *audioTrack;
@property (nonatomic, readonly) CGFloat progress;
@property (nonatomic, readonly) CGFloat duration;
@property (nonatomic, readonly) NSTimeInterval elapsedTime;
@property (nonatomic, readonly, getter=isPlaying) BOOL playing;
@property (nonatomic, weak, nullable) id<MediaPlayerDelegate> mediaPlayerDelegate;

/// Start the currently loaded/paused track.
- (void)play;

/// Pause the currently playing track.
- (void)pause;

@end

NS_ASSUME_NONNULL_END
