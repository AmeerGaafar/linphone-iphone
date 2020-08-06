##  Sesame, the doorphone

This is a stripped down Linphone for iOS tailored to suit my doorphone usecase. This is by no means a well engineered modification. Although I have extensive programming experience, I did not write a single line of Objective-C before this and I did not want to invest the time needed learn the language and craft a well-engineered solution. I have to credit Linphone.org for the clarity and cleanliness of the original codebase though, as I was able to hack my way through into this in a couple of days.

### The use case
- I don't want my doorbell, or my home automation system, to have a cloud connection. This requirement pretty much excludes 90% of  solutions in the market, and the remaining bunch is either prohibitively expensive, proprietary (as in not hackable enough), or both.
- I want the _bell/chime_ aspect to be operationally independent from the _phone_ aspect. Pressing the doorbell button should trigger a audible chime inside. Whether someone decides to pickup their phone to talk to the person at the door, or just go ahead and open anyway should be possible without fuzz. This is why I did not want a solution that's permanently glued to my phone or wall-hung answering device.   
- I would like to be able to trigger opening the door after talking to the _knocker_. This is convenient and safe because I will use it to open the front gate, or the backyard gate, but not the house door.
- I would like to be able to talk to and control 2 gates/doors using the App.
- I don't really care about answering the door while away from home. It would be nice to have an answering machine feature that emails a audio/video message, but it's not a necessity.
- Would be great to be able to integrate the solution, or parts of it, with Home-Assistant, my home automation software.

### The solution
I was not able to find something to satisfy all these needs or be hackable enough to do so with minimum effort. I built my solution during the Covit-19 lockdown since I had to spend a lot more time at home.
- My chimes are in-ceiling speakers connected to Raspberry Pis. One in each floor. These speaker serve as door chimes in addition to internal announcements. They expose Rest services that are called by the doorbell button to play a _ding dong_ audio file. I had them setup to play a different chime for each gate.
- Each gate doorphone is a Raspberry Pi 4 with a USB camera and an amplifier Hat. It is also connected to the door electric strike via GPIO to remotely trigger opening the door. I custom designed and CNCed a faceplate that allowed me to insert the electronics inside the metal posts of the door frame for an in-built look.
- A momentary push button connected to GPIO acts as a doorbell, triggering a Rest call into the ceiling chimes. That's the doorbell feature. It operates autonomously and has nothing to do with the _phone_ feature.
- The doorphone Raspberry Pi runs _baresip_ in auto answer mode with video support. This is an important design decision that I took. The doorbell _does not_ call into residents' sip clients when someone presses the doorbell button! It's the other way around. When residents hears the door chime (through the ceiling speakers), they _may_ call into the gate to talk to the _knocker_ or chose to act otherwise. If more that one person calls into the gate Pi Sip endpoint, they all join in the call.
- The doorphone Raspberry Pi doubles as a security cam, streaming rtsp feed into the nvr.
- The only remaining piece in this buzzle was a Sip client that my family and I can use to dial into the gates. It was quite possible to just use a plain Sip client, add entries in the address book for the gates and be done with it, but it was not intuitive enough. I therefore decided to find a suitable open source Sip client and hack it into a door Sip client with just enough apparent features for the usage scenarios I have. This repository is about that. A Sip client tailored to be a door answering system and nothing else.

### Main Features
- No address book and no dial pad! The dialler is a simple view with two choices for the two gates I have. The user simply fires the App, clicks a gate, and they are connected.
- Each Gate is presented with its current camera snapshot in the dialer screen
- All advanced calling features are removed. Pause, join, hold, etc. are removed
- Calls are initiated with video support and zoomed to 2x, no questions asked.
- The app does not try to get into full screen mode as the calls are usually short.
- A new button is added in the ongoing call UI to trigger open the gate.
- The dialer allows also for opening the gate without initiating a call
- The dialer screen shows icons indicating the status of the gate, like presence of potential visitors, etc..
- No Sip registration. Both Linphone and baresip support p2p calls. There was no need for an inhouse pbx. Calls are made p2p from the client to the gate. 
- No proxies, no Ice, Stun or Turn. All Sip endpoints are in the same Lan.
- Gates and other parameters are defined in a configuration file that is burned into the App. There is no UI to do that.

### Deployment
This repo is not intended to produce an App that can be distributed via App stores. It's useful only for those geeky enough to tinker with source code and configuration files then build and deploy mobile apps manually via xcode and the likes.
What I do is change my parameters if needed, then hook my family devices to xcode and deploy. Works for me, but your expectations may be different.

### Configuration
All configuration parameters are in `resources/linphonerc`
```
[doorphone]
door_open_auth_user=V8Hq7ui626F8h0t
door_open_auth_pass=XYZ2iSF72U445WS
door_open_template=http://%@:%@@%@:8080/open
door_verbose_open_template=http://%@:%@@%@:8080/open-verbosed
door_snapshot_template=http://%@:8080/periodic-snapshot
door_status_template=http://%@:8080/door-status
door_address_template=sip:%@@%@
door1_name=Front_Gate
door1_host=192.168.1.236
door2_name=Backyard_Gate
door2_host=192.168.1.236
```
You'll also need to change `Front_Gate.jpg` and `Backyard_Gate.jpg` with images of your own. These are fallback images, most of the time the image shown is the camera snapshot. This image is only used when the door unit fails to return an image for display in the dialer.

_note_
Linphone reads these params only upon installation to copy them into a database. This means if you change the params, you need to delete the previous app to remove old data before deploying the new one. You'll lose call history though.

<<<<<<< HEAD
### TODO
- Have the dialer picture changed to a cam-shot upon clicking the button (done)
- Fix the doorbell button debounce issue (done)
- Smart snapshot feature (done)
- Indicate that call has been answered - Gate has been open - Call in progress (done)
- Allow opening the door from dialer screen without establishing a call (done)
- Parametrize gate open url with an optional message "please push the gate"(done)
- New Logo
- Ajust volume
- switch playsound to use pa instead of alsa
- record please push the door 
- coat
- assemble
=======
_note_
To build, hack, etc, please read the original project readme in ORG_README.MD
>>>>>>> 2ff192a0c119818fe7e9426c5f37cbde4010f070

 

