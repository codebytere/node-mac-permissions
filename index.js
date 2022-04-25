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
    'photos',
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

module.exports = {
  askForAccessibilityAccess: permissions.askForAccessibilityAccess,
  askForCalendarAccess: permissions.askForCalendarAccess,
  askForCameraAccess: permissions.askForCameraAccess,
  askForContactsAccess: permissions.askForContactsAccess,
  askForFoldersAccess,
  askForFullDiskAccess: permissions.askForFullDiskAccess,
  askForRemindersAccess: permissions.askForRemindersAccess,
  askForMicrophoneAccess: permissions.askForMicrophoneAccess,
  askForMusicLibraryAccess: permissions.askForMusicLibraryAccess,
  askForPhotosAccess: permissions.askForPhotosAccess,
  askForSpeechRecognitionAccess: permissions.askForSpeechRecognitionAccess,
  askForScreenCaptureAccess: permissions.askForScreenCaptureAccess,
  getAuthStatus,
}
