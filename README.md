# MSXLFormValidationPopup

A simple validation message popup extension for [XLForm](https://github.com/xmartlabs/XLForm).


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.



## Installation

MSXLFormValidationPopup is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "MSXLFormValidationPopup"
```


## Usage

### Integration
In your view controller (which will be a subclass of `XLFormViewController`), after setting up the form, instantiate a validation popup (keep a strong reference so it won't get deallocated right away):

```objc
@property (nonatomic) MSXLFormValidationPopupController *validationPopup;

[...]

XLFormDescriptor *form = [XLFormDescriptor formDescriptor];
[...]
self.form = form;

self.validationPopup = [[MSXLFormValidationPopupController alloc] init];
```

Do not re-use this instance for other forms, since it will maintain some internal state. If you have multiple forms, use multiple instances of `MSXLFormValidationPopupController`.

Then, you need to forward several methods of your form view controller to the popup controller after your own implementation, so that it can react accordingly. For instance, you need to forward `-viewDidAppear:`:

```objc
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // do your own stuff here ...
    [self.validationPopup formViewController:self viewDidAppear:animated];
}
```

These are all the methods you need to forward:

* `-beginEditing:`
* `-endEditing:`
* `-formRowDescriptorValueHasChanged:oldValue:newValue:`
* `-viewDidAppear:`
* `-viewWillDisappear:`
* `-didSelectFormRow:`
* `-viewWillTransitionToSize:withTransitionCoordinator:`
* `-scrollViewDidScroll:`

Make sure they all get forwarded, otherwise the validatio popup will likely not work correctly.

### Appearance
By default, a popup will be shown on top of a XLForm table view cell, that reflects its error state. It considers [required fields](https://github.com/xmartlabs/XLForm#additional-configuration-of-rows) (`rowDescriptor.requireMsg`) as well as XLForm's [validation framework](https://github.com/xmartlabs/XLForm#validations) (messages returned by associated `XLFormValidator`s).

If you want to customize the popup, register a delegate for the validation popup controller, and implement the `MSXLFormValidationPopupControllerDelegate` protocol:

```objc
self.validationPopup = self;
``` 

To customize the appearance of the default popup, implement the `validationPopupController:willPresentValidationInController:` method:

```objc
-(void)validationPopupController:(MSXLFormValidationPopupController *)popupController willPresentValidationInController:(UIPopoverPresentationController *)popoverPresentationController {
    popoverPresentationController.containerView.tintColor =
    popoverPresentationController.presentedViewController.view.tintColor = [UIColor redColor];
}
```

If you want full control over the popup, you can provide a custom view controller (which must additionally conform to the `MSXLFormValidationMessageViewController`) via the `validationPopupController:messageViewControllerForValidationStatus:` method:

```objc
-(UIViewController<MSXLFormValidationMessageViewController> *)validationPopupController:(MSXLFormValidationPopupController * )popupController messageViewControllerForValidationStatus:(XLFormValidationStatus *)validationStatus {
    return [[MyCustomViewController alloc] initWithStatus:validationStatus];
}
```

In that case you might also provide a custom background view class for the popover controller:

```obj
-(Class)validationPopupController:(MSXLFormValidationPopupController *)popupController backgroundViewClassForValidationStatus:(XLFormValidationStatus *)validationSstatus {
    return MyCustomBackgroundView.class;
}

```



## License

MSXLFormValidationPopup is available under the MIT license. See the LICENSE file for more info.
