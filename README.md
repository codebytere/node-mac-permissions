# node-mac-permissions

```js
$ npm i node-mac-permissions
```

This native Node.js module allows you to manage an app's access to:

* Contacts
* Full Disk Access
* Calendar
* Reminders
* Photos
* Camera
* Microphone

## API

## `permissions.getAuthStatus(type)`

* `type` String - The type of system component to which you are requesting access. Can be one of 'contacts', 'full-disk-access', 'photos', 'reminders', 'camera', 'microphone', or 'calendar'.

Returns `String` - Can be one of 'not determined', 'denied', 'authorized', or 'restricted'.

Checks the authorization status of the application to access `type` on macOS.

Return Value Descriptions: 
* 'not determined' - The user has not yet made a choice regarding whether the application may access `type` data.
* 'restricted' - The application is not authorized to access `type` data. The user cannot change this application’s status, possibly due to active restrictions such as parental controls being in place.
* 'denied' - The user explicitly denied access to `type` data for the application.
* 'authorized' - The application is authorized to access `type` data.

**Notes:**
  * Access to 'contacts' will always return a status of 'Authorized' prior to macOS 10.11, as access to contacts was unilaterally allowed until that version.
  * Access to 'camera' and 'microphone' will always return a status of 'Authorized' prior to macOS 10.14, as access to contacts was unilaterally allowed until that version.

## `permissions.askForContactsAccess(callback)`

* `callback` Function (optional, returns a Promise<String> if callback is not supplied)
  * `status` String - Whether or not the request succeeded or failed; can be 'authorized' or 'denied'.

Your app’s `Info.plist` file must provide a value for the `NSContactsUsageDescription` key that explains to the user why your app is requesting Contacts access.

```
<key>NSContactsUsageDescription</key>
<string>Your reason for wanting to access the Contact store</string>
```

**Note:** `status` will be called back as 'authorized' prior to macOS 10.11, as access to contacts was unilaterally allowed until that version.

Example:
```js
const { askForContactsAccess } = require('node-mac-permissions')

askForContactsAccess((status) => {
  console.log(`Access to Contacts is ${status}`)
})

// Or as a Promise
askForContactsAccess().then((status) => {
  console.log(`Access to Contacts is ${status}`)
})
```

## `permissions.askForCalendarAccess(callback)`

* `callback` Function (optional, returns a Promise<String> if callback is not supplied)
  * `status` String - Whether or not the request succeeded or failed; can be 'authorized' or 'denied'.

Example:
```js
const { askForCalendarAccess } = require('node-mac-permissions')

askForCalendarAccess((status) => {
  console.log(`Access to Calendar is ${status}`)
})

// Or as a Promise
askForCalendarAccess().then((status) => {
  console.log(`Access to Calendar is ${status}`)
})
```

## `permissions.askForRemindersAccess(callback)`

* `callback` Function (optional, returns a Promise<String> if callback is not supplied)
  * `status` String - Whether or not the request succeeded or failed; can be 'authorized' or 'denied'.

Example:
```js
const { askForRemindersAccess } = require('node-mac-permissions')

askForRemindersAccess((status) => {
  console.log(`Access to Reminders is ${status}`)
})

// Or as a Promise
askForRemindersAccess().then((status) => {
  console.log(`Access to Reminders is ${status}`)
})
```

## `permissions.askForFullDiskAccess()`

There is no API for programmatically requesting Full Disk Access on macOS at this time, and so calling this method will trigger opening of System Preferences at the Full Disk pane of Security and Privacy.

Example:
```js
const { askForFullDiskAccess } = require('node-mac-permissions')

askForFullDiskAccess()
```

## `permissions.askForMediaAccess(type, callback)`

* `type` String - The type of media to which you are requesting access. Can be 'microphone' or 'camera'.

* `callback` Function (optional, returns a Promise<String> if callback is not supplied)
  * `status` String - Whether or not the request succeeded or failed; can be 'authorized' or 'denied'.

Your app must provide an explanation for its use of capture devices using the `NSCameraUsageDescription` or `NSMicrophoneUsageDescription` `Info.plist` keys; Calling this method or attempting to start a capture session without a usage description raises an exception.

```
<key>`NSCameraUsageDescription</key>
<string>Your reason for wanting to access the Camera</string>
<key>`NSMicrophoneUsageDescription</key>
<string>Your reason for wanting to access the Microphone</string>
```

**Note:** `status` will be called back as 'authorized' prior to macOS 10.14 High Sierra, as access to the camera and microphone was unilaterally allowed until that version.

Example using callback:
```js
const { askForMediaAccess } = require('node-mac-permissions')

for (const type of ['microphone', 'camera']) {
  askForMediaAccess(type, (status) => {
    console.log(`Access to media type ${type} is ${status}`)
  })
}

Example using Promise:
```js
const { askForMediaAccess } = require('node-mac-permissions')

askForMediaAccess('camera').then((status) => {
  console.log(`Access to media type "camera" is ${status}`)
})
```
