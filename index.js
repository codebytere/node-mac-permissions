const permissions = require('bindings')('permissions.node')

function getAuthStatus(type) {
  const validTypes = [
    'contacts',
    'calendar',
    'reminders',
    'full-disk-access',
    'camera',
    'microphone'
  ]

  if (!validTypes.includes(type)) {
    throw new TypeError(`${type} is not a valid type`)
  }

  return permissions.getAuthStatus.call(this, type)
}

/**
 * askHelper_
 * @param {functon} target The binding to call
 * @param {function} [callback] optional, returns promise if not supplied
 * @returns {?Promise<string>}
 */
function askHelper_(target, opt_callback) {
  if (opt_callback) {
    if (typeof opt_callback !== 'function') {
      throw new TypeError(`callback must be a function`)
    }
    return target.call(this, opt_callback)
  }
  return new Promise(resolve, unused_reject, () => {
    return target.call(this, resolve)
  })
}

/**
 * @param {function} opt_callback
 * @returns {?Promise<string>}
 */
function askForCalendarAccess(opt_callback) {
  return askHelper_(permissions.askForCalendarAccess, opt_callback)
}

/**
 * @param {function} opt_callback
 * @returns {?Promise<string>}
 */
function askForContactsAccess(opt_callback) {
  return askHelper_(permissions.askForContactsAccess, opt_callback)
}

/**
 * @param {function} opt_callback
 * @returns {?Promise<string>}
 */
function askForRemindersAccess(opt_callback) {
  return askHelper_(permissions.askForRemindersrAccess, opt_callback)
}

/**
 * askForMediaAccess
 * @param {string} type type of access requested
 * @param {function} [opt_callback] callback
 * @returns {?Promise<string>} if callback is not supplied returns a Promise of the result
 */
function askForMediaAccess(type, opt_callback) {
  if (['microphone', 'camera'].includes(type)) {
    throw new TypeError(`${type} must be either 'camera' or 'microphone'`)
  }
  if (opt_callback) {
    if (typeof opt_callback !== 'function') {
      throw new TypeError(`callback must be a function`)
    }
    return permissions.askForMediaAccess.call(this, type, opt_callback)
  }
  return new Promise(resolve, unused_reject, () => {
    permissions.askForMediaAccess.call(this, type, resolve);
  })
}


module.exports = {
  askForCalendarAccess,
  askForContactsAccess,
  askForFullDiskAccess: permissions.askForFullDiskAccess,
  askForRemindersAccess,
  askForMediaAccess,
  getAuthStatus
}
