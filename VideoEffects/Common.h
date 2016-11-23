//
//  Common.h
//  CustomBeauty
//
//  Created by Johnny Xu(徐景周) on 8/14/14.
//  Copyright (c) 2014 Future Studio. All rights reserved.
//

#define kGoogleBannerAdUnitID @"ca-app-pub-6198062867594871/7239756743"
#define kGoogleInterstitialAdUnitID @"ca-app-pub-6198062867594871/8716489942"

#define SUPPRESS_UNDECLARED_SELECTOR_WARNING(code)                        \
_Pragma("clang diagnostic push")                                        \
_Pragma("clang diagnostic ignored \"-Wundeclared-selector"\"")     \
code;                                                                   \
_Pragma("clang diagnostic pop")                                         \

typedef void(^Callback)(BOOL success, id result);

#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : 0)
#define IS_PHONE        (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
//#define IS_IPAD         (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define iOS8 ((([[UIDevice currentDevice].systemVersion intValue] >= 8) && ([[UIDevice currentDevice].systemVersion intValue] < 9)) ? YES : NO )
#define iOS7 ((([[UIDevice currentDevice].systemVersion intValue] >= 7) && ([[UIDevice currentDevice].systemVersion intValue] < 8)) ? YES : NO )
#define iOS6 ((([[UIDevice currentDevice].systemVersion intValue] >= 6) && ([[UIDevice currentDevice].systemVersion intValue] < 7)) ? YES : NO )
#define iOS5 ((([[UIDevice currentDevice].systemVersion intValue] >= 5) && ([[UIDevice currentDevice].systemVersion intValue] < 6)) ? YES : NO )

#define foo4random() (1.0 * (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX)
#define toolbarHeight 70
#define kMaxRecordDuration 15

#define LightBlue [UIColor colorWithRed:155/255.0f green:188/255.0f blue:220/255.0f alpha:1]
#define BrightBlue [UIColor colorWithRed:100/255.0f green:100/255.0f blue:230/255.0f alpha:1]

#pragma mark - Common function
static inline void dispatch_async_main_after(NSTimeInterval after, dispatch_block_t block)
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(after * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), block);
}

static inline float randomFloat()
{
    return (float)rand()/(float)RAND_MAX;
}

// Unstable
static inline BOOL isFileExisted(NSString *filePath)
{
    NSFileManager * filemanager = [[NSFileManager alloc]init];
    if([filemanager fileExistsAtPath:filePath])
    {
        return TRUE;
    }
    else
    {
        return FALSE;
    }
}

static inline NSInteger getFileSize(NSString *filePath)
{
    NSFileManager * filemanager = [[NSFileManager alloc]init];
    if([filemanager fileExistsAtPath:filePath])
    {
        NSDictionary * attributes = [filemanager attributesOfItemAtPath:filePath error:nil];
        NSNumber *theFileSize;
        if ( (theFileSize = [attributes objectForKey:NSFileSize]) )
        {
            return  [theFileSize intValue]/1024;
        }
        else
            return -1;
    }
    else
    {
        return -1;
    }
}

static inline void deleteFilesAt(NSString *directory, NSString *suffixName)
{
    NSError *err = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:directory];
    NSString *toDelVideoFile;
    while (toDelVideoFile = [dirEnum nextObject])
    {
        if ([[toDelVideoFile pathExtension] isEqualToString:suffixName])
        {
            NSLog(@"removing file：%@",toDelVideoFile);
            if(![fileManager removeItemAtPath:[directory stringByAppendingPathComponent:toDelVideoFile] error:&err])
            {
                NSLog(@"Error: %@", [err localizedDescription]);
            }
        }
    }
}

static inline BOOL isStringEmpty(NSString *value)
{
    BOOL result = FALSE;
    if (!value || [value isKindOfClass:[NSNull class]])
    {
        // null object
        result = TRUE;
    }
    else
    {
        NSString *trimedString = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([value isKindOfClass:[NSString class]] && [trimedString length] == 0)
        {
            // empty string
            result = TRUE;
        }
    }
    
    return result;
}

static inline float systemVersion()
{
    static dispatch_once_t pred = 0;
    static NSUInteger version = -1;
    dispatch_once(&pred, ^{
        version = [[[UIDevice currentDevice] systemVersion] floatValue];
    });
    
    return version;
}

// iOS 8 way of returning bounds for all SDK's and OS-versions
#ifndef NSFoundationVersionNumber_iOS_7_1
# define NSFoundationVersionNumber_iOS_7_1 1047.25
#endif
static inline CGRect screenBounds()
{
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    static BOOL isNotRotatedBySystem;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BOOL OSIsBelowIOS8 = [[[UIDevice currentDevice] systemVersion] floatValue] < 8.0;
        BOOL SDKIsBelowIOS8 = floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1;
        isNotRotatedBySystem = OSIsBelowIOS8 || SDKIsBelowIOS8;
    });
    
    BOOL needsToRotate = isNotRotatedBySystem && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    if(needsToRotate)
    {
        CGRect bounds = screenBounds;
        bounds.size.width = screenBounds.size.height;
        bounds.size.height = screenBounds.size.width;
        return bounds;
    }
    else
    {
        return screenBounds;
    }
}

static inline CGSize windowSize()
{
    static dispatch_once_t pred = 0;
    static CGSize size;
    dispatch_once(&pred, ^{
        size = [[UIScreen mainScreen] bounds].size;
    });
    
    return size;
}

static inline CGRect frameForStatusBar()
{
    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    return CGRectMake(0, systemVersion >= 7.0 ? 20.0f : 0.0f, windowSize().width, systemVersion >= 7.0 ? windowSize().height - 20: windowSize().height);
}
