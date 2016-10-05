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


#import <JGMethodSwizzler/JGMethodSwizzler.h>




@implementation XLFormViewController (PrivateExtensions)

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    // a no-op implementation to allow for swizzling. This method is not implemented by XLFormViewController, so swizzling would fail.
}

@end







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
    NSAssert(NO, @"Use -initWithFormViewController:");
    return nil;
}

-(instancetype)initWithFormViewController:(XLFormViewController *__weak)formViewController {
    self = [super init];
    if (self) {
        self.editingRowDescriptors = [NSMutableArray array];
        self.formViewController = formViewController;
        
        self.maximumScrollOffset = 88.f;
    }
    return self;
}

-(void)setFormViewController:(XLFormViewController *)formViewController {
    
    if (formViewController == _formViewController) {
        return;
    }
    
    //
    // Some cleanup
    
    [self.editingRowDescriptors removeAllObjects];
    
    if (_formViewController != nil) {
        @try { [_formViewController deswizzle]; } @catch (NSException* e) { NSLog(@"Failed to deswizzle: %@", e); }
        @try { [_formViewController.tableView removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset))]; } @catch (NSException* e) { NSLog(@"Failed to remove observer: %@", e); }
        @try { [_formViewController removeObserver:self forKeyPath:NSStringFromSelector(@selector(presentedViewController))]; } @catch (NSException* e) { NSLog(@"Failed to remove observer: %@", e); }
    }
    
    
    //
    // Observe and swizzle
    
    _formViewController = formViewController;
    
    if (_formViewController == nil) {
        return;
    }
    
    [_formViewController addObserver:self forKeyPath:NSStringFromSelector(@selector(presentedViewController)) options:NSKeyValueObservingOptionNew context:NULL];
    [_formViewController.tableView addObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) options:NSKeyValueObservingOptionNew context:NULL];
    
    typeof(self) __weak weakSelf = self;
    [_formViewController swizzleMethod:@selector(beginEditing:) withReplacement:JGMethodReplacementProviderBlock {
        return JGMethodReplacement(void, XLFormViewController*, XLFormRowDescriptor* row) {
            JGOriginalImplementation(void, row);
            [weakSelf beginEditing:row];
        };
    }];
    [_formViewController swizzleMethod:@selector(endEditing:) withReplacement:JGMethodReplacementProviderBlock {
        return JGMethodReplacement(void, XLFormViewController*, XLFormRowDescriptor* row) {
            JGOriginalImplementation(void, row);
            [weakSelf endEditing:row];
        };
    }];
    [_formViewController swizzleMethod:@selector(formRowDescriptorValueHasChanged:oldValue:newValue:) withReplacement:JGMethodReplacementProviderBlock {
        return JGMethodReplacement(void, XLFormViewController*, XLFormRowDescriptor* row, id oldValue, id newValue) {
            JGOriginalImplementation(void, row, oldValue, newValue);
            [weakSelf formRowDescriptorValueHasChanged:row oldValue:oldValue newValue:newValue];
        };
    }];
    [_formViewController swizzleMethod:@selector(viewDidAppear:) withReplacement:JGMethodReplacementProviderBlock {
        return JGMethodReplacement(void, XLFormViewController*, BOOL animated) {
            JGOriginalImplementation(void, animated);
            [weakSelf viewDidAppear:animated];
        };
    }];
    [_formViewController swizzleMethod:@selector(viewWillDisappear:) withReplacement:JGMethodReplacementProviderBlock {
        return JGMethodReplacement(void, XLFormViewController*, BOOL animated) {
            JGOriginalImplementation(void, animated);
            [weakSelf viewWillDisappear:animated];
        };
    }];
    [_formViewController swizzleMethod:@selector(didSelectFormRow:) withReplacement:JGMethodReplacementProviderBlock {
        return JGMethodReplacement(void, XLFormViewController*, XLFormRowDescriptor* row) {
            JGOriginalImplementation(void, row);
            [weakSelf didSelectFormRow:row];
        };
    }];
    [_formViewController swizzleMethod:@selector(viewWillTransitionToSize:withTransitionCoordinator:) withReplacement:JGMethodReplacementProviderBlock {
        return JGMethodReplacement(void, XLFormViewController*, CGSize size, id<UIViewControllerTransitionCoordinator> coordinator) {
            JGOriginalImplementation(void, size, coordinator);
            [weakSelf viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
        };
    }];
}

-(void)dealloc {
    _formViewController = nil;
}




#pragma mark KVO

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (object == self.formViewController) {
        if ([NSStringFromSelector(@selector(presentedViewController)) isEqualToString:keyPath]) {
            // If a popover or another view controller is being presented, we remove the validation popup
            [self hideValidationPopupAnimated:NO];
            return;
        }
    }
    if (object == self.formViewController.tableView) {
        if ([NSStringFromSelector(@selector(contentOffset)) isEqualToString:keyPath]) {
            // observe scrolling
            [self formTableViewDidScroll:self.formViewController.tableView];
            return;
        }
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


#pragma mark Swizzled XLFormViewController methods

-(void)beginEditing:(XLFormRowDescriptor*)row {
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
            [self showValidationPopupForStatus:validationStatus forceRefresh:NO];
        } else if (![self isValidationStatus:self.validationMessageViewController.validationStatus equalTo:validationStatus]) {
            [self hideValidationPopupAnimated:YES];
        }
    }
}

-(void)endEditing:(XLFormRowDescriptor*)row {
    if (row == self.lastEditingRowDescriptor) {
        self.lastEditingRowDescriptor = nil;
    }
    [self.editingRowDescriptors removeObject:row];
    [self updateValidationPopupForRow:row];
}

-(void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor*)formRow oldValue:(id)oldValue newValue:(id)newValue {
    if ([self.editingRowDescriptors containsObject:formRow]) {
        [self hideValidationPopupForRow:formRow forced:NO];
    } else if ([formRow.rowType isEqualToString:XLFormRowDescriptorTypeSlider]) {
        [self updateValidationPopupForRow:formRow];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    if (self.lastEditingRowDescriptor != nil) {
        [self updateValidationPopupForRow:self.lastEditingRowDescriptor];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [self hideValidationPopupAnimated:YES];
}

-(void)didSelectFormRow:(XLFormRowDescriptor*)row {
    self.lastEditingRowDescriptor = row;
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if (self.validationMessageViewController != nil) {
        XLFormValidationStatus *status = self.validationMessageViewController.validationStatus;
        [self hideValidationPopupAnimated:NO];
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            [self showValidationPopupForStatus:status forceRefresh:YES];
        }];
    }
}




#pragma mark show/hide/update

-(void)updateValidationPopupForRow:(XLFormRowDescriptor *)formRow {
    XLFormValidationStatus *validationStatus = [self validationStatusForRow:formRow];
    if (validationStatus != nil) {
        [self showValidationPopupForStatus:validationStatus];
    } else if ([self.validationMessageViewController.validationStatus.rowDescriptor isEqual:formRow]){
        [self hideValidationPopupAnimated:YES];
    }
}

-(void)showValidationPopupForStatus:(XLFormValidationStatus *)status {
    [self showValidationPopupForStatus:status forceRefresh:NO];
}

-(void)showValidationPopupForStatus:(XLFormValidationStatus *)status forceRefresh:(BOOL)forceRefresh {
    
    UITableViewCell *cell = [status.rowDescriptor cellForFormController:self.formViewController];
    
    if (self.validationMessageViewController != nil) {
        if (   forceRefresh
            || ![self isValidationStatus:self.validationMessageViewController.validationStatus equalTo:status]
            || self.validationMessageViewController.popoverPresentationController.sourceView != [self popoverSourceViewForCell:cell]) {
            [self hideValidationPopupAnimated:NO completion:^{
                [self showValidationPopupForStatus:status];
            }];
            return;
        } else {
            // correct popover is already shown
            return;
        }
    }
    
    UIViewController<MSXLFormValidationMessageViewController> *viewController = [self validationMessageViewControllerForStatus:status];
    [viewController.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(validationMessageViewControllerTapped:)]];
    viewController.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController* popoverPC = viewController.popoverPresentationController;
    popoverPC.delegate = self;
    popoverPC.sourceView = [self popoverSourceViewForCell:[status.rowDescriptor cellForFormController:self.formViewController]];
    popoverPC.sourceRect = popoverPC.sourceView.bounds;
    popoverPC.permittedArrowDirections = UIPopoverArrowDirectionDown;
    popoverPC.passthroughViews = @[self.formViewController.view];
    popoverPC.backgroundColor = [UIColor greenColor];
    popoverPC.popoverBackgroundViewClass = [viewController isKindOfClass:MSXLFormValidationPopupViewController.class]
        ? MSXLFormValidationPopoverBackgroundView.class
        : [self.delegate respondsToSelector:@selector(validationPopupController:backgroundViewClassForValidationStatus:)]
            ? [self.delegate validationPopupController:self backgroundViewClassForValidationStatus:status]
            : nil;
    
    popoverPC.popoverLayoutMargins = UIEdgeInsetsZero;

    self.validationMessageViewController = viewController;
    
    [(self.formViewController.navigationController ?: self.formViewController) presentViewController:viewController animated:NO completion:^{
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
        self.validationMessageViewControllerInitialOffset = self.formViewController.tableView.contentOffset.y;
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

-(UIViewController<MSXLFormValidationMessageViewController>*)validationMessageViewControllerForStatus:(XLFormValidationStatus*)status {
    UIViewController<MSXLFormValidationMessageViewController>* vc = [self.delegate respondsToSelector:@selector(validationPopupController:messageViewControllerForValidationStatus:)]
        ? [self.delegate validationPopupController:self messageViewControllerForValidationStatus:status]
        : nil;
    if (vc == nil) {
        MSXLFormValidationPopupViewController *validationPVC = [[MSXLFormValidationPopupViewController alloc] init];
        validationPVC.minimumSize = CGSizeMake(self.formViewController.tableView.bounds.size.width, 44.f); // there is no way to determine that magic number.
        vc = validationPVC;
    }
    vc.validationStatus = status;
    return vc;
}


#pragma mark User interaction

-(void)validationMessageViewControllerTapped:(UITapGestureRecognizer*)tapGestureRecognizer {
    [self hideValidationPopupAnimated:YES];
}


-(void)formTableViewDidScroll:(UITableView*)tableView {
    if (self.validationMessageViewController != nil && self.maximumScrollOffset >= 0) {
        // scroll popover
        CGRect rect = self.validationMessageViewController.popoverPresentationController.containerView.frame;
        rect.origin.y += self.validationMessageViewControllerOffset - tableView.contentOffset.y;
        self.validationMessageViewControllerOffset = tableView.contentOffset.y;
        self.validationMessageViewController.popoverPresentationController.containerView.frame = rect;
        
        if (fabs(self.validationMessageViewControllerOffset - self.validationMessageViewControllerInitialOffset) > self.maximumScrollOffset) {
            [self hideValidationPopupAnimated:YES];
        }
    }
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

@end
