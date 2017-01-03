//
//  MSXLFormViewController.m
//  MSXLFormValidationPopup
//
//  Created by Bernhard Schandl on 09/30/2016.
//  Copyright (c) 2016 Bernhard Schandl. All rights reserved.
//

#import "MSXLFormViewController.h"

@import MSXLFormValidationPopup;





@interface SingleValueValidator : XLFormValidator

@property id value;

@end


@implementation SingleValueValidator

-(instancetype)initWithValue:(id)value {
    self = [super init];
    if (self) {
        _value = value;
    }
    return self;
}

-(XLFormValidationStatus *)isValid:(XLFormRowDescriptor *)row {
    id currentValue = row.value;
    if ([currentValue respondsToSelector:@selector(formValue)]) {
        currentValue = [currentValue formValue];
    }
    
    NSMutableString* msg = [[NSMutableString alloc] init];
    if ([currentValue respondsToSelector:@selector(length)]) {
        for (int i = 0; i < [currentValue length]; i++) {
            [msg appendString:@"This is invalid. "];
        }
    } else {
        [msg appendString:@"This is invalid."];
    }
    
    return [XLFormValidationStatus formValidationStatusWithMsg:msg status:[_value isEqual:currentValue] rowDescriptor:row];
}

@end






@interface MSXLFormViewController () <MSXLFormValidationPopupControllerDelegate>

@property MSXLFormValidationPopupController* validationPopup;

@end




@implementation MSXLFormViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    XLFormDescriptor* form = [XLFormDescriptor formDescriptor];
    form.endEditingTableViewOnScroll = NO;
    
    {
        XLFormSectionDescriptor* section = [XLFormSectionDescriptor formSectionWithTitle:@"Some placeholders to enable scrolling"];
        
        for (int i = 1; i <= 5; i++) {
            XLFormRowDescriptor* row = [XLFormRowDescriptor formRowDescriptorWithTag:[NSString stringWithFormat:@"placeholder%d", i] rowType:XLFormRowDescriptorTypeText title:[NSString stringWithFormat:@"Placeholder row %d", i]];
            [row.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
            [section addFormRow:row];
        }

        [form addFormSection:section];
    }
    
    {
        XLFormSectionDescriptor* section = [XLFormSectionDescriptor formSectionWithTitle:@"Example"];
        
        {
            XLFormRowDescriptor* row = [XLFormRowDescriptor formRowDescriptorWithTag:@"row1" rowType:XLFormRowDescriptorTypeText title:@"Row 1 (enter \"right\")"];
            [row.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
            [row addValidator:[[SingleValueValidator alloc] initWithValue:@"right"]];
            row.required = YES;
            row.requireMsg = @"Please enter the right text here.";
            [section addFormRow:row];
        }
        {
            XLFormRowDescriptor* row = [XLFormRowDescriptor formRowDescriptorWithTag:@"row2" rowType:XLFormRowDescriptorTypeText title:@"Row 2 (enter \"left\")"];
            [row.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
            [row addValidator:[[SingleValueValidator alloc] initWithValue:@"left"]];
            row.required = YES;
            row.requireMsg = @"Please enter the left text here.";
            [section addFormRow:row];
        }
        {
            XLFormRowDescriptor* row = [XLFormRowDescriptor formRowDescriptorWithTag:@"row3" rowType:XLFormRowDescriptorTypeSelectorPickerView title:@"Row 3"];
            row.selectorOptions = @[[XLFormOptionsObject formOptionsObjectWithValue:@1 displayText:@"One"],
                                    [XLFormOptionsObject formOptionsObjectWithValue:@2 displayText:@"Two"],
                                    [XLFormOptionsObject formOptionsObjectWithValue:@3 displayText:@"Three"]];
            [row addValidator:[[SingleValueValidator alloc] initWithValue:@2]];
            [section addFormRow:row];
        }
        {
            XLFormRowDescriptor* row = [XLFormRowDescriptor formRowDescriptorWithTag:@"row4" rowType:XLFormRowDescriptorTypeSelectorPush title:@"Row 4"];
            row.selectorOptions = @[[XLFormOptionsObject formOptionsObjectWithValue:@1 displayText:@"One"],
                                    [XLFormOptionsObject formOptionsObjectWithValue:@2 displayText:@"Two"],
                                    [XLFormOptionsObject formOptionsObjectWithValue:@3 displayText:@"Three"]];
            [row addValidator:[[SingleValueValidator alloc] initWithValue:@2]];
            row.required = YES;
            row.requireMsg = @"Please choose something.";
            [section addFormRow:row];
        }
        {
            XLFormRowDescriptor* row = [XLFormRowDescriptor formRowDescriptorWithTag:@"row5" rowType:XLFormRowDescriptorTypeText title:@"Row 5"];
            [row.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
            row.required = YES;
            row.requireMsg = @"This field is required.";
            [section addFormRow:row];
        }
        
        [form addFormSection:section];
    }
    {
        XLFormSectionDescriptor* section = [XLFormSectionDescriptor formSection];
        [form addFormSection:section];
        
        XLFormRowDescriptor* row = [XLFormRowDescriptor formRowDescriptorWithTag:@"button" rowType:XLFormRowDescriptorTypeButton title:@"New form"];
        row.action.viewControllerClass = self.class;
        [section addFormRow:row];
    }
    {
        XLFormSectionDescriptor* section = [XLFormSectionDescriptor formSectionWithTitle:@"Some more placeholders"];
        
        for (int i = 6; i < 15; i++) {
            XLFormRowDescriptor* row = [XLFormRowDescriptor formRowDescriptorWithTag:[NSString stringWithFormat:@"placeholder%d", i] rowType:XLFormRowDescriptorTypeText title:[NSString stringWithFormat:@"Placeholder Row %d", i]];
            [row.cellConfig setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
            [section addFormRow:row];
        }
        
        [form addFormSection:section];
    }
    
    self.form = form;
    self.form.endEditingTableViewOnScroll = NO;
    
    self.validationPopup = [[MSXLFormValidationPopupController alloc] init];
    self.validationPopup.delegate = self;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped:)];
}

-(void)dealloc {
    self.validationPopup = nil;
}

-(void)doneButtonTapped:(id)sender {
    XLFormValidationStatus *firstValidationStatus = [self firstValidationStatus];
    if (firstValidationStatus == nil) {
        [[[UIAlertView alloc] initWithTitle:@"No errors!" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    } else {
        [self.validationPopup showValidationPopupForStatus:firstValidationStatus inFormViewController:self];
    }
}

-(XLFormValidationStatus*)firstValidationStatus {
    for (XLFormSectionDescriptor *section in self.form.formSections) {
        for (XLFormRowDescriptor *row in section.formRows) {
            XLFormValidationStatus* status = [row doValidation];
            if (status != nil && ![status isValid]) {
                return status;
            }
        }
    }
    return nil;
}


#pragma mark Validation popup method forwarding

-(void)beginEditing:(XLFormRowDescriptor *)rowDescriptor {
    [super beginEditing:rowDescriptor];
    [self.validationPopup formViewController:self beginEditing:rowDescriptor];
}

-(void)endEditing:(XLFormRowDescriptor *)rowDescriptor {
    [super endEditing:rowDescriptor];
    [self.validationPopup formViewController:self endEditing:rowDescriptor];
}

-(void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)formRow oldValue:(id)oldValue newValue:(id)newValue {
    [super formRowDescriptorValueHasChanged:formRow oldValue:oldValue newValue:newValue];
    [self.validationPopup formViewController:self formRowDescriptorValueHasChanged:formRow oldValue:oldValue newValue:newValue];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.validationPopup formViewController:self viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.validationPopup formViewController:self viewWillDisappear:animated];
}

-(void)didSelectFormRow:(XLFormRowDescriptor *)formRow {
    [super didSelectFormRow:formRow];
    [self.validationPopup formViewController:self didSelectFormRow:formRow];
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.validationPopup formViewController:self viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.validationPopup formViewController:self scrollViewDidScroll:scrollView];
}


#pragma mark MSXLFormValidationPopupControllerDelegate

-(void)validationPopupController:(MSXLFormValidationPopupController *)popupController willPresentValidationInController:(UIPopoverPresentationController *)popoverPresentationController {
    popoverPresentationController.containerView.tintColor =
    popoverPresentationController.presentedViewController.view.tintColor = [UIColor redColor];
}


@end
