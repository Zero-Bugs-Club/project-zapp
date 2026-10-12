// Shared constants. Feature code must import these instead of
// hard-coding URLs or storage names.

// Base URL of the Cloudflare Worker API. No trailing slash.
// Production value is set here once the Worker is deployed.
const String apiBaseUrl = 'https://api.example.workers.dev';

// Local sqflite database file name for GPS photo metadata.
const String photoDbFileName = 'gps_photos.db';
