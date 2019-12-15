#include <napi.h>

// Apple APIs
#import <AppKit/AppKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <Contacts/Contacts.h>
#import <EventKit/EventKit.h>
#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <pwd.h>

/***** HELPER FUNCTIONS *****/

// Dummy value to pass into function parameter for ThreadSafeFunction
Napi::Value NoOp(const Napi::CallbackInfo& info) { return info.Env().Undefined(); }

NSString* GetUserHomeFolderPath() {
  NSString* path;
  BOOL isSandboxed = (nil != NSProcessInfo.processInfo.environment[@"APP_SANDBOX_CONTAINER_ID"]);

  if (isSandboxed) {
    struct passwd *pw = getpwuid(getuid());
    assert(pw);
    path = [NSString stringWithUTF8String:pw->pw_dir];
  } else {
    path = NSHomeDirectory();
  }

  return path;
}

// Returns a status indicating whether or not the user has authorized Contacts access
std::string ContactAuthStatus() {
  std::string auth_status = "not determined";

  CNEntityType entity_type = CNEntityTypeContacts;
  CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:entity_type];

  if (status == CNAuthorizationStatusAuthorized)
    auth_status = "authorized";
  else if (status == CNAuthorizationStatusDenied)
    auth_status = "denied";
  else if (status == CNAuthorizationStatusRestricted)
    auth_status = "restricted";

  return auth_status;
}

// Returns a status indicating whether or not the user has authorized Calendar/Reminders access
std::string EventAuthStatus(const std::string& type) {
  std::string auth_status = "not determined";

  EKEntityType entity_type = (type == "calendar") ? EKEntityTypeEvent : EKEntityTypeReminder;
  EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:entity_type];

  if (status == EKAuthorizationStatusAuthorized)
    auth_status = "authorized";
  else if (status == EKAuthorizationStatusDenied)
    auth_status = "denied";
  else if (status == EKAuthorizationStatusRestricted)
    auth_status = "restricted";

  return auth_status;
}

// Returns a status indicating whether or not the user has Full Disk Access
std::string FDAAuthStatus() {
  std::string auth_status = "not determined";
  NSString *path;
  NSString* home_folder = GetUserHomeFolderPath();

  if (@available(macOS 10.15, *)) {
    path = [home_folder stringByAppendingPathComponent:@"Library/Safari/CloudTabs.db"];
  } else {
    path = [home_folder stringByAppendingPathComponent:@"Library/Safari/Bookmarks.plist"];
  }
    
  NSFileManager* manager = [NSFileManager defaultManager];
  BOOL file_exists = [manager fileExistsAtPath:path];
  NSData *data = [NSData dataWithContentsOfFile:path];
  if (data == nil && file_exists) {
    auth_status = "denied";
  } else if (file_exists) {
    auth_status = "authorized";
  }

  return auth_status;
}

// Returns a status indicating whether or not the user has authorized Camera/Microphone access
std::string MediaAuthStatus(const std::string& type) {
  std::string auth_status = "not determined";

  if (@available(macOS 10.14, *)) {
    AVMediaType media_type = (type == "microphone") ? AVMediaTypeAudio : AVMediaTypeVideo;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:media_type];

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

/***** EXPORTED FUNCTIONS *****/

// Returns the user's access consent status as a string
Napi::Value GetAuthStatus(const Napi::CallbackInfo& info) {
  Napi::Env env = info.Env();
  std::string auth_status;

  const std::string type = info[0].As<Napi::String>().Utf8Value();
  if (type == "contacts") {
    auth_status = ContactAuthStatus();
  } else if (type == "calendar") {
    auth_status = EventAuthStatus("calendar");
  }  else if (type == "reminders") {
    auth_status = EventAuthStatus("reminders");
  } else if (type == "full-disk-access") {
    auth_status = FDAAuthStatus();
  } else if (type == "microphone") {
    auth_status = MediaAuthStatus("microphone");
  } else if (type == "camera") {
    auth_status = MediaAuthStatus("camera");
  } else if (type == "accessibility") {
    auth_status = AXIsProcessTrusted() ? "authorized" : "denied";
  } else if (type == "location") {
    auth_status = LocationAuthStatus();
  }

  return Napi::Value::From(env, auth_status);
}

// Request access to the Contacts store.
Napi::Promise AskForContactsAccess(const Napi::CallbackInfo& info) {
  Napi::Env env = info.Env();
  Napi::Promise::Deferred deferred = Napi::Promise::Deferred::New(env);
  Napi::ThreadSafeFunction ts_fn = Napi::ThreadSafeFunction::New(env,
                                                                 Napi::Function::New(env, NoOp),
                                                                 "contactsCallback",
                                                                 0,
                                                                 1,
                                                                 [](Napi::Env){});

  if (@available(macOS 10.11, *)) {
    CNContactStore *store = [CNContactStore new];
    [store requestAccessForEntityType:CNEntityTypeContacts
                    completionHandler:^(BOOL granted, NSError* error) {
      auto callback = [=](Napi::Env env, Napi::Function js_cb, const char* granted) {
        deferred.Resolve(Napi::String::New(env, granted));
      };
      ts_fn.BlockingCall(granted ? "authorized" : "denied", callback);
    }];
  } else {
    deferred.Resolve(Napi::String::New(env, "authorized"));
  }

  return deferred.Promise();
}

// Request access to Calendar.
Napi::Promise AskForCalendarAccess(const Napi::CallbackInfo& info) {
  Napi::Env env = info.Env();
  Napi::Promise::Deferred deferred = Napi::Promise::Deferred::New(env);
  Napi::ThreadSafeFunction ts_fn = Napi::ThreadSafeFunction::New(env,
                                                                 Napi::Function::New(env, NoOp),
                                                                 "calendarCallback",
                                                                 0,
                                                                 1,
                                                                 [](Napi::Env){});

  [[EKEventStore new] requestAccessToEntityType:EKEntityTypeEvent
                                     completion:^(BOOL granted, NSError * error) {
    auto callback = [=](Napi::Env env, Napi::Function js_cb, const char* granted) {
      deferred.Resolve(Napi::String::New(env, granted));
    };
    ts_fn.BlockingCall(granted ? "authorized" : "denied", callback);
  }];

  return deferred.Promise();
}

// Request access to Reminders.
Napi::Promise AskForRemindersAccess(const Napi::CallbackInfo& info) {
  Napi::Env env = info.Env();
  Napi::Promise::Deferred deferred = Napi::Promise::Deferred::New(env);
  Napi::ThreadSafeFunction ts_fn = Napi::ThreadSafeFunction::New(env,
                                                                 Napi::Function::New(env, NoOp),
                                                                 "remindersCallback",
                                                                 0,
                                                                 1,
                                                                 [](Napi::Env){});

  [[EKEventStore new] requestAccessToEntityType:EKEntityTypeReminder
                                     completion:^(BOOL granted, NSError * error) {
    auto callback = [=](Napi::Env env, Napi::Function prom_cb, const char* granted) {
      deferred.Resolve(Napi::String::New(env, granted));
    };
    ts_fn.BlockingCall(granted ? "authorized" : "denied", callback);
  }];

  return deferred.Promise();
}

// Request Full Disk Access.
void AskForFullDiskAccess(const Napi::CallbackInfo &info) {
  NSWorkspace* workspace = [[NSWorkspace alloc] init];
  NSString* pref_string = @"x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles";
  [workspace openURL:[NSURL URLWithString:pref_string]];
}

// Request access to either the Camera or the Microphone.
Napi::Promise AskForMediaAccess(const Napi::CallbackInfo& info) {
  Napi::Env env = info.Env();
  const std::string type = info[0].As<Napi::String>().Utf8Value();
  Napi::Promise::Deferred deferred = Napi::Promise::Deferred::New(env);
  Napi::ThreadSafeFunction ts_fn = Napi::ThreadSafeFunction::New(env,
                                                                 Napi::Function::New(env, NoOp),
                                                                 "mediaAccessCallback",
                                                                 0,
                                                                 1,
                                                                 [](Napi::Env){});

  if (@available(macOS 10.14, *)) {
    AVMediaType media_type = (type == "microphone") ? AVMediaTypeAudio : AVMediaTypeVideo;
    [AVCaptureDevice requestAccessForMediaType:media_type
                             completionHandler:^(BOOL granted) {
      auto callback = [=](Napi::Env env, Napi::Function js_cb, const char* granted) {
        deferred.Resolve(Napi::String::New(env, granted));
      };
      ts_fn.BlockingCall(granted ? "authorized" : "denied", callback);
    }];
  } else {
    deferred.Resolve(Napi::String::New(env, "authorized"));
  }

  return deferred.Promise();
}

// Initializes all functions exposed to JS
Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports.Set(
    Napi::String::New(env, "getAuthStatus"), Napi::Function::New(env, GetAuthStatus)
  );
  exports.Set(
    Napi::String::New(env, "askForContactsAccess"), Napi::Function::New(env, AskForContactsAccess)
  );
  exports.Set(
    Napi::String::New(env, "askForCalendarAccess"), Napi::Function::New(env, AskForCalendarAccess)
  );
  exports.Set(
    Napi::String::New(env, "askForRemindersAccess"), Napi::Function::New(env, AskForRemindersAccess)
  );
  exports.Set(
    Napi::String::New(env, "askForFullDiskAccess"), Napi::Function::New(env, AskForFullDiskAccess)
  );
  exports.Set(
    Napi::String::New(env, "askForMediaAccess"), Napi::Function::New(env, AskForMediaAccess)
  );

  return exports;
}

NODE_API_MODULE(permissions, Init)