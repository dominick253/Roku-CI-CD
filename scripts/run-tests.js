//test12S
const axios = require('axios');
const xml2js = require('xml2js');
const fs = require('fs').promises;
const parser = new xml2js.Parser({ explicitArray: false, explicitRoot: false, mergeAttrs: true });

const ROKU_IP = '10.71.71.152';
const ECP_BASE_URL = `http://${ROKU_IP}:8060`;

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;

let logBuffer = [];

function log(message) {
  console.log(message);
  logBuffer.push(message);
}

function recordTestResult(name, passed) {
  totalTests++;
  if (passed) {
      passedTests++;
      log(`✅ Test passed: ${name}`);
  } else {
      failedTests++;
      log(`❌ Test failed: ${name}`);
  }
}


async function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function getActiveAppId() {
  log('Fetching active app...');
  const appResponse = await axios.get(`${ECP_BASE_URL}/query/active-app`);
  const parsed = await parser.parseStringPromise(appResponse.data);
  const activeAppId = parsed.app.id;
  log(`Active App ID: ${activeAppId}`);
  return activeAppId;
}

async function runRokuPlayTest() {
  const appId = await getActiveAppId();
  if (appId !== 'dev') {
    log('Launching dev app...');
    await axios.post(`${ECP_BASE_URL}/launch/dev`);
    await delay(5000);
  }
  log('Sending Select command to focus content and begin playback...');
  await axios.post(`${ECP_BASE_URL}/keypress/Select`);
  await delay(7000);

  log('Querying media-player state...');
  const response = await axios.get(`${ECP_BASE_URL}/query/media-player`);
  const parsed = await parser.parseStringPromise(response.data);
  log('Parsed Media-Player Response: ' + JSON.stringify(parsed, null, 2));

  if (parsed.state === 'play') {
    recordTestResult('Playback Test', parsed.state === 'play');
  } else {
    recordTestResult('Playback Test', parsed.state === 'play');
  }

  return parsed;
}

async function runBackTest() {
  log('Sending Back command...');
  await axios.post(`${ECP_BASE_URL}/keypress/Back`);
  await delay(3000);

  log('Checking active app after Back command...');
  const appResponse = await axios.get(`${ECP_BASE_URL}/query/active-app`);
  const parsedApp = await parser.parseStringPromise(appResponse.data);
  const activeAppId = parsedApp.app.id;
  log(`Active App ID after Back: ${activeAppId}`);

  if (activeAppId === 'dev') {
    recordTestResult('Back Button Test', activeAppId === 'dev');
  } else {
    recordTestResult('Back Button Test', activeAppId === 'dev');
  }

  return activeAppId;
}

async function runDeepLinkTest(contentID, expectedState = 'play', testName = 'Deep Linking Test') {
  log(`Starting ${testName} with contentID='${contentID}' & mediaType=movie...`);
  await axios.post(`${ECP_BASE_URL}/launch/dev`, null, {
    params: {
      contentID: contentID,
      mediaType: 'movie'
    }
  });
  log('Deep link launch command sent, waiting for app to load...');
  await delay(10000);

  log('Querying media-player state after deep linking...');
  const response = await axios.get(`${ECP_BASE_URL}/query/media-player`);
  const parsed = await parser.parseStringPromise(response.data);
  log(`Parsed Media-Player Response after ${testName}: ` + JSON.stringify(parsed, null, 2));

  let passed;
  if (expectedState === 'not_play') {
    passed = parsed.state !== 'play';
  } else {
    passed = parsed.state === expectedState;
  }

  recordTestResult(testName, passed);

  return parsed;
}

async function returnToHome() {
  log('Sending Home command to return to home screen...');
  await axios.post(`${ECP_BASE_URL}/keypress/Home`);
  log('Home command sent.');
}

async function runRokuTest() {
  try {
    log('Starting Roku test sequence... Waiting 5s for stabilization...');
    await delay(5000);
    const timestamp = new Date().toISOString();

    const playerState = await runRokuPlayTest();

    const activeAppIdAfterBack = await runBackTest();

    const deepLinkPlayerState = await runDeepLinkTest("video29", "play", "Deep Linking Test");

    let output = `Test Timestamp: ${timestamp}\n\n`;
    output += logBuffer.join('\n') + '\n\n';
    output += 'Parsed Media-Player State after Initial Playback:\n' + JSON.stringify(playerState, null, 2) + '\n';
    output += 'Active App ID after Back Test: ' + activeAppIdAfterBack + '\n\n';
    output += 'Parsed Media-Player State after Deep Link Test:\n' + JSON.stringify(deepLinkPlayerState, null, 2) + '\n';

    await returnToHome();

    log('Deep link test from home screen.');
    const startTime = Date.now();
    const deepLinkPlayerStateFromHome = await runDeepLinkTest("video29", "play", "Deep Linking Test From Home Screen");
    const elapsed = Date.now() - startTime;
    log(`Startup time: ${elapsed} ms`);
    
    output += 'Parsed Media-Player State after Deep Link Test From Home Screen:\n' + JSON.stringify(deepLinkPlayerStateFromHome, null, 2) + '\n';

    log('Deep link test with bad contentID.');
    const deepLinkPlayerStateWithBadVideo = await runDeepLinkTest("bad_video_id", "not_play", "Deep Linking Test with Bad ContentID");    output += 'Parsed Media-Player State after Deep Link Test From Home Screen:\n' + JSON.stringify(deepLinkPlayerStateWithBadVideo, null, 2) + '\n';

    let summary = `\nTest Summary:\nTotal Tests: ${totalTests}\nPassed: ${passedTests}\nFailed: ${failedTests}\nPass Percentage: ${((passedTests/totalTests)*100).toFixed(2)}%\n`;
    log(summary);
    output += summary;

    await fs.writeFile('test_output.json', output);
    log('Test output saved to test_output.json');

    await returnToHome();
    process.exit(0);
  } catch (err) {
    log('Test failed: ' + err);
    try { await returnToHome(); } catch (e) { log('Failed to return to Home: ' + e); }
    process.exit(1);
  }
}

if (require.main === module) {
  runRokuTest();
}