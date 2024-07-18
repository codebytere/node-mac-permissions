const isMac = process.platform === 'darwin'

function getPermissionsHandler() {
  const permissions = require('bindings')('permissions.node')

  return permissions
}

function getAuthStatus(type) {
  if (!isMac) {
    return
  }

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

  return getPermissionsHandler().getAuthStatus.call(this, type)
}

function askForAccessibilityAccess() {
  if (!isMac) {
    return
  }

  return getPermissionsHandler().askForAccessibilityAccess.call(this)
}

function askForFoldersAccess(folder) {
  if (!isMac) {
    return
  }

  const validFolders = ['desktop', 'documents', 'downloads']

  if (!validFolders.includes(folder)) {
    throw new TypeError(`${folder} is not a valid protected folder`)
  }

  return getPermissionsHandler().askForFoldersAccess.call(this, folder)
}

function askForCalendarAccess(accessLevel = 'write-only') {
  if (!isMac) {
    return
  }

  if (!['write-only', 'full'].includes(accessLevel)) {
    throw new TypeError(`${accessLevel} must be one of either 'write-only' or 'full'`)
  }

  return getPermissionsHandler().askForCalendarAccess.call(this, accessLevel)
}

function askForCameraAccess() {
  if (!isMac) {
    return
  }

  return getPermissionsHandler().askForCameraAccess.call(this)
}

function askForScreenCaptureAccess(openPreferences = false) {
  if (!isMac) {
    return
  }

  if (typeof openPreferences !== 'boolean') {
    throw new TypeError('openPreferences must be a boolean')
  }

  return getPermissionsHandler().askForScreenCaptureAccess.call(this, openPreferences)
}

function askForPhotosAccess(accessLevel = 'add-only') {
  if (!isMac) {
    return
  }

  if (!['add-only', 'read-write'].includes(accessLevel)) {
    throw new TypeError(`${accessLevel} must be one of either 'add-only' or 'read-write'`)
  }

  return getPermissionsHandler().askForPhotosAccess.call(this, accessLevel)
}

function askForInputMonitoringAccess(accessLevel = 'listen') {
  if (!isMac) {
    return
  }

  if (!['listen', 'post'].includes(accessLevel)) {
    throw new TypeError(`${accessLevel} must be one of either 'listen' or 'post'`)
  }

  return getPermissionsHandler().askForInputMonitoringAccess.call(this, accessLevel)
}

function askForContactsAccess() {
  if (!isMac) {
    return
  }

  return getPermissionsHandler().askForContactsAccess.call(this)
}

function askForFullDiskAccess() {
  if (!isMac) {
    return
  }

  return getPermissionsHandler().askForFullDiskAccess.call(this)
}

function askForRemindersAccess() {
  if (!isMac) {
    return
  }

  return getPermissionsHandler().askForRemindersAccess.call(this)
}

function askForMicrophoneAccess() {
  if (!isMac) {
    return
  }

  return getPermissionsHandler().askForMicrophoneAccess.call(this)
}

function askForMusicLibraryAccess() {
  if (!isMac) {
    return
  }

  return getPermissionsHandler().askForMusicLibraryAccess.call(this)
}

function askForSpeechRecognitionAccess() {
  if (!isMac) {
    return
  }

  return getPermissionsHandler().askForSpeechRecognitionAccess.call(this)
}

module.exports = {
  askForAccessibilityAccess: askForAccessibilityAccess,
  askForCalendarAccess: askForCalendarAccess,
  askForCameraAccess: askForCameraAccess,
  askForContactsAccess: askForContactsAccess,
  askForFoldersAccess: askForFoldersAccess,
  askForFullDiskAccess: askForFullDiskAccess,
  askForInputMonitoringAccess: askForInputMonitoringAccess,
  askForRemindersAccess: askForRemindersAccess,
  askForMicrophoneAccess: askForMicrophoneAccess,
  askForMusicLibraryAccess: askForMusicLibraryAccess,
  askForPhotosAccess: askForPhotosAccess,
  askForSpeechRecognitionAccess: askForSpeechRecognitionAccess,
  askForScreenCaptureAccess: askForScreenCaptureAccess,
  getAuthStatus: getAuthStatus,
}
