const functions = require("firebase-functions/v1");

const { nowIso, requireAuth } = require("../utils/helpers");

exports.callable_adminHealthCheck = functions.https.onCall(async (_data, context) => {
  // Require auth so it isn't a public endpoint.
  requireAuth(context);
  return { ok: true, timestamp: nowIso() };
});
