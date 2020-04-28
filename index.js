const permissions = require('bindings')('permissions.node')

function getAuthStatus(type) {
  const validTypes = [
    'contacts',
    'calendar',
    'reminders',
    'full-disk-access',
    'camera',
    'photos',
    'microphone',
    'accessibility',
    'location',
    'screen',
  ]

  if (!validTypes.includes(type)) {
    throw new TypeError(`${type} is not a valid type`)
  }

  return permissions.getAuthStatus.call(this, type)
}

module.exports = {
  askForCalendarAccess: permissions.askForCalendarAccess,
  askForContactsAccess: permissions.askForContactsAccess,
  askForFullDiskAccess: permissions.askForFullDiskAccess,
  askForRemindersAccess: permissions.askForRemindersAccess,
  askForCameraAccess: permissions.askForCameraAccess,
  askForMicrophoneAccess: permissions.askForMicrophoneAccess,
  askForPhotosAccess: permissions.askForPhotosAccess,
  askForScreenCaptureAccess: permissions.askForScreenCaptureAccess,
  askForAccessibilityAccess: permissions.askForAccessibilityAccess,
  getAuthStatus,
}
