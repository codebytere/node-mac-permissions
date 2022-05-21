const permissions = require('bindings')('permissions.node')

function getAuthStatus(type) {
  const validTypes = [
    'accessibility',
    'bluetooth',
    'calendar',
    'camera',
    'contacts',
    'full-disk-access',
    'input-monitoring',
    'location',
    'microphone',
    'music-library',
    'photos-add-only',
    'photos-read-write',
    'reminders',
    'speech-recognition',
    'screen',
  ]

  if (!validTypes.includes(type)) {
    throw new TypeError(`${type} is not a valid type`)
  }

  return permissions.getAuthStatus.call(this, type)
}

function askForFoldersAccess(folder) {
  const validFolders = ['desktop', 'documents', 'downloads']

  if (!validFolders.includes(folder)) {
    throw new TypeError(`${folder} is not a valid protected folder`)
  }

  return permissions.askForFoldersAccess.call(this, folder)
}

function askForPhotosAccess(accessLevel = 'add-only') {
  if (!['add-only', 'read-write'].includes(accessLevel)) {
    throw new TypeError(`${accessLevel} must be one of either 'add-only' or 'read-write'`)
  }

  return permissions.askForPhotosAccess.call(this, accessLevel)
}

module.exports = {
  askForAccessibilityAccess: permissions.askForAccessibilityAccess,
  askForCalendarAccess: permissions.askForCalendarAccess,
  askForCameraAccess: permissions.askForCameraAccess,
  askForContactsAccess: permissions.askForContactsAccess,
  askForFoldersAccess,
  askForFullDiskAccess: permissions.askForFullDiskAccess,
  askForInputMonitoringAccess: permissions.askForInputMonitoringAccess,
  askForRemindersAccess: permissions.askForRemindersAccess,
  askForMicrophoneAccess: permissions.askForMicrophoneAccess,
  askForMusicLibraryAccess: permissions.askForMusicLibraryAccess,
  askForPhotosAccess,
  askForSpeechRecognitionAccess: permissions.askForSpeechRecognitionAccess,
  askForScreenCaptureAccess: permissions.askForScreenCaptureAccess,
  getAuthStatus,
}
