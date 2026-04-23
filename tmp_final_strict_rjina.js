const targets = {
  "ماء": [
    "ماء بلغة الاشارة",
    "اشارة ماء",
    "إشارة ماء",
    "ماء بلغة الإشارة",
    "الماء بلغة الاشارة",
    "لغة الاشارة المصرية ماء",
    "ماية بلغة الاشارة المصرية"
  ],
  "شرطة": [
    "شرطة بلغة الاشارة",
    "إشارة شرطة",
    "اشارة شرطة",
    "شرطة بلغة الإشارة",
    "لغة الاشارة المصرية شرطة",
    "كلمة شرطة بلغة الاشارة"
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

function normalizeVideoUrl(raw) {
  if (!raw) return null;
  const fixed = raw.replace(/^http:\/\//i, "https://");

  try {
    const u = new URL(fixed);
    const host = u.hostname.replace(/^www\./, "").toLowerCase();

    if (host === "youtube.com" || host === "m.youtube.com" || host === "www.youtube.com") {
      const id = u.searchParams.get("v");
      if (id) return `https://www.youtube.com/watch?v=${id}`;
      if (u.pathname.startsWith("/shorts/")) {
        const sid = u.pathname.split("/").filter(Boolean)[1];
        if (sid) return `https://www.youtube.com/watch?v=${sid}`;
      }
    }

    if (host === "youtu.be") {
      const id = u.pathname.replace(/^\//, "").split("/")[0];
      if (id) return `https://www.youtube.com/watch?v=${id}`;
    }
  } catch {
    return null;
  }

  return null;
}

async function fetchText(url) {
  const r = await fetch(url, { headers: { "user-agent": "Mozilla/5.0" } });
  if (!r.ok) return "";
  return await r.text();
}

async function fetchRjinaSearch(query) {
  const target = "http://www.youtube.com/results?search_query=" + encodeURIComponent(query);
  const proxy = "https://r.jina.ai/" + target;
  return await fetchText(proxy);
}

function extractEntries(markdown) {
  // Parse markdown links: [title](http://www.youtube.com/watch?v=...)
  const entries = [];
  const re = /\[([^\]]+)\]\((http:\/\/(?:www\.)?(?:youtube\.com\/(?:watch\?v=[A-Za-z0-9_-]{11}[^\)]*|shorts\/[A-Za-z0-9_-]{11}[^\)]*)|youtu\.be\/[A-Za-z0-9_-]{11}[^\)]*))\)/g;

  let m;
  while ((m = re.exec(markdown)) !== null) {
    const title = (m[1] || "").replace(/\s+/g, " ").trim();
    const rawUrl = m[2] || "";
    const url = normalizeVideoUrl(rawUrl);
    if (!url) continue;
    entries.push({ title, url });
  }

  return entries;
}

async function oembed(url) {
  try {
    const endpoint = "https://www.youtube.com/oembed?url=" + encodeURIComponent(url) + "&format=json";
    const res = await fetch(endpoint, { headers: { "user-agent": "Mozilla/5.0" } });
    if (!res.ok) return null;
    const data = await res.json();
    return {
      title: data.title || "",
      channel: data.author_name || ""
    };
  } catch {
    return null;
  }
}

(async () => {
  const report = {};

  for (const [target, queries] of Object.entries(targets)) {
    const discovered = [];

    for (const q of queries) {
      const md = await fetchRjinaSearch(q);
      const rows = extractEntries(md).slice(0, 40);
      for (const row of rows) {
        discovered.push({ query: q, ...row });
      }
    }

    const dedupMap = new Map();
    for (const item of discovered) {
      if (!dedupMap.has(item.url)) dedupMap.set(item.url, item);
    }

    const unique = [...dedupMap.values()];
    const scored = [];

    for (const row of unique) {
      const meta = await oembed(row.url);
      const title = meta?.title || row.title || "";
      const channel = meta?.channel || "";

      const match = targetMatchType(title, target);
      const sign = hasSignContext(title);
      const egypt = hasEgyptianContext(title + " " + channel + " " + row.query);

      let score = 0;
      if (match === "exact") score += 5;
      if (match === "definite") score += 4;
      if (sign) score += 4;
      if (egypt) score += 1;

      // Penalize compound forms that indicate a different concept than target standalone word.
      const normTitle = normalizeArabic(title);
      if (target === "ماء" && /كرة الماء|دورة الماء|شرب الماء|ترشيد المياه|مؤسسة مياه/.test(normTitle)) {
        score -= 2;
      }

      scored.push({
        url: row.url,
        title,
        channel,
        query: row.query,
        match,
        signContext: sign,
        egyptian: egypt,
        score
      });
    }

    scored.sort((a, b) => b.score - a.score || a.title.length - b.title.length);

    report[target] = {
      queryCount: queries.length,
      discoveredCount: discovered.length,
      uniqueCount: unique.length,
      top: scored.slice(0, 15),
      confident: scored.filter((x) => x.score >= 8).slice(0, 5)
    };
  }

  console.log(JSON.stringify(report, null, 2));
})();
