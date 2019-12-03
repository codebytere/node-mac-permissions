#include <napi.h>

// Apple APIs
#import <AppKit/AppKit.h>
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
  std::string auth_status = "Not Determined";

  CNEntityType entityType = CNEntityTypeContacts;
  CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:entityType];

  if (status == CNAuthorizationStatusAuthorized)
    auth_status = "Authorized";
  else if (status == CNAuthorizationStatusDenied)
    auth_status = "Denied";
  else if (status == CNAuthorizationStatusRestricted)
    auth_status = "Restricted";

  return auth_status;
}

// Returns a status indicating whether or not the user has authorized Calendar access
std::string EventAuthStatus(std::string type) {
  std::string auth_status = "Not Determined";

  EKEntityType entityType = (type == "calendar") ? EKEntityTypeEvent : EKEntityTypeReminder;
  EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:entityType];

  if (status == EKAuthorizationStatusAuthorized)
    auth_status = "Authorized";
  else if (status == EKAuthorizationStatusDenied)
    auth_status = "Denied";
  else if (status == EKAuthorizationStatusRestricted)
    auth_status = "Restricted";

  return auth_status;
}

// Returns a status indicating whether or not the user has authorized Photos access
std::string PhotosAuthStatus() {
  std::string auth_status = "Not Determined";
  
  if (@available(macOS 10.13, *)) {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];

    if (status == PHAuthorizationStatusAuthorized)
      auth_status = "Authorized";
    else if (status == PHAuthorizationStatusDenied)
      auth_status = "Denied";
    else if (status == PHAuthorizationStatusRestricted)
      auth_status = "Restricted";
  } else {
    auth_status = "Authorized";
  }

  return auth_status;
}

std::string FDAAuthStatus() {
  std::string auth_status = "Not Determined";
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
    auth_status = "Denied";
  } else if (file_exists) {
    auth_status = "Authorized";
  }

  return auth_status;
}

/***** EXPORTED FUNCTIONS *****/

// Returns the user's access consent status as a string
Napi::Value GetAuthStatus(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();
  std::string auth_status;

  const std::string type = info[0].As<Napi::String>().Utf8Value();
  if (type == "contacts") {
    auth_status = ContactAuthStatus();
  } else if (type == "calendar") {
    auth_status = EventAuthStatus("calendar");
  } else if (type == "photos") {
    auth_status = PhotosAuthStatus();
  }  else if (type == "reminders") {
    auth_status = EventAuthStatus("reminders");
  } else if (type == "full-disk-access") {
    auth_status = FDAAuthStatus();
  }

  return Napi::Value::From(env, auth_status);
}

// Initializes all functions exposed to JS
Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports.Set(
    Napi::String::New(env, "getAuthStatus"), Napi::Function::New(env, GetAuthStatus)
  );

  return exports;
}

NODE_API_MODULE(permissions, Init)