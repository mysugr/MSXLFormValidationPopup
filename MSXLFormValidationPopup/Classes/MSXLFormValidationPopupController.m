//
//  MSXLFormValidationPopupController.m
//  Pods
//
//  Created by Bernhard Schandl on 30/09/2016.
//  Copyright © 2016 mySugr GmbH
//

#import "MSXLFormValidationPopupController.h"
#import "MSXLFormValidationPopupViewController.h"
#import "MSXLFormValidationPopoverBackgroundView.h"









@interface MSXLFormValidationPopupController () <UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) UIViewController<MSXLFormValidationMessageViewController>* validationMessageViewController;
@property (nonatomic) CGFloat validationMessageViewControllerOffset;
@property (nonatomic) CGFloat validationMessageViewControllerInitialOffset;
@property (nonatomic) BOOL validationMessageViewControllerIsHiding;

@property (nonatomic, strong) NSMutableArray<XLFormRowDescriptor*>* editingRowDescriptors;
@property (nonatomic, strong) XLFormRowDescriptor* lastEditingRowDescriptor;

@end




@implementation MSXLFormValidationPopupController

#pragma mark Lifecycle

-(instancetype)init {
    self = [super init];
    if (self) {
        self.editingRowDescriptors = [NSMutableArray array];
        self.maximumScrollOffset = 88.f;
        self.active = YES;
    }
    return self;
}



#pragma mark Activation

@synthesize active = _active;

-(void)setActive:(BOOL)active {
    _active = active;
    if (!_active) {
        [self hideValidationPopupAnimated:NO];
    }
}

-(BOOL)isActive {
    return _active;
}


#pragma mark UIViewController method forwarding

-(void)formViewController:(XLFormViewController*)formViewController beginEditing:(XLFormRowDescriptor*)row {
    NSParameterAssert(formViewController != nil);

    self.lastEditingRowDescriptor = row;
    if (row != nil) {
        [self.editingRowDescriptors addObject:row];
    }
    
    // If the user begins editing a cell, we show the popup only if there is a value and it is invalid.
    // Otherwise, if the current row is valid, we keep a popup that might be shown for some other row.
    id rowValue = [self valueForRow:row];
    XLFormValidationStatus* validationStatus = [self validationStatusForRow:row];
    if (validationStatus != nil) {
        if (rowValue != nil && rowValue != [NSNull null] && ![@"" isEqualToString:rowValue]) {
            [self showValidationPopupForStatus:validationStatus inFormViewController:formViewController forceRefresh:NO];
        } else if (![self isValidationStatus:self.validationMessageViewController.validationStatus equalTo:validationStatus]) {
            [self hideValidationPopupAnimated:YES];
        }
    }
}

-(void)formViewController:(XLFormViewController*)formViewController endEditing:(XLFormRowDescriptor*)row {
    NSParameterAssert(formViewController != nil);

    if (row == self.lastEditingRowDescriptor) {
        self.lastEditingRowDescriptor = nil;
    }
    [self.editingRowDescriptors removeObject:row];
    [self updateValidationPopupForRow:row inFormViewController:formViewController];
}

-(void)formViewController:(XLFormViewController*)formViewController formRowDescriptorValueHasChanged:(XLFormRowDescriptor*)formRow oldValue:(id)oldValue newValue:(id)newValue {
    NSParameterAssert(formViewController != nil);
    
    if ([self.editingRowDescriptors containsObject:formRow]) {
        [self hideValidationPopupForRow:formRow forced:NO];
    } else if ([formRow.rowType isEqualToString:XLFormRowDescriptorTypeSlider]) {
        [self updateValidationPopupForRow:formRow inFormViewController:formViewController];
    }
}

-(void)formViewController:(XLFormViewController*)formViewController viewDidAppear:(BOOL)animated {
    NSParameterAssert(formViewController != nil);
    
    self.active = YES;
    
    if (self.lastEditingRowDescriptor != nil) {
        [self updateValidationPopupForRow:self.lastEditingRowDescriptor inFormViewController:formViewController];
    }
}

-(void)formViewController:(XLFormViewController*)formViewController viewWillDisappear:(BOOL)animated {
    NSParameterAssert(formViewController != nil);
    
    self.active = NO;
}

-(void)formViewController:(XLFormViewController*)formViewController didSelectFormRow:(XLFormRowDescriptor*)row {
    NSParameterAssert(formViewController != nil);
    self.lastEditingRowDescriptor = row;
}

-(void)formViewController:(XLFormViewController*)formViewController viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    NSParameterAssert(formViewController != nil);
    
    if (self.validationMessageViewController != nil) {
        XLFormValidationStatus *status = self.validationMessageViewController.validationStatus;
        [self hideValidationPopupAnimated:NO];
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            [self showValidationPopupForStatus:status inFormViewController:formViewController forceRefresh:YES];
        }];
    }
}

-(void)formViewController:(XLFormViewController*)formViewController scrollViewDidScroll:(UIScrollView*)scrollView {
    NSParameterAssert(formViewController != nil);
    
    if (self.validationMessageViewController != nil && self.maximumScrollOffset >= 0) {
        // scroll popover
        CGRect rect = self.validationMessageViewController.popoverPresentationController.containerView.frame;
        rect.origin.y += self.validationMessageViewControllerOffset - scrollView.contentOffset.y;
        self.validationMessageViewControllerOffset = scrollView.contentOffset.y;
        self.validationMessageViewController.popoverPresentationController.containerView.frame = rect;
        
        if (fabs(self.validationMessageViewControllerOffset - self.validationMessageViewControllerInitialOffset) > self.maximumScrollOffset) {
            [self hideValidationPopupAnimated:YES];
        }
    }
}




#pragma mark show/hide/update

-(void)updateValidationPopupForRow:(XLFormRowDescriptor *)formRow inFormViewController:(XLFormViewController *)formViewController {
    XLFormValidationStatus *validationStatus = [self validationStatusForRow:formRow];
    if (validationStatus != nil) {
        [self showValidationPopupForStatus:validationStatus inFormViewController:formViewController];
    } else if ([self.validationMessageViewController.validationStatus.rowDescriptor isEqual:formRow]){
        [self hideValidationPopupAnimated:YES];
    }
}

-(void)showValidationPopupForStatus:(XLFormValidationStatus *)status inFormViewController:(XLFormViewController *)formViewController {
    [self showValidationPopupForStatus:status inFormViewController:formViewController forceRefresh:NO];
}

-(void)showValidationPopupForStatus:(XLFormValidationStatus *)status inFormViewController:(XLFormViewController *)formViewController forceRefresh:(BOOL)forceRefresh {
    
    if (!self.isActive) {
        return;
    }
    
    UITableViewCell *cell = [status.rowDescriptor cellForFormController:formViewController];
    
    if (self.validationMessageViewController != nil) {
        if (   forceRefresh
            || ![self isValidationStatus:self.validationMessageViewController.validationStatus equalTo:status]
            || self.validationMessageViewController.popoverPresentationController.sourceView != [self popoverSourceViewForCell:cell]) {
            [self hideValidationPopupAnimated:NO completion:^{
                [self showValidationPopupForStatus:status inFormViewController:formViewController];
            }];
            return;
        } else {
            // correct popover is already shown
            return;
        }
    }
    
    if (formViewController.parentViewController == nil) {
        // Form is not shown - so we do nothing
        return;
    }

    UIViewController<MSXLFormValidationMessageViewController> *viewController = [self validationMessageViewControllerForStatus:status inFormViewController:formViewController];
    [viewController.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(validationMessageViewControllerTapped:)]];
    viewController.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController* popoverPC = viewController.popoverPresentationController;
    popoverPC.delegate = self;
    popoverPC.sourceView = [self popoverSourceViewForCell:[status.rowDescriptor cellForFormController:formViewController]];
    popoverPC.sourceRect = popoverPC.sourceView.bounds;
    popoverPC.permittedArrowDirections = UIPopoverArrowDirectionDown;
    popoverPC.passthroughViews = nil;
    popoverPC.backgroundColor = [UIColor greenColor];
    popoverPC.popoverBackgroundViewClass = [viewController isKindOfClass:MSXLFormValidationPopupViewController.class]
        ? MSXLFormValidationPopoverBackgroundView.class
        : [self.delegate respondsToSelector:@selector(validationPopupController:backgroundViewClassForValidationStatus:)]
            ? [self.delegate validationPopupController:self backgroundViewClassForValidationStatus:status]
            : nil;
    
    popoverPC.popoverLayoutMargins = UIEdgeInsetsZero;

    self.validationMessageViewController = viewController;
    
    [(formViewController.navigationController ?: formViewController) presentViewController:viewController animated:NO completion:^{
        for (UIView* view in popoverPC.containerView.subviews) {
            if ([NSStringFromClass(view.class) rangeOfString:@"Mirror"].location != NSNotFound) {
                [view removeFromSuperview];
            }
        }
        [UIView animateWithDuration:.2 animations:^{
            popoverPC.containerView.alpha = 1;
            for (UIView* view in popoverPC.containerView.subviews) {
                view.alpha = 1;
            }
        }];
        
        self.validationMessageViewControllerOffset =
        self.validationMessageViewControllerInitialOffset = formViewController.tableView.contentOffset.y;
    }];
}

-(void)hideValidationPopupAnimated:(BOOL)animated {
    [self hideValidationPopupAnimated:animated completion:nil];
}

-(void)hideValidationPopupAnimated:(BOOL)animated completion:(void(^)(void))completion {
    if (self.validationMessageViewController != nil && !self.validationMessageViewControllerIsHiding) {
        self.validationMessageViewControllerIsHiding = YES;
        
        void(^animations)(void) = ^{
            self.validationMessageViewController.view.superview.superview.alpha = 0;
        };
        void(^animationCompletion)(BOOL) = ^(BOOL finished) {
            [self.validationMessageViewController dismissViewControllerAnimated:NO completion:^{
                self.validationMessageViewController = nil;
                self.validationMessageViewControllerIsHiding = NO;
                if (completion) {
                    completion();
                }
            }];
        };
        
        if (animated) {
            [UIView animateWithDuration:.2 animations:animations completion:animationCompletion];
        } else {
            animations();
            animationCompletion(YES);
        }
    }
}

-(void)hideValidationPopupForRow:(XLFormRowDescriptor*)formRow forced:(BOOL)forced {
    if (   self.validationMessageViewController == nil
        || ![self.validationMessageViewController.validationStatus.rowDescriptor isEqual:formRow]) {
        return;
    }
    
    if (!forced) {
        XLFormValidationStatus *validationStatus = [self validationStatusForRow:formRow];
        if (validationStatus == nil || validationStatus.isValid) {
            forced = YES;
        }
    }
    
    if (forced) {
        [self hideValidationPopupAnimated:YES];
    }
}


-(UIView*)popoverSourceViewForCell:(UITableViewCell*)cell {
    return cell;
}

-(UIViewController<MSXLFormValidationMessageViewController>*)validationMessageViewControllerForStatus:(XLFormValidationStatus*)status inFormViewController:(XLFormViewController *)formViewController {
    UIViewController<MSXLFormValidationMessageViewController>* vc = [self.delegate respondsToSelector:@selector(validationPopupController:messageViewControllerForValidationStatus:)]
        ? [self.delegate validationPopupController:self messageViewControllerForValidationStatus:status]
        : nil;
    if (vc == nil) {
        MSXLFormValidationPopupViewController *validationPVC = [[MSXLFormValidationPopupViewController alloc] init];
        CGFloat width = formViewController.tableView.bounds.size.width;
        if ([formViewController.tableView respondsToSelector:@selector(safeAreaLayoutGuide)]) {
            CGFloat safeAreaWidth = formViewController.tableView.safeAreaLayoutGuide.layoutFrame.size.width;
            width = MIN(width, safeAreaWidth);
            validationPVC.maximumSize = CGSizeMake(width, UIViewNoIntrinsicMetric);
        }
        validationPVC.minimumSize = CGSizeMake(width, 44.f); // there is no way to determine that magic number.
        vc = validationPVC;
    }
    vc.validationStatus = status;
    return vc;
}


#pragma mark User interaction

-(void)validationMessageViewControllerTapped:(UITapGestureRecognizer*)tapGestureRecognizer {
    [self hideValidationPopupAnimated:YES];
}




#pragma mark Validation Status generation and comparison

-(id)valueForRow:(XLFormRowDescriptor*)row {
    return [row.value respondsToSelector:@selector(formValue)] ? [row.value formValue] : row.value;
}

-(XLFormValidationStatus*)validationStatusForRow:(XLFormRowDescriptor*)row {
    id value = [self valueForRow:row];
    if (row.isRequired && (value == nil || value == [NSNull null])) {
        return [XLFormValidationStatus formValidationStatusWithMsg:row.requireMsg status:NO rowDescriptor:row];
    } else {
        XLFormValidationStatus* status = [row doValidation];
        if (status == nil || status.isValid) {
            return nil;
        } else {
            return status;
        }
    }
}

-(BOOL)isRowValid:(XLFormRowDescriptor*)row {
    return [self validationStatusForRow:row] == nil;
}

-(BOOL)isValidationStatus:(XLFormValidationStatus*)status equalTo:(XLFormValidationStatus*)other {
    if (status == nil && other == nil) {
        return YES;
    } else if ((status != nil && other == nil) || (status == nil && other != nil)) {
        return NO;
    } else {
        return [status.rowDescriptor isEqual:other.rowDescriptor]
            && status.isValid == other.isValid
            && [status.msg isEqualToString:other.msg];
    }
}




#pragma mark UIPopoverPresentationControllerDelegate

-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

-(void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController {
    if ([self.delegate respondsToSelector:@selector(validationPopupController:willPresentValidationMessageViewController:inPopoverPresentationController:)]) {
        [self.delegate validationPopupController:self willPresentValidationMessageViewController:self.validationMessageViewController inPopoverPresentationController:popoverPresentationController];
    }
    popoverPresentationController.containerView.alpha = 0;
}

-(void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    self.validationMessageViewController = nil;
}

@end
