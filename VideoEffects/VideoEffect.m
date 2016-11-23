//
//  VideoEffect
//  CustomBeauty
//
//  Created by Johnny Xu(徐景周) on 7/23/14.
//  Copyright (c) 2014 Future Studio. All rights reserved.
//

#import "VideoEffect.h"
#import "VideoBuilder.h"
#import "VideoThemes.h"
#import "Common.h"
#import <AssetsLibrary/AssetsLibrary.h>

#pragma mark - Private
@interface VideoEffect()
{
    AVAssetExportSession *_exportSession;
    NSTimer *_timerEffect;
    
    NSMutableDictionary *_themesDic;
    
    VideoBuilder *_videoBuilder;
}

@property (retain, nonatomic) VideoBuilder *videoBuilder;
@property (retain, nonatomic) NSMutableDictionary *themesDic;
@property (weak, nonatomic) id delegate;

@property (retain, nonatomic) AVAssetExportSession *exportSession;
@property (retain, nonatomic) NSTimer *timerEffect;

@end


@implementation VideoEffect

@synthesize exportSession = _exportSession;
@synthesize timerEffect = _timerEffect;

@synthesize delegate = _delegate;
@synthesize themeCurrentType = _themeCurrentType;
@synthesize themesDic = _themesDic;
@synthesize videoBuilder = _videoBuilder;

#pragma mark - Init instance
- (id) initWithDelegate:(id)delegate
{
	if (self = [super init])
    {
        _delegate = delegate;
        _exportSession = nil;
        _timerEffect = nil;
        _themesDic = nil;
        
        // Default theme
        self.themeCurrentType = kThemeButterfly;
        
        self.videoBuilder = [[VideoBuilder alloc] init];
        
        self.themesDic = [[VideoThemesData sharedInstance] getThemesData];
	}
    
	return self;
}

- (void) clearAll
{
    if (_videoBuilder)
    {
        _videoBuilder = nil;
    }
    
    if (_exportSession)
    {
        _exportSession = nil;
    }
    
    if (_timerEffect)
    {
        [_timerEffect invalidate];
        _timerEffect = nil;
    }
}

- (void)dealloc
{
    [self clearAll];
    
//    [super dealloc];
}

- (void) pause
{
    if (_exportSession.progress < 1.0)
    {
        [_exportSession cancelExport];
    }
}

- (void) resume
{
    [self clearAll];
}

#pragma mark - Common function
// Convert 'space' char
- (NSString *)returnFormatString:(NSString *)str
{
    return [str stringByReplacingOccurrencesOfString:@" " withString:@""];
}

- (UIImage *)imageFromAsset:(ALAsset *)asset
{
    ALAssetRepresentation *representation = [asset defaultRepresentation];
    return [UIImage imageWithCGImage:representation.fullResolutionImage
                               scale:[representation scale]
                         orientation:(UIImageOrientation)[representation orientation]];
}

#pragma mark - Build video
- (BOOL)image2Video:(NSMutableArray*)photos exportVideoFile:(NSString *)exportVideoFile highestQuality:(BOOL)highestQuality
{
    CGSize videoSize = CGSizeMake(0, 0);
    return [self image2Video:photos exportVideoFile:exportVideoFile exportVideoSize:videoSize highestQuality:highestQuality];
}

- (BOOL)image2Video:(NSMutableArray*)photos exportVideoFile:(NSString *)exportVideoFile exportVideoSize:(CGSize)videoSize highestQuality:(BOOL)highestQuality
{
    return [self image2Videos:photos exportVideoFile:exportVideoFile exportVideoSize:videoSize videosMultiInputURL:nil highestQuality:highestQuality];
}

- (BOOL)image2Videos:(NSMutableArray*)photos exportVideoFile:(NSString *)exportVideoFile exportVideoSize:(CGSize)videoSize videosMultiInputURL:(NSArray*)videosInputURLs highestQuality:(BOOL)highestQuality
{
    if (self.themeCurrentType == kThemeNone)
    {
        NSLog(@"Theme is empty!");
        
        return FALSE;
    }
    
    VideoThemes *themeCurrent = nil;
    if (self.themeCurrentType != kThemeNone && [self.themesDic count] >= self.themeCurrentType)
    {
        themeCurrent = [self.themesDic objectForKey:[NSNumber numberWithInt:self.themeCurrentType]];
    }
    
    return [self buildVideoEffectsToMP4:exportVideoFile inputVideoFile:themeCurrent.bgVideoFile photos:photos exportVideoSize:videoSize highestQuality:highestQuality videosMultiInputURL:videosInputURLs];
}
                       
// Add effect
- (BOOL)buildVideoEffectsToMP4:(NSString *)exportVideoFile inputVideoFile:(NSURL *)inputVideoURL photos:(NSMutableArray*)photos exportVideoSize:(CGSize)videoSize highestQuality:(BOOL)highestQuality videosMultiInputURL:(NSArray*)videosInputURLs
{
    // 1.
    if (isStringEmpty(exportVideoFile))
    {
        NSLog(@"Output filename is invalied!");
        return NO;
    }
    
    NSLog(@"inputVideoURL: %@", inputVideoURL);
    
    if (!videosInputURLs || [videosInputURLs count] < 1)
    {
        if (inputVideoURL && [inputVideoURL isFileURL])
        {
            videosInputURLs = [NSArray arrayWithObjects:inputVideoURL, nil];
        }
        else
        {
            return FALSE;
        }
    }
    
    // 2. Create the composition and tracks
    NSError *error = nil;
    CGSize renderSize = CGSizeMake(0, 0);
    NSMutableArray *layerInstructionArray = [[NSMutableArray alloc] init];
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    CMTime totalDuration = kCMTimeZero;
    
    NSMutableArray *assetTrackArray = [[NSMutableArray alloc] init];
    NSMutableArray *assetArray = [[NSMutableArray alloc] init];
    for (NSURL *fileURL in videosInputURLs)
    {
        NSLog(@"fileURL: %@", fileURL);
        
        AVAsset *asset = [AVAsset assetWithURL:fileURL];
        if (!asset)
        {
            // Retry once
            asset = [AVAsset assetWithURL:fileURL];
            if (!asset)
            {
                continue;
            }
        }
        [assetArray addObject:asset];
        
        AVAssetTrack *assetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        if (!assetTrack)
        {
            // Retry once
            assetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            if (!assetTrack)
            {
                NSLog(@"Error reading the transformed video track");
            }
        }
        [assetTrackArray addObject:assetTrack];
        
        NSLog(@"assetTrack.naturalSize Width: %f, Height: %f", assetTrack.naturalSize.width, assetTrack.naturalSize.height);
        
        renderSize.width = MAX(renderSize.width, assetTrack.naturalSize.width);
        renderSize.height = MAX(renderSize.height, assetTrack.naturalSize.height);
    }
    
    NSLog(@"renderSize width: %f, Height: %f", renderSize.width, renderSize.height);
    if (renderSize.height == 0 || renderSize.width == 0)
    {
        return NO;
    }
    
    // 3. Insert the tracks in the composition's tracks
    CGFloat renderW = MIN(renderSize.width, renderSize.height);
    for (int i = 0; i < [assetArray count] && i < [assetTrackArray count]; i++)
    {
        AVAsset *asset = [assetArray objectAtIndex:i];
        AVAssetTrack *assetTrack = [assetTrackArray objectAtIndex:i];
        
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        if ([[asset tracksWithMediaType:AVMediaTypeAudio] count]>0)
        {
            AVAssetTrack *assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:assetAudioTrack atTime:totalDuration error:nil];
        }
        else
        {
            NSLog(@"Reminder: video hasn't audio!");
        }
        
        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                            ofTrack:assetTrack
                             atTime:totalDuration
                              error:&error];
        
        // Fix orientation issue
        AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        totalDuration = CMTimeAdd(totalDuration, asset.duration);
        
        CGFloat rate;
        rate = renderW / MIN(assetTrack.naturalSize.width, assetTrack.naturalSize.height);
        
        CGAffineTransform layerTransform = CGAffineTransformMake(assetTrack.preferredTransform.a, assetTrack.preferredTransform.b, assetTrack.preferredTransform.c, assetTrack.preferredTransform.d, assetTrack.preferredTransform.tx * rate, assetTrack.preferredTransform.ty * rate);
        layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, 0, -(assetTrack.naturalSize.width - assetTrack.naturalSize.height) / 2.0));
        layerTransform = CGAffineTransformScale(layerTransform, rate, rate);
        
        [layerInstruciton setTransform:layerTransform atTime:kCMTimeZero];
        [layerInstruciton setOpacity:0.0 atTime:totalDuration];
        
        [layerInstructionArray addObject:layerInstruciton];
    }
    
    // 4. Effects
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    int limitMinLen = 100;
    CGSize videoSizeResult;
    if (videoSize.width >= limitMinLen || videoSize.height >= limitMinLen)
    {
        // Assign a output size
        parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
        videoSizeResult = videoSize;
    }
    else
    {
        // Original video size
        parentLayer.frame = CGRectMake(0, 0, renderW, renderW);
        videoSizeResult = CGSizeMake(renderW, renderW);
    }
    
    videoLayer.frame = parentLayer.frame;
    [parentLayer addSublayer:videoLayer];
    
    VideoThemes *themeCurrent = nil;
    if (self.themeCurrentType != kThemeNone && [self.themesDic count] >= self.themeCurrentType)
    {
        themeCurrent = [self.themesDic objectForKey:[NSNumber numberWithInt:self.themeCurrentType]];
    }
    
    // Animation effects
    NSMutableArray *animatedLayers = [[NSMutableArray alloc] initWithCapacity:[[themeCurrent animationActions] count]];
    if (themeCurrent && [[themeCurrent animationActions] count]>0)
    {
        for (NSNumber *animationAction in [themeCurrent animationActions])
        {
            CALayer *animatedLayer = nil;
            switch ([animationAction intValue])
            {
                case kAnimationFireworks:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildEmitterFireworks:videoSizeResult startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationSnow:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildEmitterSnow:videoSizeResult startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationSnow2:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildEmitterSnow2:videoSizeResult startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationHeart:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildEmitterHeart:videoSizeResult startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationRing:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildEmitterRing:videoSizeResult startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationStar:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildEmitterStar:videoSizeResult startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationMoveDot:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildEmitterMoveDot:videoSizeResult position:CGPointMake(160, 240) startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationTextSparkle:
                {
                    if (!isStringEmpty(themeCurrent.textSparkle))
                    {
                        NSTimeInterval startTime = 10;
                        animatedLayer = [_videoBuilder buildEmitterSparkle:videoSizeResult text:themeCurrent.textSparkle startTime:startTime];
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationTextStar:
                {
                    if (!isStringEmpty(themeCurrent.textStar))
                    {
                        NSTimeInterval startTime = 0.1;
                        animatedLayer = [_videoBuilder buildAnimationStarText:videoSizeResult text:themeCurrent.textStar startTime:startTime];
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationSky:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildEmitterSky:videoSizeResult startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationMeteor:
                {
                    NSTimeInterval timeInterval = 0.1;
                    for (int i=0; i<2; ++i)
                    {
                        animatedLayer = [_videoBuilder buildEmitterMeteor:videoSizeResult startTime:timeInterval pathN:i];
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationRain:
                {
                    animatedLayer = [_videoBuilder buildEmitterRain:videoSizeResult];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationFlower:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildEmitterFlower:videoSizeResult startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationFire:
                {
                    if (!isStringEmpty(themeCurrent.imageFile))
                    {
                        UIImage *image = [UIImage imageNamed:themeCurrent.imageFile];
                        animatedLayer = [_videoBuilder buildEmitterFire:videoSizeResult position:CGPointMake(videoSizeResult.width/2.0, image.size.height+10)];
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    break;
                }
                case kAnimationSmoke:
                {
                    animatedLayer = [_videoBuilder buildEmitterSmoke:videoSizeResult position:CGPointMake(videoSizeResult.width/2.0, 105)];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationSpark:
                {
                    animatedLayer = [_videoBuilder buildEmitterSpark:videoSizeResult];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationBirthday:
                {
                    animatedLayer = [_videoBuilder buildEmitterBirthday:videoSizeResult];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationImage:
                {
                    if (!isStringEmpty(themeCurrent.imageFile))
                    {
                        UIImage *image = [UIImage imageNamed:themeCurrent.imageFile];
                        animatedLayer = [_videoBuilder buildImage:videoSizeResult image:themeCurrent.imageFile position:CGPointMake(videoSizeResult.width/2, image.size.height/2)];
                        
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationImageArray:
                {
                    if(themeCurrent.animationImages)
                    {
                        UIImage *image = [UIImage imageWithCGImage:(CGImageRef)themeCurrent.animationImages[0]];
                        animatedLayer = [_videoBuilder buildAnimationImages:videoSizeResult imagesArray:themeCurrent.animationImages position:CGPointMake(videoSizeResult.width/2, image.size.height/2)];
                        
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationVideoFrame:
                {
//                    if (themeCurrent.keyFrameTimes  && [[themeCurrent keyFrameTimes] count]>0)
//                    {
//                        for (NSNumber *timeSecond in themeCurrent.keyFrameTimes)
//                        {
//                            CMTime time = CMTimeMake([timeSecond doubleValue], 1);
//                            if (CMTIME_COMPARE_INLINE(totalDuration, >, time))
//                            {
//                                animatedLayer = [_videoBuilder buildVideoFrameImage:videoSizeResult videoFile:inputVideoURL startTime:time];
//                                if (animatedLayer)
//                                {
//                                    [animatedLayers addObject:(id)animatedLayer];
//                                }
//                            }
//                        }
//                    }
                    
                    break;
                }
                case kAnimationSpotlight:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildSpotlight:videoSizeResult startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationScrollScreen:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildAnimationScrollScreen:videoSizeResult startTime:timeInterval];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationTextScroll:
                {
                    if (themeCurrent.scrollText && [[themeCurrent scrollText] count] > 0)
                    {
                        NSArray *startYPoints = [NSArray arrayWithObjects:[NSNumber numberWithFloat:videoSizeResult.height/3], [NSNumber numberWithFloat:videoSizeResult.height/2], [NSNumber numberWithFloat:videoSizeResult.height*2/3], nil];
                        
                        NSTimeInterval timeInterval = 12.0;
                        for (NSString *text in themeCurrent.scrollText)
                        {
                            animatedLayer = [_videoBuilder buildAnimatedScrollText:videoSizeResult text:text startPoint:CGPointMake(videoSizeResult.width, [startYPoints[arc4random()%(int)3] floatValue]) startTime:timeInterval];
                            
                            if (animatedLayer)
                            {
                                [animatedLayers addObject:(id)animatedLayer];
                                
                                timeInterval += 3.0;
                            }
                        }
                    }
                    
                    break;
                }
                case kAnimationBlackWhiteDot:
                {
                    for (int i=0; i<2; ++i)
                    {
                        animatedLayer = [_videoBuilder buildEmitterBlackWhiteDot:videoSizeResult positon:CGPointMake(videoSizeResult.width/2, i*videoSizeResult.height) startTime:2.0f];
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationScrollLine:
                {
                    NSTimeInterval timeInterval = 0.1;
                    animatedLayer = [_videoBuilder buildAnimatedScrollLine:videoSizeResult startTime:timeInterval lineHeight:30.0f image:nil];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationRipple:
                {
                    NSTimeInterval timeInterval = 1.0;
                    animatedLayer = [_videoBuilder buildAnimationRipple:videoSizeResult centerPoint:CGPointMake(videoSizeResult.width/2, videoSizeResult.height/2) radius:videoSizeResult.width/2 startTime:timeInterval];
                    
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationSteam:
                {
                    animatedLayer = [_videoBuilder buildEmitterSteam:videoSizeResult positon:CGPointMake(videoSizeResult.width/2, videoSizeResult.height - videoSizeResult.height/8)];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationTextGradient:
                {
                    if (!isStringEmpty(themeCurrent.textGradient))
                    {
                        NSTimeInterval timeInterval = 3.0;
                        animatedLayer = [_videoBuilder buildGradientText:videoSizeResult positon:CGPointMake(videoSizeResult.width/2, videoSizeResult.height - videoSizeResult.height/4) text:themeCurrent.textGradient startTime:timeInterval];
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationFlashScreen:
                {
                    for (int timeSecond=2; timeSecond<12; timeSecond+=3)
                    {
                        CMTime time = CMTimeMake(timeSecond, 1);
                        if (CMTIME_COMPARE_INLINE(totalDuration, >, time))
                        {
                            animatedLayer = [_videoBuilder buildAnimationFlashScreen:videoSizeResult startTime:timeSecond startOpacity:TRUE];
                            if (animatedLayer)
                            {
                                [animatedLayers addObject:(id)animatedLayer];
                            }
                        }
                    }
                    
                    break;
                }
                case kAnimationPhotoLinearScroll:
                {
                    NSTimeInterval startTime = 3;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoLinearScroll:videoSizeResult photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case KAnimationPhotoCentringShow:
                {
                    NSTimeInterval startTime = 10;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoCentringShow:videoSizeResult photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationPhotoDrop:
                {
                    NSTimeInterval startTime = 1;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoDrop:videoSizeResult photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }

                    break;
                }
                case kAnimationPhotoParabola:
                {
                    NSTimeInterval startTime = 1;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoParabola:videoSizeResult photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationPhotoFlare:
                {
                    NSTimeInterval startTime = 1;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoFlare:videoSizeResult photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationPhotoEmitter:
                {
                    NSTimeInterval startTime = 1;
                    animatedLayer = [_videoBuilder BuildAnimationPhotoEmitter:videoSizeResult photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationPhotoExplode:
                {
                    NSTimeInterval startTime = 1;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoExplode:videoSizeResult photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationPhotoExplodeDrop:
                {
                    NSTimeInterval startTime = 0.1;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoExplodeDrop:videoSizeResult photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationPhotoCloud:
                {
                    NSTimeInterval startTime = 0.1;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoCloud:videoSizeResult photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationPhotoSpin360:
                {
                    NSTimeInterval startTime = 0.1;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoSpin360:videoSizeResult photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationPhotoCarousel:
                {
                    NSTimeInterval startTime = 0.1;
                    animatedLayer = [_videoBuilder buildAnimatedPhotoCarousel:videoSizeResult photos:photos startTime:startTime];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationVideoBorder:
                {
                    if (!isStringEmpty(themeCurrent.imageVideoBorder))
                    {
                        animatedLayer = [_videoBuilder BuildVideoBorderImage:videoSizeResult borderImage:themeCurrent.imageVideoBorder position:CGPointMake(videoSizeResult.width/2, videoSizeResult.height/2)];
                        
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                default:
                    break;
            }
        }
        
        if (animatedLayers && [animatedLayers count] > 0)
        {
            for (CALayer *animatedLayer in animatedLayers)
            {
                [parentLayer addSublayer:animatedLayer];
            }
        }
    }
    
    AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    mainInstruciton.layerInstructions = layerInstructionArray;
    
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = @[mainInstruciton];
    mainCompositionInst.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    mainCompositionInst.renderSize = videoSizeResult;
    
    NSLog(@"videoSizeResult width: %f, Height: %f", videoSizeResult.width, videoSizeResult.height);
    
    if (animatedLayers)
    {
        [animatedLayers removeAllObjects];
        animatedLayers = nil;
    }
    
    // 5. Music effect
    AVMutableAudioMix *audioMix = nil;
    if (themeCurrent && !isStringEmpty(themeCurrent.bgMusicFile))
    {
        NSString *fileName = [themeCurrent.bgMusicFile stringByDeletingPathExtension];
        NSLog(@"%@",fileName);
        
        NSString *fileExt = [themeCurrent.bgMusicFile pathExtension];
        NSLog(@"%@",fileExt);
        
        NSURL *bgMusicURL = [[NSBundle mainBundle] URLForResource:fileName withExtension:fileExt];
        AVURLAsset *assetMusic = [[AVURLAsset alloc] initWithURL:bgMusicURL options:nil];
        _videoBuilder.commentary = assetMusic;
        audioMix = [AVMutableAudioMix audioMix];
        [_videoBuilder addCommentaryTrackToComposition:mixComposition withAudioMix:audioMix];
    }
    
    // 6. Export to mp4
    unlink([exportVideoFile UTF8String]);
    
    NSString *mp4Quality = AVAssetExportPresetMediumQuality;
    if (highestQuality)
    {
        mp4Quality = AVAssetExportPresetHighestQuality;
    }
    NSString *exportPath = exportVideoFile;
    NSURL *exportUrl = [NSURL fileURLWithPath:[self returnFormatString:exportPath]];
    
    _exportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:mp4Quality];
    _exportSession.outputURL = exportUrl;
    _exportSession.outputFileType = [[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0 ? AVFileTypeMPEG4 : AVFileTypeQuickTimeMovie;
    
    _exportSession.shouldOptimizeForNetworkUse = YES;
    
    if (audioMix)
    {
        _exportSession.audioMix = audioMix;
    }
    
    if (mainCompositionInst)
    {
        _exportSession.videoComposition = mainCompositionInst;
    }
    
    // 6.1
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Progress monitor for effect
        _timerEffect = [NSTimer scheduledTimerWithTimeInterval:0.3f
                                                 target:self
                                               selector:@selector(retrievingProgressMP4)
                                               userInfo:nil
                                                repeats:YES];
    });
    
    
    // 7. Success status
    __block typeof(self) blockSelf = self;
    [blockSelf.exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch ([blockSelf.exportSession status])
        {
            case AVAssetExportSessionStatusCompleted:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    // Close timer
                    [blockSelf.timerEffect invalidate];
                    blockSelf.timerEffect = nil;
                    
                    NSLog(@"MP4 Successful!");

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
                    if (blockSelf.delegate && [blockSelf.delegate respondsToSelector:@selector(AVAssetExportMP4SessionStatusCompleted:)])
                    {
                        [blockSelf.delegate performSelector:@selector(AVAssetExportMP4SessionStatusCompleted:) withObject:nil];
                    }
#pragma clang diagnostic pop
                    
                    NSLog(@"Output Mp4 is %@", exportVideoFile);
                    
                });
                
                break;
            }
            case AVAssetExportSessionStatusFailed:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    // Close timer
                    [blockSelf.timerEffect invalidate];
                    blockSelf.timerEffect = nil;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
                    if (blockSelf.delegate && [blockSelf.delegate respondsToSelector:@selector(AVAssetExportMP4SessionStatusFailed:)])
                    {
                        [blockSelf.delegate performSelector:@selector(AVAssetExportMP4SessionStatusFailed:) withObject:nil];
                    }
#pragma clang diagnostic pop
                });
                
                NSLog(@"Export failed: %@, %@", [[_exportSession error] localizedDescription], [_exportSession error]);
                
                break;
            }
            case AVAssetExportSessionStatusCancelled:
            {
                NSLog(@"Export canceled");
                break;
            }
            case AVAssetExportSessionStatusWaiting:
            {
                NSLog(@"Export Waiting");
                break;
            }
            case AVAssetExportSessionStatusExporting:
            {
                NSLog(@"Export Exporting");
                break;
            }
            default:
                break;
        }
        
    }];
    
    return YES;
}

- (void)retrievingProgressMP4
{
    if (_exportSession)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        if (_delegate && [_delegate respondsToSelector:@selector(retrievingProgressMP4:)])
        {
            [_delegate performSelector:@selector(retrievingProgressMP4:) withObject:[NSNumber numberWithFloat:_exportSession.progress]];
#pragma clang diagnostic pop
        }
    }
    
}

@end
