/*
 * Copyright (c) 2010-2020 Belledonne Communications SARL.
 *
 * This file is part of linphone-iphone
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#import "StatusBarView.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import <UserNotifications/UserNotifications.h>

@implementation StatusBarView {

	NSTimer *callQualityTimer;
	NSTimer *callSecurityTimer;
	int messagesUnreadCount;
}

#pragma mark - Lifecycle Functions

- (void)dealloc {
	[NSNotificationCenter.defaultCenter removeObserver:self];
	[callQualityTimer invalidate];
}

#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	// Set observer
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(registrationUpdate:)
											   name:kLinphoneRegistrationUpdate
											 object:nil];

	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(globalStateUpdate:)
											   name:kLinphoneGlobalStateUpdate
											 object:nil];

	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(notifyReceived:)
											   name:kLinphoneNotifyReceived
											 object:nil];
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(mainViewChanged:)
											   name:kLinphoneMainViewChange
											 object:nil];

	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(callUpdate:)
											   name:kLinphoneCallUpdate
											 object:nil];
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(onCallEncryptionChanged:)
											   name:kLinphoneCallEncryptionChanged
											 object:nil];
    _gate1Connected=-1;
    _gate2Connected=-1;
    
    [ self updateGatesReachabilityStatus ];
	
	[self updateUI:linphone_core_get_calls_nb(LC)];
	[self updateVoicemail];
    

    [self generalStatusUpdate];
    
       if (_gateCountingTimer) {
           [_gateCountingTimer invalidate];
           _gateCountingTimer = nil;
       }
       
       _gateCountingTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                     target:self
                                     selector:@selector(updateGatesReachabilityStatus)
                                     userInfo:nil
                                     repeats:YES];
}
- (void) updateGatesReachabilityStatus {
    //LOGI(@"-------------- update Gates Status ----------------------");
    [self generalStatusUpdate];
    
    NSString *door1Host=[LinphoneManager.instance lpConfigStringForKey:@"door1_host" inSection:@"doorphone" withDefault:@"unknown"];

    NSString *door2Host=[LinphoneManager.instance lpConfigStringForKey:@"door2_host" inSection:@"doorphone" withDefault:@"unknown"];

    NSString *healthTemplate=[LinphoneManager.instance lpConfigStringForKey:@"door_health_template" inSection:@"doorphone" withDefault:@"unknown"];

    NSURL *gate1HealthUrl=[NSURL URLWithString: [NSString stringWithFormat:healthTemplate, door1Host]];

    NSURL *gate2HealthUrl=[NSURL URLWithString: [NSString stringWithFormat:healthTemplate, door2Host]];

    NSURLRequest *gate1Request = [[NSURLRequest alloc] initWithURL:gate1HealthUrl];
    NSURLRequest *gate2Request = [[NSURLRequest alloc] initWithURL:gate2HealthUrl];
    
    [NSURLConnection sendAsynchronousRequest:gate1Request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                            
        NSString *responseData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        //LOGI(@"--- Gate1 Async Response: %@",responseData);
        if ([responseData hasPrefix:@"Healthy!"]){
            _gate1Connected=1;
            //LOGI(@"--- Gate1 Connected-----------");
        } else {
            _gate1Connected=0;
            //LOGI(@"--- Gate1 DisConnected-----------");
        }
    }];

    [NSURLConnection sendAsynchronousRequest:gate2Request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSString *responseData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        //LOGI(@"--- Gate2 Async Response: %@",responseData);
        if ([responseData hasPrefix:@"Healthy!"]){
            _gate2Connected=1;
            //LOGI(@"--- Gate2 Connected-----------");
        } else {
            _gate2Connected=0;
            //LOGI(@"--- Gate2 DisConnected-----------");
        }
    }];

}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	// Remove observer
	[NSNotificationCenter.defaultCenter removeObserver:self name:kLinphoneRegistrationUpdate object:nil];
	[NSNotificationCenter.defaultCenter removeObserver:self name:kLinphoneGlobalStateUpdate object:nil];
	[NSNotificationCenter.defaultCenter removeObserver:self name:kLinphoneNotifyReceived object:nil];
	[NSNotificationCenter.defaultCenter removeObserver:self name:kLinphoneCallUpdate object:nil];
	[NSNotificationCenter.defaultCenter removeObserver:self name:kLinphoneMainViewChange object:nil];

	if (callQualityTimer != nil) {
		[callQualityTimer invalidate];
		callQualityTimer = nil;
	}
	if (callSecurityTimer != nil) {
		[callSecurityTimer invalidate];
		callSecurityTimer = nil;
	}

	if (securityDialog != nil) {
		[securityDialog dismiss];
		securityDialog = nil;
	}
    
    if (_gateCountingTimer) {
        [_gateCountingTimer invalidate];
        _gateCountingTimer = nil;
    }

}

#pragma mark - Event Functions

- (void)registrationUpdate:(NSNotification *)notif {
	//LinphoneProxyConfig *config = linphone_core_get_default_proxy_config(LC);
	[self generalStatusUpdate];
}

- (void)globalStateUpdate:(NSNotification *)notif {
	[self registrationUpdate:nil];
}

- (void)mainViewChanged:(NSNotification *)notif {
	[self registrationUpdate:nil];
}

- (void)onCallEncryptionChanged:(NSNotification *)notif {
	LinphoneCall *call = linphone_core_get_current_call(LC);

	if (call && (linphone_call_params_get_media_encryption(linphone_call_get_current_params(call)) ==
				 LinphoneMediaEncryptionZRTP) &&
		(!linphone_call_get_authentication_token_verified(call))) {
		[self onSecurityClick:nil];
	}
}

- (void)notifyReceived:(NSNotification *)notif {
	const LinphoneContent *content = [[notif.userInfo objectForKey:@"content"] pointerValue];

	if ((content == NULL) || (strcmp("application", linphone_content_get_type(content)) != 0) ||
		(strcmp("simple-message-summary", linphone_content_get_subtype(content)) != 0) ||
		(linphone_content_get_buffer(content) == NULL)) {
		return;
	}
	const uint8_t *bodyTmp = linphone_content_get_buffer(content);
	const char *body = (const char *)bodyTmp;
	if ((body = strstr(body, "voice-message: ")) == NULL) {
		LOGW(@"Received new NOTIFY from voice mail but could not find 'voice-message' in BODY. Ignoring it.");
		return;
	}

	sscanf((const char *)body, "voice-message: %d", &messagesUnreadCount);

	LOGI(@"Received new NOTIFY from voice mail: there is/are now %d message(s) unread", messagesUnreadCount);

	// save in lpconfig for future
	lp_config_set_int(linphone_core_get_config(LC), "app", "voice_mail_messages_count", messagesUnreadCount);

	[self updateVoicemail];
}

- (void)updateVoicemail {
	_voicemailButton.hidden = (messagesUnreadCount <= 0);
	_voicemailButton.titleLabel.text = @(messagesUnreadCount).stringValue;
}

- (void)callUpdate:(NSNotification *)notif {
	// show voice mail only when there is no call
	[self updateUI:linphone_core_get_calls(LC) != NULL];
	[self updateVoicemail];
}

#pragma mark -
- (void)generalStatusUpdate {
    NSString *message = nil;
    int count=0;
    UIImage * led;
    
    if (_gate1Connected==1) count++;
    if (_gate2Connected==1) count++;
    //LOGI(@"--- Gate Count %d-----------",count);
    
    if (_gate1Connected==-1 || _gate2Connected==-1){
        message = @"Checking Gates Connectivity...";
        led = [UIImage imageNamed:@"led_disconnected.png"];
    } else if (count == 0){
        message = @"Gates Unreachable!";
        led = [UIImage imageNamed:@"led_error.png"];
    } else if (count ==1){
        message = [NSString stringWithFormat:@"1 of 2 Gates Connected"];
        led = [UIImage imageNamed:@"led_semi_connected.png"];
    } else {
        message = [NSString stringWithFormat:@"2 Gates Connected"];
        led = [UIImage imageNamed:@"led_connected.png"];
    }
    
    [_registrationState setTitle:message forState:UIControlStateNormal];
    _registrationState.accessibilityValue = message;
    [_registrationState setImage:led forState:UIControlStateNormal];
}

#pragma mark -

- (void)updateUI:(BOOL)inCall {
	BOOL hasChanged = (_outcallView.hidden != inCall);

	_outcallView.hidden = inCall;
	_incallView.hidden = !inCall;

	if (!hasChanged)
		return;

	if (callQualityTimer) {
		[callQualityTimer invalidate];
		callQualityTimer = nil;
	}
	if (callSecurityTimer) {
		[callSecurityTimer invalidate];
		callSecurityTimer = nil;
	}
	if (securityDialog) {
		[securityDialog dismiss];
	}

	// if we are in call, we have to update quality and security icons every sec
	if (inCall) {
		callQualityTimer = [NSTimer scheduledTimerWithTimeInterval:1
															target:self
														  selector:@selector(callQualityUpdate)
														  userInfo:nil
														   repeats:YES];
		callSecurityTimer = [NSTimer scheduledTimerWithTimeInterval:1
															 target:self
														   selector:@selector(callSecurityUpdate)
														   userInfo:nil
															repeats:YES];
	}
}

- (void)callSecurityUpdate {
	BOOL pending = false;
	BOOL security = true;

	const MSList *list = linphone_core_get_calls(LC);
	if (list == NULL) {
		if (securityDialog) {
			[securityDialog dismiss];
		}
	} else {
		_callSecurityButton.hidden = NO;
		while (list != NULL) {
			LinphoneCall *call = (LinphoneCall *)list->data;
			LinphoneMediaEncryption enc =
				linphone_call_params_get_media_encryption(linphone_call_get_current_params(call));
			if (enc == LinphoneMediaEncryptionNone)
				security = false;
			else if (enc == LinphoneMediaEncryptionZRTP) {
				if (!linphone_call_get_authentication_token_verified(call)) {
					pending = true;
				}
			}
			list = list->next;
		}
		NSString *imageName =
			(security ? (pending ? @"security_pending.png" : @"security_ok.png") : @"security_ko.png");
		[_callSecurityButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
	}
}

- (void)callQualityUpdate {
	LinphoneCall *call = linphone_core_get_current_call(LC);
	if (call != NULL) {
		int quality = MIN(4, floor(linphone_call_get_current_quality(call)));
		NSString *accessibilityValue = [NSString stringWithFormat:NSLocalizedString(@"Call quality: %d", nil), quality];
		if (![accessibilityValue isEqualToString:_callQualityButton.accessibilityValue]) {
			_callQualityButton.accessibilityValue = accessibilityValue;
			_callQualityButton.hidden = NO; //(quality == -1.f);
			UIImage *image =
				(quality == -1.f)
					? [UIImage imageNamed:@"call_quality_indicator_0.png"] // nil
					: [UIImage imageNamed:[NSString stringWithFormat:@"call_quality_indicator_%d.png", quality]];
			[_callQualityButton setImage:image forState:UIControlStateNormal];
		}
	}
}

#pragma mark - Action Functions

- (IBAction)onSecurityClick:(id)sender {
	if (linphone_core_get_calls_nb(LC)) {
		LinphoneCall *call = linphone_core_get_current_call(LC);
		if (call != NULL) {
			LinphoneMediaEncryption enc =
				linphone_call_params_get_media_encryption(linphone_call_get_current_params(call));
			if (enc == LinphoneMediaEncryptionZRTP) {
				NSString *code = [NSString stringWithUTF8String:linphone_call_get_authentication_token(call)];
				NSString *myCode;
				NSString *correspondantCode;
				if (linphone_call_get_dir(call) == LinphoneCallIncoming) {
					myCode = [code substringToIndex:2];
					correspondantCode = [code substringFromIndex:2];
				} else {
					correspondantCode = [code substringToIndex:2];
					myCode = [code substringFromIndex:2];
				}
				NSString *message =
					[NSString stringWithFormat:NSLocalizedString(@"\nConfirmation security\n\n"
                                                                 @"Say: %@\n"
                                                                 @"Confirm that your interlocutor\n"
																 @"says: %@",
																 nil),
											   myCode.uppercaseString, correspondantCode.uppercaseString];
                
				if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive &&
					floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max) {
					UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
					content.title = NSLocalizedString(@"ZRTP verification", nil);
					content.body = message;
					content.categoryIdentifier = @"zrtp_request";
					content.userInfo = @{
						@"CallId" : [NSString
							stringWithUTF8String:linphone_call_log_get_call_id(linphone_call_get_call_log(call))]
					};

					UNNotificationRequest *req =
						[UNNotificationRequest requestWithIdentifier:@"zrtp_request" content:content trigger:NULL];
					[[UNUserNotificationCenter currentNotificationCenter]
						addNotificationRequest:req
						 withCompletionHandler:^(NSError *_Nullable error) {
						   // Enable or disable features based on authorization.
						   if (error) {
							   LOGD(@"Error while adding notification request :");
							   LOGD(error.description);
						   }
						 }];
				} else {
					if (securityDialog == nil) {
						__block __strong StatusBarView *weakSelf = self;
                        // define font of message
                        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:message];
                        NSUInteger length = [message length];
                        UIFont *baseFont = [UIFont systemFontOfSize:21.0];
                        [attrString addAttribute:NSFontAttributeName value:baseFont range:NSMakeRange(0, length)];
                        UIFont *boldFont = [UIFont boldSystemFontOfSize:23.0];
                        [attrString addAttribute:NSFontAttributeName value:boldFont range:[message rangeOfString:@"Confirmation security"]];
                        UIColor *color = [UIColor colorWithRed:(150 / 255.0) green:(193 / 255.0) blue:(31 / 255.0) alpha:1.0];
                        [attrString addAttribute:NSForegroundColorAttributeName value:color range:[message rangeOfString:myCode.uppercaseString]];
                        [attrString addAttribute:NSForegroundColorAttributeName value:color range:[message rangeOfString:correspondantCode.uppercaseString]];
                        
						securityDialog = [UIConfirmationDialog ShowWithAttributedMessage:attrString
							cancelMessage:NSLocalizedString(@"DENY", nil)
							confirmMessage:NSLocalizedString(@"ACCEPT", nil)
							onCancelClick:^() {
							  if (linphone_core_get_current_call(LC) == call) {
								  linphone_call_set_authentication_token_verified(call, NO);
							  }
							  weakSelf->securityDialog = nil;
                              [LinphoneManager.instance lpConfigSetString:[NSString stringWithUTF8String:linphone_call_get_remote_address_as_string(call)] forKey:@"sas_dialog_denied"];
							}
							onConfirmationClick:^() {
							  if (linphone_core_get_current_call(LC) == call) {
								  linphone_call_set_authentication_token_verified(call, YES);
							  }
							  weakSelf->securityDialog = nil;
                                [LinphoneManager.instance lpConfigSetString:nil forKey:@"sas_dialog_denied"];
							} ];
                        
                        securityDialog.securityImage.hidden = FALSE;
						[securityDialog setSpecialColor];
					}
				}
			}
		}
	}
}

- (IBAction)onSideMenuClick:(id)sender {
	UICompositeView *cvc = PhoneMainView.instance.mainViewController;
	[cvc hideSideMenu:(cvc.sideMenuView.frame.origin.x == 0)];
}

- (IBAction)onRegistrationStateClick:(id)sender {
	if (linphone_core_get_default_proxy_config(LC)) {
		linphone_core_refresh_registers(LC);
	} else if (linphone_core_get_proxy_config_list(LC)) {
		[PhoneMainView.instance changeCurrentView:SettingsView.compositeViewDescription];
	} else {
		[PhoneMainView.instance changeCurrentView:AssistantView.compositeViewDescription];
	}
}

@end
