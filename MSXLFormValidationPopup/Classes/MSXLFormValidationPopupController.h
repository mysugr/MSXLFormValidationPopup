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
 A simple flag to activate / deactivate the popup. If set to NO, the controller will never show a popup.
 It's YES by default.
 */
@property (nonatomic, assign, getter=isActive) BOOL active;

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
-(void)showValidationPopupForStatus:(XLFormValidationStatus * _Nonnull)status inFormViewController:(XLFormViewController * _Nonnull)formViewController;

/**
 Enforces hiding of a currently displayed validation popup.
 */
-(void)hideValidationPopupAnimated:(BOOL)animated;


/**
 Forward methods for the hosting view controller. All the methods should be forwarded from the XLFormViewController, after doing any custom actions.
 */

-(void)formViewController:(XLFormViewController * _Nonnull)formViewController beginEditing:(XLFormRowDescriptor * _Nonnull)row;
-(void)formViewController:(XLFormViewController * _Nonnull)formViewController endEditing:(XLFormRowDescriptor * _Nonnull)row;
-(void)formViewController:(XLFormViewController * _Nonnull)formViewController formRowDescriptorValueHasChanged:(XLFormRowDescriptor * _Nonnull)formRow oldValue:(id _Nullable)oldValue newValue:(id _Nullable)newValue;
-(void)formViewController:(XLFormViewController * _Nonnull)formViewController viewDidAppear:(BOOL)animated;
-(void)formViewController:(XLFormViewController * _Nonnull)formViewController viewWillDisappear:(BOOL)animated;
-(void)formViewController:(XLFormViewController * _Nonnull)formViewController didSelectFormRow:(XLFormRowDescriptor * _Nonnull)row;
-(void)formViewController:(XLFormViewController * _Nonnull)formViewController viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator> _Nonnull)coordinator;
-(void)formViewController:(XLFormViewController * _Nonnull)formViewController scrollViewDidScroll:(UIScrollView * _Nonnull)scrollView;

@end
