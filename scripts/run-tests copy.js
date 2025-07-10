const axios = require('axios');
const fs = require('fs').promises;

const ROKU_IP = '10.71.71.152';
const ECP_BASE_URL = `http://${ROKU_IP}:8060`;

async function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Main test runner
async function runRokuTest() {
  try {
    console.log('Starting Roku tests...');
    // console.log('Waiting 30 seconds for app to load...');
    // await delay(30000); // 30-second delay, commented out as per your preference

    const timestamp = new Date().toLocaleString('en-US', { timeZone: 'America/Chicago' });
    const { stateData, response } = await runRokuPlayTest();

    // Combine state and response with newlines and timestamp
    const outputContent = [
      `Test Run Timestamp: ${timestamp}`,
      '\n\n\n', // Several newlines
      'Roku Device State:',
      JSON.stringify(stateData, null, 2),
      '\n\n\n',
      'Full ECP Response:',
      JSON.stringify(response, null, 2)
    ].join('');

    // Save to single file
    const outputFile = 'test_output.json';
    await fs.writeFile(outputFile, outputContent);
    console.log(`Output saved to ${outputFile}`);
  } catch (error) {
    console.error('Error during test:', error.message);
    process.exit(1);
  }
}

// Test: Send Play command and query media player state
async function runRokuPlayTest() {
  try {
    // Debug: Check active app
    console.log('Checking active app...');
    const appResponse = await axios.get(`${ECP_BASE_URL}/query/active-app`);
    console.log('Active App:', JSON.stringify(appResponse.data, null, 2));

    // Step 1: Send ECP command to ensure app is focused (optional navigation)
    console.log('Sending Select command to focus video...');
    await axios.post(`${ECP_BASE_URL}/keypress/Select`);
    console.log('Select command sent.');
    await delay(1000); // Short delay after Select

    // Step 2: Send Play command
    console.log('Sending Play command...');
    await axios.post(`${ECP_BASE_URL}/keypress/Play`);
    console.log('Play command sent.');

    // Step 3: Wait for playback to start (2 seconds)
    await delay(2000);

    // Step 4: Query device state
    console.log('Querying device state...');
    const response = await axios.get(`${ECP_BASE_URL}/query/media-player`);
    console.log('Device response received:', JSON.stringify(response.data, null, 2));
    const stateData = response.data;

    // Step 5: Log state to console
    console.log('Roku Device State:');
    console.log(JSON.stringify(stateData, null, 2));

    return { stateData, response: response.data };
  } catch (error) {
    throw new Error(`Play test failed: ${error.message}`);
  }
}

// Export for future modularity
module.exports = { runRokuTest, runRokuPlayTest };

// Run tests
if (require.main === module) {
  runRokuTest();
}