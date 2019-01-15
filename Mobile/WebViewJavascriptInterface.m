//
//  WebViewJavascriptLibrary.m
//  Mobile
//
//  Created by Jason Hocker on 10/23/14.
//  Copyright (c) 2014 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import "WebViewJavascriptInterface.h"
#import "Module.h"

#import "Ellucian_GO-Swift.h"

@implementation WebViewJavascriptInterface

+ (void) log:(NSString *)message
{
    NSLog(@"%@", message);
}

+ (BOOL) refreshRoles
{
    __block NSInteger success;
    if ([NSThread isMainThread]) {
        success = [LoginExecutor getUserInfo:YES];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            success = [LoginExecutor getUserInfo:YES];
        });
    }
    return success == 200;
}

+ (void) openMenuItem:(NSString *)name type:(NSString *)type
{
    OpenModuleOperation* operation = [[OpenModuleOperation alloc] initWithName:name type:type];
    [[NSOperationQueue mainQueue] addOperation:operation];
}

+ (void) reloadWebModule
{
    UIWebView *webView = self.webViewController.webView;
    [webView loadRequest:[NSURLRequest requestWithURL:self.webViewController.originalUrlCopy]];
}

+ (ECSlidingViewController *) slidingViewController
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return appDelegate.slidingViewController;
}

+ (WebViewController *) webViewController
{
    id topController= [self slidingViewController].topViewController;
    if ([topController isKindOfClass:[WebViewController class]]) {
        return (WebViewController *)topController;
    } else if ([topController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)topController;
        WebViewController *webViewController = [[navigationController childViewControllers] lastObject];
        return webViewController;
    } else if ([topController isKindOfClass:[UISplitViewController class]]) {
        UISplitViewController *splitViewController = (UISplitViewController *)topController;
        id detailController = splitViewController.childViewControllers[1];
        if ([detailController isKindOfClass:[WebViewController class]]) {
            return (WebViewController *)detailController;
        } else if ([detailController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navigationController = (UINavigationController *)detailController;
            WebViewController *webViewController = [[navigationController childViewControllers] lastObject];
            return webViewController;
        }
    }
    return nil;
}

//Ellucian Mobile 4.5
+ (NSString *) primaryColor
{
    return [[UIColor primary] toHexString];
}

+ (NSString *) headerTextColor
{
    return [[UIColor headerText] toHexString];
}

+ (NSString *) accentColor
{
    return [[UIColor accent] toHexString];
}

+ (NSString *) subheaderTextColor
{
    return [[UIColor subheaderText] toHexString];
}


@end
