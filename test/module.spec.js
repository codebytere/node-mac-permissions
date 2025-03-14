const { expect } = require('chai')
const {
  askForFoldersAccess,
  askForCalendarAccess,
  getAuthStatus,
  askForPhotosAccess,
  askForScreenCaptureAccess,
  askForInputMonitoringAccess,
  askForLocationAccess,
} = require('../index')

describe('node-mac-permissions', () => {
  describe('getAuthStatus()', () => {
    it('should throw on invalid types', () => {
      expect(() => {
        getAuthStatus('bad-type')
      }).to.throw(/bad-type is not a valid type/)
    })

    it('should return a string', () => {
      const types = [
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

      const statuses = ['not determined', 'denied', 'authorized', 'restricted']
      for (const type of types) {
        const status = getAuthStatus(type)
        expect(statuses).to.contain(status)
      }
    })
  })

  describe('askForFoldersAccess()', () => {
    it('should throw on invalid types', () => {
      expect(() => {
        askForFoldersAccess('bad-type')
      }).to.throw(/bad-type is not a valid protected folder/)
    })
  })

  describe('askForCalendarAccess([accessLevel])', () => {
    it('should throw on invalid accessLevel', () => {
      expect(() => {
        askForCalendarAccess('bad-type')
      }).to.throw(/bad-type must be one of either 'write-only' or 'full'/)
    })
  })

  describe('askForInputMonitoringAccess()', () => {
    it('should throw on invalid types', () => {
      expect(() => {
        askForInputMonitoringAccess('bad-type')
      }).to.throw(/bad-type must be one of either 'listen' or 'post'/)
    })
  })

  describe('askForPhotosAccess()', () => {
    it('should throw on invalid types', () => {
      expect(() => {
        askForPhotosAccess('bad-type')
      }).to.throw(/bad-type must be one of either 'add-only' or 'read-write'/)
    })
  })

  describe('askForScreenCaptureAccess()', () => {
    it('should throw on invalid openPreferences type', () => {
      expect(() => {
        askForScreenCaptureAccess('bad-type')
      }).to.throw(/openPreferences must be a boolean/)
    })
  })

  describe('askForLocationAccess()', () => {
    it('should throw on invalid accessLevel type', () => {
      expect(() => {
        askForLocationAccess('bad-type')
      }).to.throw(/bad-type must be one of either 'when-in-use' or 'always'/)
    })
  })
})
