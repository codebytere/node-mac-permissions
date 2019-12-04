const { expect } = require('chai')
const { 
  getAuthStatus,
  askForMediaAccess
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
        'microphone'
      ]

      const statuses = ['not determined', 'denied', 'authorized', 'restricted']
      for (const type of types) {
        const status = getAuthStatus(type)
        expect(statuses).to.contain(status)
      }
    })
  })

  describe('askForMediaAccess(type, callback)', () => {
    it ('throws on invalid media types', () => {
      expect(() => {
        askForMediaAccess('bad-type', (status) =>{
          console.log(status)
        })
      }).to.throw(/bad-type must be either 'camera' or 'microphone'/)
    })
  })
})
