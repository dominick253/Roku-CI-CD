// scripts/run-tests.js

const axios = require('axios');
const xml2js = require('xml2js');
const parser = new xml2js.Parser({ explicitArray: false, explicitRoot: false, mergeAttrs: true });

const ROKU_IP = '10.71.71.152';
const ECP_BASE_URL = `http://${ROKU_IP}:8060`;

async function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function getActiveAppId() {
  console.log('Fetching active app...');
  const appResponse = await axios.get(`${ECP_BASE_URL}/query/active-app`);
  const parsed = await parser.parseStringPromise(appResponse.data);
  const activeAppId = parsed.app.id;
  console.log(`Active App ID: ${activeAppId}`);
  return activeAppId;
}

async function runRokuPlayTest() {
  const appId = await getActiveAppId();
  if (appId !== 'dev') {
    console.log('Launching dev app...');
    await axios.post(`${ECP_BASE_URL}/launch/dev`);
    await delay(5000);
  }
  console.log('Sending Select command to focus content...');
  await axios.post(`${ECP_BASE_URL}/keypress/Select`);
  await delay(2000);
  console.log('Sending Play command...');
  await axios.post(`${ECP_BASE_URL}/keypress/Play`);
  await delay(5000);
  console.log('Querying media-player state...');
  const response = await axios.get(`${ECP_BASE_URL}/query/media-player`);
  const parsed = await parser.parseStringPromise(response.data);
  console.log('Parsed Media-Player Response:', JSON.stringify(parsed, null, 2));
  return parsed;
}

async function runRokuTest() {
  try {
    console.log('Starting Roku playback test... Waiting 10s for app to stabilize...');
    await delay(10000);
    const timestamp = new Date().toISOString();
    const playerState = await runRokuPlayTest();
    const output = `Test Timestamp: ${timestamp}\n\nParsed Media-Player State:\n${JSON.stringify(playerState, null, 2)}\n`;
    await require('fs').promises.writeFile('test_output.json', output);
    console.log('Test output saved to test_output.json');
    process.exit(0);
  } catch (err) {
    console.error('Test failed:', err);
    process.exit(1);
  }
}

if (require.main === module) {
  runRokuTest();
}
