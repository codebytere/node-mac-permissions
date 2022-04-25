// Type definitions for node-mac-permissions
// Project: node-mac-permissions

export function askForCalendarAccess(): Promise<Omit<PermissionType, 'restricted'>>
export function askForContactsAccess(): Promise<Omit<PermissionType, 'restricted'>>
export function askForFoldersAccess(): Promise<Omit<PermissionType, 'restricted'>>
export function askForFullDiskAccess(): undefined
export function askForRemindersAccess(): Promise<Omit<PermissionType, 'restricted'>>
export function askForCameraAccess(): Promise<PermissionType>
export function askForMicrophoneAccess(): Promise<PermissionType>
export function askForPhotosAccess(): Promise<PermissionType>
export function askForSpeechRecognitionAccess(): Promise<Omit<PermissionType, 'restricted'>>
export function askForScreenCaptureAccess(): undefined
export function askForAccessibilityAccess(): undefined
export function getAuthStatus(authType: AuthType): PermissionType | 'not determined'

export type AuthType =
  | 'bluetooth'
  | 'contacts'
  | 'calendar'
  | 'reminders'
  | 'full-disk-access'
  | 'camera'
  | 'photos'
  | 'speech-recognition'
  | 'microphone'
  | 'music-library'
  | 'accessibility'
  | 'location'
  | 'screen'

export type PermissionType =  'authorized' | 'denied' | 'restricted'
