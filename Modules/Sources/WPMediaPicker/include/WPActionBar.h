#import <UIKit/UIKit.h>

@interface WPActionBar : UIView

/**
 The color for the top horizontal line.
 */
@property (nonatomic, strong) UIColor *lineColor UI_APPEARANCE_SELECTOR;

/**
The color for the action bar background.
*/
@property (nonatomic, strong) UIColor *barBackgroundColor UI_APPEARANCE_SELECTOR;

/**
 Adds the given button to the left side of the bar

 @param button The button to add.
 */
- (void)addLeftButton:(UIButton *)button;

/**
 Adds the given button to the right side of the bar

 @param button The button to add.
 */
- (void)addRightButton:(UIButton *)button;

@end
