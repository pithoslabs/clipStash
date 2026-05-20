function buildEvent(req) {
  return {
    event: "download",
    file: "ClipStash-v2.1.0.zip",
    timestamp: new Date().toISOString(),
    host: req.headers.host || null,
    referrer: req.headers.referer || null,
    userAgent: req.headers["user-agent"] || null,
    country: req.headers["x-vercel-ip-country"] || null,
    region: req.headers["x-vercel-ip-country-region"] || null,
    city: req.headers["x-vercel-ip-city"] || null,
  };
}

module.exports = function handler(req, res) {
  console.log(JSON.stringify(buildEvent(req)));

  res.statusCode = 302;
  res.setHeader(
    "Location",
    process.env.CLIPSTASH_DOWNLOAD_URL ||
      "https://github.com/pithoslabs/clipStash/releases/download/v2.1.0/ClipStash-v2.1.0.zip"
  );
  res.setHeader("Cache-Control", "no-store");
  res.end();
};
