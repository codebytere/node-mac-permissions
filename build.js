const { promisify } = require('util');
// eslint-disable-next-line import/no-extraneous-dependencies
const prebuildify = promisify(require('prebuildify'));

const { platform } = process;

const getSupportedArchs = () => {
  if (platform === 'darwin') {
    return ['x64', 'arm64'];
  }

  if (platform === 'win32') {
    return ['x64', 'ia32'];
  }

  return [];
};

async function build() {
  // eslint-disable-next-line no-restricted-syntax
  for (const arch of getSupportedArchs()) {
    // eslint-disable-next-line no-await-in-loop
    await prebuildify({
      platform,
      arch,
      napi: true,
    });
  }
}

build();
