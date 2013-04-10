
#define kDEFAULT_DATE_TIME_FORMAT @"yyyy-MM-dd HH:mm"
#define kDEFAULT_SECOND_DATE_TIME_FORMAT @"yyyy-MM-dd HH:mm:ss"
#define kDEFAULT_T_DATE_TIME_FORMAT @"yyyy-MM-dd'T'HH:mm:ss+00:00"
#import "RFKit.h"
#import "NSDate+RFKit.h"

@implementation NSDate (RFKit)

- (BOOL)isSameDayWithDate:(NSDate *)date {
    NSDateComponents *target = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
    NSDateComponents *source = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:self];
    return [target isEqual:source];
}

+ (NSString *)nowDate {
    NSDate* now = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    NSInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit |
    NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    comps = [calendar components:unitFlags fromDate:now];
    int hour = [comps hour];
    int min = [comps minute];
    int sec = [comps second];
    int year = [comps year];
    int month = [comps    month];
    int day = [comps day];
    
    NSString *time =  [NSString stringWithFormat:@"%02d:%02d:%02d", hour, min,sec];
    NSString *date = [NSString stringWithFormat:@"%04d-%02d-%02d", year, month, day];
    NSString *date_time = [NSString stringWithFormat:@"%@ %@",date ,time];
    return date_time;
}

+(NSDate *)NSStringDateToNSDate:(NSString *)string {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [formatter setDateFormat:kDEFAULT_DATE_TIME_FORMAT];
    NSDate *date = [formatter dateFromString:string];
    return date;
}

+(NSDate *)NSStringDateToNSDateWithSecond:(NSString *)string {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [formatter setDateFormat:kDEFAULT_SECOND_DATE_TIME_FORMAT];
    NSDate *date = [formatter dateFromString:string];
    return date;
}

+(NSDate *)NSStringDateToNSDateWithT:(NSString *)string {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [formatter setDateFormat:kDEFAULT_T_DATE_TIME_FORMAT];
    NSDate *date = [formatter dateFromString:string];
    return date;
}

+ (NSDate *)localNowDate {
    NSDate *date = [NSDate date];
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate: date];
    NSDate *localeDate = [date  dateByAddingTimeInterval: interval];
    return localeDate;
}


- (NSString *)daySinceNowReferenceDate:(NSString *)dateString {
    NSDate *compareDate = [NSDate NSStringDateToNSDateWithSecond:dateString];
    NSString *compareDateString = [compareDate description];
    NSString *hourString = [compareDateString componentsSeparatedByString:@" "][1];
    NSString *hourStingNoSeconds = [hourString substringToIndex:[hourString length]-3];
    NSString *dateFormatString = @"";
    
    NSTimeInterval interval = [[NSDate localNowDate]timeIntervalSinceDate:compareDate];
    
    NSInteger day = interval/24/3600;
    if ( day == 0 )
        dateFormatString = [NSString stringWithFormat:@"今天 %@",hourStingNoSeconds];
    else if ( day == 1 )
        dateFormatString = [NSString stringWithFormat:@"昨天 %@",hourStingNoSeconds];
    else if ( day == 2 )
        dateFormatString = [NSString stringWithFormat:@"前天 %@",hourStingNoSeconds];
    else
        dateFormatString = [NSString stringWithFormat:@"%@ %@",[compareDateString componentsSeparatedByString:@" "][0],hourStingNoSeconds];
    
    return dateFormatString;
}

- (NSString *)showSelf {
	NSDateFormatter* formater = [[NSDateFormatter alloc] init];
	[formater setDateFormat:@"yyyy-MM-dd HH:mm"];
	[formater setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	NSString* timeDesp = [formater stringFromDate:self];
	return timeDesp;
}

- (NSString *)showSelfWithoutTime {
	NSDateFormatter* formater = [[NSDateFormatter alloc] init];
	[formater setDateFormat:@"yyyy-MM-dd"];
	[formater setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	NSString* timeDesp = [formater stringFromDate:self];
	return timeDesp;
}

@end
