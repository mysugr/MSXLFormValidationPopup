//
//  MSXLFormValidationPopupViewController.m
//  Pods
//
//  Created by Bernhard Schandl on 30/09/2016.
//  Copyright © 2016 mySugr GmbH
//

#import "MSXLFormValidationPopupViewController.h"


#define kLabelPaddingTop 5
#define kLabelPaddingBottom kLabelPaddingTop
#define kLabelPaddingLeft 10
#define kLabelPaddingRight kLabelPaddingLeft



@interface MSXLFormValidationPopupViewController ()

@property (nonatomic, strong, readwrite) UILabel *textLabel;

@end


@implementation MSXLFormValidationPopupViewController

@synthesize validationStatus = _validationStatus;

-(void)viewDidLoad {
    [super viewDidLoad];
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 0;
    label.text = self.validationStatus.msg;
    label.textColor = [UIColor whiteColor];
    [self.view addSubview:label];
    self.textLabel = label;
    
    [self.view addConstraints:@[
        [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:kLabelPaddingTop],
        [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:kLabelPaddingLeft],
        [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:-kLabelPaddingRight],
        [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:-kLabelPaddingBottom],
    ]];
}

-(void)setValidationStatus:(XLFormValidationStatus *)validationStatus {
    _validationStatus = validationStatus;
    self.textLabel.text = _validationStatus.msg;
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

-(void)viewWillLayoutSubviews {
    CGFloat labelWidth = MIN(self.maximumSize.width, self.view.bounds.size.width) - kLabelPaddingLeft - kLabelPaddingRight;
    self.textLabel.preferredMaxLayoutWidth = labelWidth;
    CGSize labelSize = [self.textLabel sizeThatFits:CGSizeMake(labelWidth, CGFLOAT_MAX)];
    CGSize computedContentSize = CGSizeMake(MAX(self.minimumSize.width, labelSize.width + kLabelPaddingLeft + kLabelPaddingRight),
                                            MAX(self.minimumSize.height, labelSize.height + kLabelPaddingTop + kLabelPaddingBottom));
    self.preferredContentSize = computedContentSize;
    
    [super viewWillLayoutSubviews];
}

-(void)viewWillAppear:(BOOL)animated {
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    [super viewWillAppear:animated];
    self.view.backgroundColor = self.view.tintColor;
}


@end
