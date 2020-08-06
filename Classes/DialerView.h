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

#import <UIKit/UIKit.h>

#import "UICompositeView.h"

#import "UICamSwitch.h"
#import "UICallButton.h"
#import "UIDigitButton.h"
#import "UIOpenDoorButton.h"

@interface DialerView
	: TPMultiLayoutViewController <UITextFieldDelegate, UICompositeViewDelegate, MFMailComposeViewControllerDelegate> {
        NSTimer *picsUpdateTimer;
        NSTimer *callStatusUpdateTimer;
}

@property(nonatomic, strong) IBOutlet UIImageView *door1Picture;
@property(nonatomic, strong) IBOutlet UIImageView *door2Picture;
@property(nonatomic, strong) IBOutlet UITextField *addressField;
@property(nonatomic, strong) IBOutlet UIButton *addContactButton;
@property(nonatomic, strong) IBOutlet UICallButton *callButton;
@property(nonatomic, strong) IBOutlet UIButton *backButton;
@property(weak, nonatomic) IBOutlet UIButton *backspaceButton;

@property(nonatomic, strong) IBOutlet UIDigitButton *oneButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *twoButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *threeButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *fourButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *fiveButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *sixButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *sevenButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *eightButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *nineButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *starButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *zeroButton;
@property(nonatomic, strong) IBOutlet UIDigitButton *hashButton;
@property(nonatomic, strong) IBOutlet UIView *backgroundView;
@property(nonatomic, strong) IBOutlet UIView *videoPreview;
@property(nonatomic, strong) IBOutlet UICamSwitch *videoCameraSwitch;
@property(weak, nonatomic) IBOutlet UIView *padView;

@property(weak, nonatomic) IBOutlet UIRoundedImageView *gate1Talked;
@property(weak, nonatomic) IBOutlet UIRoundedImageView *gate1OpenedGate;
@property(weak, nonatomic) IBOutlet UIRoundedImageView *gate1Talking;
@property(weak, nonatomic) IBOutlet UIRoundedImageView *gate1Unanswered;

@property(weak, nonatomic) IBOutlet UIRoundedImageView *gate2Talked;
@property(weak, nonatomic) IBOutlet UIRoundedImageView *gate2OpenedGate;
@property(weak, nonatomic) IBOutlet UIRoundedImageView *gate2Talking;
@property(weak, nonatomic) IBOutlet UIRoundedImageView *gate2Unanswered;

@property(weak, nonatomic) IBOutlet UIOpenDoorButton *door1OpenButton;
@property(weak, nonatomic) IBOutlet UIOpenDoorButton *door2OpenButton;;

@property  bool gate1TalkedFlag;
@property  bool gate1TalkingFlag;
@property  bool gate1OpenedGateFlag;
@property  bool gate1UnAnsweredFlag;
@property  bool gate2TalkedFlag;
@property  bool gate2TalkingFlag;
@property  bool gate2OpenedGateFlag;
@property  bool gate2UnAnsweredFlag;

- (IBAction)onAddContactClick:(id)event;
- (IBAction)onBackClick:(id)event;
- (IBAction)onAddressChange:(id)sender;
- (IBAction)onBackspaceClick:(id)sender;
- (IBAction)onOpenDoor1Click:(id)sender;
- (IBAction)onOpenDoor2Click:(id)sender;
- (void)setAddress:(NSString *)address;
- (void) readGatesStatus;
- (void) updateGatesPics;
- (void) updateCallStatus;
- (bool) parseBooleanStatus:(NSString*) payload property:(NSString *)property;
@end
