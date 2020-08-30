const { expect } = require('chai')
const {
  askForFoldersAccess,
  getAuthStatus,
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
        'screen'
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
})
