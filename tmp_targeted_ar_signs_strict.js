const targets = ["ماء", "أنا", "شرطة", "نعم"];

function tokenize(s) {
  return (s || "")
    .replace(/[\u060C\u061B\u061F.,!?;:()\[\]{}"'`~@#$%^&*_+=<>|\\/-]/g, " ")
    .split(/\s+/)
    .filter(Boolean);
}

function hasWord(text, word) {
  return tokenize(text).includes(word);
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

async function searchYoutube(query) {
  const html = await fetchText("https://www.youtube.com/results?search_query=" + encodeURIComponent(query));
  const ids = [...html.matchAll(/"videoId":"([A-Za-z0-9_-]{11})"/g)].map((m) => m[1]);
  return [...new Set(ids)].slice(0, 15).map((id) => `https://www.youtube.com/watch?v=${id}`);
}

async function searchDdg(query) {
  const html = await fetchText("https://duckduckgo.com/html/?q=" + encodeURIComponent(query));
  const hrefs = [...html.matchAll(/href="([^"]+)"/gi)].map((m) => m[1]);
  const out = [];
  for (const href of hrefs) {
    let candidate = null;
    if (href.includes("uddg=")) {
      const m = href.match(/uddg=([^&]+)/);
      if (m) candidate = decodeURIComponent(m[1]);
    } else candidate = href;
    const w = candidate ? toWatchUrl(candidate) : null;
    if (w) out.push(w);
  }
  return [...new Set(out)].slice(0, 15);
}

async function oembedTitle(url) {
  try {
    const o = "https://www.youtube.com/oembed?url=" + encodeURIComponent(url) + "&format=json";
    const res = await fetch(o, { headers: { "user-agent": "Mozilla/5.0" } });
    if (!res.ok) return null;
    const data = await res.json();
    return { title: data.title || "", channel: data.author_name || "" };
  } catch {
    return null;
  }
}

(async () => {
  const report = {};
  for (const word of targets) {
    const queries = [
      `${word} بلغة الإشارة`,
      `${word} بلغة الاشارة`,
      `لغة الإشارة ${word}`,
      `لغة الاشارة ${word}`,
      `تعلم ${word} بلغة الإشارة`,
      `تعلم ${word} بلغة الاشارة`,
      `${word} لغة الإشارة المصرية`,
      `${word} لغة الاشارة العربية`
    ];

    const links = [];
    for (const q of queries) {
      const [a, b] = await Promise.all([searchYoutube(q), searchDdg(q)]);
      links.push(...a, ...b);
    }

    const unique = [...new Set(links)].slice(0, 60);
    const accepted = [];
    for (const u of unique) {
      const meta = await oembedTitle(u);
      if (!meta) continue;
      const t = meta.title;
      const isSignContext = /لغة\s*الإشارة|لغة\s*الاشارة|بلغة\s*الإشارة|بلغة\s*الاشارة|اشارات|إشارات/.test(t);
      const hasExact = hasWord(t, word);
      if (hasExact && isSignContext) {
        accepted.push({ url: u, title: t, channel: meta.channel });
      }
    }

    report[word] = accepted;
  }

  console.log(JSON.stringify(report, null, 2));
})();
