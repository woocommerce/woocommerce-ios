
#import "WPBadgeView.h"

static const CGFloat kDefaultCornerRadius = 6.f;
static const UIEdgeInsets kDefaultEdgeInsets = {3.f, 6.f, 3.f, 6.f};

@interface WPBadgeView()
@property (nonatomic, strong) NSLayoutConstraint *topConstraint;
@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;
@property (nonatomic, strong) NSLayoutConstraint* leadingConstraint;
@property (nonatomic, strong) NSLayoutConstraint* trailingConstraint;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIVisualEffectView *blurEffectView;
@end

@implementation WPBadgeView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)init
{
    self = [super initWithFrame:(CGRectZero)];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    [self setupBlur];
    [self layoutLabel];
    [self setupStyle];
}

- (void)layoutLabel
{
    self.label.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.label];

    self.topConstraint = [self.label.topAnchor constraintEqualToAnchor:self.topAnchor];
    self.bottomConstraint = [self.label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor];
    self.leadingConstraint = [self.label.leadingAnchor constraintEqualToAnchor:self.leadingAnchor];
    self.trailingConstraint = [self.label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor];

    [NSLayoutConstraint activateConstraints: @[
                                               self.topConstraint,
                                               self.bottomConstraint,
                                               self.leadingConstraint,
                                               self.trailingConstraint
                                               ]];
}

#pragma mark - Getters / setters

- (UILabel *)label
{
    if (_label == nil) {
        _label = [UILabel new];
    }
    return _label;
}

- (void)setInsets:(UIEdgeInsets)insets
{
    _insets = insets;
    self.topConstraint.constant = insets.top;
    self.bottomConstraint.constant = -insets.bottom;
    self.leadingConstraint.constant = insets.left;
    self.trailingConstraint.constant = -insets.right;
    [self setNeedsLayout];
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    _cornerRadius = cornerRadius;
    self.blurEffectView.layer.cornerRadius = cornerRadius;
    self.blurEffectView.layer.masksToBounds = YES;
}

#pragma mark - Helpers

- (void)setupStyle
{
    self.label.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
    self.label.textColor = UIColor.whiteColor;
    self.insets = kDefaultEdgeInsets;
    self.cornerRadius = kDefaultCornerRadius;
}

- (void)setupBlur
{
    self.backgroundColor = [UIColor clearColor];

    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];

    _contentView = blurEffectView.contentView;
    _blurEffectView = blurEffectView;
    
    [self addSubview:blurEffectView];
    [self constraintEffectView:blurEffectView];
}

- (void)constraintEffectView:(UIView *)view
{
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
                                 [view.heightAnchor constraintEqualToAnchor:self.heightAnchor],
                                 [view.widthAnchor constraintEqualToAnchor:self.widthAnchor],
                                 [view.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
                                 [view.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
                                 ]];
}

@end
