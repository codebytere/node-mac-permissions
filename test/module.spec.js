const { expect } = require('chai')
const { 
  getAuthStatus
} = require('../index')

describe('node-mac-permissions', () => {
  describe('getAuthStatus()', () => {
    it('should throw on invalid types', () => {
      expect(() => {
        getAuthStatus('bad-type')
      }).to.throw(/bad-type is not a valid type/)
    })

    it('should return a string', () => {
      const types = ['contacts', 'calendar', 'reminders', 'photos', 'full-disk-access']
      const statuses = ['Not Determined', 'Denied', 'Authorized', 'Restricted']
      for (const type of types) {
        const status = getAuthStatus(type)
        expect(statuses).to.contain(status)
      }
    })
  })
})