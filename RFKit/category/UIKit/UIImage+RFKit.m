
#import "RFKit.h"
#import "NYXImagesHelper.h"
#import "UIImage+RFKit.h"
#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h> // For CGImageDestination
#import <MobileCoreServices/MobileCoreServices.h> // For the UTI types constants
#import <AssetsLibrary/AssetsLibrary.h> // For photos album saving

@interface UIImage (NYX_Saving_private)
- (CFStringRef)utiForType:(NYXImageType)type;
@end

@implementation UIImage (RFKit)
+ (UIImage *)resourceName:(NSString *)PNGFileName{
	return [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:PNGFileName ofType:@"png"]];
}

+ (UIImage *)resourceName:(NSString *)fileName ofType:(NSString *)type {
	return [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:fileName ofType:type]];
}

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize {
	
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
	
	if (CGSizeEqualToSize(imageSize, targetSize) == NO) 
	{
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
		
        if (widthFactor > heightFactor) 
			scaleFactor = widthFactor; // scale to fit height
        else
			scaleFactor = heightFactor; // scale to fit width
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
		
        // center the image
        if (widthFactor > heightFactor)
		{
			thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5; 
		}
        else 
			if (widthFactor < heightFactor)
			{
				thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
			}
	}       
	
	UIGraphicsBeginImageContext(targetSize); // this will crop
	
	CGRect thumbnailRect = CGRectZero;
	thumbnailRect.origin = thumbnailPoint;
	thumbnailRect.size.width  = scaledWidth;
	thumbnailRect.size.height = scaledHeight;
	
	[sourceImage drawInRect:thumbnailRect];
	
	newImage = UIGraphicsGetImageFromCurrentImageContext();
	if(newImage == nil) 
        dout_error(@"could not scale image");
	
	//pop the context to get back to the default
	UIGraphicsEndImageContext();
	return newImage;
}

- (UIImage *)imageAspectFillSize:(CGSize)targetSize{
	if (CGSizeEqualToSize(self.size, targetSize)) {
		return RF_AUTORELEASE([self copy]);
	}
	
	CGFloat xSource = self.size.width;
	CGFloat ySource = self.size.height;
	CGFloat xTarget = targetSize.width;
	CGFloat yTarget = targetSize.height;
	CGRect tmpImageRect = CGRectMake(0, 0, xSource, ySource);
	CGFloat factor;
	
	if (xSource/ySource > xTarget/yTarget) {
		// 图像按高适配
		factor = yTarget/ySource;
		tmpImageRect.size.width = xSource*factor;
		tmpImageRect.size.height = yTarget;
		tmpImageRect.origin.x = (xTarget -tmpImageRect.size.width)/2;
	}
	else {
		// 图像按宽度适配
		factor = xTarget/xSource;
		tmpImageRect.size.height = ySource*factor;
		tmpImageRect.size.width = xTarget;
		tmpImageRect.origin.y = (yTarget - tmpImageRect.size.height)/2;
	}
	
	UIGraphicsBeginImageContext(targetSize); // this will crop
	[self drawInRect:tmpImageRect];
	UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
	if (!newImage) {
		douts(@"Resize Image Faile");
	}
	UIGraphicsEndImageContext();
	return newImage;
}

//rotate
- (UIImage*)rotateInRadians:(float)radians {
	const size_t width = (size_t)(self.size.width * self.scale);
	const size_t height = (size_t)(self.size.height * self.scale);
    
	CGRect imgRect = (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height};
	CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, CGAffineTransformMakeRotation(radians));
    
	/// Create an ARGB bitmap context
	CGContextRef bmContext = NYXCreateARGBBitmapContext((size_t)rotatedRect.size.width, (size_t)rotatedRect.size.height, 0);
	if (!bmContext)
		return nil;
	
	CGContextSetShouldAntialias(bmContext, true);
	CGContextSetAllowsAntialiasing(bmContext, true);
	CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    
	/// Rotation happen here (around the center)
	CGContextTranslateCTM(bmContext, +(rotatedRect.size.width * 0.5f), +(rotatedRect.size.height * 0.5f));
	CGContextRotateCTM(bmContext, radians);
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = -(width * 0.5f), .origin.y = -(height * 0.5f), .size.width = width, .size.height = height}, self.CGImage);
    
	/// Create an image object from the context
	CGImageRef rotatedImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* rotated = [UIImage imageWithCGImage:rotatedImageRef scale:self.scale orientation:self.imageOrientation];
    
	/// Cleanup
	CGImageRelease(rotatedImageRef);
	CGContextRelease(bmContext);
    
	return rotated;
}

- (UIImage*)rotateInDegrees:(float)degrees {
	return [self rotateInRadians:(float)NYX_DEGREES_TO_RADIANS(degrees)];
}

- (UIImage*)rotateImagePixelsInRadians:(float)radians {
	/// Create an ARGB bitmap context
	const size_t width = (size_t)(self.size.width * self.scale);
	const size_t height = (size_t)(self.size.height * self.scale);
	const size_t bytesPerRow = width * kNyxNumberOfComponentsPerARBGPixel;
	CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, bytesPerRow);
	if (!bmContext)
		return nil;
	
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
	
	/// Grab the image raw data
	UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
	if (!data)
	{
		CGContextRelease(bmContext);
		return nil;
	}
	
	vImage_Buffer src = {data, height, width, bytesPerRow};
	vImage_Buffer dest = {data, height, width, bytesPerRow};
	Pixel_8888 bgColor = {0, 0, 0, 0};
	vImageRotate_ARGB8888(&src, &dest, NULL, radians, bgColor, kvImageBackgroundColorFill);
	
	CGImageRef rotatedImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* rotated = [UIImage imageWithCGImage:rotatedImageRef scale:self.scale orientation:self.imageOrientation];
	
	/// Cleanup
	CGImageRelease(rotatedImageRef);
	CGContextRelease(bmContext);
	
	return rotated;
}

- (UIImage*)rotateImagePixelsInDegrees:(float)degrees {
	return [self rotateImagePixelsInRadians:(float)NYX_DEGREES_TO_RADIANS(degrees)];
}

- (UIImage*)verticalFlip {
	/// Create an ARGB bitmap context
	const size_t originalWidth = (size_t)(self.size.width * self.scale);
	const size_t originalHeight = (size_t)(self.size.height * self.scale);
	CGContextRef bmContext = NYXCreateARGBBitmapContext(originalWidth, originalHeight, originalWidth * kNyxNumberOfComponentsPerARBGPixel);
	if (!bmContext)
		return nil;
    
	/// Image quality
	CGContextSetShouldAntialias(bmContext, true);
	CGContextSetAllowsAntialiasing(bmContext, true);
	CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    
	CGContextTranslateCTM(bmContext, 0.0f, originalHeight);
	CGContextScaleCTM(bmContext, 1.0f, -1.0f);
	
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0, .size.width = originalWidth, .size.height = originalHeight}, self.CGImage);
	
	/// Create an image object from the context
	CGImageRef flippedImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* flipped = [UIImage imageWithCGImage:flippedImageRef scale:self.scale orientation:self.imageOrientation];
	
	/// Cleanup
	CGImageRelease(flippedImageRef);
	CGContextRelease(bmContext);
	
	return flipped;
}

- (UIImage*)horizontalFlip {
	/// Create an ARGB bitmap context
	const size_t originalWidth = (size_t)(self.size.width * self.scale);
	const size_t originalHeight = (size_t)(self.size.height * self.scale);
	CGContextRef bmContext = NYXCreateARGBBitmapContext(originalWidth, originalHeight, originalWidth * kNyxNumberOfComponentsPerARBGPixel);
	if (!bmContext)
		return nil;
	
	/// Image quality
	CGContextSetShouldAntialias(bmContext, true);
	CGContextSetAllowsAntialiasing(bmContext, true);
	CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    
	CGContextTranslateCTM(bmContext, originalWidth, 0.0f);
	CGContextScaleCTM(bmContext, -1.0f, 1.0f);
	
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = originalWidth, .size.height = originalHeight}, self.CGImage);
	
	/// Create an image object from the context
	CGImageRef flippedImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* flipped = [UIImage imageWithCGImage:flippedImageRef scale:self.scale orientation:self.imageOrientation];
	
	/// Cleanup
	CGImageRelease(flippedImageRef);
	CGContextRelease(bmContext);
	
	return flipped;
}


//Blurring
static int16_t __s_gaussianblur_kernel_5x5[25] = {
	1, 4, 6, 4, 1,
	4, 16, 24, 16, 4,
	6, 24, 36, 24, 6,
	4, 16, 24, 16, 4,
	1, 4, 6, 4, 1
};

- (UIImage*)gaussianBlurWithBias:(NSInteger)bias
{
	/// Create an ARGB bitmap context
	const size_t width = (size_t)self.size.width;
	const size_t height = (size_t)self.size.height;
	const size_t bytesPerRow = width * kNyxNumberOfComponentsPerARBGPixel;
	CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, bytesPerRow);
	if (!bmContext)
		return nil;
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
	/// Grab the image raw data
	UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
	if (!data)
	{
		CGContextRelease(bmContext);
		return nil;
	}
    
	const size_t n = sizeof(UInt8) * width * height * 4;
	void* outt = malloc(n);
	vImage_Buffer src = {data, height, width, bytesPerRow};
	vImage_Buffer dest = {outt, height, width, bytesPerRow};
	vImageConvolveWithBias_ARGB8888(&src, &dest, NULL, 0, 0, __s_gaussianblur_kernel_5x5, 5, 5, 256/*divisor*/, bias, NULL, kvImageCopyInPlace);
	memcpy(data, outt, n);
	free(outt);
    
	CGImageRef blurredImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* blurred = [UIImage imageWithCGImage:blurredImageRef];
    
	/// Cleanup
	CGImageRelease(blurredImageRef);
	CGContextRelease(bmContext);
    
	return blurred;
}

- (UIImage*)autoEnhance {
	/// No Core Image, return original image
	if (![CIImage class])
		return self;
    
	CIImage* ciImage = [[CIImage alloc] initWithCGImage:self.CGImage];
    
	NSArray* adjustments = [ciImage autoAdjustmentFiltersWithOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:kCIImageAutoAdjustRedEye]];
    
	for (CIFilter* filter in adjustments)
	{
		[filter setValue:ciImage forKey:kCIInputImageKey];
		ciImage = filter.outputImage;
	}
    
	CIContext* ctx = [CIContext contextWithOptions:nil];
	CGImageRef cgImage = [ctx createCGImage:ciImage fromRect:[ciImage extent]];
	UIImage* final = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	return final;
}

- (UIImage*)redEyeCorrection {
	/// No Core Image, return original image
	if (![CIImage class])
		return self;
    
	CIImage* ciImage = [[CIImage alloc] initWithCGImage:self.CGImage];
    
	/// Get the filters and apply them to the image
	NSArray* filters = [ciImage autoAdjustmentFiltersWithOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:kCIImageAutoAdjustEnhance]];
	for (CIFilter* filter in filters)
	{
		[filter setValue:ciImage forKey:kCIInputImageKey];
		ciImage = filter.outputImage;
	}
	/// Create the corrected image
	CIContext* ctx = [CIContext contextWithOptions:nil];
	CGImageRef cgImage = [ctx createCGImage:ciImage fromRect:[ciImage extent]];
	UIImage* final = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	return final;
}

//Filtering
/* Sepia values for manual filtering (< iOS 5) */
static float const __sepiaFactorRedRed = 0.393f;
static float const __sepiaFactorRedGreen = 0.349f;
static float const __sepiaFactorRedBlue = 0.272f;
static float const __sepiaFactorGreenRed = 0.769f;
static float const __sepiaFactorGreenGreen = 0.686f;
static float const __sepiaFactorGreenBlue = 0.534f;
static float const __sepiaFactorBlueRed = 0.189f;
static float const __sepiaFactorBlueGreen = 0.168f;
static float const __sepiaFactorBlueBlue = 0.131f;

/* Negative multiplier to invert a number */
static float __negativeMultiplier = -1.0f;

#pragma mark - Edge detection kernels
/* vImage kernel */
/*static int16_t __s_edgedetect_kernel_3x3[9] = {
 -1, -1, -1,
 -1, 8, -1,
 -1, -1, -1
 };*/
/* vDSP kernel */
static float __f_edgedetect_kernel_3x3[9] = {
	-1.0f, -1.0f, -1.0f,
	-1.0f, 8.0f, -1.0f,
	-1.0f, -1.0f, -1.0f
};

#pragma mark - Emboss kernels
/* vImage kernel */
static int16_t __s_emboss_kernel_3x3[9] = {
	-2, 0, 0,
	0, 1, 0,
	0, 0, 2
};

#pragma mark - Sharpen kernels
/* vImage kernel */
static int16_t __s_sharpen_kernel_3x3[9] = {
	-1, -1, -1,
	-1, 9, -1,
	-1, -1, -1
};

#pragma mark - Unsharpen kernels
/* vImage kernel */
static int16_t __s_unsharpen_kernel_3x3[9] = {
	-1, -1, -1,
	-1, 17, -1,
	-1, -1, -1
};

// Value should be in the range (-255, 255)
- (UIImage*)brightenWithValue:(float)value {
	/// Create an ARGB bitmap context
	const size_t width = (size_t)self.size.width;
	const size_t height = (size_t)self.size.height;
	CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, width * kNyxNumberOfComponentsPerARBGPixel);
	if (!bmContext)
		return nil;
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
	/// Grab the image raw data
	UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
	if (!data)
	{
		CGContextRelease(bmContext);
		return nil;
	}
    
	const size_t pixelsCount = width * height;
	float* dataAsFloat = (float*)malloc(sizeof(float) * pixelsCount);
	float min = (float)kNyxMinPixelComponentValue, max = (float)kNyxMaxPixelComponentValue;
    
	/// Calculate red components
	vDSP_vfltu8(data + 1, 4, dataAsFloat, 1, pixelsCount);
	vDSP_vsadd(dataAsFloat, 1, &value, dataAsFloat, 1, pixelsCount);
	vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vfixu8(dataAsFloat, 1, data + 1, 4, pixelsCount);
    
	/// Calculate green components
	vDSP_vfltu8(data + 2, 4, dataAsFloat, 1, pixelsCount);
	vDSP_vsadd(dataAsFloat, 1, &value, dataAsFloat, 1, pixelsCount);
	vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vfixu8(dataAsFloat, 1, data + 2, 4, pixelsCount);
    
	/// Calculate blue components
	vDSP_vfltu8(data + 3, 4, dataAsFloat, 1, pixelsCount);
	vDSP_vsadd(dataAsFloat, 1, &value, dataAsFloat, 1, pixelsCount);
	vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vfixu8(dataAsFloat, 1, data + 3, 4, pixelsCount);
    
	CGImageRef brightenedImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* brightened = [UIImage imageWithCGImage:brightenedImageRef scale:self.scale orientation:self.imageOrientation];
    
	/// Cleanup
	CGImageRelease(brightenedImageRef);
	free(dataAsFloat);
	CGContextRelease(bmContext);
    
	return brightened;
}

/// (-255, 255)
- (UIImage*)contrastAdjustmentWithValue:(float)value {
	/// Create an ARGB bitmap context
	const size_t width = (size_t)self.size.width;
	const size_t height = (size_t)self.size.height;
	CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, width * kNyxNumberOfComponentsPerARBGPixel);
	if (!bmContext)
		return nil;
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
	/// Grab the image raw data
	UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
	if (!data)
	{
		CGContextRelease(bmContext);
		return nil;
	}
    
	const size_t pixelsCount = width * height;
	float* dataAsFloat = (float*)malloc(sizeof(float) * pixelsCount);
	float min = (float)kNyxMinPixelComponentValue, max = (float)kNyxMaxPixelComponentValue;
    
	/// Contrast correction factor
	const float factor = (259.0f * (value + 255.0f)) / (255.0f * (259.0f - value));
    
	float v1 = -128.0f, v2 = 128.0f;
    
	/// Calculate red components
	vDSP_vfltu8(data + 1, 4, dataAsFloat, 1, pixelsCount);
	vDSP_vsadd(dataAsFloat, 1, &v1, dataAsFloat, 1, pixelsCount);
	vDSP_vsmul(dataAsFloat, 1, &factor, dataAsFloat, 1, pixelsCount);
	vDSP_vsadd(dataAsFloat, 1, &v2, dataAsFloat, 1, pixelsCount);
	vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vfixu8(dataAsFloat, 1, data + 1, 4, pixelsCount);
    
	/// Calculate green components
	vDSP_vfltu8(data + 2, 4, dataAsFloat, 1, pixelsCount);
	vDSP_vsadd(dataAsFloat, 1, &v1, dataAsFloat, 1, pixelsCount);
	vDSP_vsmul(dataAsFloat, 1, &factor, dataAsFloat, 1, pixelsCount);
	vDSP_vsadd(dataAsFloat, 1, &v2, dataAsFloat, 1, pixelsCount);
	vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vfixu8(dataAsFloat, 1, data + 2, 4, pixelsCount);
    
	/// Calculate blue components
	vDSP_vfltu8(data + 3, 4, dataAsFloat, 1, pixelsCount);
	vDSP_vsadd(dataAsFloat, 1, &v1, dataAsFloat, 1, pixelsCount);
	vDSP_vsmul(dataAsFloat, 1, &factor, dataAsFloat, 1, pixelsCount);
	vDSP_vsadd(dataAsFloat, 1, &v2, dataAsFloat, 1, pixelsCount);
	vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vfixu8(dataAsFloat, 1, data + 3, 4, pixelsCount);
    
	/// Create an image object from the context
	CGImageRef contrastedImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* contrasted = [UIImage imageWithCGImage:contrastedImageRef scale:self.scale orientation:self.imageOrientation];
    
	/// Cleanup
	CGImageRelease(contrastedImageRef);
	free(dataAsFloat);
	CGContextRelease(bmContext);
    
	return contrasted;
}

- (UIImage*)edgeDetectionWithBias:(NSInteger)bias {
#pragma unused(bias)
	/// Create an ARGB bitmap context
	const size_t width = (size_t)self.size.width;
	const size_t height = (size_t)self.size.height;
	const size_t bytesPerRow = width * kNyxNumberOfComponentsPerARBGPixel;
	CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, bytesPerRow);
	if (!bmContext)
		return nil;
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
	/// Grab the image raw data
	UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
	if (!data)
	{
		CGContextRelease(bmContext);
		return nil;
	}
    
	/// vImage (iOS 5) works on simulator but not on device
	/*if ((&vImageConvolveWithBias_ARGB8888))
     {
     const size_t n = sizeof(UInt8) * width * height * 4;
     void* outt = malloc(n);
     vImage_Buffer src = {data, height, width, bytesPerRow};
     vImage_Buffer dest = {outt, height, width, bytesPerRow};
     
     vImageConvolveWithBias_ARGB8888(&src, &dest, NULL, 0, 0, __s_edgedetect_kernel_3x3, 3, 3, 1, bias, NULL, kvImageCopyInPlace);
     
     CGDataProviderRef dp = CGDataProviderCreateWithData(NULL, data, n, NULL);
     
     CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
     CGImageRef edgedImageRef = CGImageCreate(width, height, 8, 32, bytesPerRow, cs, kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipFirst, dp, NULL, true, kCGRenderingIntentDefault);
     CGColorSpaceRelease(cs);
     
     //memcpy(data, outt, n);
     //CGImageRef edgedImageRef = CGBitmapContextCreateImage(bmContext);
     UIImage* edged = [UIImage imageWithCGImage:edgedImageRef];
     
     /// Cleanup
     CGImageRelease(edgedImageRef);
     CGDataProviderRelease(dp);
     free(outt);
     CGContextRelease(bmContext);
     
     return edged;
     }
     else
     {*/
    const size_t pixelsCount = width * height;
    const size_t n = sizeof(float) * pixelsCount;
    float* dataAsFloat = malloc(n);
    float* resultAsFloat = malloc(n);
    float min = (float)kNyxMinPixelComponentValue, max = (float)kNyxMaxPixelComponentValue;
    
    /// Red components
    vDSP_vfltu8(data + 1, 4, dataAsFloat, 1, pixelsCount);
    vDSP_f3x3(dataAsFloat, height, width, __f_edgedetect_kernel_3x3, resultAsFloat);
    vDSP_vclip(resultAsFloat, 1, &min, &max, resultAsFloat, 1, pixelsCount);
    vDSP_vfixu8(resultAsFloat, 1, data + 1, 4, pixelsCount);
    
    /// Green components
    vDSP_vfltu8(data + 2, 4, dataAsFloat, 1, pixelsCount);
    vDSP_f3x3(dataAsFloat, height, width, __f_edgedetect_kernel_3x3, resultAsFloat);
    vDSP_vclip(resultAsFloat, 1, &min, &max, resultAsFloat, 1, pixelsCount);
    vDSP_vfixu8(resultAsFloat, 1, data + 2, 4, pixelsCount);
    
    /// Blue components
    vDSP_vfltu8(data + 3, 4, dataAsFloat, 1, pixelsCount);
    vDSP_f3x3(dataAsFloat, height, width, __f_edgedetect_kernel_3x3, resultAsFloat);
    vDSP_vclip(resultAsFloat, 1, &min, &max, resultAsFloat, 1, pixelsCount);
    vDSP_vfixu8(resultAsFloat, 1, data + 3, 4, pixelsCount);
    
    CGImageRef edgedImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* edged = [UIImage imageWithCGImage:edgedImageRef];
    
    /// Cleanup
    CGImageRelease(edgedImageRef);
    free(resultAsFloat);
    free(dataAsFloat);
    CGContextRelease(bmContext);
    
    return edged;
	//}
}

- (UIImage*)embossWithBias:(NSInteger)bias {
	/// Create an ARGB bitmap context
	const size_t width = (size_t)self.size.width;
	const size_t height = (size_t)self.size.height;
	const size_t bytesPerRow = width * kNyxNumberOfComponentsPerARBGPixel;
	CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, bytesPerRow);
	if (!bmContext)
		return nil;
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
	/// Grab the image raw data
	UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
	if (!data)
	{
		CGContextRelease(bmContext);
		return nil;
	}
    
	const size_t n = sizeof(UInt8) * width * height * 4;
	void* outt = malloc(n);
	vImage_Buffer src = {data, height, width, bytesPerRow};
	vImage_Buffer dest = {outt, height, width, bytesPerRow};
	vImageConvolveWithBias_ARGB8888(&src, &dest, NULL, 0, 0, __s_emboss_kernel_3x3, 3, 3, 1/*divisor*/, bias, NULL, kvImageCopyInPlace);
	
	memcpy(data, outt, n);
	
	free(outt);
    
	CGImageRef embossImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* emboss = [UIImage imageWithCGImage:embossImageRef];
    
	/// Cleanup
	CGImageRelease(embossImageRef);
	CGContextRelease(bmContext);
    
	return emboss;
}

/// (0.01, 8)
- (UIImage*)gammaCorrectionWithValue:(float)value {
	const size_t width = (size_t)self.size.width;
	const size_t height = (size_t)self.size.height;
	/// Number of bytes per row, each pixel in the bitmap will be represented by 4 bytes (ARGB), 8 bits of alpha/red/green/blue
	const size_t bytesPerRow = width * kNyxNumberOfComponentsPerARBGPixel;
    
	/// Create an ARGB bitmap context
	CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, bytesPerRow);
	if (!bmContext)
		return nil;
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
	/// Grab the image raw data
	UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
	if (!data)
	{
		CGContextRelease(bmContext);
		return nil;
	}
    
	const size_t pixelsCount = width * height;
	const size_t n = sizeof(float) * pixelsCount;
	float* dataAsFloat = (float*)malloc(n);
	float* temp = (float*)malloc(n);
	float min = (float)kNyxMinPixelComponentValue, max = (float)kNyxMaxPixelComponentValue;
	const int iPixels = (int)pixelsCount;
	
	/// Need a vector with same size :(
	vDSP_vfill(&value, temp, 1, pixelsCount);
	
	/// Calculate red components
	vDSP_vfltu8(data + 1, 4, dataAsFloat, 1, pixelsCount);
	vDSP_vsdiv(dataAsFloat, 1, &max, dataAsFloat, 1, pixelsCount);
	vvpowf(dataAsFloat, temp, dataAsFloat, &iPixels);
	vDSP_vsmul(dataAsFloat, 1, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vfixu8(dataAsFloat, 1, data + 1, 4, pixelsCount);
	
	/// Calculate green components
	vDSP_vfltu8(data + 2, 4, dataAsFloat, 1, pixelsCount);
	vDSP_vsdiv(dataAsFloat, 1, &max, dataAsFloat, 1, pixelsCount);
	vvpowf(dataAsFloat, temp, dataAsFloat, &iPixels);
	vDSP_vsmul(dataAsFloat, 1, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vfixu8(dataAsFloat, 1, data + 2, 4, pixelsCount);
	
	/// Calculate blue components
	vDSP_vfltu8(data + 3, 4, dataAsFloat, 1, pixelsCount);
	vDSP_vsdiv(dataAsFloat, 1, &max, dataAsFloat, 1, pixelsCount);
	vvpowf(dataAsFloat, temp, dataAsFloat, &iPixels);
	vDSP_vsmul(dataAsFloat, 1, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vfixu8(dataAsFloat, 1, data + 3, 4, pixelsCount);
	
	/// Cleanup
	free(temp);
	free(dataAsFloat);
    
	/// Create an image object from the context
	CGImageRef gammaImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* gamma = [UIImage imageWithCGImage:gammaImageRef];
    
	/// Cleanup
	CGImageRelease(gammaImageRef);
	CGContextRelease(bmContext);
    
	return gamma;
}

- (UIImage*)grayscale {
	/* const UInt8 luminance = (red * 0.2126) + (green * 0.7152) + (blue * 0.0722); // Good luminance value */
	/// Create a gray bitmap context
	const size_t width = (size_t)self.size.width;
	const size_t height = (size_t)self.size.height;
    
    CGRect imageRect = CGRectMake(0, 0, self.size.width, self.size.height);
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8/*Bits per component*/, width * kNyxNumberOfComponentsPerGreyPixel, colorSpace, kCGImageAlphaNone);
	CGColorSpaceRelease(colorSpace);
	if (!bmContext)
		return nil;
    
	/// Image quality
	CGContextSetShouldAntialias(bmContext, false);
	CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, imageRect, self.CGImage);
    
	/// Create an image object from the context
	CGImageRef grayscaledImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage *grayscaled = [UIImage imageWithCGImage:grayscaledImageRef scale:self.scale orientation:self.imageOrientation];
    
	/// Cleanup
	CGImageRelease(grayscaledImageRef);
	CGContextRelease(bmContext);
    
	return grayscaled;
}

- (UIImage*)invert {
	/// Create an ARGB bitmap context
	const size_t width = (size_t)self.size.width;
	const size_t height = (size_t)self.size.height;
	CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, width * kNyxNumberOfComponentsPerARBGPixel);
	if (!bmContext)
		return nil;
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
	/// Grab the image raw data
	UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
	if (!data)
	{
		CGContextRelease(bmContext);
		return nil;
	}
    
	const size_t pixelsCount = width * height;
	float* dataAsFloat = (float*)malloc(sizeof(float) * pixelsCount);
	float min = (float)kNyxMinPixelComponentValue, max = (float)kNyxMaxPixelComponentValue;
	UInt8* dataRed = data + 1;
	UInt8* dataGreen = data + 2;
	UInt8* dataBlue = data + 3;
    
	/// vDSP_vsmsa() = multiply then add
	/// slightly faster than the couple vDSP_vneg() & vDSP_vsadd()
	/// Probably because there are 3 function calls less
    
	/// Calculate red components
	vDSP_vfltu8(dataRed, 4, dataAsFloat, 1, pixelsCount);
	vDSP_vsmsa(dataAsFloat, 1, &__negativeMultiplier, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vfixu8(dataAsFloat, 1, dataRed, 4, pixelsCount);
    
	/// Calculate green components
	vDSP_vfltu8(dataGreen, 4, dataAsFloat, 1, pixelsCount);
	vDSP_vsmsa(dataAsFloat, 1, &__negativeMultiplier, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vfixu8(dataAsFloat, 1, dataGreen, 4, pixelsCount);
    
	/// Calculate blue components
	vDSP_vfltu8(dataBlue, 4, dataAsFloat, 1, pixelsCount);
	vDSP_vsmsa(dataAsFloat, 1, &__negativeMultiplier, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vclip(dataAsFloat, 1, &min, &max, dataAsFloat, 1, pixelsCount);
	vDSP_vfixu8(dataAsFloat, 1, dataBlue, 4, pixelsCount);
    
	CGImageRef invertedImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* inverted = [UIImage imageWithCGImage:invertedImageRef];
    
	/// Cleanup
	CGImageRelease(invertedImageRef);
	free(dataAsFloat);
	CGContextRelease(bmContext);
    
	return inverted;
}

- (UIImage*)opacity:(float)value {
	/// Create an ARGB bitmap context
	const size_t width = (size_t)self.size.width;
	const size_t height = (size_t)self.size.height;
	CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, width * kNyxNumberOfComponentsPerARBGPixel);
	if (!bmContext)
		return nil;
    
	/// Set the alpha value and draw the image in the bitmap context
	CGContextSetAlpha(bmContext, value);
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
	/// Create an image object from the context
	CGImageRef transparentImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* transparent = [UIImage imageWithCGImage:transparentImageRef];
    
	/// Cleanup
	CGImageRelease(transparentImageRef);
	CGContextRelease(bmContext);
    
	return transparent;
}

- (UIImage*)sepia {
	if ([CIImage class])
	{
		/// The sepia output from Core Image is nicer than manual method and 1.6x faster than vDSP
		CIImage* ciImage = [[CIImage alloc] initWithCGImage:self.CGImage];
		CIImage* output = [CIFilter filterWithName:@"CISepiaTone" keysAndValues:kCIInputImageKey, ciImage, @"inputIntensity", [NSNumber numberWithFloat:1.0f], nil].outputImage;
		CGImageRef cgImage = [NYXGetCIContext() createCGImage:output fromRect:[output extent]];
		UIImage* sepia = [UIImage imageWithCGImage:cgImage];
		CGImageRelease(cgImage);
		return sepia;
	}
	else
	{
		/* 1.6x faster than before */
		/// Create an ARGB bitmap context
		const size_t width = (size_t)self.size.width;
		const size_t height = (size_t)self.size.height;
		CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, width * kNyxNumberOfComponentsPerARBGPixel);
		if (!bmContext)
			return nil;
        
		/// Draw the image in the bitmap context
		CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
        
		/// Grab the image raw data
		UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
		if (!data)
		{
			CGContextRelease(bmContext);
			return nil;
		}
        
		const size_t pixelsCount = width * height;
		const size_t n = sizeof(float) * pixelsCount;
		float* reds = (float*)malloc(n);
		float* greens = (float*)malloc(n);
		float* blues = (float*)malloc(n);
		float* tmpRed = (float*)malloc(n);
		float* tmpGreen = (float*)malloc(n);
		float* tmpBlue = (float*)malloc(n);
		float* finalRed = (float*)malloc(n);
		float* finalGreen = (float*)malloc(n);
		float* finalBlue = (float*)malloc(n);
		float min = (float)kNyxMinPixelComponentValue, max = (float)kNyxMaxPixelComponentValue;
        
		/// Convert byte components to float
		vDSP_vfltu8(data + 1, 4, reds, 1, pixelsCount);
		vDSP_vfltu8(data + 2, 4, greens, 1, pixelsCount);
		vDSP_vfltu8(data + 3, 4, blues, 1, pixelsCount);
        
		/// Calculate red components
		vDSP_vsmul(reds, 1, &__sepiaFactorRedRed, tmpRed, 1, pixelsCount);
		vDSP_vsmul(greens, 1, &__sepiaFactorGreenRed, tmpGreen, 1, pixelsCount);
		vDSP_vsmul(blues, 1, &__sepiaFactorBlueRed, tmpBlue, 1, pixelsCount);
		vDSP_vadd(tmpRed, 1, tmpGreen, 1, finalRed, 1, pixelsCount);
		vDSP_vadd(finalRed, 1, tmpBlue, 1, finalRed, 1, pixelsCount);
		vDSP_vclip(finalRed, 1, &min, &max, finalRed, 1, pixelsCount);
		vDSP_vfixu8(finalRed, 1, data + 1, 4, pixelsCount);
        
		/// Calculate green components
		vDSP_vsmul(reds, 1, &__sepiaFactorRedGreen, tmpRed, 1, pixelsCount);
		vDSP_vsmul(greens, 1, &__sepiaFactorGreenGreen, tmpGreen, 1, pixelsCount);
		vDSP_vsmul(blues, 1, &__sepiaFactorBlueGreen, tmpBlue, 1, pixelsCount);
		vDSP_vadd(tmpRed, 1, tmpGreen, 1, finalGreen, 1, pixelsCount);
		vDSP_vadd(finalGreen, 1, tmpBlue, 1, finalGreen, 1, pixelsCount);
		vDSP_vclip(finalGreen, 1, &min, &max, finalGreen, 1, pixelsCount);
		vDSP_vfixu8(finalGreen, 1, data + 2, 4, pixelsCount);
        
		/// Calculate blue components
		vDSP_vsmul(reds, 1, &__sepiaFactorRedBlue, tmpRed, 1, pixelsCount);
		vDSP_vsmul(greens, 1, &__sepiaFactorGreenBlue, tmpGreen, 1, pixelsCount);
		vDSP_vsmul(blues, 1, &__sepiaFactorBlueBlue, tmpBlue, 1, pixelsCount);
		vDSP_vadd(tmpRed, 1, tmpGreen, 1, finalBlue, 1, pixelsCount);
		vDSP_vadd(finalBlue, 1, tmpBlue, 1, finalBlue, 1, pixelsCount);
		vDSP_vclip(finalBlue, 1, &min, &max, finalBlue, 1, pixelsCount);
		vDSP_vfixu8(finalBlue, 1, data + 3, 4, pixelsCount);
        
		/// Create an image object from the context
		CGImageRef sepiaImageRef = CGBitmapContextCreateImage(bmContext);
		UIImage* sepia = [UIImage imageWithCGImage:sepiaImageRef];
        
		/// Cleanup
		CGImageRelease(sepiaImageRef);
		free(reds), free(greens), free(blues), free(tmpRed), free(tmpGreen), free(tmpBlue), free(finalRed), free(finalGreen), free(finalBlue);
		CGContextRelease(bmContext);
        
		return sepia;
	}
}

- (UIImage*)sharpenWithBias:(NSInteger)bias {
	/// Create an ARGB bitmap context
	const size_t width = (size_t)self.size.width;
	const size_t height = (size_t)self.size.height;
	const size_t bytesPerRow = width * kNyxNumberOfComponentsPerARBGPixel;
	CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, bytesPerRow);
	if (!bmContext)
		return nil;
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
	/// Grab the image raw data
	UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
	if (!data)
	{
		CGContextRelease(bmContext);
		return nil;
	}
    
	const size_t n = sizeof(UInt8) * width * height * 4;
	void* outt = malloc(n);
	vImage_Buffer src = {data, height, width, bytesPerRow};
	vImage_Buffer dest = {outt, height, width, bytesPerRow};
	vImageConvolveWithBias_ARGB8888(&src, &dest, NULL, 0, 0, __s_sharpen_kernel_3x3, 3, 3, 1/*divisor*/, bias, NULL, kvImageCopyInPlace);
	
	memcpy(data, outt, n);
	
	free(outt);
    
	CGImageRef sharpenedImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* sharpened = [UIImage imageWithCGImage:sharpenedImageRef];
    
	/// Cleanup
	CGImageRelease(sharpenedImageRef);
	CGContextRelease(bmContext);
    
	return sharpened;
}

- (UIImage*)unsharpenWithBias:(NSInteger)bias {
	/// Create an ARGB bitmap context
	const size_t width = (size_t)self.size.width;
	const size_t height = (size_t)self.size.height;
	const size_t bytesPerRow = width * kNyxNumberOfComponentsPerARBGPixel;
	CGContextRef bmContext = NYXCreateARGBBitmapContext(width, height, bytesPerRow);
	if (!bmContext)
		return nil;
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    
	/// Grab the image raw data
	UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
	if (!data)
	{
		CGContextRelease(bmContext);
		return nil;
	}
    
	const size_t n = sizeof(UInt8) * width * height * 4;
	void* outt = malloc(n);
	vImage_Buffer src = {data, height, width, bytesPerRow};
	vImage_Buffer dest = {outt, height, width, bytesPerRow};
	vImageConvolveWithBias_ARGB8888(&src, &dest, NULL, 0, 0, __s_unsharpen_kernel_3x3, 3, 3, 9/*divisor*/, bias, NULL, kvImageCopyInPlace);
	
	memcpy(data, outt, n);
	
	free(outt);
    
	CGImageRef unsharpenedImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* unsharpened = [UIImage imageWithCGImage:unsharpenedImageRef];
    
	/// Cleanup
	CGImageRelease(unsharpenedImageRef);
	CGContextRelease(bmContext);
	return unsharpened;
}

//Masking
- (UIImage*)maskWithImage:(UIImage*)maskImage {
	/// Create a bitmap context with valid alpha
	const size_t originalWidth = (size_t)self.size.width;
	const size_t originalHeight = (size_t)self.size.height;
	CGContextRef bmContext = NYXCreateARGBBitmapContext(originalWidth, originalHeight, 0);
	if (!bmContext)
		return nil;
    
	/// Image quality
	CGContextSetShouldAntialias(bmContext, true);
	CGContextSetAllowsAntialiasing(bmContext, true);
	CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    
	/// Image mask
	CGImageRef cgMaskImage = maskImage.CGImage;
	CGImageRef mask = CGImageMaskCreate((size_t)maskImage.size.width, (size_t)maskImage.size.height, CGImageGetBitsPerComponent(cgMaskImage), CGImageGetBitsPerPixel(cgMaskImage), CGImageGetBytesPerRow(cgMaskImage), CGImageGetDataProvider(cgMaskImage), NULL, false);
    
	/// Draw the original image in the bitmap context
	const CGRect r = (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = originalWidth, .size.height = originalHeight};
	CGContextClipToMask(bmContext, r, cgMaskImage);
	CGContextDrawImage(bmContext, r, self.CGImage);
    
	/// Get the CGImage object
	CGImageRef imageRefWithAlpha = CGBitmapContextCreateImage(bmContext);
	/// Apply the mask
	CGImageRef maskedImageRef = CGImageCreateWithMask(imageRefWithAlpha, mask);
    
	UIImage* result = [UIImage imageWithCGImage:maskedImageRef];
    
	/// Cleanup
	CGImageRelease(maskedImageRef);
	CGImageRelease(imageRefWithAlpha);
	CGContextRelease(bmContext);
	CGImageRelease(mask);
    
    return result;
}

//Reflection
- (UIImage*)reflectedImageWithHeight:(NSUInteger)height fromAlpha:(float)fromAlpha toAlpha:(float)toAlpha {
    if (!height)
		return nil;
    
	// create a bitmap graphics context the size of the image
	UIGraphicsBeginImageContextWithOptions((CGSize){.width = self.size.width, .height = height}, NO, 0.0f);
    CGContextRef mainViewContentContext = UIGraphicsGetCurrentContext();
    
	// create a 2 bit CGImage containing a gradient that will be used for masking the
	// main view content to create the 'fade' of the reflection. The CGImageCreateWithMask
	// function will stretch the bitmap image as required, so we can create a 1 pixel wide gradient
	CGImageRef gradientMaskImage = NYXCreateGradientImage(1, height, fromAlpha, toAlpha);
    
	// create an image by masking the bitmap of the mainView content with the gradient view
	// then release the  pre-masked content bitmap and the gradient bitmap
	CGContextClipToMask(mainViewContentContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = self.size.width, .size.height = height}, gradientMaskImage);
	CGImageRelease(gradientMaskImage);
    
	// draw the image into the bitmap context
	CGContextDrawImage(mainViewContentContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size = self.size}, self.CGImage);
    
	// convert the finished reflection image to a UIImage
	UIImage* theImage = UIGraphicsGetImageFromCurrentImageContext();
    
	UIGraphicsEndImageContext();
    
	return theImage;
}

//Resizing
- (UIImage*)cropToSize:(CGSize)newSize usingMode:(NYXCropMode)cropMode {
	const CGSize size = self.size;
	CGFloat x, y;
	switch (cropMode)
	{
		case NYXCropModeTopLeft:
			x = y = 0.0f;
			break;
		case NYXCropModeTopCenter:
			x = (size.width - newSize.width) * 0.5f;
			y = 0.0f;
			break;
		case NYXCropModeTopRight:
			x = size.width - newSize.width;
			y = 0.0f;
			break;
		case NYXCropModeBottomLeft:
			x = 0.0f;
			y = size.height - newSize.height;
			break;
		case NYXCropModeBottomCenter:
			x = newSize.width * 0.5f;
			y = size.height - newSize.height;
			break;
		case NYXCropModeBottomRight:
			x = size.width - newSize.width;
			y = size.height - newSize.height;
			break;
		case NYXCropModeLeftCenter:
			x = 0.0f;
			y = (size.height - newSize.height) * 0.5f;
			break;
		case NYXCropModeRightCenter:
			x = size.width - newSize.width;
			y = (size.height - newSize.height) * 0.5f;
			break;
		case NYXCropModeCenter:
			x = (size.width - newSize.width) * 0.5f;
			y = (size.height - newSize.height) * 0.5f;
			break;
		default: // Default to top left
			x = y = 0.0f;
			break;
	}
    
    CGRect cropRect = CGRectMake(x * self.scale, y * self.scale, newSize.width * self.scale, newSize.height * self.scale);
    
	/// Create the cropped image
	CGImageRef croppedImageRef = CGImageCreateWithImageInRect(self.CGImage, cropRect);
	UIImage* cropped = [UIImage imageWithCGImage:croppedImageRef scale:self.scale orientation:self.imageOrientation];
    
	/// Cleanup
	CGImageRelease(croppedImageRef);
    
	return cropped;
}

/* Convenience method to crop the image from the top left corner */
- (UIImage*)cropToSize:(CGSize)newSize {
	return [self cropToSize:newSize usingMode:NYXCropModeTopLeft];
}

- (UIImage*)scaleByFactor:(float)scaleFactor {
	const size_t originalWidth = (size_t)(self.size.width * self.scale * scaleFactor);
	const size_t originalHeight = (size_t)(self.size.height * self.scale * scaleFactor);
	/// Number of bytes per row, each pixel in the bitmap will be represented by 4 bytes (ARGB), 8 bits of alpha/red/green/blue
	const size_t bytesPerRow = originalWidth * kNyxNumberOfComponentsPerARBGPixel;
    
	/// Create an ARGB bitmap context
	CGContextRef bmContext = NYXCreateARGBBitmapContext(originalWidth, originalHeight, bytesPerRow);
	if (!bmContext)
		return nil;
	
	/// Handle orientation
	if (UIImageOrientationLeft == self.imageOrientation)
	{
		CGContextRotateCTM(bmContext, (CGFloat)M_PI_2);
		CGContextTranslateCTM(bmContext, 0, -originalHeight);
	}
	else if (UIImageOrientationRight == self.imageOrientation)
	{
		CGContextRotateCTM(bmContext, (CGFloat)-M_PI_2);
		CGContextTranslateCTM(bmContext, -originalWidth, 0);
	}
	else if (UIImageOrientationDown == self.imageOrientation)
	{
		CGContextTranslateCTM(bmContext, originalWidth, originalHeight);
		CGContextRotateCTM(bmContext, (CGFloat)-M_PI);
	}
    
	/// Image quality
	CGContextSetShouldAntialias(bmContext, true);
	CGContextSetAllowsAntialiasing(bmContext, true);
	CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    
	/// Draw the image in the bitmap context
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = originalWidth, .size.height = originalHeight}, self.CGImage);
    
	/// Create an image object from the context
	CGImageRef scaledImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* scaled = [UIImage imageWithCGImage:scaledImageRef scale:self.scale orientation:self.imageOrientation];
    
	/// Cleanup
	CGImageRelease(scaledImageRef);
	CGContextRelease(bmContext);
    
	return scaled;
}

- (UIImage*)scaleToFitSize:(CGSize)newSize {
	const size_t originalWidth = (size_t)(self.size.width * self.scale);
	const size_t originalHeight = (size_t)(self.size.height * self.scale);
    
	/// Keep aspect ratio
	size_t destWidth, destHeight;
	if (originalWidth > originalHeight)
	{
		destWidth = (size_t)newSize.width;
		destHeight = (size_t)(originalHeight * newSize.width / originalWidth);
	}
	else
	{
		destHeight = (size_t)newSize.height;
		destWidth = (size_t)(originalWidth * newSize.height / originalHeight);
	}
	if (destWidth > newSize.width)
	{
		destWidth = (size_t)newSize.width;
		destHeight = (size_t)(originalHeight * newSize.width / originalWidth);
	}
	if (destHeight > newSize.height)
	{
		destHeight = (size_t)newSize.height;
		destWidth = (size_t)(originalWidth * newSize.height / originalHeight);
	}
    
	/// Create an ARGB bitmap context
	CGContextRef bmContext = NYXCreateARGBBitmapContext(destWidth, destHeight, destWidth * kNyxNumberOfComponentsPerARBGPixel);
	if (!bmContext)
		return nil;
    
	/// Image quality
	CGContextSetShouldAntialias(bmContext, true);
	CGContextSetAllowsAntialiasing(bmContext, true);
	CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    
	/// Draw the image in the bitmap context
    
    UIGraphicsPushContext(bmContext);
    CGContextTranslateCTM(bmContext, 0.0f, destHeight);
    CGContextScaleCTM(bmContext, 1.0f, -1.0f);
    [self drawInRect:(CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = destWidth, .size.height = destHeight}];
    UIGraphicsPopContext();
    
	/// Create an image object from the context
	CGImageRef scaledImageRef = CGBitmapContextCreateImage(bmContext);
	UIImage* scaled = [UIImage imageWithCGImage:scaledImageRef scale:self.scale orientation:self.imageOrientation];
    
	/// Cleanup
	CGImageRelease(scaledImageRef);
	CGContextRelease(bmContext);
    
	return scaled;	
}

//Saving


- (BOOL)saveToURL:(NSURL*)url uti:(CFStringRef)uti backgroundFillColor:(UIColor*)fillColor
{
	if (!url)
		return NO;
    
	if (!uti)
		uti = kUTTypePNG;
    
	CGImageDestinationRef dest = CGImageDestinationCreateWithURL((__bridge CFURLRef)url, uti, 1, NULL);
	if (!dest)
		return NO;
    
	/// Set the options, 1 -> lossless
	CFMutableDictionaryRef options = CFDictionaryCreateMutable(kCFAllocatorDefault, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	if (!options)
	{
		CFRelease(dest);
		return NO;
	}
	CFDictionaryAddValue(options, kCGImageDestinationLossyCompressionQuality, (__bridge CFNumberRef)[NSNumber numberWithFloat:1.0f]); // No compression
	if (fillColor)
		CFDictionaryAddValue(options, kCGImageDestinationBackgroundColor, fillColor.CGColor);
	
	/// Add the image
	CGImageDestinationAddImage(dest, self.CGImage, (CFDictionaryRef)options);
	
	/// Write it to the destination
	const bool success = CGImageDestinationFinalize(dest);
	
	/// Cleanup
	CFRelease(options);
	CFRelease(dest);
	
	return success;
}

- (BOOL)saveToURL:(NSURL*)url type:(NYXImageType)type backgroundFillColor:(UIColor*)fillColor
{
	return [self saveToURL:url uti:[self utiForType:type] backgroundFillColor:fillColor];
}

- (BOOL)saveToURL:(NSURL*)url
{
	return [self saveToURL:url uti:kUTTypePNG backgroundFillColor:nil];
}

- (BOOL)saveToPath:(NSString*)path uti:(CFStringRef)uti backgroundFillColor:(UIColor*)fillColor
{
	if (!path)
		return NO;
	
	NSURL* url = [[NSURL alloc] initFileURLWithPath:path];
	const BOOL ret = [self saveToURL:url uti:uti backgroundFillColor:fillColor];
	return ret;
}

- (BOOL)saveToPath:(NSString*)path type:(NYXImageType)type backgroundFillColor:(UIColor*)fillColor
{
	if (!path)
		return NO;
    
	NSURL* url = [[NSURL alloc] initFileURLWithPath:path];
	const BOOL ret = [self saveToURL:url uti:[self utiForType:type] backgroundFillColor:fillColor];
	return ret;
}

- (BOOL)saveToPath:(NSString*)path
{
	if (!path)
		return NO;
    
	NSURL* url = [[NSURL alloc] initFileURLWithPath:path];
	const BOOL ret = [self saveToURL:url type:NYXImageTypePNG backgroundFillColor:nil];
	return ret;
}

- (BOOL)saveToPhotosAlbum
{
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	__block BOOL ret = YES;
	[library writeImageToSavedPhotosAlbum:self.CGImage orientation:(ALAssetOrientation)self.imageOrientation completionBlock:^(NSURL* assetURL, NSError* error) {
		if (!assetURL)
		{
			NSLog(@"%@", error);
			ret = NO;
		}
	}];
	return ret;
}

+ (NSString*)extensionForUTI:(CFStringRef)uti
{
	if (!uti)
		return nil;
    
	NSDictionary* declarations = (__bridge_transfer NSDictionary*)UTTypeCopyDeclaration(uti);
	if (!declarations)
		return nil;
    
	id extensions = [(NSDictionary*)[declarations objectForKey:(__bridge NSString*)kUTTypeTagSpecificationKey] objectForKey:(__bridge NSString*)kUTTagClassFilenameExtension];
	NSString* extension = ([extensions isKindOfClass:[NSArray class]]) ? [extensions objectAtIndex:0] : extensions;
    
	return extension;
}

#pragma mark - Private
- (CFStringRef)utiForType:(NYXImageType)type
{
	CFStringRef uti = NULL;
	switch (type)
	{
		case NYXImageTypeBMP:
			uti = kUTTypeBMP;
			break;
		case NYXImageTypeJPEG:
			uti = kUTTypeJPEG;
			break;
		case NYXImageTypePNG:
			uti = kUTTypePNG;
			break;
		case NYXImageTypeTIFF:
			uti = kUTTypeTIFF;
			break;
		case NYXImageTypeGIF:
			uti = kUTTypeGIF;
			break;
		default:
			uti = kUTTypePNG;
			break;
	}
	return uti;
}

@end


