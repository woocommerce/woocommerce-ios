#import "WPActionBar.h"

static const CGFloat SeparatorLineHeight = 2.f;
static const CGFloat BarMinimumHeight = 44.f;
static const UIEdgeInsets ButtonsBarEdgeInsets = {0, 20, 0, 20}; //top, left, bottom, right

@interface WPActionBar()
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UIView *lineView;
@end

@implementation WPActionBar

- (instancetype)init
{
    if (self = [super initWithFrame:CGRectZero]) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    [self setupView];
    [self setupStackView];
    [self setupConstraints];
}

- (void)setupView
{
    [self setBackgroundColor:[UIColor whiteColor]];
    [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    [self addSubview:[self lineView]];
}

- (void)setupStackView
{
    [self.stackView setAxis:UILayoutConstraintAxisHorizontal];
    [self.stackView setAlignment:UIStackViewAlignmentFill];
    [self.stackView setDistribution:UIStackViewDistributionFill];
    [self.stackView setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.stackView addArrangedSubview:[self separatorView]];
    [self.stackView setLayoutMargins:ButtonsBarEdgeInsets];
    [self.stackView setLayoutMarginsRelativeArrangement:YES];

    [self addSubview:self.stackView];
}

- (UIView *)separatorView
{
    UIView *view = [UIView new];
    [view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[view.heightAnchor constraintEqualToConstant:BarMinimumHeight] setActive:YES];
    return view;
}

- (UIView *)lineView
{
    if (_lineView) {
        return _lineView;
    }
    _lineView = [UIView new];
    [_lineView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [[_lineView.heightAnchor constraintEqualToConstant:SeparatorLineHeight] setActive:YES];
    [_lineView setBackgroundColor:[UIColor whiteColor]];
    return _lineView;
}

- (CGSize)intrinsicContentSize
{
    // Necessary to make the iPhone X bottom inset work.
    return CGSizeZero;
}

- (UIStackView *)stackView
{
    if (!_stackView) {
        _stackView = [UIStackView new];
    }
    return _stackView;
}

#pragma mark - public methods

- (UIColor *)barBackgroundColor
{
    return self.backgroundColor;
}

- (void)setBarBackgroundColor:(UIColor *)barBackgroundColor
{
    self.backgroundColor = barBackgroundColor;
}

- (UIColor *)lineColor
{
    return self.lineView.backgroundColor;
}

- (void)setLineColor:(UIColor *)lineColor
{
    [self.lineView setBackgroundColor:lineColor];
}

- (void)addLeftButton:(UIButton *)button
{
    [self.stackView insertArrangedSubview:button atIndex:0];
}

- (void)addRightButton:(UIButton *)button
{
    [self.stackView addArrangedSubview:button];
}

#pragma mark - Layout

- (void)setupConstraints
{
    [NSLayoutConstraint activateConstraints:
     @[
       [self.lineView.topAnchor constraintEqualToAnchor:self.topAnchor],
       [self.lineView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
       [self.lineView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
    ]];

    [NSLayoutConstraint activateConstraints:
     @[
       [self.stackView.topAnchor constraintEqualToAnchor:self.lineView.bottomAnchor],
       [self.stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
       [self.stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
       [self.stackView.bottomAnchor constraintEqualToAnchor:self.layoutMarginsGuide.bottomAnchor]
    ]];
}

@end
