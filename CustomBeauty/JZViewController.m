//
//  JZViewController.m
//  CustomBeauty
//
//  Created by Johnny Xu(徐景周) on 10/19/14.
//  Copyright (c) 2014 Future Studio. All rights reserved.
//

#import "JZViewController.h"
#import "VideoEffect.h"
#import "PBJVideoPlayerController.h"
#import "MMProgressHUD.h"
#import "CMPopTipView.h"
#import "OnboardingViewController.h"
#import "OnboardingContentViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface JZViewController ()<PBJVideoPlayerControllerDelegate, CMPopTipViewDelegate>
{
    NSString* _mp4OutputPath;

    BOOL _hasPhotos;
    BOOL _hasMp4;

    VideoEffect *_videoEffects;

    PBJVideoPlayerController *_videoPlayerController;
    UIImageView *_playButton;

    NSMutableArray *_selectedPhotos;

    CMPopTipView *_popTipView;
}

@property (assign, nonatomic) int videoBorderIndex;
@property (assign, nonatomic) int effectInput;
@property (copy, nonatomic) NSString* musicInputPath;
@property (copy, nonatomic) NSURL* videoInputURL;
@property (retain, nonatomic) NSArray* videosMultiInputURL;
@property (copy, nonatomic) NSString* mp4OutputPath;

@property (assign, nonatomic) BOOL hasPhotos;
@property (assign, nonatomic) BOOL hasMp4;

@property (retain, nonatomic) VideoEffect *videoEffects;

@property (retain, nonatomic) UIView *viewToolbar;
@property (retain, nonatomic) UIImageView *imageViewToolbarBG;

@property (retain, nonatomic) UIButton *toggleCustom;
@property (retain, nonatomic) UIButton *titleCustom;
@property (retain, nonatomic) UIButton *saveVideo;
@property (retain, nonatomic) UIButton *titleSaveVideo;

@property (retain ,nonatomic) NSMutableArray *selectedPhotos;

@end

@implementation JZViewController

@synthesize mp4OutputPath = _mp4OutputPath;
@synthesize hasPhotos = _hasPhotos;
@synthesize hasMp4 = _hasMp4;
@synthesize videoEffects = _videoEffects;
@synthesize selectedPhotos = _selectedPhotos;

#pragma mark - Video effects status
- (void)AVAssetExportMP4SessionStatusFailed:(id)object
{
    NSString *failed = NSLocalizedString(@"Failed", nil);
    [self dismissProgressBar:failed];
    
    // Clear video input if failed
    if (self.videoInputURL && [self.videoInputURL isFileURL])
    {
        self.videoInputURL = nil;
        NSString *defaultVideo = @"Cloud02.mov";
        [[[VideoThemesData sharedInstance] getThemeByType:kThemeCustom] setBgVideoFile:[self getFileURL:defaultVideo]];
    }
    
    // Dispose memory
    [self.videoEffects clearAll];
}

- (void)AVAssetExportMP4SessionStatusCompleted:(id)object
{
    // Dispose memory
    [self.videoEffects clearAll];
    self.hasMp4 = YES;
    
    NSString *success = NSLocalizedString(@"Success", nil);
    [self dismissProgressBar:success];
    
    if (!isStringEmpty(_mp4OutputPath))
    {
        [self playMp4Video:_mp4OutputPath];
    }
    
    // Enable "Save" button
    [self enableSaveButton:YES];
}

- (void)AVAssetExportMP4ToAlbumStatusCompleted:(id)object
{
    NSString *success = NSLocalizedString(@"Success", nil);
    NSString *msgSuccess =  NSLocalizedString(@"MsgSuccess", nil);
    NSString *ok = NSLocalizedString(@"Ok", nil);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:success message:msgSuccess
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:ok, nil];
    [alert show];
    
    // Enable "Save" button
    [self enableSaveButton:YES];
}

- (void)AVAssetExportMP4ToAlbumStatusFailed:(id)object
{
    NSString *failed = NSLocalizedString(@"Failed", nil);
    NSString *msgFailed =  NSLocalizedString(@"MsgFailed", nil);
    NSString *ok = NSLocalizedString(@"Ok", nil);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: failed message:msgFailed
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:ok, nil];
    [alert show];
    
    // Enable "Save" button
    [self enableSaveButton:YES];
}

#pragma mark - Progress callback
- (void)retrievingProgressMP4:(id)progress
{
    if (progress && [progress isKindOfClass:[NSNumber class]])
    {
        NSString *title = NSLocalizedString(@"Effect", nil);
        [self updateProgressBarTitle:title status:[NSString stringWithFormat:@"%d%%", (int)([progress floatValue] * 100)]];
    }
}

#pragma mark - Progress Bar
- (void) setProgressBarDefaultStyle
{
    if (arc4random()%(int)2)
    {
        [MMProgressHUD setPresentationStyle:MMProgressHUDPresentationStyleSwingLeft];
    }
    else
    {
        [MMProgressHUD setPresentationStyle:MMProgressHUDPresentationStyleSwingRight];
    }
}

- (void) updateProgress:(CGFloat)value
{
    [MMProgressHUD updateProgress:value];
}

- (void) updateProgressBarTitle:(NSString*)title status:(NSString*)status
{
    [MMProgressHUD updateTitle:title status:status];
}

- (void) dismissProgressBarbyDelay:(NSTimeInterval)delay
{
    [MMProgressHUD dismissAfterDelay:delay];
}

- (void) dismissProgressBar:(NSString*)status
{
    [MMProgressHUD dismissWithSuccess:status];
}

#pragma mark - Export Video
- (void) writeExportedVideoToAssetsLibrary:(NSString *)outputURL
{
    __unsafe_unretained typeof(self) weakSelf = self;
	NSURL *exportURL = [NSURL fileURLWithPath:outputURL];
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:exportURL])
    {
		[library writeVideoAtPathToSavedPhotosAlbum:exportURL completionBlock:^(NSURL *assetURL, NSError *error)
         {
             if (error)
             {
                 [weakSelf AVAssetExportMP4ToAlbumStatusFailed:error];
             }
             else
             {
                 [weakSelf AVAssetExportMP4ToAlbumStatusCompleted:error];
             }
         }];
	}
    else
    {
		NSLog(@"Video could not be exported to camera roll.");
        
        // Enable "Save" button
        [self enableSaveButton:YES];
	}
    
    library = nil;
}

#pragma mark - Private Methods
- (NSString*)getOutputFilePath
{
    NSString *path = @"outputMovie.mp4";
    NSString* mp4OutputFile = [NSTemporaryDirectory() stringByAppendingPathComponent:path];
    return mp4OutputFile;
    
//    NSString *path = NSTemporaryDirectory();
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    formatter.dateFormat = @"yyyyMMddHHmmss";
//    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
//    
//    NSString *fileName = [[path stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@".mp4"];
//    return fileName;
}

- (CGFloat)getVideoDuration:(NSURL*)URL
{
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:URL options:opts];
    float second = 0;
    second = urlAsset.duration.value/urlAsset.duration.timescale;
    
    return second;
}

- (NSURL*) getFileURL:(NSString*)inputFileName
{
    NSString *fileName = [inputFileName stringByDeletingPathExtension];
    NSLog(@"%@",fileName);
    NSString *fileExt = [inputFileName pathExtension];
    NSLog(@"%@",fileExt);
    
    NSURL *inputVideoURL = [[NSBundle mainBundle] URLForResource:fileName withExtension:fileExt];
    return inputVideoURL;
}

- (void)deleteTempDirectory
{
    NSString *dir = NSTemporaryDirectory();
    deleteFilesAt(dir, @"mov");
}

- (void)buildVideoEffect:(ThemesType)curThemeType
{
    if (_videoEffects)
    {
        _videoEffects = nil;
    }

    BOOL highestQuality = TRUE;
    CGSize videoSize = self.view.frame.size;
    self.videoEffects = [[VideoEffect alloc] initWithDelegate:self];
    self.videoEffects.themeCurrentType = curThemeType;
    
//    BOOL result = [self.videoEffects image2Video:self.selectedPhotos exportVideoFile:_mp4OutputPath exportVideoSize:videoSize highestQuality:highestQuality];
    BOOL result = [self.self.videoEffects image2Videos:self.selectedPhotos exportVideoFile:_mp4OutputPath exportVideoSize:videoSize videosMultiInputURL:self.videosMultiInputURL highestQuality:highestQuality];
    if (!result)
    {
        NSString *failed = NSLocalizedString(@"Failed", nil);
        [self dismissProgressBar:failed];
        
        // Resume play
        if (_videoPlayerController.playbackState == PBJVideoPlayerPlaybackStatePaused)
        {
            [_videoPlayerController playFromCurrentTime];
        }
    }
}

- (void)playMp4Video:(NSString*)videoFilePath
{
//    if (!_hasMp4)
//    {
//        NSLog(@"Mp4 file not found!");
//        return;
//    }
    
    NSLog(@"%@",[NSString stringWithFormat:@"Play file is: %@", videoFilePath]);
    
    [self showVideoPlayView:TRUE];
    _videoPlayerController.videoPath = videoFilePath;
    [_videoPlayerController playFromBeginning];
}

- (void)playDemoVideo:(NSString*)demoVideo
{
    NSLog(@"%@",[NSString stringWithFormat:@"Play file is: %@", demoVideo]);
    
    [self showVideoPlayView:TRUE];
    
    NSString *fileName = [demoVideo stringByDeletingPathExtension];
    NSLog(@"%@",fileName);
    NSString *fileExt = [demoVideo pathExtension];
    NSLog(@"%@",fileExt);
    NSString *inputVideoURL = [[NSBundle mainBundle] pathForResource:fileName ofType:fileExt];
    
    _videoPlayerController.videoPath = inputVideoURL;
    [_videoPlayerController playFromBeginning];
}

#pragma mark - PBJVideoPlayerControllerDelegate
- (void)videoPlayerReady:(PBJVideoPlayerController *)videoPlayer
{
    //NSLog(@"Max duration of the video: %f", videoPlayer.maxDuration);
}

- (void)videoPlayerPlaybackStateDidChange:(PBJVideoPlayerController *)videoPlayer
{
}

- (void)videoPlayerPlaybackWillStartFromBeginning:(PBJVideoPlayerController *)videoPlayer
{
    _playButton.alpha = 1.0f;
    _playButton.hidden = NO;
    
    [UIView animateWithDuration:0.1f animations:^{
        _playButton.alpha = 0.0f;
    } completion:^(BOOL finished)
     {
         _playButton.hidden = YES;
         
     }];
}

- (void)videoPlayerPlaybackDidEnd:(PBJVideoPlayerController *)videoPlayer
{
    _playButton.hidden = NO;
    
    [UIView animateWithDuration:0.1f animations:^{
        _playButton.alpha = 1.0f;
    } completion:^(BOOL finished)
     {
         
     }];
}

#pragma mark - Custom Template
- (void)handleCustomCompletion
{
    NSLog(@"Template Custom End.");
    
    // Progress bar display
    [self setProgressBarDefaultStyle];
    NSString *title = NSLocalizedString(@"Processing", nil);
    [self updateProgressBarTitle:title status:@""];
    
    // Pause play
    if (_videoPlayerController.playbackState == PBJVideoPlayerPlaybackStatePlaying)
    {
        [_videoPlayerController pause];
    }
    
    // Custom backgroud video
    if ([self.videoInputURL isFileURL])
    {
        [[[VideoThemesData sharedInstance] getThemeByType:kThemeCustom] setBgVideoFile:self.videoInputURL];
    }
    
    // Custom background music
    if (!isStringEmpty(self.musicInputPath))
    {
        [[[VideoThemesData sharedInstance] getThemeByType:kThemeCustom] setBgMusicFile:self.musicInputPath];
    }
    
    // Random Animation
    if (self.effectInput != -1)
    {
        NSArray *aniArray = nil;
        if (self.selectedPhotos && [self.selectedPhotos count] > 1)
        {
            aniArray = [[VideoThemesData sharedInstance] getAnimationByIndex:self.effectInput];
        }
        else
        {
            aniArray = [[VideoThemesData sharedInstance] getAnimationByIndex:100];
        }
        [[[VideoThemesData sharedInstance] getThemeByType:kThemeCustom] setAnimationActions:aniArray];
    }
    else
    {
        if (self.selectedPhotos && [self.selectedPhotos count] > 1)
        {
            NSArray *aniArray = [[VideoThemesData sharedInstance] getRandomAnimation];
            [[[VideoThemesData sharedInstance] getThemeByType:kThemeCustom] setAnimationActions:aniArray];
        }
    }
    
    // Custom video border
    if (self.videoBorderIndex >= -1)
    {
        NSString *videoBorder = [[VideoThemesData sharedInstance] getVideoBorderByIndex:self.videoBorderIndex];
        [[[VideoThemesData sharedInstance] getThemeByType:kThemeCustom] setImageVideoBorder:videoBorder];
    }
    
    // Get ready
    self.mp4OutputPath = [self getOutputFilePath];
    
    ThemesType curThemeType = kThemeCustom;
    [self buildVideoEffect:curThemeType];
}

- (OnboardingViewController *)createCustom
{
    OnboardingViewController *onboardingVC;
     __block typeof(OnboardingViewController*) blockSelf;
    
    NSString *title = NSLocalizedString(@"CustomPhotoTitle", nil);
    NSString *body = NSLocalizedString(@"CustomPhotoBody", nil);
    NSString *btnText = NSLocalizedString(@"CustomPhotoBtnText", nil);
    OnboardingContentViewController *firstPage = [[OnboardingContentViewController alloc] initWithTitle:title body:body image:[UIImage imageNamed:@"red"] buttonText:btnText action:^{
        
        // Choose some photos
        [blockSelf pickPhotos];
    }];
    
    title = NSLocalizedString(@"CustomVideoTitle", nil);
    body = NSLocalizedString(@"CustomVideoBody", nil);
    btnText = NSLocalizedString(@"CustomVideoBtnText", nil);
    OnboardingContentViewController *secondPage = [[OnboardingContentViewController alloc] initWithTitle:title body:body image:[UIImage imageNamed:@"yellow"] buttonText:btnText action:^{
        
        // Choose a video
        [blockSelf pickVideo];
    }];
    
    title = NSLocalizedString(@"CustomEffectTitle", nil);
    body = NSLocalizedString(@"CustomEffectBody", nil);
    btnText = NSLocalizedString(@"CustomEffectBtnText", nil);
    OnboardingContentViewController *thirdPage = [[OnboardingContentViewController alloc] initWithTitle:title body:body image:[UIImage imageNamed:@"blue"] buttonText:btnText action:^{
        
        // Choose a photo effect
        [blockSelf pickEffect];
    }];

    title = NSLocalizedString(@"CustomMusicTitle", nil);
    body = NSLocalizedString(@"CustomMusicBody", nil);
    btnText = NSLocalizedString(@"CustomMusicBtnText", nil);
    OnboardingContentViewController *fourthPage = [[OnboardingContentViewController alloc] initWithTitle:title body:body image:[UIImage imageNamed:@"red"] buttonText:btnText action:^{
        
        // Choose a background music
        [blockSelf pickMusic];
    }];
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:3];
    VideoThemes *themesCustom = [[VideoThemesData sharedInstance] getThemeByType:kThemeCustom];
    [dic setObject:[themesCustom textStar] forKey:@"StartupText"];
    [dic setObject:[themesCustom textSparkle] forKey:@"BottomText"];
    [dic setObject:[themesCustom textGradient] forKey:@"TopText"];
    NSString *scrollText = [[themesCustom scrollText] componentsJoinedByString:@","];
    [dic setObject:scrollText forKey:@"ScrollText"];
    
    title = NSLocalizedString(@"CustomTextEffectTitle", nil);
    body = NSLocalizedString(@"CustomTextEffectBody", nil);
    btnText = NSLocalizedString(@"CustomTextEffectBtnText", nil);
    OnboardingContentViewController *fifthPage = [[OnboardingContentViewController alloc] initWithTitle:title body:body image:[UIImage imageNamed:@"blue"] buttonText:btnText action:^{
        
        // Choose a text effect
        [blockSelf pickTextEffectByDic:dic];
    }];
    

    title = NSLocalizedString(@"CustomVideoBorderTitle", nil);
    body = NSLocalizedString(@"CustomVideoBorderBody", nil);
    btnText = NSLocalizedString(@"CustomVideoBorderBtnText", nil);
    OnboardingContentViewController *sixthPage = [[OnboardingContentViewController alloc] initWithTitle:title body:body image:[UIImage imageNamed:@"yellow"] buttonText:btnText action:^{
        
        // Choose a video border
        [blockSelf pickVideoBorder];
    }];
    
    NSString *bgImage = [NSString stringWithFormat:@"tutorial_background_%1u@2x.jpg", arc4random()%(int)2];
    onboardingVC = [[OnboardingViewController alloc] initWithBackgroundImage:[UIImage imageNamed:bgImage] contents:@[firstPage, secondPage, thirdPage, fourthPage, fifthPage, sixthPage]];
    NSLog(@"bgImage: %@", bgImage);
    
    blockSelf = onboardingVC;
    [onboardingVC setButtonTextColor:BrightBlue];
    [onboardingVC setButtonFontName:@"Noteworthy-Bold"];
    
    // Pick image callback
    [blockSelf setCallbackPickPhotos:^(BOOL success, id result)
     {
         if (success)
         {
             if (self.selectedPhotos && [self.selectedPhotos count]>0)
             {
                 NSLog(@"Clear original photos");
                 [self.selectedPhotos removeAllObjects];
             }
             [self.selectedPhotos setArray:result];
             
             if (self.selectedPhotos && [self.selectedPhotos count]>0)
             {
                 self.hasPhotos = YES;
             }
         }
         else
         {
             NSLog(@"Image Picker Failed: %@", result);
         }
     }];

    // Pick video callback
    [blockSelf setCallbackPickVideo:^(BOOL success, id result)
     {
         // Return a URL of NSArray
         if (success)
         {
             NSArray *fileURLs = result;
             if (fileURLs && [fileURLs count]>0)
             {
                 self.videosMultiInputURL = fileURLs;
                 self.videoInputURL = nil;
                 NSLog(@"Pick video is success: %@", fileURLs);
             }
             else
             {
                 NSLog(@"Video Picker is empty.");
             }
         }
         else
         {
             NSLog(@"Video Picker Failed: %@", result);
         }

     }];
    
    // Pick music callback
    [blockSelf setCallbackPickMusic:^(BOOL success, id result)
     {
         if (success)
         {
             NSArray *musics = [NSArray arrayWithObjects: @"Untitled", @"Pretty Boy", @"Big Big World", @"Rhythm Of Rain", @"The mood of love", @"Because I Love You", @"Yesterday Once More", @"The Day You Went Away",  @"I love you more than I can say", nil];
             NSString *musicFile = [musics objectAtIndex:[result longValue]];
             self.musicInputPath = [musicFile stringByAppendingString:@".mp3"];
             
             NSLog(@"musicInputPath: %@", self.musicInputPath);
         }
         else
         {
             NSLog(@"Music Picker Failed: %@", result);
         }
     }];
    
    // Pick effect callback
    [blockSelf setCallbackPickEffect:^(BOOL success, id result)
     {
         if (success)
         {
             self.effectInput = [result intValue];
             NSLog(@"Effect Input: %i", self.effectInput);
         }
         else
         {
             NSLog(@"Effect Picker Failed: %@", result);
         }
     }];
    
    // Pick text effect callback
    [blockSelf setCallbackPickTextEffect:^(BOOL success, id result)
     {
         if (success)
         {
             NSMutableDictionary *resultDic = [result copy];
             NSString *result = [resultDic objectForKey:@"StartupText"];
             if (result && ![result isEqualToString:@""])
             {
                 [[[VideoThemesData sharedInstance] getThemeByType:kThemeCustom] setTextStar:[resultDic objectForKey:@"StartupText"]];
             }
             
             result = [resultDic objectForKey:@"BottomText"];
             if (result && ![result isEqualToString:@""])
             {
                 [[[VideoThemesData sharedInstance] getThemeByType:kThemeCustom] setTextSparkle:[resultDic objectForKey:@"BottomText"]];
             }
             
             result = [resultDic objectForKey:@"TopText"];
             if (result && ![result isEqualToString:@""])
             {
                 [[[VideoThemesData sharedInstance] getThemeByType:kThemeCustom] setTextGradient:[resultDic objectForKey:@"TopText"]];
             }
             
             result = [resultDic objectForKey:@"ScrollText"];
             if (result && ![result isEqualToString:@""])
             {
                 NSString *str = [[resultDic objectForKey:@"ScrollText"] stringByReplacingOccurrencesOfString:@"，" withString:@","];
                 NSArray *arrayResult = [str componentsSeparatedByString:@","];
                 [[[VideoThemesData sharedInstance] getThemeByType:kThemeCustom] setScrollText:[arrayResult mutableCopy]];
             }
             
             NSLog(@"Text Effect Input: %@", resultDic);
         }
         else
         {
             NSLog(@"Text Effect Picker Failed: %@", result);
         }
     }];
    
    
    // Pick video border callback
    [blockSelf setCallbackPickVideoBorder:^(BOOL success, id result)
     {
         if (success)
         {
             self.videoBorderIndex = [result intValue];
             NSLog(@"Video border index: %i", self.videoBorderIndex);
         }
         else
         {
             NSLog(@"Video border picker failed: %@", result);
         }
     }];
    
    // If you want to allow skipping the onboarding process, enable skipping and set a block to be executed
    // when the user hits the skip button.
    onboardingVC.allowSkipping = YES;
    onboardingVC.skipHandler = ^{
          [blockSelf  dismissViewControllerAnimated:YES completion:^{
            
                [self handleCustomCompletion];
            }];
    };
    
    return onboardingVC;
}

#pragma mark - IBAction Methods
- (void)handleActionTakeCustom
{
    NSLog(@"handleActionTakeCustom");
    
    // Pause play
    if (_videoPlayerController.playbackState == PBJVideoPlayerPlaybackStatePlaying)
    {
        [_videoPlayerController pause];
    }
    
    [self presentViewController:[self createCustom] animated:YES completion:^{
        NSLog(@"createCustom present");
    }];
}

- (void) handleActionSavetoAlbums
{
    NSLog(@"handleActionSavetoAlbums");
    
    if (_hasMp4)
    {
        // Disable "Save" button
        [self enableSaveButton:NO];
        
        [self writeExportedVideoToAssetsLibrary:_mp4OutputPath];
    }
}

- (void) enableSaveButton:(BOOL)enable
{
    if (enable)
    {
        _saveVideo.enabled = YES;
        _titleSaveVideo.enabled = YES;
    }
    else
    {
        _saveVideo.enabled = NO;
        _titleSaveVideo.enabled = NO;
    }
}

- (void) showVideoPlayView:(BOOL)show
{
    if (show)
    {
        _playButton.hidden = NO;
        _videoPlayerController.view.hidden = NO;
    }
    else
    {
        _playButton.hidden = YES;
        _videoPlayerController.view.hidden = YES;
    }
}

#pragma mark - CMPopTipViewDelegate methods
- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView
{
}

#pragma mark - App NSNotifications
- (void)_applicationWillEnterForeground:(NSNotification *)notification
{
    NSLog(@"applicationWillEnterForeground");
    
    [self.videoEffects resume];
    
    // Resume play
    if (_videoPlayerController.playbackState == PBJVideoPlayerPlaybackStatePaused)
    {
        [_videoPlayerController playFromCurrentTime];
    }
    
    [self dismissProgressBar:@"Failed!"];
}

- (void)_applicationDidEnterBackground:(NSNotification *)notification
{
    NSLog(@"applicationDidEnterBackground");
    
    [self.videoEffects pause];
    
    // Pause play
    if (_videoPlayerController.playbackState == PBJVideoPlayerPlaybackStatePlaying)
    {
        [_videoPlayerController pause];
    }
}

#pragma mark - View LifeCycle
- (id) init
{
    if (self = [super init])
    {
        self.hasPhotos = NO;
        self.hasMp4 = NO;
        self.mp4OutputPath = nil;
        self.selectedPhotos = [NSMutableArray array];
        self.effectInput = -1;
        self.videoBorderIndex = -1;
        self.musicInputPath = nil;
        self.videosMultiInputURL = nil;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillEnterForeground:) name:@"UIApplicationWillEnterForegroundNotification" object:[UIApplication sharedApplication]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidEnterBackground:) name:@"UIApplicationDidEnterBackgroundNotification" object:[UIApplication sharedApplication]];
        
        [self deleteTempDirectory];
    }
    
	return self;
}

- (void)initToolbarView
{
    CGFloat orginHeight = self.view.frame.size.height - toolbarHeight;
    if (iOS6 || iOS5)
    {
        orginHeight += 20;
    }
    
    int margin = 10;
    UIImage *imageCustomUp = [UIImage imageNamed:@"cameraRoll_up"];
    _toggleCustom = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 - imageCustomUp.size.width - margin, orginHeight, imageCustomUp.size.width, imageCustomUp.size.height)];
    [_toggleCustom setImage:imageCustomUp forState:(UIControlStateNormal)];
    [_toggleCustom setImage:[UIImage imageNamed:@"cameraRoll_down"] forState:(UIControlStateSelected)];
    [_toggleCustom addTarget:self action:@selector(handleActionTakeCustom) forControlEvents:UIControlEventTouchUpInside];
    
    int gap = 10;
    CGRect rectCustom = CGRectMake(_toggleCustom.frame.origin.x-gap/2, _toggleCustom.frame.origin.y+_toggleCustom.frame.size.height, _toggleCustom.frame.size.width+gap, 15);
    NSString *textCustom = NSLocalizedString(@"Custom", nil);
    _titleCustom = [[UIButton alloc] initWithFrame:rectCustom];
    [_titleCustom setBackgroundColor:[UIColor clearColor]];
    [_titleCustom setTitleColor:LightBlue forState:UIControlStateNormal];
    _titleCustom.titleLabel.font = [UIFont systemFontOfSize: 14.0];
    _titleCustom.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_titleCustom setTitle:textCustom forState: UIControlStateNormal];
    [_titleCustom addTarget:self action:@selector(handleActionTakeCustom) forControlEvents:UIControlEventTouchUpInside];
    
    UIImage *imageSaveUp = [UIImage imageNamed:@"saveCameraRoll_up"];
    _saveVideo = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 + imageSaveUp.size.width - margin, orginHeight, imageSaveUp.size.width, imageSaveUp.size.height)];
    [_saveVideo setImage:imageSaveUp forState:(UIControlStateNormal)];
    [_saveVideo setImage:[UIImage imageNamed:@"saveCameraRoll_down"] forState:(UIControlStateSelected)];
    [_saveVideo setImage:[UIImage imageNamed:@"saveCameraRoll_disabled"] forState:(UIControlStateHighlighted)];
    [_saveVideo addTarget:self action:@selector(handleActionSavetoAlbums) forControlEvents:UIControlEventTouchUpInside];
    
    CGRect rectSave = CGRectMake(_saveVideo.frame.origin.x-gap/2, _saveVideo.frame.origin.y+_saveVideo.frame.size.height, _saveVideo.frame.size.width+gap, 15);
    NSString *textSave = NSLocalizedString(@"Save", nil);
    _titleSaveVideo = [[UIButton alloc] initWithFrame:rectSave];
    [_titleSaveVideo setBackgroundColor:[UIColor clearColor]];
    [_titleSaveVideo setTitleColor:LightBlue forState:UIControlStateNormal];
    _titleSaveVideo.titleLabel.font = [UIFont systemFontOfSize: 14.0];
    _titleSaveVideo.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_titleSaveVideo setTitle:textSave forState: UIControlStateNormal];
    [_titleSaveVideo addTarget:self action:@selector(handleActionSavetoAlbums) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_toggleCustom];
    [self.view addSubview:_titleCustom];
    [self.view addSubview:_saveVideo];
    [self.view addSubview:_titleSaveVideo];
}

- (void) initVideoPlayView
{
    _videoPlayerController = [[PBJVideoPlayerController alloc] init];
    _videoPlayerController.delegate = self;
    _videoPlayerController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    _videoPlayerController.view.clipsToBounds = YES;
    
    [self addChildViewController:_videoPlayerController];
    [self.view addSubview:_videoPlayerController.view];
    
    _playButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play_button"]];
    _playButton.center = self.view.center;
    [_videoPlayerController.view addSubview:_playButton];
}

- (void)initPopView
{
    NSArray *colorSchemes = [NSArray arrayWithObjects:
                             [NSArray arrayWithObjects:[NSNull null], [NSNull null], nil],
                             [NSArray arrayWithObjects:[UIColor colorWithRed:134.0/255.0 green:74.0/255.0 blue:110.0/255.0 alpha:1.0], [NSNull null], nil],
                             [NSArray arrayWithObjects:[UIColor darkGrayColor], [NSNull null], nil],
                             [NSArray arrayWithObjects:[UIColor lightGrayColor], [UIColor darkTextColor], nil],
                             [NSArray arrayWithObjects:[UIColor colorWithRed:220.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0], [NSNull null], nil],
                             nil];
    NSArray *colorScheme = [colorSchemes objectAtIndex:foo4random()*[colorSchemes count]];
    UIColor *backgroundColor = [colorScheme objectAtIndex:0];
    UIColor *textColor = [colorScheme objectAtIndex:1];
    
    NSString *hint = NSLocalizedString(@"UsageHint", nil);
    _popTipView = [[CMPopTipView alloc] initWithMessage:hint];
    _popTipView.delegate = self;
    if (backgroundColor && ![backgroundColor isEqual:[NSNull null]])
    {
        _popTipView.backgroundColor = backgroundColor;
    }
    if (textColor && ![textColor isEqual:[NSNull null]])
    {
        _popTipView.textColor = textColor;
    }
    
    if (!iOS5 && !iOS6)
    {
        _popTipView.preferredPointDirection = PointDirectionDown;
    }
    _popTipView.animation = arc4random() % 2;
    _popTipView.has3DStyle = FALSE;
    _popTipView.dismissTapAnywhere = YES;
    [_popTipView autoDismissAnimated:YES atTimeInterval:3.0];
    
    [_popTipView presentPointingAtView:_toggleCustom inView:self.view animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initVideoPlayView];
    [self initToolbarView];
    [self initPopView];
    
    // Disable "Save" button
    [self enableSaveButton:NO];
    
    NSString *filePathLatest = [self getOutputFilePath];
    if (getFileSize(filePathLatest) > 0)
    {
        [self playMp4Video:filePathLatest];
    }
    else
    {
        // Preview demo video
        NSString *demoFile = [NSString stringWithFormat:@"Demo%1u.mp4", (arc4random() % 2)+1];
        [self playDemoVideo:demoFile];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewDidUnload
{
    _videoPlayerController = nil;
    [_selectedPhotos removeAllObjects];
    _selectedPhotos = nil;
    
    _playButton = nil;
    _viewToolbar = nil;
    _imageViewToolbarBG = nil;
    _toggleCustom = nil;
    _saveVideo = nil;
    _titleCustom = nil;
    _titleSaveVideo = nil;
    
    _popTipView = nil;
    
    [super viewDidUnload];
}

- (void) dealloc
{

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(BOOL)shouldAutorotate
{
    return NO;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

@end
