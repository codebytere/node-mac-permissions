const permissions = require('node-gyp-build')(__dirname)

function getAuthStatus(type) {
  const validTypes = [
    'contacts',
    'calendar',
    'reminders',
    'full-disk-access',
    'camera',
    'photos',
    'speech-recognition',
    'microphone',
    'music-library',
    'accessibility',
    'location',
    'screen',
    'bluetooth',
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
  askForCalendarAccess: permissions.askForCalendarAccess,
  askForContactsAccess: permissions.askForContactsAccess,
  askForFoldersAccess,
  askForFullDiskAccess: permissions.askForFullDiskAccess,
  askForRemindersAccess: permissions.askForRemindersAccess,
  askForCameraAccess: permissions.askForCameraAccess,
  askForMicrophoneAccess: permissions.askForMicrophoneAccess,
  askForMusicLibraryAccess: permissions.askForMusicLibraryAccess,
  askForPhotosAccess: permissions.askForPhotosAccess,
  askForSpeechRecognitionAccess: permissions.askForSpeechRecognitionAccess,
  askForScreenCaptureAccess: permissions.askForScreenCaptureAccess,
  askForAccessibilityAccess: permissions.askForAccessibilityAccess,
  getAuthStatus,
}
