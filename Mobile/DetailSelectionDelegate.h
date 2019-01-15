//
//  DetailSelectionDelegate.h
//  Mobile
//
//  Created by Alan McEwan on 2/11/14.
//  Copyright (c) 2014 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Module;
@protocol DetailSelectionDelegate <NSObject>
@required
- (void)selectedDetail:(id)newDetail withIndex:(NSIndexPath *)myIndex withModule:(Module *)myModule withController:(id)myController;

@optional
- (void)dismissMasterPopover;
- (void)overlayDisplay;
@end
