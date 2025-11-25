#import "WPNUXSecondaryButton.h"
#import <UIKit/UIKit.h>
@import WordPressSharedObjC;


static UIEdgeInsets const WPNUXSecondaryButtonTitleEdgeInsets = {0, 15.0, 0, 15.0};


@implementation WPNUXSecondaryButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configureButton];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self configureButton];
    }
    return self;
}

- (void)sizeToFit
{
    [super sizeToFit];

    // Adjust frame to account for the edge insets
    CGRect frame = self.frame;
    frame.size.width += self.configuration.contentInsets.leading + self.configuration.contentInsets.trailing;
    self.frame = frame;
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    size.width += self.configuration.contentInsets.leading + self.configuration.contentInsets.trailing;
    return size;
}

#pragma mark - Private Methods

- (void)configureButton
{
    UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
    config.contentInsets = NSDirectionalEdgeInsetsMake(
        WPNUXSecondaryButtonTitleEdgeInsets.top,
        WPNUXSecondaryButtonTitleEdgeInsets.left,
        WPNUXSecondaryButtonTitleEdgeInsets.bottom,
        WPNUXSecondaryButtonTitleEdgeInsets.right
    );
    self.configuration = config;

    self.titleLabel.font = [WPFontManager systemRegularFontOfSize:15.0];
    self.titleLabel.minimumScaleFactor = 10.0/15.0;
    self.titleLabel.adjustsFontSizeToFitWidth = YES;

    [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.4] forState:UIControlStateHighlighted];
}

@end
