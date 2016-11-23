//
//  VideoEffect
//  CustomBeauty
//
//  Created by Johnny Xu(徐景周) on 7/23/14.
//  Copyright (c) 2014 Future Studio. All rights reserved.
//

#import "VideoThemesData.h"

@interface VideoEffect : NSObject
{
    ThemesType _themeCurrentType;
}

@property (assign, nonatomic) ThemesType themeCurrentType;

- (id) initWithDelegate:(id)delegate;

- (BOOL)image2Video:(NSMutableArray*)photos exportVideoFile:(NSString *)exportVideoFile exportVideoSize:(CGSize)videoSize highestQuality:(BOOL)highestQuality;
- (BOOL)image2Videos:(NSMutableArray*)photos exportVideoFile:(NSString *)exportVideoFile exportVideoSize:(CGSize)videoSize videosMultiInputURL:(NSArray*)videosInputURLs highestQuality:(BOOL)highestQuality;

- (void) clearAll;
- (void) pause;
- (void) resume;

@end
