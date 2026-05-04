function parseBody(req) {
  return new Promise((resolve) => {
    let body = "";

    req.on("data", (chunk) => {
      body += chunk;
    });

    req.on("end", () => {
      if (!body) {
        resolve({});
        return;
      }

      try {
        resolve(JSON.parse(body));
      } catch {
        resolve({});
      }
    });
  });
}

module.exports = async function handler(req, res) {
  if (req.method !== "POST") {
    res.statusCode = 405;
    res.setHeader("Allow", "POST");
    res.end("Method Not Allowed");
    return;
  }

  const body = await parseBody(req);
  const event = {
    event: body.event === "page_view" ? "page_view" : "unknown",
    path: typeof body.path === "string" ? body.path : null,
    title: typeof body.title === "string" ? body.title : null,
    timestamp: new Date().toISOString(),
    host: req.headers.host || null,
    referrer: req.headers.referer || null,
    userAgent: req.headers["user-agent"] || null,
    country: req.headers["x-vercel-ip-country"] || null,
    region: req.headers["x-vercel-ip-country-region"] || null,
    city: req.headers["x-vercel-ip-city"] || null,
  };

  console.log(JSON.stringify(event));

  res.statusCode = 204;
  res.setHeader("Cache-Control", "no-store");
  res.end();
};
