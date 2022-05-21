{
  "targets": [{
    "target_name": "permissions",
    "sources": [ ],
    "conditions": [
      ['OS=="mac"', {
        "sources": [
          "permissions.mm"
        ],
      }]
    ],
    'include_dirs': [
      "<!@(node -p \"require('node-addon-api').include\")"
    ],
    'libraries': [],
    'dependencies': [
      "<!(node -p \"require('node-addon-api').gyp\")"
    ],
    'defines': [ 'NAPI_DISABLE_CPP_EXCEPTIONS' ],
    "xcode_settings": {
      "MACOSX_DEPLOYMENT_TARGET": "10.13",
      "SYSTEM_VERSION_COMPAT": 1,
      "OTHER_CPLUSPLUSFLAGS": ["-std=c++14", "-stdlib=libc++"],
      "OTHER_LDFLAGS": [
        "-framework AppKit",
        "-framework AVFoundation",
        "-framework CoreBluetooth",
        "-framework CoreFoundation",
        "-framework CoreLocation",
        "-framework CoreGraphics",
        "-framework Contacts",
        "-framework EventKit",
        "-framework IOKit",
        "-framework Photos",
        "-framework Speech",
        "-framework Storekit"
      ]
    }
  }]
}
