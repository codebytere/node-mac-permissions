const permissions = require('bindings')('permissions.node')

function getAuthStatus(type) {
  const validTypes = [
    'contacts',
    'calendar',
    'reminders',
    'full-disk-access',
    'camera',
    'microphone'
  ]

  if (!validTypes.includes(type)) {
    throw new TypeError(`${type} is not a valid type`)
  }

  return permissions.getAuthStatus.call(this, type)
} 

function askForMediaAccess(type, callback) {
  if (['microphone', 'camera'].includes(type)) {
    throw new TypeError(`${type} must be either 'camera' or 'microphone'`)
  }
  if (typeof callback !== 'function') {
    throw new TypeError(`callback must be a function`)
  }

  return permissions.askForMediaAccess.call(this, type, callback)
}

module.exports = {
  askForCalendarAccess: permissions.askForCalendarAccess,
  askForContactsAccess: permissions.askForContactsAccess,
  askForFullDiskAccess: permissions.askForFullDiskAccess,
  askForRemindersAccess: permissions.askForRemindersAccess,
  askForMediaAccess,
  getAuthStatus
}