const targets = {
  "ماء": [
    "\"ماء بلغة الاشارة\" site:youtube.com/watch",
    "\"ماء بلغة الإشارة\" site:youtube.com/watch",
    "\"اشارة ماء\" site:youtube.com/watch",
    "\"إشارة ماء\" site:youtube.com/watch",
    "\"الماء بلغة الاشارة\" site:youtube.com/watch",
    "\"ماية بلغة الاشارة المصرية\" site:youtube.com/watch",
    "\"لغة الاشارة المصرية ماء\" site:youtube.com/watch"
  ],
  "شرطة": [
    "\"شرطة بلغة الاشارة\" site:youtube.com/watch",
    "\"شرطة بلغة الإشارة\" site:youtube.com/watch",
    "\"اشارة شرطة\" site:youtube.com/watch",
    "\"إشارة شرطة\" site:youtube.com/watch",
    "\"لغة الاشارة المصرية شرطة\" site:youtube.com/watch",
    "\"كلمة شرطة بلغة الاشارة\" site:youtube.com/watch"
  ]
};

function normalizeArabic(s) {
  return (s || "")
    .replace(/[\u064B-\u0652\u0670]/g, "")
    .replace(/أ|إ|آ/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/ؤ/g, "و")
    .replace(/ئ/g, "ي")
    .replace(/\s+/g, " ")
    .trim();
}

function tokenizeArabic(s) {
  return normalizeArabic(s)
    .replace(/[^\u0600-\u06FF0-9a-zA-Z\s]/g, " ")
    .split(/\s+/)
    .filter(Boolean);
}

function targetMatchType(text, target) {
  const tokens = tokenizeArabic(text);
  const t = normalizeArabic(target);
  if (tokens.includes(t)) return "exact";
  if (tokens.includes("ال" + t)) return "definite";
  return "none";
}

function hasSignContext(text) {
  const n = normalizeArabic(text);
  return /(لغة\s*الاشارة|بلغة\s*الاشارة|اشارة|اشاره|اشارات|الصم)/.test(n);
}

function hasEgyptianContext(text) {
  const n = normalizeArabic(text);
  return /(مصرية|مصري|مصر|egypt)/i.test(n);
}

function toWatchUrl(candidate) {
  try {
    const u = new URL(candidate);
    const host = u.hostname.replace(/^www\./, "").toLowerCase();
    if (host === "youtu.be") {
      const id = u.pathname.replace(/^\//, "").split("/")[0];
      if (id) return `https://www.youtube.com/watch?v=${id}`;
    }
    if (host.endsWith("youtube.com")) {
      const id = u.searchParams.get("v");
      if (id) return `https://www.youtube.com/watch?v=${id}`;
    }
  } catch {}
  return null;
}

async function fetchText(url) {
  const res = await fetch(url, { headers: { "user-agent": "Mozilla/5.0" } });
  if (!res.ok) return "";
  return await res.text();
}

async function ddgSearch(query) {
  try {
    const html = await fetchText("https://duckduckgo.com/html/?q=" + encodeURIComponent(query));
    const hrefs = [...html.matchAll(/href="([^"]+)"/gi)].map((m) => m[1]);
    const links = [];
    for (const href of hrefs) {
      let candidate = null;
      if (href.includes("uddg=")) {
        const m = href.match(/uddg=([^&]+)/);
        if (m) candidate = decodeURIComponent(m[1]);
      } else {
        candidate = href;
      }
      const w = candidate ? toWatchUrl(candidate) : null;
      if (w) links.push(w);
      if (links.length >= 20) break;
    }
    return [...new Set(links)];
  } catch {
    return [];
  }
}

async function oembed(url) {
  try {
    const endpoint = "https://www.youtube.com/oembed?url=" + encodeURIComponent(url) + "&format=json";
    const res = await fetch(endpoint, { headers: { "user-agent": "Mozilla/5.0" } });
    if (!res.ok) return null;
    return await res.json();
  } catch {
    return null;
  }
}

(async () => {
  const report = {};

  for (const [target, queries] of Object.entries(targets)) {
    const discovered = [];
    for (const q of queries) {
      const links = await ddgSearch(q);
      discovered.push(...links);
    }

    const uniqueLinks = [...new Set(discovered)].slice(0, 120);
    const candidates = [];

    for (const url of uniqueLinks) {
      const data = await oembed(url);
      if (!data) continue;

      const title = data.title || "";
      const channel = data.author_name || "";
      const m = targetMatchType(title, target);
      const sign = hasSignContext(title);
      const egypt = hasEgyptianContext(title + " " + channel);

      let score = 0;
      if (m === "exact") score += 4;
      if (m === "definite") score += 3;
      if (sign) score += 4;
      if (egypt) score += 1;

      candidates.push({
        url,
        title,
        channel,
        match: m,
        signContext: sign,
        egyptian: egypt,
        score
      });
    }

    candidates.sort((a, b) => b.score - a.score || a.title.length - b.title.length);

    report[target] = {
      checked: uniqueLinks.length,
      top: candidates.slice(0, 12),
      confident: candidates.filter((c) => c.score >= 7).slice(0, 5)
    };
  }

  console.log(JSON.stringify(report, null, 2));
})();
