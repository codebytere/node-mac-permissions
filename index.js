const permissions = require('bindings')('permissions.node')

function getAuthStatus(type) {
  const validTypes = ['contacts', 'calendar', 'reminders', 'full-disk-access']
  if (!validTypes.includes(type)) {
    throw new TypeError(`${type} is not a valid type`)
  }

  return permissions.getAuthStatus.call(this, type)
} 

module.exports = {
  getAuthStatus,
  askForContactsAccess: permissions.askForContactsAccess,
  askForCalendarAccess: permissions.askForCalendarAccess,
  askForRemindersAccess: permissions.askForRemindersAccess,
  askForFullDiskAccess: permissions.askForFullDiskAccess
}