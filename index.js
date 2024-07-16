const permissions = require('bindings')('permissions.node')
const isMac = process.platform === 'darwin'

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

function askForCalendarAccess(accessLevel = 'write-only') {
  if (!['write-only', 'full'].includes(accessLevel)) {
    throw new TypeError(`${accessLevel} must be one of either 'write-only' or 'full'`)
  }

  return permissions.askForCalendarAccess.call(this, accessLevel)
}

function askForScreenCaptureAccess(openPreferences = false) {
  if (typeof openPreferences !== 'boolean') {
    throw new TypeError('openPreferences must be a boolean')
  }

  return permissions.askForScreenCaptureAccess.call(this, openPreferences)
}

function askForPhotosAccess(accessLevel = 'add-only') {
  if (!['add-only', 'read-write'].includes(accessLevel)) {
    throw new TypeError(`${accessLevel} must be one of either 'add-only' or 'read-write'`)
  }

  return permissions.askForPhotosAccess.call(this, accessLevel)
}

function askForInputMonitoringAccess(accessLevel = 'listen') {
  if (!['listen', 'post'].includes(accessLevel)) {
    throw new TypeError(`${accessLevel} must be one of either 'listen' or 'post'`)
  }

  return permissions.askForInputMonitoringAccess.call(this, accessLevel)
}

function notOnMacPlatform() {
  return false
}

module.exports = {
  askForAccessibilityAccess: isMac ? permissions.askForAccessibilityAccess : notOnMacPlatform,
  askForCalendarAccess: isMac ? askForCalendarAccess : notOnMacPlatform,
  askForCameraAccess: isMac ? permissions.askForCameraAccess : notOnMacPlatform,
  askForContactsAccess: isMac ? permissions.askForContactsAccess : notOnMacPlatform,
  askForFoldersAccess: isMac ? askForFoldersAccess : notOnMacPlatform,
  askForFullDiskAccess: isMac ? permissions.askForFullDiskAccess : notOnMacPlatform,
  askForInputMonitoringAccess: isMac ? askForInputMonitoringAccess : notOnMacPlatform,
  askForRemindersAccess: isMac ? permissions.askForRemindersAccess : notOnMacPlatform,
  askForMicrophoneAccess: isMac ? permissions.askForMicrophoneAccess : notOnMacPlatform,
  askForMusicLibraryAccess: isMac ? permissions.askForMusicLibraryAccess : notOnMacPlatform,
  askForPhotosAccess: isMac ? askForPhotosAccess : notOnMacPlatform,
  askForSpeechRecognitionAccess: isMac ? permissions.askForSpeechRecognitionAccess : notOnMacPlatform,
  askForScreenCaptureAccess: isMac ? askForScreenCaptureAccess : notOnMacPlatform,
  getAuthStatus: isMac ? getAuthStatus : notOnMacPlatform,
}
