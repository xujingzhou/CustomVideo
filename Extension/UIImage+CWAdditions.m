//
//  UIImage+CWResize.m
//  CWUIKit
//  Created by Fredrik Olsson 
//
//  Copyright (c) 2011, Jayway AB All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of Jayway AB nor the names of its contributors may 
//       be used to endorse or promote products derived from this software 
//       without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL JAYWAY AB BE LIABLE FOR ANY DIRECT, INDIRECT, 
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
//  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//





#import "UIImage+CWAdditions.h"


@implementation UIImage (CWResize)

-(UIImage*)imageByResizingToFitSize:(CGSize)size scaleUpIfNeeded:(BOOL)scaleUp;
{
    CGSize originalSize = self.size;
    if (scaleUp || (size.width < originalSize.width) || (size.height < originalSize.height)) {
        CGRect rect = CGRectZero;
        if (originalSize.width > originalSize.height) {
            rect.size = CGSizeMake(size.width, size.height * (originalSize.height / originalSize.width));
        } else {
            rect.size = CGSizeMake(size.width * (originalSize.width / originalSize.height), size.height);
        }
        UIGraphicsBeginImageContext(rect.size);
        [self drawInRect:rect];
        UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image;
    } else {
    	return self;
    }	
}

-(UIImage*)imageByApsectFillToSize:(CGSize)size withInset:(UIEdgeInsets)insets;
{
    UIGraphicsBeginImageContext(size);
    size = UIEdgeInsetsInsetRect(CGRectMake(0, 0, size.width, size.height), insets).size;
    CGSize originalSize = self.size;
    CGRect rect;
    if (originalSize.width > originalSize.height) {
        rect.size = CGSizeMake(size.width, size.height * (originalSize.height / originalSize.width));
        rect.origin = CGPointMake(insets.left, insets.top + (size.height - rect.size.height) / 2);
    } else {
        rect.size = CGSizeMake(size.width * (originalSize.width / originalSize.height), size.height);
        rect.origin = CGPointMake(insets.left +(size.width - rect.size.width) / 2, insets.top);
    }
    [self drawInRect:rect];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

-(UIImage*)imageCroppedToSquareWithSide:(CGFloat)sideLength;
{
	// used code from http://www.nickkuh.com/iphone/how-to-create-square-thumbnails-using-iphone-sdk-cg-quartz-2d/2010/03/	
	
    
	UIImageView *mainImageView = [[UIImageView alloc] initWithImage:self];
	BOOL widthGreaterThanHeight = (self.size.width > self.size.height);
	float sideFull = (widthGreaterThanHeight) ? self.size.height : self.size.width;
	CGRect clippedRect = CGRectMake(0, 0, sideFull, sideFull);
	//creating a square context the size of the final image which we will then
	// manipulate and transform before drawing in the original image
	UIGraphicsBeginImageContext(CGSizeMake(sideLength, sideLength));
	CGContextRef currentContext = UIGraphicsGetCurrentContext();
	CGContextClipToRect( currentContext, clippedRect);
	CGFloat scaleFactor = sideLength/sideFull;
	if (widthGreaterThanHeight) {
		//a landscape image – make context shift the original image to the left when drawn into the context
		CGContextTranslateCTM(currentContext, - ((self.size.width - sideFull) /2 ) * scaleFactor, 0);
	}
	else {
		//a portfolio image – make context shift the original image upwards when drawn into the context
		CGContextTranslateCTM(currentContext, 0, -((self.size.height - sideFull) / 2) * scaleFactor);
	}
	CGContextScaleCTM(currentContext, scaleFactor, scaleFactor);
	[mainImageView.layer renderInContext:currentContext];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

@end


@implementation UIImage (CWNormalization)


-(UIImage*)normalizedImage;
{
    CGImageRef imgRef = self.CGImage;  
    
    CGAffineTransform transform = CGAffineTransformIdentity;  
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));  
    CGRect bounds = CGRectZero;
    bounds.size = imageSize;
    
    UIImageOrientation orient = self.imageOrientation;
    CGFloat temp;
    
    switch (orient) {  
            
        case UIImageOrientationUp: //EXIF = 1
            return self;
            
        case UIImageOrientationUpMirrored: //EXIF = 2  
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);  
            transform = CGAffineTransformScale(transform, -1.0, 1.0);  
            break;  
            
        case UIImageOrientationDown: //EXIF = 3  
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);  
            transform = CGAffineTransformRotate(transform, M_PI);  
            break;  
            
        case UIImageOrientationDownMirrored: //EXIF = 4  
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);  
            transform = CGAffineTransformScale(transform, 1.0, -1.0);  
            break;  
            
        case UIImageOrientationLeftMirrored: //EXIF = 5  
            temp = bounds.size.height;  
            bounds.size.height = bounds.size.width;  
            bounds.size.width = temp;  
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);  
            transform = CGAffineTransformScale(transform, -1.0, 1.0);  
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);  
            break;  
            
        case UIImageOrientationLeft: //EXIF = 6  
            temp = bounds.size.height;  
            bounds.size.height = bounds.size.width;  
            bounds.size.width = temp;  
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);  
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);  
            break;  
            
        case UIImageOrientationRightMirrored: //EXIF = 7  
            temp = bounds.size.height;  
            bounds.size.height = bounds.size.width;  
            bounds.size.width = temp;  
            transform = CGAffineTransformMakeScale(-1.0, 1.0);  
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);  
            break;  
            
        case UIImageOrientationRight: //EXIF = 8  
            temp = bounds.size.height;  
            bounds.size.height = bounds.size.width;  
            bounds.size.width = temp;  
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);  
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);  
            break;  
            
        default:  
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];  
            
    }  
    
    UIGraphicsBeginImageContext(bounds.size);  
    
    CGContextRef context = UIGraphicsGetCurrentContext();  
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextTranslateCTM(context, -imageSize.height, 0);  
    }  
    else {  
        CGContextTranslateCTM(context, 0, -imageSize.height);  
    }  
    
    CGContextConcatCTM(context, transform);  
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), 
                       CGRectMake(0, 0, imageSize.width, imageSize.height), 
                       imgRef);  
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();  
    
    UIGraphicsEndImageContext();  
    
    return imageCopy;
        
}

@end


@implementation UIImage (CWStretchable)

-(UIImage*)subimageWithRect:(CGRect)rect;
{
    
	UIGraphicsBeginImageContextWithOptions(rect.size, YES, self.scale);
    [self drawAtPoint:CGPointMake(-rect.origin.x, -rect.origin.y)];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGContextRelease(UIGraphicsGetCurrentContext());

    return image;
        
}

-(UIImage*)stretchableImageFromLeftCapOfImage;
{
    CGFloat leftCap = self.leftCapWidth;
    CGSize size = self.size;
	CGRect rect = CGRectMake(0, 0, leftCap + 1, size.height);
    UIImage* image = [self subimageWithRect:rect];
    return [image stretchableImageWithLeftCapWidth:leftCap topCapHeight:self.topCapHeight];
}

-(UIImage*)stretchableImageFromMiddleOfImage;
{
    CGFloat leftCap = self.leftCapWidth;
    CGSize size = self.size;
	CGRect rect = CGRectMake(leftCap, 0, 1, size.height);
    UIImage* image = [self subimageWithRect:rect];
    return [image stretchableImageWithLeftCapWidth:0 topCapHeight:self.topCapHeight];
}

-(UIImage*)stretchableImageFromRightCapOfImage;
{
    CGFloat leftCap = self.leftCapWidth;
    CGSize size = self.size;
	CGRect rect = CGRectMake(leftCap, 0, size.width - leftCap, size.height);
    UIImage* image = [self subimageWithRect:rect];
    return [image stretchableImageWithLeftCapWidth:1 topCapHeight:self.topCapHeight];
}

@end

//
//  UIImage-Extensions.m
//
//  Created by Hardy Macia on 7/1/09.
//  Copyright 2009 Catamount Software. All rights reserved.
//

CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};
CGFloat RadiansToDegrees(CGFloat radians) {return radians * 180/M_PI;};

@implementation UIImage (CS_Extensions)

-(UIImage *)imageAtRect:(CGRect)rect
{
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], rect);
    UIImage* subImage = [UIImage imageWithCGImage: imageRef];
    CGImageRelease(imageRef);
    
    return subImage;
    
}

- (UIImage *)imageByScalingProportionallyToMinimumSize:(CGSize)targetSize {
    
    UIImage *sourceImage = self;
    UIImage *newImage = nil;
    
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor) 
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5; 
        } else if (widthFactor < heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    
    // this is actually the interesting part:
    
    UIGraphicsBeginImageContext(targetSize);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil) NSLog(@"could not scale image");
    
    
    return newImage ;
}


- (UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize {
    
    UIImage *sourceImage = self;
    UIImage *newImage = nil;
    
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor < heightFactor) 
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        
        if (widthFactor < heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5; 
        } else if (widthFactor > heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    
    // this is actually the interesting part:
    
    UIGraphicsBeginImageContext(targetSize);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil) NSLog(@"could not scale image");;
    
    
    return newImage ;
}


- (UIImage *)imageByScalingToSize:(CGSize)targetSize {
    
    UIImage *sourceImage = self;
    UIImage *newImage = nil;
    
    //   CGSize imageSize = sourceImage.size;
    //   CGFloat width = imageSize.width;
    //   CGFloat height = imageSize.height;
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    //   CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    // this is actually the interesting part:
    
    UIGraphicsBeginImageContext(targetSize);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil) NSLog(@"could not scale image");;
    
    
    return newImage ;
}


- (UIImage *)imageRotatedByRadians:(CGFloat)radians
{
    return [self imageRotatedByDegrees:RadiansToDegrees(radians)];
}

- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees 
{   
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.size.width, self.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(DegreesToRadians(degrees));
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //   // Rotate the image context
    CGContextRotateCTM(bitmap, DegreesToRadians(degrees));
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), [self CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
    
}

@end;