#include <napi.h>

// Apple APIs
#import <AVFoundation/AVFoundation.h>
#import <AppKit/AppKit.h>
#import <Contacts/Contacts.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreLocation/CoreLocation.h>
#import <EventKit/EventKit.h>
#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <Speech/Speech.h>
#import <Storekit/Storekit.h>
#import <pwd.h>

/***** HELPER FUNCTIONS *****/

const std::string kAuthorized{"authorized"};
const std::string kDenied{"denied"};
const std::string kRestricted{"restricted"};
const std::string kNotDetermined{"not determined"};

NSURL *URLForDirectory(NSSearchPathDirectory directory) {
  NSFileManager *fm = [NSFileManager defaultManager];
  return [fm URLForDirectory:directory
                    inDomain:NSUserDomainMask
           appropriateForURL:nil
                      create:false
                       error:nil];
}

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

// This method determines whether or not a system preferences security
// authentication request is currently open on the user's screen and foregrounds
// it if found
bool HasOpenSystemPreferencesDialog() {
  int MAX_NUM_LIKELY_OPEN_WINDOWS = 4;
  bool isDialogOpen = false;
  CFArrayRef windowList;

  // loops for max 1 second, breaks if/when dialog is found
  for (int index = 0; index <= MAX_NUM_LIKELY_OPEN_WINDOWS; index++) {
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

        [NSRunningApplication.currentApplication
            activateWithOptions:NSApplicationActivateAllWindows];
        [authApplication activateWithOptions:NSApplicationActivateAllWindows];

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

// Returns a status indicating whether the user has authorized Contacts
// access.
std::string ContactAuthStatus() {
  switch (
      [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts]) {
  case CNAuthorizationStatusAuthorized:
    return kAuthorized;
  case CNAuthorizationStatusDenied:
    return kDenied;
  case CNAuthorizationStatusRestricted:
    return kRestricted;
  default:
    return kNotDetermined;
  }
}

// Returns a status indicating whether the user has authorized Bluetooth access.
std::string BluetoothAuthStatus() {
  if (@available(macOS 10.15, *)) {
    switch ([CBCentralManager authorization]) {
    case CBManagerAuthorizationAllowedAlways:
      return kAuthorized;
    case CBManagerAuthorizationDenied:
      return kDenied;
    case CBManagerAuthorizationRestricted:
      return kRestricted;
    default:
      return kNotDetermined;
    }
  }

  return kAuthorized;
}

// Returns a status indicating whether the user has authorized Apple Music
// Library access.
std::string MusicLibraryAuthStatus() {
  if (@available(macOS 10.16, *)) {
    switch ([SKCloudServiceController authorizationStatus]) {
    case SKCloudServiceAuthorizationStatusAuthorized:
      return kAuthorized;
    case SKCloudServiceAuthorizationStatusDenied:
      return kDenied;
    case SKCloudServiceAuthorizationStatusRestricted:
      return kRestricted;
    default:
      return kNotDetermined;
    }
  }

  return kAuthorized;
}

// Returns a status indicating whether the user has authorized
// Calendar/Reminders access.
std::string EventAuthStatus(const std::string &type) {
  EKEntityType entity_type =
      (type == "calendar") ? EKEntityTypeEvent : EKEntityTypeReminder;

  switch ([EKEventStore authorizationStatusForEntityType:entity_type]) {
  case EKAuthorizationStatusAuthorized:
    return kAuthorized;
  case EKAuthorizationStatusDenied:
    return kDenied;
  case EKAuthorizationStatusRestricted:
    return kRestricted;
  default:
    return kNotDetermined;
  }
}

// Returns a status indicating whether the user has Full Disk Access.
std::string FDAAuthStatus() {
  std::string auth_status = kNotDetermined;
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
    auth_status = kDenied;
  } else if (file_exists) {
    auth_status = kAuthorized;
  }

  return auth_status;
}

// Returns a status indicating whether the user has authorized
// Screen Capture access.
std::string ScreenAuthStatus() {
  std::string auth_status = kNotDetermined;
  if (@available(macOS 11, *)) {
    if (CGPreflightScreenCaptureAccess()) {
      auth_status = kAuthorized;
    } else {
      auth_status = kDenied;
    }
  } else if (@available(macOS 10.15, *)) {
    auth_status = kDenied;
    NSRunningApplication *runningApplication =
        NSRunningApplication.currentApplication;
    NSNumber *ourProcessIdentifier =
        [NSNumber numberWithInteger:runningApplication.processIdentifier];

    CFArrayRef windowList =
        CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);
    int numberOfWindows = CFArrayGetCount(windowList);
    for (int index = 0; index < numberOfWindows; index++) {
      // Get information for each window.
      NSDictionary *windowInfo =
          (NSDictionary *)CFArrayGetValueAtIndex(windowList, index);
      NSString *windowName = windowInfo[(id)kCGWindowName];
      NSNumber *processIdentifier = windowInfo[(id)kCGWindowOwnerPID];

      // Don't check windows owned by the current process.
      if (![processIdentifier isEqual:ourProcessIdentifier]) {
        // Get process information for each window.
        pid_t pid = processIdentifier.intValue;
        NSRunningApplication *windowRunningApplication =
            [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
        if (windowRunningApplication) {
          NSString *windowExecutableName =
              windowRunningApplication.executableURL.lastPathComponent;
          if (windowName) {
            if (![windowExecutableName isEqual:@"Dock"]) {
              auth_status = kAuthorized;
              break;
            }
          }
        }
      }
    }
    CFRelease(windowList);
  } else {
    auth_status = kAuthorized;
  }

  return auth_status;
}

// Returns a status indicating whether the user has authorized
// Camera/Microphone access.
std::string MediaAuthStatus(const std::string &type) {
  if (@available(macOS 10.14, *)) {
    AVMediaType media_type =
        (type == "microphone") ? AVMediaTypeAudio : AVMediaTypeVideo;

    switch ([AVCaptureDevice authorizationStatusForMediaType:media_type]) {
    case AVAuthorizationStatusAuthorized:
      return kAuthorized;
    case AVAuthorizationStatusDenied:
      return kDenied;
    case AVAuthorizationStatusRestricted:
      return kRestricted;
    default:
      return kNotDetermined;
    }
  }

  return kAuthorized;
}

// Returns a status indicating whether the user has authorized speech
// recognition access.
std::string SpeechRecognitionAuthStatus() {
  if (@available(macOS 10.15, *)) {
    switch ([SFSpeechRecognizer authorizationStatus]) {
    case SFSpeechRecognizerAuthorizationStatusAuthorized:
      return kAuthorized;
    case SFSpeechRecognizerAuthorizationStatusDenied:
      return kDenied;
    case SFSpeechRecognizerAuthorizationStatusRestricted:
      return kRestricted;
    default:
      return kNotDetermined;
    }
  }

  return kAuthorized;
}

// Returns a status indicating whether the user has authorized location
// access.
std::string LocationAuthStatus() {
  switch ([CLLocationManager authorizationStatus]) {
  case kCLAuthorizationStatusAuthorized:
    return kAuthorized;
  case kCLAuthorizationStatusDenied:
    return kDenied;
  case kCLAuthorizationStatusRestricted:
    return kDenied;
  default:
    return kDenied;
  }
}

// Returns a status indicating whether or not the user has authorized Photos
// access.
std::string PhotosAuthStatus() {
  if (@available(macOS 10.13, *)) {
    switch ([PHPhotoLibrary authorizationStatus]) {
    case PHAuthorizationStatusAuthorized:
      return kAuthorized;
    case PHAuthorizationStatusDenied:
      return kDenied;
    case PHAuthorizationStatusRestricted:
      return kRestricted;
    default:
      return kNotDetermined;
    }
  }

  return kAuthorized;
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
    auth_status = AXIsProcessTrusted() ? kAuthorized : kDenied;
  } else if (type == "location") {
    auth_status = LocationAuthStatus();
  } else if (type == "screen") {
    auth_status = ScreenAuthStatus();
  } else if (type == "bluetooth") {
    auth_status = BluetoothAuthStatus();
  } else if (type == "music-library") {
    auth_status = MusicLibraryAuthStatus();
  }

  return Napi::Value::From(env, auth_status);
}

// Request access to various protected folders on the system.
Napi::Promise AskForFoldersAccess(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  Napi::Promise::Deferred deferred = Napi::Promise::Deferred::New(env);
  const std::string folder_name = info[0].As<Napi::String>().Utf8Value();

  NSString *path = @"";
  if (folder_name == "documents") {
    NSURL *url = URLForDirectory(NSDocumentDirectory);
    path = [url path];
  } else if (folder_name == "downloads") {
    NSURL *url = URLForDirectory(NSDownloadsDirectory);
    path = [url path];
  } else if (folder_name == "desktop") {
    NSURL *url = URLForDirectory(NSDesktopDirectory);
    path = [url path];
  }

  NSError *error = nil;
  NSFileManager *fm = [NSFileManager defaultManager];
  NSArray<NSString *> *contents __unused =
      [fm contentsOfDirectoryAtPath:path error:&error];

  std::string status = (error) ? kDenied : kAuthorized;
  deferred.Resolve(Napi::String::New(env, status));
  return deferred.Promise();
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
    deferred.Resolve(Napi::String::New(env, kAuthorized));
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

    if (auth_status == kNotDetermined) {
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
    } else if (auth_status == kDenied) {
      NSWorkspace *workspace = [[NSWorkspace alloc] init];
      NSString *pref_string = @"x-apple.systempreferences:com.apple.preference."
                              @"security?Privacy_Camera";

      [workspace openURL:[NSURL URLWithString:pref_string]];

      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, kDenied));
    } else {
      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, auth_status));
    }
  } else {
    ts_fn.Release();
    deferred.Resolve(Napi::String::New(env, kAuthorized));
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

    if (auth_status == kNotDetermined) {
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
    } else if (auth_status == kDenied) {
      NSWorkspace *workspace = [[NSWorkspace alloc] init];
      NSString *pref_string = @"x-apple.systempreferences:com.apple.preference."
                              @"security?Privacy_SpeechRecognition";

      [workspace openURL:[NSURL URLWithString:pref_string]];

      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, kDenied));
    } else {
      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, auth_status));
    }
  } else {
    ts_fn.Release();
    deferred.Resolve(Napi::String::New(env, kAuthorized));
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

    if (auth_status == kNotDetermined) {
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
    } else if (auth_status == kDenied) {
      NSWorkspace *workspace = [[NSWorkspace alloc] init];
      NSString *pref_string = @"x-apple.systempreferences:com.apple.preference."
                              @"security?Privacy_Photos";

      [workspace openURL:[NSURL URLWithString:pref_string]];

      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, kDenied));
    } else {
      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, auth_status));
    }
  } else {
    ts_fn.Release();
    deferred.Resolve(Napi::String::New(env, kAuthorized));
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

    if (auth_status == kNotDetermined) {
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
    } else if (auth_status == kDenied) {
      NSWorkspace *workspace = [[NSWorkspace alloc] init];
      NSString *pref_string = @"x-apple.systempreferences:com.apple.preference."
                              @"security?Privacy_Microphone";

      [workspace openURL:[NSURL URLWithString:pref_string]];

      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, kDenied));
    } else {
      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, auth_status));
    }
  } else {
    ts_fn.Release();
    deferred.Resolve(Napi::String::New(env, kAuthorized));
  }

  return deferred.Promise();
}

// Request Apple Music Library access.
Napi::Promise AskForMusicLibraryAccess(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  Napi::Promise::Deferred deferred = Napi::Promise::Deferred::New(env);
  Napi::ThreadSafeFunction ts_fn = Napi::ThreadSafeFunction::New(
      env, Napi::Function::New(env, NoOp), "musicLibraryCallback", 0, 1);

  if (@available(macOS 10.16, *)) {
    std::string auth_status = MusicLibraryAuthStatus();

    if (auth_status == kNotDetermined) {
      __block Napi::ThreadSafeFunction tsfn = ts_fn;
      [SKCloudServiceController
          requestAuthorization:^(SKCloudServiceAuthorizationStatus status) {
            auto callback = [=](Napi::Env env, Napi::Function js_cb,
                                const char *granted) {
              deferred.Resolve(Napi::String::New(env, granted));
            };

            bool granted =
                status == SKCloudServiceAuthorizationStatusAuthorized;
            tsfn.BlockingCall(granted ? "authorized" : "denied", callback);
            tsfn.Release();
          }];
    } else if (auth_status == kDenied) {
      NSWorkspace *workspace = [[NSWorkspace alloc] init];
      NSString *pref_string = @"x-apple.systempreferences:com.apple.preference."
                              @"security?Privacy_Media";

      [workspace openURL:[NSURL URLWithString:pref_string]];

      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, kDenied));
    } else {
      ts_fn.Release();
      deferred.Resolve(Napi::String::New(env, auth_status));
    }
  } else {
    ts_fn.Release();
    deferred.Resolve(Napi::String::New(env, kAuthorized));
  }

  return deferred.Promise();
}

// Request Screen Capture Access.
void AskForScreenCaptureAccess(const Napi::CallbackInfo &info) {
  if (@available(macOS 11, *)) {
    CGRequestScreenCaptureAccess();
  } else if (@available(macOS 10.15, *)) {
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
  exports.Set(Napi::String::New(env, "askForFoldersAccess"),
              Napi::Function::New(env, AskForFoldersAccess));
  exports.Set(Napi::String::New(env, "askForFullDiskAccess"),
              Napi::Function::New(env, AskForFullDiskAccess));
  exports.Set(Napi::String::New(env, "askForCameraAccess"),
              Napi::Function::New(env, AskForCameraAccess));
  exports.Set(Napi::String::New(env, "askForMicrophoneAccess"),
              Napi::Function::New(env, AskForMicrophoneAccess));
  exports.Set(Napi::String::New(env, "askForMusicLibraryAccess"),
              Napi::Function::New(env, AskForMusicLibraryAccess));
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
