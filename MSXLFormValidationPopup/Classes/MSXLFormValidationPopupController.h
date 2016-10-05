//
//  MSXLFormValidationPopupController.h
//  Pods
//
//  Created by Bernhard Schandl on 30/09/2016.
//  Copyright © 2016 mySugr GmbH
//


#import <XLForm/XLForm.h>
@class MSXLFormValidationPopupController;




/**
 Any view controller used as validation popup must implement this protocol.
 */
@protocol MSXLFormValidationMessageViewController

/**
 A reference to the form validation status this view controller is expected to display.
 It is recommended that the view controller displays the validation status message; additionally,
 the view controller may use any attribute of the status (including the row descriptor) to display
 more contextual information to the user.
 
 In case a required field is empty, XLForm usually does not provide a validation status object. This
 is done by |MSXLFormValidationMessage|, so the message view controller can still use that object
 for that case.
 */
@property (nonatomic, strong, nonnull) XLFormValidationStatus *validationStatus;

@end







/**
 The delegate for an MSXLFormValidationPopupController.
 */
@protocol MSXLFormValidationPopupControllerDelegate

/**
 This method gives the delegate the option to provide a different view controller that is used for 
 displaying the validation popup. This view controller must conform to the |MSXLFormValidationMessageViewController|
 protocol. If this method is not implemented, or nil is returned, the default view controller is used.
 */
@optional
-(UIViewController<MSXLFormValidationMessageViewController> * _Nonnull)validationPopupController:(MSXLFormValidationPopupController * _Nonnull)popupController
                                                        messageViewControllerForValidationStatus:(XLFormValidationStatus * _Nonnull)validationStatus;

/**
 This method gives the delegate the option to provide a custom background view class for the validation
 popup. See documentation for |UIPopoverPresentationController| for more information on this topic.
 If this is not implemented, or nil is returned, the default background view class is used.
 */
@optional
-(Class _Nonnull)validationPopupController:(MSXLFormValidationPopupController * _Nonnull)popupController
    backgroundViewClassForValidationStatus:(XLFormValidationStatus * _Nonnull)validationSstatus;

/**
 This method is called immediately before a validation popup is being displayed. It gives the delegate
 the option to perform last-moment customization of the view controller. It also allows the delegate
 to customize the default popups, in case no custom view controller is used.
 */
@optional
-(void)validationPopupController:(MSXLFormValidationPopupController * _Nonnull)popupController
    willPresentValidationMessageViewController:(UIViewController<MSXLFormValidationMessageViewController> * _Nonnull)validationMessageViewController
               inPopoverPresentationController:(UIPopoverPresentationController * _Nonnull)popoverPresentationController;

@end






/**
 The core class of the MSXLFormValidationPopup framework. This class associates a validation popover
 to a provided |XLFormViewController|. It uses |XLForm|'s built-in mechanisms (ie., required fields and
 validators) on individual fields. It shows an error popup when a user finishes editing a value, and 
 that value is missing (if it is required) or invalid. The popup is removed 1) when the user edits another
 field, 2) scrolls more than specified by |scrollOffsetLimit|, 3) taps on the popover, or 4) enters a correct value 
 into the field.
 */
@interface MSXLFormValidationPopupController : NSObject

/**
 Initialize a popup controller.
 @param formViewController an |XLFormViewController| that this popup controller will be bound to.
 */
-(instancetype _Nonnull)initWithFormViewController:(__unsafe_unretained XLFormViewController * _Nonnull)formViewController NS_DESIGNATED_INITIALIZER;

/**
 The form view controller that this popup controller is bound to. This should be set to nil
 when the form view controller is being deallocated.
 */
@property (nonatomic, unsafe_unretained) XLFormViewController *formViewController;

/**
 The delegate for this popup controller.
 */
@property (nonatomic, weak, nullable) NSObject<MSXLFormValidationPopupControllerDelegate>* delegate;

/**
 The maximum scroll offset for the form's table view. If the view is scrolled more than this amount,
 the validation popover will be dismissed. Default value is 88; set to a negative value to disable
 hide on scroll.
 */
@property (nonatomic, assign) CGFloat maximumScrollOffset;

/**
 Enforces display of a validation popup for the given status. If it's already displayed, nothing will change.
 If a popup for a different validation status is shown, that one will disappear first.
 */
-(void)showValidationPopupForStatus:(XLFormValidationStatus * _Nonnull)status;

/**
 Enforces hiding of a currently displayed validation popup.
 */
-(void)hideValidationPopupAnimated:(BOOL)animated;

@end
