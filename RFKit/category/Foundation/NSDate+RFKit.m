
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
@end
