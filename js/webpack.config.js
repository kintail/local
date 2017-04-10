var path = require('path');

module.exports = {
  entry: './kintail-local.js',
  output: {
    filename: 'kintail-local.js',
    path: path.resolve(__dirname, 'dist'),
    library: ['Kintail', 'Local']
  }
};
