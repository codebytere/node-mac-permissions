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

Returns `String` - Can be one of 'Not Determined', 'Denied', 'Authorized', or 'Restricted'.

Checks the authorization status of the application to access `type` on macOS.

Return Value Descriptions: 
* 'Not Determined' - The user has not yet made a choice regarding whether the application may access `type` data.
* 'Not Authorized' - The application is not authorized to access `type` data. The user cannot change this application’s status, possibly due to active restrictions such as parental controls being in place.
* 'Denied' - The user explicitly denied access to `type` data for the application.
* 'Authorized' - The application is authorized to access `type` data.

**Note:** Access to 'contacts' will always return a status of 'Authorized' prior to macOS 10.13 High Sierra, as access to contacts was unilaterally allowed until that version.

## `permissions.askForContactsAccess(callback)`

* `callback` Function
  * `error` String | null - An error in performing the request, if one occurred.
  * `status` String - Whether or not the request succeeded or failed; can be 'authorized' or 'denied'.

In your app, you should put the reason you're requesting to manipulate user's contacts database in your `Info.plist` like so:

```
<key>NSContactsUsageDescription</key>
<string>Your reason for wanting to access the Contact store</string>
```

```js
const { askForContactsAccess } = require('node-mac-permissions')

askForContactsAccess((err, status) => {
  console.log(`Access to Contacts was ${status}`)
})
```
