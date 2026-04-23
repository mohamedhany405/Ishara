const words = ["ماء", "أنا", "شرطة", "نعم"];

function tokenize(s) {
  return (s || "")
    .replace(/[\u060C\u061B\u061F.,!?;:()\[\]{}"'`~@#$%^&*_+=<>|\\/-]/g, " ")
    .split(/\s+/)
    .filter(Boolean);
}

function hasWord(text, word) {
  return tokenize(text).includes(word);
}

function isSignLangContext(text) {
  return /لغة\s*الإشارة|لغة\s*الاشارة|بلغة\s*الإشارة|بلغة\s*الاشارة|تعلم\s*لغة\s*الإشارة|تعلم\s*لغة\s*الاشارة/.test(text || "");
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

async function fetchText(url, retries = 2) {
  for (let i = 0; i <= retries; i++) {
    try {
      const r = await fetch(url, { headers: { "user-agent": "Mozilla/5.0" } });
      if (!r.ok) return "";
      return await r.text();
    } catch (e) {
      if (i === retries) return "";
    }
  }
  return "";
}

async function searchYoutube(q) {
  const html = await fetchText("https://www.youtube.com/results?search_query=" + encodeURIComponent(q));
  const ids = [...html.matchAll(/"videoId":"([A-Za-z0-9_-]{11})"/g)].map((m) => m[1]);
  return [...new Set(ids)].slice(0, 12).map((id) => `https://www.youtube.com/watch?v=${id}`);
}

async function searchDdg(q) {
  const html = await fetchText("https://duckduckgo.com/html/?q=" + encodeURIComponent(q));
  const hrefs = [...html.matchAll(/href="([^"]+)"/gi)].map((m) => m[1]);
  const out = [];
  for (const href of hrefs) {
    let cand = null;
    if (href.includes("uddg=")) {
      const m = href.match(/uddg=([^&]+)/);
      if (m) cand = decodeURIComponent(m[1]);
    } else {
      cand = href;
    }
    const watch = cand ? toWatchUrl(cand) : null;
    if (watch) out.push(watch);
  }
  return [...new Set(out)].slice(0, 12);
}

async function oembed(u) {
  try {
    const r = await fetch("https://www.youtube.com/oembed?url=" + encodeURIComponent(u) + "&format=json", { headers: { "user-agent": "Mozilla/5.0" } });
    if (!r.ok) return null;
    const d = await r.json();
    return { url: u, title: d.title || "", channel: d.author_name || "" };
  } catch {
    return null;
  }
}

function extractShortDescription(html) {
  const m = html.match(/"shortDescription":"((?:\\.|[^"\\])*)"/);
  if (!m) return "";
  try { return JSON.parse('"' + m[1].replace(/"/g, '\\"') + '"'); } catch { return ""; }
}

async function getDescription(u) {
  const html = await fetchText(u + "&hl=ar");
  return extractShortDescription(html);
}

async function mapLimit(items, limit, fn) {
  const out = [];
  let i = 0;
  async function worker() {
    while (i < items.length) {
      const idx = i++;
      out[idx] = await fn(items[idx]);
    }
  }
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, () => worker()));
  return out;
}

function scoreCandidate(word, title, desc) {
  let score = 0;
  const reasons = [];

  const titleSign = isSignLangContext(title);
  const descSign = isSignLangContext(desc);

  if (hasWord(title, word)) {
    score += 3;
    reasons.push("exact word in title");
  }
  if (hasWord(desc, word)) {
    score += 2;
    reasons.push("exact word in description");
  }
  if (titleSign) {
    score += 2;
    reasons.push("sign-language wording in title");
  } else if (descSign) {
    score += 1;
    reasons.push("sign-language wording in description");
  }

  if (word === "شرطة" && /مركز\s*الشرطة|قسم\s*الشرطة|محطة\s*الشرطة/.test(`${title} ${desc}`)) {
    score -= 3;
    reasons.push("police-station context (penalty)");
  }

  return { score, reasons };
}

(async () => {
  const results = {};

  for (const word of words) {
    const queries = [
      `${word} بلغة الإشارة`,
      `${word} بلغة الاشارة`,
      `لغة الإشارة ${word}`,
      `لغة الاشارة ${word}`,
      `${word} لغة الإشارة المصرية`,
      `كلمة ${word} بلغة الاشارة`,
      `${word} لغة الاشارة للصم`,
      `${word} او لا بلغة الاشارة`
    ];

    const links = [];
    for (const q of queries) {
      const [yt, ddg] = await Promise.all([searchYoutube(q), searchDdg(q)]);
      links.push(...yt, ...ddg);
    }

    const unique = [...new Set(links)].slice(0, 40);
    const metas = (await mapLimit(unique, 8, oembed)).filter(Boolean);

    // Fetch descriptions only for plausible sign-language title candidates or exact-word titles.
    const needDesc = metas
      .filter((m) => isSignLangContext(m.title) || hasWord(m.title, word))
      .slice(0, 18)
      .map((m) => m.url);
    const descMap = {};
    const descPairs = await mapLimit(needDesc, 6, async (u) => [u, await getDescription(u)]);
    for (const [u, d] of descPairs) descMap[u] = d || "";

    const scored = metas.map((m) => {
      const desc = descMap[m.url] || "";
      const { score, reasons } = scoreCandidate(word, m.title, desc);
      return { ...m, description: desc, score, reasons };
    }).sort((a, b) => b.score - a.score);

    results[word] = {
      best: scored[0] || null,
      top: scored.slice(0, 8)
    };
  }

  const fs = await import("node:fs/promises");
  await fs.writeFile("tmp_targeted_ar_final_candidates.json", JSON.stringify(results, null, 2), "utf8");
  console.log("written tmp_targeted_ar_final_candidates.json");
})();
