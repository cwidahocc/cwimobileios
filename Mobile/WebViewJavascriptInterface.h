//
//  WebViewJavascriptInterface.h
//  Mobile
//
//  Created by Jason Hocker on 10/23/14.
//  Copyright (c) 2014 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol WebViewJavascriptExports<JSExport>

// Logs a message to the native app's log
+ (void) log:(NSString *) message;

// Synchronously call to get roles.  Returns a success flag.
+ (BOOL) refreshRoles;

// Open the first menu item found with that name and type.  Exported as "openMenu" to the javascript.
JSExportAs(openMenu, + (void) openMenuItem:(id)name type:(id)type);

//Causes the web frame to load the original URL defined for this module.
+ (void) reloadWebModule;

+ (NSString *) primaryColor;
+ (NSString *) headerTextColor;
+ (NSString *) accentColor;
+ (NSString *) subheaderTextColor;
           
@end

@interface WebViewJavascriptInterface : NSObject<WebViewJavascriptExports>

@end
