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

* `type` - The type of system component to which you are requesting access. Can be one of 'contacts', 'full-disk-access', 'photos', 'reminders', or 'calendar'.

Returns `String` - Can be one of 'Not Determined', 'Denied', 'Authorized', or 'Restricted'.

Checks the authorization status of the application to access `type` on macOS.

Return Value Descriptions: 
* 'Not Determined' - The user has not yet made a choice regarding whether the application may access `type` data.
* 'Not Authorized' - The application is not authorized to access `type` data. The user cannot change this application’s status, possibly due to active restrictions such as parental controls being in place.
* 'Denied' - The user explicitly denied access to `type` data for the application.
* 'Authorized' - The application is authorized to access `type` data.

**Note:** Access to 'contacts' will always return a status of 'Authorized' prior to macOS 10.13 High Sierra, as access to contacts was unilaterally allowed until that version.
