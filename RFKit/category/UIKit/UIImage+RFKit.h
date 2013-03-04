/*!
    UIImage extension
    RFKit

    Copyright (c) 2012-2013 BB9z
    http://github.com/bb9z/RFKit

    The MIT License (MIT)
    http://www.opensource.org/licenses/mit-license.php
 */

typedef enum {
	NYXCropModeTopLeft,
	NYXCropModeTopCenter,
	NYXCropModeTopRight,
	NYXCropModeBottomLeft,
	NYXCropModeBottomCenter,
	NYXCropModeBottomRight,
	NYXCropModeLeftCenter,
	NYXCropModeRightCenter,
	NYXCropModeCenter
} NYXCropMode;

typedef enum {
	NYXImageTypePNG,
	NYXImageTypeJPEG,
	NYXImageTypeGIF,
	NYXImageTypeBMP,
	NYXImageTypeTIFF
} NYXImageType;

#import "RFRuntime.h"

@interface UIImage (RFKit)
+ (UIImage *)resourceName:(NSString *)PNGFileName;
+ (UIImage *)resourceName:(NSString *)fileName ofType:(NSString *)type;

// @REF: http://stackoverflow.com/a/605385/945906
- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize;
- (UIImage*)imageAspectFillSize:(CGSize)targetSize;

//rotate
- (UIImage*)rotateInRadians:(float)radians;
- (UIImage*)rotateInDegrees:(float)degrees;
- (UIImage*)rotateImagePixelsInRadians:(float)radians;
- (UIImage*)rotateImagePixelsInDegrees:(float)degrees;
- (UIImage*)verticalFlip;
- (UIImage*)horizontalFlip;

//Blurring
- (UIImage*)gaussianBlurWithBias:(NSInteger)bias;

//Enhancing
- (UIImage*)autoEnhance;
- (UIImage*)redEyeCorrection;

//Filtering
- (UIImage*)brightenWithValue:(float)factor;
- (UIImage*)contrastAdjustmentWithValue:(float)value;
- (UIImage*)edgeDetectionWithBias:(NSInteger)bias;
- (UIImage*)embossWithBias:(NSInteger)bias;
- (UIImage*)gammaCorrectionWithValue:(float)value;
- (UIImage*)grayscale;
- (UIImage*)invert;
- (UIImage*)opacity:(float)value;
- (UIImage*)sepia;
- (UIImage*)sharpenWithBias:(NSInteger)bias;
- (UIImage*)unsharpenWithBias:(NSInteger)bias;

//Masking
- (UIImage*)maskWithImage:(UIImage*)mask;

//Reflection
- (UIImage*)reflectedImageWithHeight:(NSUInteger)height fromAlpha:(float)fromAlpha toAlpha:(float)toAlpha;

//Resizing
- (UIImage*)cropToSize:(CGSize)newSize usingMode:(NYXCropMode)cropMode;
- (UIImage*)cropToSize:(CGSize)newSize;
- (UIImage*)scaleByFactor:(float)scaleFactor;
- (UIImage*)scaleToFitSize:(CGSize)newSize;

//Saving
- (BOOL)saveToURL:(NSURL*)url uti:(CFStringRef)uti backgroundFillColor:(UIColor*)fillColor;
- (BOOL)saveToURL:(NSURL*)url type:(NYXImageType)type backgroundFillColor:(UIColor*)fillColor;
- (BOOL)saveToURL:(NSURL*)url;
- (BOOL)saveToPath:(NSString*)path uti:(CFStringRef)uti backgroundFillColor:(UIColor*)fillColor;
- (BOOL)saveToPath:(NSString*)path type:(NYXImageType)type backgroundFillColor:(UIColor*)fillColor;
- (BOOL)saveToPath:(NSString*)path;
- (BOOL)saveToPhotosAlbum;
+ (NSString*)extensionForUTI:(CFStringRef)uti;

@end


