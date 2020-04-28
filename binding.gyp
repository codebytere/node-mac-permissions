{
  "targets": [{
    "target_name": "permissions",
    "sources": [ ],
    "conditions": [
      ['OS=="mac"', {
        "xcode_settings": {
          "MACOSX_DEPLOYMENT_TARGET": "10.10"
        },
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
      "OTHER_CPLUSPLUSFLAGS": ["-std=c++14", "-stdlib=libc++"],
      "OTHER_LDFLAGS": ["-framework CoreFoundation -framework CoreLocation -framework AppKit -framework Contacts -framework Photos -framework EventKit -framework AVFoundation"]
    }
  }]
}