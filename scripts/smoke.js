const fs = require('fs');
const path = require('path');

const dist = path.resolve(__dirname, '..', 'dist');
const index = path.join(dist, 'index.html');

function fail(msg){
  console.error('SMOKE FAIL:', msg);
  process.exit(2);
}

if(!fs.existsSync(dist)) fail('dist directory not found — run build first');
if(!fs.existsSync(index)) fail('dist/index.html not found');

const html = fs.readFileSync(index, 'utf8');
if(!html.includes('id="root"') && !html.includes('<div id=\"root\"')) fail('root element not found in index.html');

// ensure there is at least one asset file in dist/assets
const assetsDir = path.join(dist, 'assets');
if(!fs.existsSync(assetsDir)) fail('dist/assets folder not found');
const assets = fs.readdirSync(assetsDir).filter(Boolean);
if(assets.length === 0) fail('no asset files found in dist/assets');

console.log('SMOKE OK — built assets present, index contains root');
process.exit(0);
