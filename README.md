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

## API

## `permissions.getAuthStatus(type)`

* `type` String - The type of system component to which you are requesting access. Can be one of 'contacts', 'full-disk-access', 'photos', 'reminders', or 'calendar'.

Returns `String` - Can be one of 'not determined', 'denied', 'authorized', or 'restricted'.

Checks the authorization status of the application to access `type` on macOS.

Return Value Descriptions: 
* 'not determined' - The user has not yet made a choice regarding whether the application may access `type` data.
* 'restricted' - The application is not authorized to access `type` data. The user cannot change this application’s status, possibly due to active restrictions such as parental controls being in place.
* 'denied' - The user explicitly denied access to `type` data for the application.
* 'authorized' - The application is authorized to access `type` data.

**Note:** Access to 'contacts' will always return a status of 'Authorized' prior to macOS 10.13 High Sierra, as access to contacts was unilaterally allowed until that version.

## `permissions.askForContactsAccess(callback)`

* `callback` Function
  * `error` String | null - An error in performing the request, if one occurred.
  * `status` String - Whether or not the request succeeded or failed; can be 'authorized' or 'denied'.

Your app’s `Info.plist` file must provide a value for the `NSContactsUsageDescription` key that explains to the user why your app is requesting Contacts access.

```
<key>NSContactsUsageDescription</key>
<string>Your reason for wanting to access the Contact store</string>
```

```js
const { askForContactsAccess } = require('node-mac-permissions')

askForContactsAccess((err, status) => {
  console.log(`Access to Contacts is ${status}`)
})
```

## `permissions.askForCalendarAccess(callback)`

* `callback` Function
  * `error` String | null - An error in performing the request, if one occurred.
  * `status` String - Whether or not the request succeeded or failed; can be 'authorized' or 'denied'.

```js
const { askForCalendarAccess } = require('node-mac-permissions')

askForCalendarAccess((err, status) => {
  console.log(`Access to Calendar is ${status}`)
})
```

## `permissions.askForRemindersAccess(callback)`

* `callback` Function
  * `error` String | null - An error in performing the request, if one occurred.
  * `status` String - Whether or not the request succeeded or failed; can be 'authorized' or 'denied'.

```js
const { askForRemindersAccess } = require('node-mac-permissions')

askForRemindersAccess((err, status) => {
  console.log(`Access to Reminders is ${status}`)
})
```

## `permissions.askForFullDiskAccess()`

```js
const { askForFullAccess } = require('node-mac-permissions')

askForRemindersAccess()
```
