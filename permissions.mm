#include <napi.h>

// Apple APIs
#import <AppKit/AppKit.h>
#import <AVFoundation/AVFoundation.h> 
#import <Contacts/Contacts.h>
#import <EventKit/EventKit.h>
#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <pwd.h>

/***** HELPER FUNCTIONS *****/

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
  }

  return Napi::Value::From(env, auth_status);
}

// Request access to the Contacts store.
void AskForContactsAccess(const Napi::CallbackInfo& info) {
  Napi::Env env = info.Env();
  Napi::ThreadSafeFunction ts_fn = Napi::ThreadSafeFunction::New(env,
                                                                 info[0].As<Napi::Function>(),
                                                                 "Resource Name",
                                                                 0,
                                                                 1,
                                                                 [](Napi::Env){});

  if (@available(macOS 10.11, *)) {
    CNContactStore *store = [CNContactStore new];
    [store requestAccessForEntityType:CNEntityTypeContacts
                    completionHandler:^(BOOL granted, NSError* error) {
      auto callback = [](Napi::Env env, Napi::Function js_cb, const char* granted) {
        js_cb.Call({Napi::String::New(env, granted)});
      };
      ts_fn.BlockingCall(granted ? "authorized" : "denied", callback);
    }];
  } else {
    Napi::FunctionReference fn = Napi::Persistent(info[0].As<Napi::Function>());
    fn.Call({Napi::String::New(env, "authorized")});
  }
}

// Request access to Calendar.
void AskForCalendarAccess(const Napi::CallbackInfo& info) {
  Napi::Env env = info.Env();
  Napi::ThreadSafeFunction ts_fn = Napi::ThreadSafeFunction::New(env,
                                                                 info[0].As<Napi::Function>(),
                                                                 "Resource Name",
                                                                 0,
                                                                 1,
                                                                 [](Napi::Env){});

  [[EKEventStore new] requestAccessToEntityType:EKEntityTypeEvent
                                     completion:^(BOOL granted, NSError * error) {
    auto callback = [](Napi::Env env, Napi::Function js_cb, const char* granted) {
      js_cb.Call({Napi::String::New(env, granted)});
    };
    ts_fn.BlockingCall(granted ? "authorized" : "denied", callback);
  }];
}

// Request access to Reminders.
void AskForRemindersAccess(const Napi::CallbackInfo& info) {
  Napi::Env env = info.Env();
  Napi::ThreadSafeFunction ts_fn = Napi::ThreadSafeFunction::New(env,
                                                                 info[0].As<Napi::Function>(),
                                                                 "Resource Name",
                                                                 0,
                                                                 1,
                                                                 [](Napi::Env){});

  [[EKEventStore new] requestAccessToEntityType:EKEntityTypeReminder
                                    completion:^(BOOL granted, NSError * error) {
    auto callback = [](Napi::Env env, Napi::Function js_cb, const char* granted) {
      js_cb.Call({Napi::String::New(env, granted)});
    };
    ts_fn.BlockingCall(granted ? "authorized" : "denied", callback);
  }];
}

// Request Full Disk Access.
void AskForFullDiskAccess(const Napi::CallbackInfo &info) {
  NSWorkspace* workspace = [[NSWorkspace alloc] init];
  NSString* pref_string = @"x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles";
  [workspace openURL:[NSURL URLWithString:pref_string]];
}

// Request access to either the Camera or the Microphone.
void AskForMediaAccess(const Napi::CallbackInfo& info) {
  Napi::Env env = info.Env();
  const std::string type = info[0].As<Napi::String>().Utf8Value();
  Napi::ThreadSafeFunction ts_fn = Napi::ThreadSafeFunction::New(env,
                                                                 info[1].As<Napi::Function>(),
                                                                 "Resource Name",
                                                                 0,
                                                                 1,
                                                                 [](Napi::Env){});

  if (@available(macOS 10.14, *)) {
    AVMediaType media_type = (type == "microphone") ? AVMediaTypeAudio : AVMediaTypeVideo;
    [AVCaptureDevice requestAccessForMediaType:media_type
                             completionHandler:^(BOOL granted) {
      auto callback = [](Napi::Env env, Napi::Function js_cb, const char* granted) {
        js_cb.Call({Napi::String::New(env, granted)});
      };
      ts_fn.BlockingCall(granted ? "authorized" : "denied", callback);
    }];
  } else {
    Napi::FunctionReference fn = Napi::Persistent(info[0].As<Napi::Function>());
    fn.Call({Napi::String::New(env, "authorized")});
  }
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