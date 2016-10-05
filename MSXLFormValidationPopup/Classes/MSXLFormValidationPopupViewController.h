//
//  MSXLFormValidationPopupViewController.h
//  Pods
//
//  Created by Bernhard Schandl on 30/09/2016.
//  Copyright © 2016 mySugr GmbH
//

#import <UIKit/UIKit.h>
#import "MSXLFormValidationPopupController.h"



/**
 A simple validation popup view controller. It basically shows the message of the passed-in |XLFormValidationStatus|
 object with some padding around it.
 */
@interface MSXLFormValidationPopupViewController : UIViewController <MSXLFormValidationMessageViewController>

/** 
 The minimum size that this view controller uses for its |preferredContentSize| attribute. In general, the 
 view controller will scale so that the entire validation message fits into it, as far as possible.
 */
@property (nonatomic, assign) CGSize minimumSize;

@end
