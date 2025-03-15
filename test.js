const { askForCalendarAccess, getAuthStatus } = require('./index.js')

const status = getAuthStatus('calendar')
console.log(`Current access status: ${status}`)

askForCalendarAccess().then((status) => {
  console.log(`Access to Contacts is ${status}`)
})
