#include <napi.h>

// Apple APIs
#import <AVFoundation/AVFoundation.h>
#import <AppKit/AppKit.h>
#import <Contacts/Contacts.h>
#import <CoreLocation/CoreLocation.h>
#import <EventKit/EventKit.h>
#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <Speech/Speech.h>
#import <pwd.h>

/***** HELPER FUNCTIONS *****/

// Dummy value to pass into function parameter for ThreadSafeFunction.
Napi::Value NoOp(const Napi::CallbackInfo &info) {
  return info.Env().Undefined();
}

// Returns the user's home folder path.
NSString *GetUserHomeFolderPath() {
  NSString *path;
  BOOL isSandboxed =
      (nil !=
       NSProcessInfo.processInfo.environment[@"APP_SANDBOX_CONTAINER_ID"]);

  if (isSandboxed) {
    struct passwd *pw = getpwuid(getuid());
    assert(pw);
    path = [NSString stringWithUTF8String:pw->pw_dir];
  } else {
    path = NSHomeDirectory();
  }

  return path;
}

// Returns a status indicating whether the user has authorized Contacts
// access.
std::string ContactAuthStatus() {
  std::string auth_status = "not determined";

  CNEntityType entity_type = CNEntityTypeContacts;
  CNAuthorizationStatus status =
      [CNContactStore authorizationStatusForEntityType:entity_type];

  if (status == CNAuthorizationStatusAuthorized)
    auth_status = "authorized";
  else if (status == CNAuthorizationStatusDenied)
    auth_status = "denied";
  else if (status == CNAuthorizationStatusRestricted)
    auth_status = "restricted";

  return auth_status;
}

// Returns a status indicating whether the user has authorized
// Calendar/Reminders access.
std::string EventAuthStatus(const std::string &type) {
  std::string auth_status = "not determined";

  EKEntityType entity_type =
      (type == "calendar") ? EKEntityTypeEvent : EKEntityTypeReminder;
  EKAuthorizationStatus status =
      [EKEventStore authorizationStatusForEntityType:entity_type];

  if (status == EKAuthorizationStatusAuthorized)
    auth_status = "authorized";
  else if (status == EKAuthorizationStatusDenied)
    auth_status = "denied";
  else if (status == EKAuthorizationStatusRestricted)
    auth_status = "restricted";

  return auth_status;
}

// Returns a status indicating whether the user has Full Disk Access.
std::string FDAAuthStatus() {
  std::string auth_status = "not determined";
  NSString *path;
  NSString *home_folder = GetUserHomeFolderPath();

  if (@available(macOS 10.15, *)) {
    path = [home_folder
        stringByAppendingPathComponent:@"Library/Safari/CloudTabs.db"];
  } else {
    path = [home_folder
        stringByAppendingPathComponent:@"Library/Safari/Bookmarks.plist"];
  }

  NSFileManager *manager = [NSFileManager defaultManager];
  BOOL file_exists = [manager fileExistsAtPath:path];
  NSData *data = [NSData dataWithContentsOfFile:path];
  if (data == nil && file_exists) {
    auth_status = "denied";
  } else if (file_exists) {
    auth_status = "authorized";
  }

  return auth_status;
}

// Returns a status indicating whether the user has authorized
// Screen Capture access.
std::string ScreenAuthStatus() {
  std::string auth_status = "not determined";
  if (@available(macOS 10.15, *)) {
    auth_status = "denied";
    NSRunningApplication *runningApplication =
        NSRunningApplication.currentApplication;
    NSNumber *ourProcessIdentifier =
        [NSNumber numberWithInteger:runningApplication.processIdentifier];

    CFArrayRef windowList =
        CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);
    int numberOfWindows = CFArrayGetCount(windowList);
    for (int index = 0; index < numberOfWindows; index++) {
      // get information for each window
      NSDictionary *windowInfo =
          (NSDictionary *)CFArrayGetValueAtIndex(windowList, index);
      NSString *windowName = windowInfo[(id)kCGWindowName];
      NSNumber *processIdentifier = windowInfo[(id)kCGWindowOwnerPID];

      // don't check windows owned by this process
      if (![processIdentifier isEqual:ourProcessIdentifier]) {
        // get process information for each window
        pid_t pid = processIdentifier.intValue;
        NSRunningApplication *windowRunningApplication =
            [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
        if (windowRunningApplication) {
          NSString *windowExecutableName =
              windowRunningApplication.executableURL.lastPathComponent;
          if (windowName) {
            if (![windowExecutableName isEqual:@"Dock"]) {
              auth_status = "authorized";
              break;
            }
          }
        }
      }
    }
    CFRelease(windowList);
  } else {
    auth_status = "authorized";
  }

  return auth_status;
}

// Returns a status indicating whether the user has authorized
// Camera/Microphone access.
std::string MediaAuthStatus(const std::string &type) {
  std::string auth_status = "not determined";

  if (@available(macOS 10.14, *)) {
    AVMediaType media_type =
        (type == "microphone") ? AVMediaTypeAudio : AVMediaTypeVideo;
    AVAuthorizationStatus status =
        [AVCaptureDevice authorizationStatusForMediaType:media_type];

    if (status == AVAuthorizationStatusAuthorized)
      auth_status = "authorized";
    else if (status == AVAuthorizationStatusDenied)
      auth_status = "denied";
    else if (status == AVAuthorizationStatusRestricted)
      auth_status = "restricted";
  } else {
    auth_status = "authorized";
  }

  return auth_status;
}

// Returns a status indicating whether the user has authorized speech
// recognition access.
std::string SpeechRecognitionAuthStatus() {
  std::string auth_status = "not determined";

  if (@available(macOS 10.15, *)) {
    SFSpeechRecognizerAuthorizationStatus status =
        [SFSpeechRecognizer authorizationStatus];

    if (status == SFSpeechRecognizerAuthorizationStatusAuthorized)
      auth_status = "authorized";
    else if (status == SFSpeechRecognizerAuthorizationStatusDenied)
      auth_status = "denied";
    else if (status == SFSpeechRecognizerAuthorizationStatusRestricted)
      auth_status = "restricted";
  } else {
    auth_status = "authorized";
  }

  return auth_status;
}

// Returns a status indicating whether the user has authorized location
// access.
std::string LocationAuthStatus() {
  std::string auth_status = "not determined";

  CLAuthorizationStatus status = [CLLocationManager authorizationStatus];

  if (status == kCLAuthorizationStatusAuthorizedAlways)
    auth_status = "authorized";
  else if (status == kCLAuthorizationStatusDenied)
    auth_status = "denied";
  else if (status == kCLAuthorizationStatusNotDetermined)
    auth_status = "restricted";

  return auth_status;
}

// Returns a status indicating whether or not the user has authorized Photos
// access.
std::string PhotosAuthStatus() {
  std::string auth_status = "not determined";

  if (@available(macOS 10.13, *)) {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];

    if (status == PHAuthorizationStatusAuthorized)
      auth_status = "authorized";
    else if (status == PHAuthorizationStatusDenied)
      auth_status = "denied";
    else if (status == PHAuthorizationStatusRestricted)
      auth_status = "restricted";
  } else {
    auth_status = "authorized";
  }

  return auth_status;
}

/***** EXPORTED FUNCTIONS *****/

// Returns the user's access consent status as a string.
Napi::Value GetAuthStatus(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  std::string auth_status;

  const std::string type = info[0].As<Napi::String>().Utf8Value();
  if (type == "contacts") {
    auth_status = ContactAuthStatus();
  } else if (type == "calendar") {
    auth_status = EventAuthStatus("calendar");
  } else if (type == "reminders") {
    auth_status = EventAuthStatus("reminders");
  } else if (type == "full-disk-access") {
    auth_status = FDAAuthStatus();
  } else if (type == "microphone") {
    auth_status = MediaAuthStatus("microphone");
  } else if (type == "photos") {
    auth_status = PhotosAuthStatus();
  } else if (type == "speech-recognition") {
    auth_status = SpeechRecognitionAuthStatus();
  } else if (type == "camera") {
    auth_status = MediaAuthStatus("camera");
  } else if (type == "accessibility") {
    auth_status = AXIsProcessTrusted() ? "authorized" : "denied";
  } else if (type == "location") {
    auth_status = LocationAuthStatus();
  } else if (type == "screen") {
    auth_status = ScreenAuthStatus();
  }

  return Napi::Value::From(env, auth_status);
}

// Request Contacts access.
Napi::Promise AskForContactsAccess(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  Napi::Promise::Deferred deferred = Napi::Promise::Deferred::New(env);
  Napi::ThreadSafeFunction ts_fn = Napi::ThreadSafeFunction::New(
      env, Napi::Function::New(env, NoOp), "contactsCallback", 0, 1);

  if (@available(macOS 10.11, *)) {
    __block Napi::ThreadSafeFunction tsfn = ts_fn;
    CNContactStore *store = [CNContactStore new];
    [store requestAccessForEntityType:CNEntityTypeContacts
                    completionHandler:^(BOOL granted, NSError *error) {
                      auto callback = [=](Napi::Env env, Napi::Function js_cb,
                                          const char *granted) {
                        deferred.Resolve(Napi::String::New(env, granted));
                      };
                      tsfn.BlockingCall(granted ? "authorized" : "denied",
                                        callback);
                      tsfn.Release();
                    }];
  } else {
    ts_fn.Release();
    deferred.Resolve(Napi::String::New(env, "authorized"));
  }

  return deferred.Promise();
}

// Request Calendar access.
Napi::Promise AskForCalendarAccess(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  Napi::Promise::Deferred deferred = Napi::Promise::Deferred::New(env);
  Napi::ThreadSafeFunction ts_fn = Napi::ThreadSafeFunction::New(
      env, Napi::Function::New(env, NoOp), "calendarCallback", 0, 1);

  __block Napi::ThreadSafeFunction tsfn = ts_fn;
  [[EKEventStore new]
      requestAccessToEntityType:EKEntityTypeEvent
                     completion:^(BOOL granted, NSError *error) {
                       auto callback = [=](Napi::Env env, Napi::Function js_cb,
                                           const char *granted) {
                         deferred.Resolve(Napi::String::New(env, granted));
                       };
                       tsfn.BlockingCall(granted ? "authorized" : "denied",
                                         callback);
                       tsfn.Release();
                     }];

  return deferred.Promise();
}

// Request Reminders access.
Napi::Promise AskForRemindersAccess(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  Napi::Promise::Deferred deferred = Napi::Promise::Deferred::New(env);
  Napi::ThreadSafeFunction ts_fn = Napi::ThreadSafeFunction::New(
      env, Napi::Function::New(env, NoOp), "remindersCallback", 0, 1);

  __block Napi::ThreadSafeFunction tsfn = ts_fn;
  [[EKEventStore new]
      requestAccessToEntityType:EKEntityTypeReminder
                     completion:^(BOOL granted, NSError *error) {
                       auto callback = [=](Napi::Env env,
                                           Napi::Function prom_cb,
                                           const char *granted) {
                         deferred.Resolve(Napi::String::New(env, granted));
                       };
                       tsfn.BlockingCall(granted ? "authorized" : "denied",
                                         callback);
                       tsfn.Release();
                     }];

  return deferred.Promise();
}

// Request Full Disk Access.
void AskForFullDiskAccess(const Napi::CallbackInfo &info) {
  NSWorkspace *workspace = [[NSWorkspace alloc] init];
  NSString *pref_string = @"x-apple.systempreferences:com.apple.preference."
                          @"security?Privacy_AllFiles";
  [workspace openURL:[NSURL URLWithString:pref_string]];
}

// Request Camera access.
Napi::Promise AskForCameraAccess(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  Napi::Promise::Deferred deferred = Napi::Promise::Deferred::New(env);
  Napi::ThreadSafeFunction ts_fn = Napi::ThreadSafeFunction::New(
      env, Napi::Function::New(env, NoOp), "cameraCallback", 0, 1);

  if (@available(macOS 10.14, *)) {
    std::string auth_status = MediaAuthStatus("camera");

    if (auth_status == "not determined") {
      __block Napi::ThreadSafeFunction tsfn = ts_fn;
      [AVCaptureDevice
          requestAccessForMediaType:AVMediaTypeVideo
                  completionHandler:^(BOOL granted) {
                    auto callback = [=](Napi::Env env, Napi::Function js_cb,
                                        const char *granted) {
                      deferred.Resolve(Napi::String::New(env, granted));
                    };

                    tsfn.BlockingCall(granted ? "authorized" : "denied",
                                      callback);
                    tsfn.Release();
                  }];
    } else if (auth_status == "denied") {
      NSWorkspace *workspace = [[NSWorkspace alloc] init];
      NSString *pref_string = @"x-apple.systempreferences:com.apple.preference."
                              @"security?Privacy_Camera";

      [workspace openURL:[NSURL URLWithString:pref_string]];

      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, "denied"));
    } else {
      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, auth_status));
    }
  } else {
    ts_fn.Release();
    deferred.Resolve(Napi::String::New(env, "authorized"));
  }

  return deferred.Promise();
}

// Request Speech Recognition access.
Napi::Promise AskForSpeechRecognitionAccess(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  Napi::Promise::Deferred deferred = Napi::Promise::Deferred::New(env);
  Napi::ThreadSafeFunction ts_fn = Napi::ThreadSafeFunction::New(
      env, Napi::Function::New(env, NoOp), "speechRecognitionCallback", 0, 1);

  if (@available(macOS 10.15, *)) {
    std::string auth_status = SpeechRecognitionAuthStatus();

    if (auth_status == "not determined") {
      __block Napi::ThreadSafeFunction tsfn = ts_fn;
      [SFSpeechRecognizer
          requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
            auto callback = [=](Napi::Env env, Napi::Function js_cb,
                                const char *granted) {
              deferred.Resolve(Napi::String::New(env, granted));
            };
            tsfn.BlockingCall(
                status == SFSpeechRecognizerAuthorizationStatusAuthorized
                    ? "authorized"
                    : "denied",
                callback);
            tsfn.Release();
          }];
    } else if (auth_status == "denied") {
      NSWorkspace *workspace = [[NSWorkspace alloc] init];
      NSString *pref_string = @"x-apple.systempreferences:com.apple.preference."
                              @"security?Privacy_SpeechRecognition";

      [workspace openURL:[NSURL URLWithString:pref_string]];

      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, "denied"));
    } else {
      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, auth_status));
    }
  } else {
    ts_fn.Release();
    deferred.Resolve(Napi::String::New(env, "authorized"));
  }

  return deferred.Promise();
}

// Request Photos access.
Napi::Promise AskForPhotosAccess(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  Napi::Promise::Deferred deferred = Napi::Promise::Deferred::New(env);
  Napi::ThreadSafeFunction ts_fn = Napi::ThreadSafeFunction::New(
      env, Napi::Function::New(env, NoOp), "photosCallback", 0, 1);

  if (@available(macOS 10.13, *)) {
    std::string auth_status = PhotosAuthStatus();

    if (auth_status == "not determined") {
      __block Napi::ThreadSafeFunction tsfn = ts_fn;
      [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        auto callback = [=](Napi::Env env, Napi::Function js_cb,
                            const char *granted) {
          deferred.Resolve(Napi::String::New(env, granted));
        };
        tsfn.BlockingCall(
            status == PHAuthorizationStatusAuthorized ? "authorized" : "denied",
            callback);
        tsfn.Release();
      }];
    } else if (auth_status == "denied") {
      NSWorkspace *workspace = [[NSWorkspace alloc] init];
      NSString *pref_string = @"x-apple.systempreferences:com.apple.preference."
                              @"security?Privacy_Photos";

      [workspace openURL:[NSURL URLWithString:pref_string]];

      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, "denied"));
    } else {
      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, auth_status));
    }
  } else {
    ts_fn.Release();
    deferred.Resolve(Napi::String::New(env, "authorized"));
  }

  return deferred.Promise();
}

// Request Microphone access.
Napi::Promise AskForMicrophoneAccess(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  Napi::Promise::Deferred deferred = Napi::Promise::Deferred::New(env);
  Napi::ThreadSafeFunction ts_fn = Napi::ThreadSafeFunction::New(
      env, Napi::Function::New(env, NoOp), "microphoneCallback", 0, 1);

  if (@available(macOS 10.14, *)) {
    std::string auth_status = MediaAuthStatus("microphone");

    if (auth_status == "not determined") {
      __block Napi::ThreadSafeFunction tsfn = ts_fn;
      [AVCaptureDevice
          requestAccessForMediaType:AVMediaTypeAudio
                  completionHandler:^(BOOL granted) {
                    auto callback = [=](Napi::Env env, Napi::Function js_cb,
                                        const char *granted) {
                      deferred.Resolve(Napi::String::New(env, granted));
                    };

                    tsfn.BlockingCall(granted ? "authorized" : "denied",
                                      callback);
                    tsfn.Release();
                  }];
    } else if (auth_status == "denied") {
      NSWorkspace *workspace = [[NSWorkspace alloc] init];
      NSString *pref_string = @"x-apple.systempreferences:com.apple.preference."
                              @"security?Privacy_Microphone";

      [workspace openURL:[NSURL URLWithString:pref_string]];

      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, "denied"));
    } else {
      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, auth_status));
    }
  } else {
    ts_fn.Release();
    deferred.Resolve(Napi::String::New(env, "authorized"));
  }

  return deferred.Promise();
}

bool HasOpenSystemPreferencesDialog() {
  bool isDialogOpen = false;
  CFArrayRef windowList;

  // loops for max 1 second, breaks if/when dialog is found
  for (int index = 0; index <= 4; index++) {
    windowList = CGWindowListCopyWindowInfo(
        kCGWindowListOptionOnScreenAboveWindow, kCGNullWindowID);
    int numberOfWindows = CFArrayGetCount(windowList);

    for (int windowIndex = 0; windowIndex < numberOfWindows; windowIndex++) {
      NSDictionary *windowInfo =
          (NSDictionary *)CFArrayGetValueAtIndex(windowList, windowIndex);
      NSString *windowOwnerName = windowInfo[(id)kCGWindowOwnerName];
      NSNumber *windowLayer = windowInfo[(id)kCGWindowLayer];
      NSNumber *windowOwnerPID = windowInfo[(id)kCGWindowOwnerPID];

      if ([windowLayer integerValue] == 0 &&
          [windowOwnerName isEqual:@"universalAccessAuthWarn"]) {
        // make sure the auth window is in the foreground
        NSRunningApplication *authApplication = [NSRunningApplication
            runningApplicationWithProcessIdentifier:[windowOwnerPID
                                                        integerValue]];

        if (!authApplication.active) {
          [authApplication
              activateWithOptions:NSApplicationActivateAllWindows];
        }

        isDialogOpen = true;
        break;
      }
    }

    CFRelease(windowList);

    if (isDialogOpen) {
      break;
    }

    usleep(250000);
  }

  return isDialogOpen;
}

// Request Screen Capture Access.
void AskForScreenCaptureAccess(const Napi::CallbackInfo &info) {
  if (@available(macOS 10.15, *)) {
    // Tries to create a capture stream. This is necessary to add the app back
    // to the list in sysprefs if the user previously denied.
    // https://stackoverflow.com/questions/56597221/detecting-screen-recording-settings-on-macos-catalina
    CGDisplayStreamRef stream = CGDisplayStreamCreate(
        CGMainDisplayID(), 1, 1, kCVPixelFormatType_32BGRA, NULL,
        ^(CGDisplayStreamFrameStatus status, uint64_t displayTime,
          IOSurfaceRef frameSurface, CGDisplayStreamUpdateRef updateRef){
        });

    if (stream) {
      CFRelease(stream);
    } else {
      if (!HasOpenSystemPreferencesDialog()) {
        NSWorkspace *workspace = [[NSWorkspace alloc] init];
        NSString *pref_string =
            @"x-apple.systempreferences:com.apple.preference."
            @"security?Privacy_ScreenCapture";
        [workspace openURL:[NSURL URLWithString:pref_string]];
      }
    }
  } 
}

// Request Accessibility Access.
void AskForAccessibilityAccess(const Napi::CallbackInfo &info) {
  NSDictionary *options = @{(id)kAXTrustedCheckOptionPrompt : @(NO)};
  bool trusted = AXIsProcessTrustedWithOptions((CFDictionaryRef)options);

  if (!trusted) {
    NSWorkspace *workspace = [[NSWorkspace alloc] init];
    NSString *pref_string = @"x-apple.systempreferences:com.apple.preference."
                            @"security?Privacy_Accessibility";
    [workspace openURL:[NSURL URLWithString:pref_string]];
  }
}

// Initializes all functions exposed to JS
Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports.Set(Napi::String::New(env, "getAuthStatus"),
              Napi::Function::New(env, GetAuthStatus));
  exports.Set(Napi::String::New(env, "askForContactsAccess"),
              Napi::Function::New(env, AskForContactsAccess));
  exports.Set(Napi::String::New(env, "askForCalendarAccess"),
              Napi::Function::New(env, AskForCalendarAccess));
  exports.Set(Napi::String::New(env, "askForRemindersAccess"),
              Napi::Function::New(env, AskForRemindersAccess));
  exports.Set(Napi::String::New(env, "askForFullDiskAccess"),
              Napi::Function::New(env, AskForFullDiskAccess));
  exports.Set(Napi::String::New(env, "askForCameraAccess"),
              Napi::Function::New(env, AskForCameraAccess));
  exports.Set(Napi::String::New(env, "askForMicrophoneAccess"),
              Napi::Function::New(env, AskForMicrophoneAccess));
  exports.Set(Napi::String::New(env, "askForSpeechRecognitionAccess"),
              Napi::Function::New(env, AskForSpeechRecognitionAccess));
  exports.Set(Napi::String::New(env, "askForPhotosAccess"),
              Napi::Function::New(env, AskForPhotosAccess));
  exports.Set(Napi::String::New(env, "askForScreenCaptureAccess"),
              Napi::Function::New(env, AskForScreenCaptureAccess));
  exports.Set(Napi::String::New(env, "askForAccessibilityAccess"),
              Napi::Function::New(env, AskForAccessibilityAccess));

  return exports;
}

NODE_API_MODULE(permissions, Init)