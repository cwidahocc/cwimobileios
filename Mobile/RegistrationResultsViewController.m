//
//  RegistrationResultsViewController.m
//  Mobile
//
//  Created by Jason Hocker on 12/6/13.
//  Copyright (c) 2013 - 2014 Ellucian. All rights reserved.
//

#import "RegistrationResultsViewController.h"
#import "RegistrationTabBarController.h"
#import "Module.h"
#import "Ellucian_GO-Swift.h"

@interface RegistrationResultsViewController ()

@end

@implementation RegistrationResultsViewController

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self sendView:@"Registration Results" moduleName:self.module.name];
}

- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return [self.importantMessages count];
            break;
        case 1:
            return [self.registeredMessages count];
            break;
        case 2:
            return [self.warningMessages count];
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView configureCell:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell;
    switch([indexPath section])
    {
        case 0:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"Registration Message Cell"];
            UILabel *label = (UILabel *)[cell viewWithTag:1];
            NSDictionary *selected = [self.importantMessages objectAtIndex:[indexPath row]];
            label.text = [selected objectForKey:@"message"];
            break;
        }
        case 1:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"Registration Message For Planned Course Cell"];
            NSDictionary *selected = [self.registeredMessages objectAtIndex:[indexPath row]];
            UILabel *label = (UILabel *)[cell viewWithTag:3];
            label.textColor = [UIColor colorWithRed:57/255.0f green:181/255.0f blue:74/255.0f alpha:1.0f]; //green
            NSArray *messages = [selected objectForKey:@"messages"];
            NSMutableArray *messagesArray = [NSMutableArray new];
            for(NSDictionary *dict in messages) {
                [messagesArray addObject:[dict objectForKey:@"message"]];
            }
            NSString *message =  [messagesArray componentsJoinedByString:@"\n\n"];
            if([message length] > 0) message = [NSString stringWithFormat:@"! %@", message];
            label.text = message;
            UILabel *courseNameLabel = (UILabel *)[cell viewWithTag:1];
            courseNameLabel.text = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"course name-section number", @"Localizable", [NSBundle mainBundle], @"%@-%@", @"course name-section number"), [selected objectForKey:@"courseName"], [selected objectForKey:@"courseSectionNumber"]];
            UILabel *titleLabel = (UILabel *)[cell viewWithTag:2];
            titleLabel.text = [selected objectForKey:@"courseTitle"];
            UILabel *termLabel = (UILabel *)[cell viewWithTag:4];
            NSString* termId = [selected objectForKey:@"termId"];
            termLabel.text = [self.delegate termName:termId];

            break;
        }
        case 2:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"Registration Message For Planned Course Cell"];
            NSDictionary *selected = [self.warningMessages objectAtIndex:[indexPath row]];
            UILabel *label = (UILabel *)[cell viewWithTag:3];
            label.textColor = [UIColor colorWithRed:237/255.0f green:28/255.0f blue:36/255.0f alpha:1.0f]; //red
            NSArray *messages = [selected objectForKey:@"messages"];
            NSMutableArray *messagesArray = [NSMutableArray new];
            for(NSDictionary *dict in messages) {
                [messagesArray addObject:[dict objectForKey:@"message"]];
            }
            NSString *message =  [messagesArray componentsJoinedByString:@"\n\n"];
            if([message length] > 0) message = [NSString stringWithFormat:@"! %@", message];
            label.text = message;
            UILabel *courseNameLabel = (UILabel *)[cell viewWithTag:1];
            courseNameLabel.text = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"course name-section number", @"Localizable", [NSBundle mainBundle], @"%@-%@", @"course name-section number"), [selected objectForKey:@"courseName"], [selected objectForKey:@"courseSectionNumber"]];
            UILabel *titleLabel = (UILabel *)[cell viewWithTag:2];
            titleLabel.text = [selected objectForKey:@"courseTitle"];
            UILabel *termLabel = (UILabel *)[cell viewWithTag:4];
            NSString* termId = [selected objectForKey:@"termId"];
            termLabel.text = [self.delegate termName:termId];

            break;
        }
    }
    [cell.contentView setNeedsLayout];
    [cell.contentView layoutIfNeeded];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableView:tableView configureCell:indexPath];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableView:tableView configureCell:indexPath];
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    return height + 14;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0f;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	NSInteger rowCount = [self tableView:tableView numberOfRowsInSection:section];
    if(rowCount > 0) {
        switch(section) {
            case 0:
                return 80.0f;
            case 1:
                return 42.0f;
            case 2:
                return 60.0f;
        }
        
    }
    return 0.0f;
}

#pragma mark - custom headers
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    switch(section)
    {
        case 0:
            return [self resultsHeader:tableView];
        case 1:
            return [self successResultsHeader:tableView];
        case 2:
            return[self failureResultsHeader:tableView];
    }
    return nil;
}

- (UIView *)resultsHeader:(UITableView *)tableView
{
    UIView* h = [UIView new];
    h.opaque = NO;
    h.backgroundColor = [UIColor whiteColor];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [h addSubview:imageView];
    
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [h addSubview:label];
    
    UILabel *label2 = [[UILabel alloc] init];
    label2.numberOfLines = 0;
    label2.translatesAutoresizingMaskIntoConstraints = NO;
    [h addSubview:label2];

    UIEdgeInsets separatorInset = [tableView separatorInset];
    UIView *bottom = [[UIView alloc]initWithFrame:CGRectMake(separatorInset.left, 80, 9999, 1)];
    UIColor *separatorColor = [tableView separatorColor];
    [bottom setBackgroundColor:separatorColor];
    [h addSubview:bottom];

    imageView.image = [UIImage imageNamed:@"Registration Results Status Important"];
    label.textColor = [UIColor colorWithRed:251/255.0f green:174/255.0f blue:23/255.0f alpha:1.0f];
    label.text = NSLocalizedString(@"Critical", @"message for heading of messages during registration");
    label2.text = NSLocalizedString(@"These issues may have prevented registration.", @"second message for heading of failed registered classes");
    
    NSDictionary *views = NSDictionaryOfVariableBindings(imageView, label, label2);
    
    [h addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[imageView]-10-[label]-10-|"
                                             options:0 metrics:nil
                                               views:views]];
    [h addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-42-[label2]-10-|"
                                             options:0 metrics:nil
                                               views:views]];
    [h addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-6-[label][label2]-6-|"
                                             options:0 metrics:nil
                                               views:views]];
    
    [h addConstraint: [NSLayoutConstraint constraintWithItem:imageView
                                                   attribute:NSLayoutAttributeCenterY
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:h
                                                   attribute:NSLayoutAttributeCenterY
                                                  multiplier:1.0
                                                    constant:0]];
    [h addConstraint: [NSLayoutConstraint
                       constraintWithItem:imageView
                       attribute:NSLayoutAttributeWidth
                       relatedBy:NSLayoutRelationEqual
                       toItem: nil
                       attribute:NSLayoutAttributeNotAnAttribute
                       multiplier:1.0f
                       constant:22.0f]];
    [h addConstraint: [NSLayoutConstraint
                       constraintWithItem:imageView
                       attribute:NSLayoutAttributeHeight
                       relatedBy:NSLayoutRelationEqual
                       toItem: nil
                       attribute:NSLayoutAttributeNotAnAttribute
                       multiplier:1.0f
                       constant:22.0f]];
    
    return h;
    
}

- (UIView *)successResultsHeader:(UITableView *)tableView
{
    UIView* h = [UIView new];
    h.opaque = NO;
    h.backgroundColor = [UIColor whiteColor];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [h addSubview:imageView];
    
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [h addSubview:label];
    
    UIEdgeInsets separatorInset = [tableView separatorInset];
    UIView *bottom = [[UIView alloc]initWithFrame:CGRectMake(separatorInset.left, 42, 9999, 1)];
    UIColor *separatorColor = [tableView separatorColor];
    [bottom setBackgroundColor:separatorColor];
    [h addSubview:bottom];
    
    imageView.image = [UIImage imageNamed:@"Registration Results Status Registered"];
    label.textColor = [UIColor colorWithRed:57/255.0f green:181/255.0f blue:74/255.0f alpha:1.0f];
    label.text = NSLocalizedString(@"Registered!", @"message for heading of successful registered classes");

    NSDictionary *views = NSDictionaryOfVariableBindings(imageView, label);
    
    [h addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[imageView]-10-[label]-10-|"
                                             options:0 metrics:nil
                                               views:views]];
    
    [h addConstraint: [NSLayoutConstraint constraintWithItem:label
                                                   attribute:NSLayoutAttributeCenterY
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:h
                                                   attribute:NSLayoutAttributeCenterY
                                                  multiplier:1.0
                                                    constant:0]];
    
    [h addConstraint: [NSLayoutConstraint constraintWithItem:imageView
                                                   attribute:NSLayoutAttributeCenterY
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:h
                                                   attribute:NSLayoutAttributeCenterY
                                                  multiplier:1.0
                                                    constant:0]];
    [h addConstraint: [NSLayoutConstraint
                       constraintWithItem:imageView
                       attribute:NSLayoutAttributeWidth
                       relatedBy:NSLayoutRelationEqual
                       toItem: nil
                       attribute:NSLayoutAttributeNotAnAttribute
                       multiplier:1.0f
                       constant:22.0f]];
    [h addConstraint: [NSLayoutConstraint
                       constraintWithItem:imageView
                       attribute:NSLayoutAttributeHeight
                       relatedBy:NSLayoutRelationEqual
                       toItem: nil
                       attribute:NSLayoutAttributeNotAnAttribute
                       multiplier:1.0f
                       constant:22.0f]];
    
    return h;
    
}

- (UIView *)failureResultsHeader:(UITableView *)tableView
{
    UIView* h = [UIView new];
    h.opaque = NO;
    h.backgroundColor = [UIColor whiteColor];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [h addSubview:imageView];
    
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [h addSubview:label];
    
    UILabel *label2 = [[UILabel alloc] init];
    label2.font = [UIFont systemFontOfSize:15.0f];
    label2.translatesAutoresizingMaskIntoConstraints = NO;
    label2.adjustsFontSizeToFitWidth = YES;
    [h addSubview:label2];
 
    UIEdgeInsets separatorInset = [tableView separatorInset];
    UIView *bottom = [[UIView alloc]initWithFrame:CGRectMake(separatorInset.left, 60, 9999, 1)];
    UIColor *separatorColor = [tableView separatorColor];
    [bottom setBackgroundColor:separatorColor];
    [h addSubview:bottom];

    imageView.image = [UIImage imageNamed:@"Registration Results Status Error"];
    label.textColor = [UIColor colorWithRed:237/255.0f green:28/255.0f blue:36/255.0f alpha:1.0f];
    label.text = NSLocalizedString(@"We're sorry.", @"message for heading of failed registered classes");
    label2.text = NSLocalizedString(@"We couldn't register these courses:", @"second message for heading of failed registered classes");
    
    
    NSDictionary *views = NSDictionaryOfVariableBindings(imageView, label, label2);
    
    [h addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[imageView]-10-[label]-(>=10)-|"
                                             options:0 metrics:nil
                                               views:views]];
    [h addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[imageView]-10-[label2]-(>=10)-|"
                                             options:0 metrics:nil
                                               views:views]];

    [h addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-6-[label][label2]-6-|"
                                             options:0 metrics:nil
                                               views:views]];
    
    
    [h addConstraint: [NSLayoutConstraint constraintWithItem:label
                                                   attribute:NSLayoutAttributeLeading
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:label2
                                                   attribute:NSLayoutAttributeLeading
                                                  multiplier:1.0
                                                    constant:0]];
    
    [h addConstraint: [NSLayoutConstraint constraintWithItem:imageView
                                                   attribute:NSLayoutAttributeCenterY
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:h
                                                   attribute:NSLayoutAttributeCenterY
                                                  multiplier:1.0
                                                    constant:0]];
    [h addConstraint: [NSLayoutConstraint
                       constraintWithItem:imageView
                       attribute:NSLayoutAttributeWidth
                       relatedBy:NSLayoutRelationEqual
                       toItem: nil
                       attribute:NSLayoutAttributeNotAnAttribute
                       multiplier:1.0f
                       constant:22.0f]];
    [h addConstraint: [NSLayoutConstraint
                       constraintWithItem:imageView
                       attribute:NSLayoutAttributeHeight
                       relatedBy:NSLayoutRelationEqual
                       toItem: nil
                       attribute:NSLayoutAttributeNotAnAttribute
                       multiplier:1.0f
                       constant:22.0f]];
    
    return h;
    
}

@end
