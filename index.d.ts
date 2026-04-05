// Type definitions for node-mac-permissions
// Project: node-mac-permissions

export function askForAppleEventsAccess(targetAppBundleId: string, shouldPrompt?: boolean): Promise<Omit<PermissionType, 'restricted'>>
export function askForAccessibilityAccess(): undefined
export function askForCalendarAccess(accessType?: 'write-only' | 'full'): Promise<Omit<PermissionType, 'restricted'>>
export function askForCameraAccess(): Promise<PermissionType>
export function askForContactsAccess(): Promise<Omit<PermissionType, 'restricted'>>
export function askForExternalStorageAccess(): Promise<PermissionType>
export function askForFocusStatusAccess(): Promise<PermissionType>
export function askForFoldersAccess(): Promise<Omit<PermissionType, 'restricted'>>
export function askForFullDiskAccess(): undefined
export function askForInputMonitoringAccess(accessType?: 'listen' | 'post'): Promise<Omit<PermissionType, 'restricted'>>
export function askForLocationAccess(accessType?: 'when-in-use' | 'always'): Promise<Omit<PermissionType, 'restricted'>>
export function askForMicrophoneAccess(): Promise<PermissionType>
export function askForPhotosAccess(accessType?: 'add-only' | 'read-write'): Promise<PermissionType>
export function askForRemindersAccess(): Promise<Omit<PermissionType, 'restricted'>>
export function askForSpeechRecognitionAccess(): Promise<Omit<PermissionType, 'restricted'>>
export function askForScreenCaptureAccess(openPreferences?: boolean): undefined
export function getAuthStatus(authType: AuthType): PermissionType | 'not determined' | 'provisional' | 'limited'

export type AuthType =
  | 'accessibility'
  | 'bluetooth'
  | 'calendar'
  | 'camera'
  | 'contacts'
  | 'external-storage'
  | 'focus-status'
  | 'full-disk-access'
  | 'input-monitoring'
  | 'location'
  | 'microphone'
  | 'music-library'
  | 'notifications'
  | 'photos-add-only'
  | 'photos-read-write'
  | 'reminders'
  | 'speech-recognition'
  | 'screen'

export type PermissionType =  'authorized' | 'denied' | 'restricted'
