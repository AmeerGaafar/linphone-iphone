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

#import "UIDoor2CallButton.h"
#import "LinphoneManager.h"

#import <CoreTelephony/CTCallCenter.h>

@implementation UIDoor2CallButton

@synthesize addressField;

#pragma mark - Lifecycle Functions

- (void)initUIDoor2CallButton {
    [self addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchUpInside];
}

- (id)init {
    self = [super init];
    if (self) {
        [self initUIDoor2CallButton];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initUIDoor2CallButton];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        [self initUIDoor2CallButton];
    }
    return self;
}

#pragma mark -

- (void)touchUp:(id)sender {
    
    NSString *doorName=[LinphoneManager.instance lpConfigStringForKey:@"door2_name" inSection:@"doorphone" withDefault:@"unknown"];

    NSString *doorHost=[LinphoneManager.instance lpConfigStringForKey:@"door2_host" inSection:@"doorphone" withDefault:@"unknown"];

    NSString *addressTemplate=[LinphoneManager.instance lpConfigStringForKey:@"door_address_template" inSection:@"doorphone" withDefault:@"unknown"];
    
    NSString *address=[NSString stringWithFormat:addressTemplate, doorName,doorHost];
    
    if ([address length] > 0) {
        LinphoneAddress *addr = [LinphoneUtils normalizeSipOrPhoneAddress:address];
        [LinphoneManager.instance call:addr];
        if (addr)
            linphone_address_unref(addr);
    }

}

- (void)updateIcon {
    if (linphone_core_video_capture_enabled(LC) && linphone_core_get_video_policy(LC)->automatically_initiate) {
        [self setImage:[UIImage imageNamed:@"call_video_start_default.png"] forState:UIControlStateNormal];
        [self setImage:[UIImage imageNamed:@"call_video_start_disabled.png"] forState:UIControlStateDisabled];
    } else {
        [self setImage:[UIImage imageNamed:@"call_video_start_default.png"] forState:UIControlStateNormal];
        [self setImage:[UIImage imageNamed:@"call_video_start_disabled.png"] forState:UIControlStateDisabled];
    }

    if (CallManager.instance.nextCallIsTransfer) {
        [self setImage:[UIImage imageNamed:@"call_transfer_default.png"] forState:UIControlStateNormal];
        [self setImage:[UIImage imageNamed:@"call_transfer_disabled.png"] forState:UIControlStateDisabled];
    } else if (linphone_core_get_calls_nb(LC) > 0) {
        [self setImage:[UIImage imageNamed:@"call_add_default.png"] forState:UIControlStateNormal];
        [self setImage:[UIImage imageNamed:@"call_add_disabled.png"] forState:UIControlStateDisabled];
    }
}

@end
