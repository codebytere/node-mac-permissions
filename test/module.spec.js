const { expect } = require('chai')
const permissions = require('../index')

const { platform } = require('os')
const isMac = platform() === 'darwin'
it.ifMac = isMac ? it : it.skip
it.ifNotMac = isMac ? it.skip : it

describe('node-mac-permissions', () => {
  describe('getAuthStatus()', () => {
    it('should throw on invalid types', () => {
      expect(() => {
        permissions.getAuthStatus('bad-type')
      }).to.throw(/bad-type is not a valid type/)
    })

    it.ifMac('should return a string', () => {
      const types = [
        'contacts',
        'calendar',
        'reminders',
        'full-disk-access',
        'camera',
        'photos',
        'speech-recognition',
        'microphone',
        'accessibility',
        'location',
        'screen',
      ]

      const statuses = ['not determined', 'denied', 'authorized', 'restricted']
      for (const type of types) {
        const status = permissions.getAuthStatus(type)
        expect(statuses).to.contain(status)
      }
    })
  })

  describe('askForFoldersAccess()', () => {
    it('should throw on invalid types', () => {
      expect(() => {
        permissions.askForFoldersAccess('bad-type')
      }).to.throw(/bad-type is not a valid protected folder/)
    })
  })

  describe('conditional binding', () => {
    it.ifNotMac('always return undefined for non-mac OS', async () => {
      const asyncModuleExports = [
        'askForCalendarAccess',
        'askForContactsAccess',
        'askForFullDiskAccess',
        'askForRemindersAccess',
        'askForCameraAccess',
        'askForMicrophoneAccess',
        'askForPhotosAccess',
        'askForSpeechRecognitionAccess',
        'askForScreenCaptureAccess',
        'askForAccessibilityAccess',
      ]

      for (const func of asyncModuleExports) {
        const auth = await permissions[func]()
        expect(auth).to.be.undefined
      }

      expect(permissions.getAuthStatus('contacts')).to.be.undefined
      expect(permissions.askForFoldersAccess('desktop')).to.be.undefined
    })
  })
})
