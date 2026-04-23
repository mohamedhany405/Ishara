const targets = {
  "ماء": [
    "ماء بلغة الاشارة",
    "ماء بلغة الإشارة",
    "اشارة ماء",
    "إشارة ماء",
    "تعلم اشارة ماء",
    "ماء لغة الاشارة المصرية",
    "ماء لغة الإشارة المصرية",
    "الماء بلغة الاشارة",
    "ماية بلغة الاشارة المصرية"
  ],
  "شرطة": [
    "شرطة بلغة الاشارة",
    "شرطة بلغة الإشارة",
    "اشارة شرطة",
    "إشارة شرطة",
    "تعلم اشارة شرطة",
    "شرطة لغة الاشارة المصرية",
    "شرطة لغة الإشارة المصرية",
    "علامة شرطة بلغة الاشارة",
    "كلمة شرطة بلغة الاشارة"
  ]
};

function normalizeArabic(s) {
  return (s || "")
    .replace(/[\u064B-\u0652\u0670]/g, "")
    .replace(/أ|إ|آ/g, "ا")
    .replace(/ة/g, "ة")
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

function hasTargetWord(text, target) {
  const tokens = tokenizeArabic(text);
  const t = normalizeArabic(target);
  if (tokens.includes(t)) return "exact";
  if (tokens.includes("ال" + t)) return "definite";
  return "none";
}

function hasSignContext(text) {
  const n = normalizeArabic(text);
  return /(لغة\s*الاشارة|بلغة\s*الاشارة|اشارة|اشارات|اشاره|الصم)/.test(n);
}

function hasEgyptianContext(text) {
  const n = normalizeArabic(text);
  return /(مصرية|مصري|مصر)/.test(n);
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

async function searchYoutube(query) {
  const html = await fetchText("https://www.youtube.com/results?search_query=" + encodeURIComponent(query));
  const ids = [...html.matchAll(/"videoId":"([A-Za-z0-9_-]{11})"/g)].map((m) => m[1]);
  return [...new Set(ids)].slice(0, 20).map((id) => `https://www.youtube.com/watch?v=${id}`);
}

async function searchDdg(query) {
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
  }
  return [...new Set(links)].slice(0, 20);
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
  const out = {};

  for (const [target, queries] of Object.entries(targets)) {
    const allLinks = [];
    for (const q of queries) {
      const [yt, ddg] = await Promise.all([searchYoutube(q), searchDdg(q)]);
      allLinks.push(...yt, ...ddg);
    }

    const uniqueLinks = [...new Set(allLinks)].slice(0, 120);
    const candidates = [];

    for (const url of uniqueLinks) {
      const data = await oembed(url);
      if (!data) continue;

      const title = data.title || "";
      const channel = data.author_name || "";
      const targetMatch = hasTargetWord(title, target);
      const signContext = hasSignContext(title);
      const egyptian = hasEgyptianContext(title + " " + channel);

      let score = 0;
      if (targetMatch === "exact") score += 4;
      if (targetMatch === "definite") score += 3;
      if (signContext) score += 4;
      if (egyptian) score += 1;

      if (score >= 7) {
        candidates.push({
          url,
          title,
          channel,
          targetMatch,
          signContext,
          egyptian,
          score
        });
      }
    }

    candidates.sort((a, b) => b.score - a.score || a.title.length - b.title.length);
    out[target] = {
      totalChecked: uniqueLinks.length,
      confident: candidates.slice(0, 10)
    };
  }

  console.log(JSON.stringify(out, null, 2));
})();
