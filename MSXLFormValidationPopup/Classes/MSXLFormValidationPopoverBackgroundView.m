//
//  MSXLFormValidationPopoverBackgroundView.m
//  Pods
//
//  Created by Bernhard Schandl on 30/09/2016.
//  Copyright © 2016 mySugr GmbH
//

#import "MSXLFormValidationPopoverBackgroundView.h"




@interface MSXLFormValidationMessageArrowView : UIView

@property (nonatomic) UIPopoverArrowDirection arrowDirection;
@property (nonatomic) UIColor* color;

@end

@implementation MSXLFormValidationMessageArrowView

-(void)setArrowDirection:(UIPopoverArrowDirection)arrowDirection {
    _arrowDirection = arrowDirection;
    [self setNeedsDisplay];
}

-(void)drawRect:(CGRect)rect {
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(c, self.tintColor.CGColor);
    if (self.arrowDirection == UIPopoverArrowDirectionUp) {
        CGContextMoveToPoint(c, 0, self.bounds.size.height);
        CGContextAddLineToPoint(c, self.bounds.size.width, self.bounds.size.height);
        CGContextAddLineToPoint(c, self.bounds.size.width / 2, 0);
        CGContextAddLineToPoint(c, 0, self.bounds.size.height);
    } else {
        CGContextMoveToPoint(c, 0, 0);
        CGContextAddLineToPoint(c, self.bounds.size.width, 0);
        CGContextAddLineToPoint(c, self.bounds.size.width / 2, self.bounds.size.height);
        CGContextAddLineToPoint(c, 0, 0);
    }
    CGContextFillPath(c);
}

@end


@interface MSXLFormValidationPopoverBackgroundView ()

@property (nonatomic, assign) CGFloat arrowOffset;
@property (nonatomic, assign) UIPopoverArrowDirection arrowDirection;
@property (nonatomic, strong) MSXLFormValidationMessageArrowView* arrowView;

@end


@implementation MSXLFormValidationPopoverBackgroundView

@synthesize arrowOffset = _arrowOffset;
@synthesize arrowDirection = _arrowDirection;

+(BOOL)wantsDefaultContentAppearance {
    return NO;
}

+(CGFloat)arrowHeight {
    return 10;
}

+(UIEdgeInsets)contentViewInsets {
    return UIEdgeInsetsZero;
}

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.arrowView = [[MSXLFormValidationMessageArrowView alloc] initWithFrame:CGRectMake(0, 0, 20, 10)];
        self.arrowView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.arrowView];
        
        self.backgroundColor = [UIColor clearColor];
        self.layer.shadowColor = [[UIColor clearColor] CGColor];
        self.layer.cornerRadius = 0;
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat xPosition = self.bounds.size.width / 2.f;
    CGFloat yPosition = self.arrowDirection == UIPopoverArrowDirectionDown ? self.bounds.size.height - 5
                                                                           : 5;
    self.arrowView.center = CGPointMake(xPosition, yPosition);
}

-(void)setArrowOffset:(CGFloat)arrowOffset {
    _arrowOffset = arrowOffset;
    [self setNeedsLayout];
}

-(void)setArrowDirection:(UIPopoverArrowDirection)arrowDirection {
    if (arrowDirection != UIPopoverArrowDirectionUp && arrowDirection != UIPopoverArrowDirectionDown) {
        arrowDirection = UIPopoverArrowDirectionUp;
    }
    _arrowDirection = arrowDirection;
    self.arrowView.arrowDirection = arrowDirection;
    [self setNeedsLayout];
}

@end

