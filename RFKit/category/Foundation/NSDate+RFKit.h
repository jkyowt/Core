/*!
    NSDate extension
    RFKit

    Copyright (c) 2012-2013 BB9z
    https://github.com/bb9z/RFKit

    The MIT License (MIT)
    http://www.opensource.org/licenses/mit-license.php
 */

#import <Foundation/Foundation.h>

@interface NSDate (RFKit)

- (BOOL)isSameDayWithDate:(NSDate *)date;

+(NSDate *)NSStringDateToNSDate:(NSString *)string;
+(NSDate *)NSStringDateToNSDateWithT:(NSString *)string;
+(NSDate *)NSStringDateToNSDateWithSecond:(NSString *)string;

+ (NSString *)getCurrentTime;
+ (NSDate *)localNowDate;
- (NSString *)showSelf;
- (NSString *)showSelfWithoutTime;
@end
