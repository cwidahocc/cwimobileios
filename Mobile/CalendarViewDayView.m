#import "CalendarViewDayView.h"
#import "CalendarViewEvent.h"
#import "CalendarViewAllDayGridView.h"
#import "CalendarViewDayGridView.h"
#import <QuartzCore/QuartzCore.h>
#import "Ellucian_GO-Swift.h"
#import "CalendarViewDayGridView.h"

static const unsigned int HOURS_IN_DAY                   = 25; // Beginning and end of day is include twice
static const unsigned int SPACE_BETWEEN_HOUR_LABELS      = 5;
static const unsigned int ALL_DAY_VIEW_EMPTY_SPACE       = 3;

@implementation CalendarViewDayView


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupCustomInitialisation];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        [self setupCustomInitialisation];
    }
    return self;
}

- (void)setupCustomInitialisation {
    self.day = [NSDate date];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([otherGestureRecognizer.view isEqual:self.scrollView]) {
        return YES;
    }
    if ([otherGestureRecognizer.view isEqual:self]) {
        return YES;
    }
    return NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.backgroundView.backgroundColor = self.dateLabelBackgroundColor;
    self.dateLabel.textColor = self.dateLabelTextColor;
    
    [self.scrollView addSubview:self.allDayGridView];
    [self.scrollView addSubview:self.gridView];
    
    self.allDayGridView.frame = CGRectMake(0, 0,
                                           CGRectGetWidth(self.bounds),
                                           ALL_DAY_VIEW_EMPTY_SPACE);
    CGFloat fontHeight = [@"A" sizeWithAttributes: @{NSFontAttributeName: self.boldFont}].height;
    self.gridView.frame = CGRectMake(CGRectGetMinX(self.allDayGridView.bounds),
                                     CGRectGetMaxY(self.allDayGridView.bounds),
                                     CGRectGetWidth(self.scrollView.bounds),
                                     fontHeight * SPACE_BETWEEN_HOUR_LABELS * HOURS_IN_DAY);
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds),
                                             CGRectGetHeight(self.allDayGridView.bounds) + CGRectGetHeight(self.gridView.bounds));

    self.dateLabel.text = [self titleText];
    [self.gridView setNeedsDisplay];
    
}

- (CalendarViewAllDayGridView *)allDayGridView {
    if (!_allDayGridView) {
        _allDayGridView = [[CalendarViewAllDayGridView alloc] init];
        _allDayGridView.backgroundColor = [UIColor whiteColor];
        _allDayGridView.dayView = self;
    }
    return _allDayGridView;
}

- (CalendarViewDayGridView *)gridView {
    if (!_gridView){
        _gridView = [[CalendarViewDayGridView alloc] init];
        _gridView.backgroundColor = [UIColor whiteColor];
        _gridView.dayView = self;
    }
    return _gridView;
}

- (UIFont *)regularFont {
    if (!_regularFont) {
        _regularFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    }
    return _regularFont;
}

- (UIFont *)boldFont {
    if (!_boldFont) {
        UIFontDescriptor *caption1FontDesciptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleCaption1];
        UIFontDescriptor *boldCaption1FontDescriptor = [caption1FontDesciptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        _boldFont = [UIFont fontWithDescriptor:boldCaption1FontDescriptor size:0.0];
    }
    return _boldFont;
}

- (void)setDataSource:(id <CalendarViewDayViewDataSource>)newDataSource {
    dataSource = newDataSource;
}

- (id <CalendarViewDayViewDataSource>)dataSource {
    return dataSource;
}

- (void)setDay:(NSDate *)date {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay |  NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal) fromDate:date];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    _day = [[NSCalendar currentCalendar] dateFromComponents:components];
    self.dateLabel.text = [self titleText];
    [self reloadData];
}

- (void)reloadData {
    for (id view in self.allDayGridView.subviews) {
        if ([NSStringFromClass([view class])isEqualToString:@"CalendarViewDayEventView"]) {
            [view removeFromSuperview];
        }
    }
    
    for (id view in self.gridView.subviews) {
        if ([NSStringFromClass([view class])isEqualToString:@"CalendarViewDayEventView"]) {
            [view removeFromSuperview];
        }
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        NSArray *events = [self.dataSource dayView:self eventsFor:self.day];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            
            for (id view in self.allDayGridView.subviews) {
                if ([NSStringFromClass([view class])isEqualToString:@"CalendarViewDayEventView"]) {
                    [view removeFromSuperview];
                }
            }
            
            for (id view in self.gridView.subviews) {
                if ([NSStringFromClass([view class])isEqualToString:@"CalendarViewDayEventView"]) {
                    [view removeFromSuperview];
                }
            }
            
            [self.allDayGridView resetCachedData];
            
            for (id e in events) {
                CalendarViewEvent *event = e;
                event.displayDate = self.day;
            }
            
            NSArray *sortedEvents = [events sortedArrayUsingComparator:^(id ev1, id ev2) {
                CalendarViewEvent *event1 = (CalendarViewEvent *)ev1;
                CalendarViewEvent *event2 = (CalendarViewEvent *)ev2;
                
                NSUInteger v1 = [event1 minutesSinceMidnight];
                NSUInteger v2 = [event2 minutesSinceMidnight];
                
                if (v1 < v2) {
                    return NSOrderedAscending;
                } else if (v1 > v2) {
                    return NSOrderedDescending;
                } else {
                    /* Event start time is the same, compare by duration.
                     */
                    NSUInteger d1 = [event1 durationInMinutes];
                    NSUInteger d2 = [event2 durationInMinutes];
                    
                    if (d1 < d2) {
                        /*
                         * Event with a shorter duration is after an event
                         * with a longer duration. Looks nicer when drawing the events.
                         */
                        return NSOrderedDescending;
                    } else if (d1 > d2) {
                        return NSOrderedAscending;
                    } else {
                        /*
                         * The last resort: compare by title.
                         */
                        return (NSInteger)[event1.line1 compare:event2.line1];
                    }
                }
                
            }];
            for (id e in sortedEvents) {
                CalendarViewEvent *event = e;
                event.displayDate = self.day;
                
                if ([event isAllDayForDisplayDate]) {
                    [self.allDayGridView addEvent:event];
                } else if([event minutesSinceMidnight] > 0) {
                    [self.gridView addEvent:event];
                }
            }
        });
    });
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}


- (IBAction)changeToPreviousDay:(id)sender {
    self.day = [self previousDayFromDate:_day];
}
- (IBAction)changeToNextDay:(id)sender {
    self.day = [self nextDayFromDate:_day];
    
}

- (void)dateWasSelected:(NSDate *)selectedDate element:(id)element {
    self.day = selectedDate;
}

- (NSDate *)nextDayFromDate:(NSDate *)date {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay |  NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal) fromDate:date];
    [components setDay:[components day] + 1];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    return [[NSCalendar currentCalendar] dateFromComponents:components];
}

- (NSDate *)previousDayFromDate:(NSDate *)date {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay |  NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal) fromDate:date];
    [components setDay:[components day] - 1];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    return [[NSCalendar currentCalendar] dateFromComponents:components];
}

- (NSString *)titleText {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay |  NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal) fromDate:_day];
    
    NSArray *weekdaySymbols = [formatter shortWeekdaySymbols];
    
    return [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"day of week date", @"Localizable", [NSBundle mainBundle], @"%@ %@", @"day of week date"), [weekdaySymbols objectAtIndex:[components weekday] - 1], [formatter stringFromDate:_day]];
}

+ (NSArray *) hourLabels
{
    static NSArray *hours;
    if(!hours) {
        NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
        [timeFormatter setDateStyle:NSDateFormatterNoStyle];
        [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
        
        NSMutableArray *dates = [[NSMutableArray alloc] init];
        NSDate *date = [NSDate date];
        NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
        NSUInteger preservedComponents = (NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay);
        date = [calendar dateFromComponents:[calendar components:preservedComponents fromDate:date]];
        register unsigned int i;
        
        for (i=0; i < HOURS_IN_DAY; i++) {
            [dates addObject:[timeFormatter stringFromDate:date]];
            date = [date dateByAddingTimeInterval:60*60]; 
        }
        hours = [dates copy];
    }
    return hours;
}

-(NSArray *) accessibilityElements {
    NSArray *elements = @[self.leftArrow, self.rightArrow, self.datePickerButton, self.dateLabel];
    elements = [elements arrayByAddingObjectsFromArray:self.allDayGridView.subviews];
    elements = [elements arrayByAddingObjectsFromArray:self.gridView.subviews];
    return elements;
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction
{

    switch (direction) {
        case UIAccessibilityScrollDirectionDown: {
            NSUInteger count = [self.gridView.subviews count];
            for (NSUInteger i = 0; i < count - 1; i++) {
                UIView *view = self.gridView.subviews[i];
                if ([view accessibilityElementIsFocused]) {
                    view = self.gridView.subviews[i + 1];
                    if ([view isKindOfClass:[CalendarViewDayEventView class]]) {
                        [self.gridView scrollToEvent:(CalendarViewDayEventView *)view];
                        break;
                    }
                }
               
            }
        } break;
            
        case UIAccessibilityScrollDirectionUp: {
            NSUInteger count = [self.gridView.subviews count];
            for (NSUInteger i = 1; i < count; i++) {
                UIView *view = self.gridView.subviews[i];
                if ([view accessibilityElementIsFocused]) {
                    view = self.gridView.subviews[i - 1];
                    if ([view isKindOfClass:[CalendarViewDayEventView class]]) {
                        [self.gridView scrollToEvent:(CalendarViewDayEventView *)view];
                        break;
                    }
                }
                
            }


        } break;
            
        default:
            // These cases are not handled
            return NO;
    }
    
    return YES; // We handled the scroll
}




@end


