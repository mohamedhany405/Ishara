const targets = ["ماء", "أنا", "شرطة", "نعم"];

function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }

function stripHtml(s) {
  return (s || "").replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
}

function normalizeArabic(s) {
  return (s || "")
    .replace(/[\u064B-\u065F\u0670]/g, "")
    .replace(/[إأآ]/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/ؤ/g, "و")
    .replace(/ئ/g, "ي")
    .replace(/\s+/g, " ")
    .trim();
}

function toWatchUrl(candidate) {
  try {
    const u = new URL(candidate);
    if (u.hostname.includes("youtu.be")) {
      const id = u.pathname.replace("/", "").split("/")[0];
      if (id) return `https://www.youtube.com/watch?v=${id}`;
    }
    if (u.hostname.includes("youtube.com")) {
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

async function searchYoutubeIds(query) {
  const url = "https://www.youtube.com/results?search_query=" + encodeURIComponent(query);
  const html = await fetchText(url);
  const ids = [...html.matchAll(/"videoId":"([A-Za-z0-9_-]{11})"/g)].map((m) => m[1]);
  return [...new Set(ids)].slice(0, 12).map((id) => `https://www.youtube.com/watch?v=${id}`);
}

async function searchDuckduckgo(query) {
  const url = "https://duckduckgo.com/html/?q=" + encodeURIComponent(query);
  const html = await fetchText(url);
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
    if (!candidate) continue;
    const watch = toWatchUrl(candidate);
    if (watch) links.push(watch);
  }
  return [...new Set(links)].slice(0, 12);
}

function unescapeJsonString(escaped) {
  try {
    return JSON.parse('"' + escaped.replace(/"/g, '\\"') + '"');
  } catch {
    return escaped || "";
  }
}

async function getVideoMeta(watchUrl) {
  const meta = {
    url: watchUrl,
    title: "",
    description: "",
    channel: "",
  };

  try {
    const oembed = "https://www.youtube.com/oembed?url=" + encodeURIComponent(watchUrl) + "&format=json";
    const res = await fetch(oembed, { headers: { "user-agent": "Mozilla/5.0" } });
    if (res.ok) {
      const data = await res.json();
      meta.title = data.title || "";
      meta.channel = data.author_name || "";
    }
  } catch {}

  try {
    const html = await fetchText(watchUrl + "&hl=ar");

    const descMatch = html.match(/"shortDescription":"((?:\\.|[^"\\])*)"/);
    if (descMatch) meta.description = unescapeJsonString(descMatch[1]);

    if (!meta.title) {
      const titleMatch = html.match(/<meta property="og:title" content="([^"]+)"/i);
      if (titleMatch) meta.title = stripHtml(titleMatch[1]);
    }
  } catch {}

  return meta;
}

function tokenize(s) {
  return (s || "")
    .replace(/[\u060C\u061B\u061F.,!?;:()\[\]{}"'`~@#$%^&*_+=<>|\\/-]/g, " ")
    .split(/\s+/)
    .filter(Boolean);
}

function hasExactWord(text, word) {
  const tokens = tokenize(text);
  return tokens.includes(word);
}

function hasNormalizedWord(text, word) {
  const tokens = tokenize(normalizeArabic(text));
  return tokens.includes(normalizeArabic(word));
}

function scoreCandidate(meta, word) {
  const title = meta.title || "";
  const desc = meta.description || "";
  const joined = `${title} ${desc}`;

  let score = 0;
  const reasons = [];

  if (hasExactWord(title, word)) {
    score += 4;
    reasons.push("exact word in title");
  } else if (hasNormalizedWord(title, word)) {
    score += 2;
    reasons.push("normalized word match in title");
  }

  if (hasExactWord(desc, word)) {
    score += 3;
    reasons.push("exact word in description");
  } else if (hasNormalizedWord(desc, word)) {
    score += 1;
    reasons.push("normalized word match in description");
  }

  if (/لغة\s*الاشارة|لغة\s*الإشارة|اشارة|إشارة/.test(joined)) {
    score += 1;
    reasons.push("sign-language context");
  }

  if (word === "شرطة") {
    if (/مركز\s*الشرطة|قسم\s*الشرطة|محطة\s*الشرطة/.test(joined)) {
      score -= 3;
      reasons.push("likely police-station context");
    }
  }

  if (/الحروف|الابجدية|الأبجدية|تعليم\s*الحروف/.test(joined)) {
    score -= 2;
    reasons.push("alphabet-focused, not word-focused");
  }

  return { score, reasons };
}

function confidenceFromScore(score) {
  if (score >= 7) return "high";
  if (score >= 4) return "medium";
  return "low";
}

async function pickBestForWord(word) {
  const queries = [
    `لغة الإشارة العربية ${word}`,
    `تعلم لغة الإشارة العربية ${word}`,
    `إشارة ${word}`,
    `اشارة ${word}`,
    `Arabic sign language ${word}`,
  ];

  const links = [];
  for (const q of queries) {
    try {
      const [yt, ddg] = await Promise.all([searchYoutubeIds(q), searchDuckduckgo(q)]);
      links.push(...yt, ...ddg);
      await sleep(150);
    } catch {}
  }

  const unique = [...new Set(links)].slice(0, 30);
  const metas = [];
  for (const url of unique) {
    const meta = await getVideoMeta(url);
    const scored = scoreCandidate(meta, word);
    metas.push({ ...meta, ...scored });
    await sleep(120);
  }

  metas.sort((a, b) => b.score - a.score);
  const best = metas[0];

  return {
    word,
    best: best || null,
    top: metas.slice(0, 8),
  };
}

(async () => {
  const results = [];
  for (const w of targets) {
    const r = await pickBestForWord(w);
    results.push(r);
  }

  const final = {};
  for (const r of results) {
    if (!r.best || r.best.score < 4) {
      final[r.word] = {
        result: "NOT FOUND",
        confidence: "low",
        justification: "No candidate with a confident exact-word match in title/description.",
        topCandidates: r.top,
      };
    } else {
      final[r.word] = {
        result: r.best.url,
        confidence: confidenceFromScore(r.best.score),
        justification: r.best.reasons.join(", "),
        title: r.best.title,
        channel: r.best.channel,
        score: r.best.score,
        topCandidates: r.top,
      };
    }
  }

  console.log(JSON.stringify(final, null, 2));
})();
