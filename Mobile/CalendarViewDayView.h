
#import <UIKit/UIKit.h>
#import "CalendarViewDayEventView.h"
#import "CalendarViewDayViewDataSource.h"
#import "CalendarViewDayViewDelegate.h"

@class CalendarViewAllDayGridView;
@class CalendarViewDayGridView;

@protocol CalendarViewDayViewDataSource, CalendarViewDayViewDelegate;

@interface CalendarViewDayView : UIView <UIGestureRecognizerDelegate, UIPopoverControllerDelegate>{
    id<CalendarViewDayViewDataSource> dataSource;
}

@property (nonatomic,assign) BOOL autoScrollToFirstEvent;
@property (nonatomic,strong) NSDate *day;
@property (nonatomic,unsafe_unretained) IBOutlet id<CalendarViewDayViewDataSource> dataSource;
@property (nonatomic,unsafe_unretained) IBOutlet id<CalendarViewDayViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIImageView *topBackground;
@property (weak, nonatomic) IBOutlet UIButton *leftArrow;
@property (weak, nonatomic) IBOutlet UIButton *rightArrow;
@property (weak, nonatomic) IBOutlet UIButton *datePickerButton;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (nonatomic, retain) UIColor *dateLabelBackgroundColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, retain) UIColor *dateLabelTextColor UI_APPEARANCE_SELECTOR;
//@property (nonatomic, strong) CalendarActionSheetDatePicker *datePicker;

@property (nonatomic, strong) CalendarViewDayGridView *gridView;
@property (nonatomic, strong) CalendarViewAllDayGridView *allDayGridView;
@property (nonatomic, strong) UIFont *regularFont;
@property (nonatomic, strong) UIFont *boldFont;

@property (strong, nonatomic) IBOutlet UIButton *dateButton;
- (void)reloadData;

+ (NSArray *) hourLabels;

@end



