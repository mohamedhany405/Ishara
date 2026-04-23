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

async function fetchText(url) {
  const res = await fetch(url, { headers: { "user-agent": "Mozilla/5.0" } });
  if (!res.ok) return "";
  return await res.text();
}

async function searchYoutube(query) {
  const html = await fetchText("https://www.youtube.com/results?search_query=" + encodeURIComponent(query));
  const ids = [...html.matchAll(/"videoId":"([A-Za-z0-9_-]{11})"/g)].map((m) => m[1]);
  return [...new Set(ids)].slice(0, 12).map((id) => `https://www.youtube.com/watch?v=${id}`);
}

async function oembed(url) {
  try {
    const res = await fetch("https://www.youtube.com/oembed?url=" + encodeURIComponent(url) + "&format=json", {
      headers: { "user-agent": "Mozilla/5.0" },
    });
    if (!res.ok) return null;
    const d = await res.json();
    return { url, title: d.title || "", channel: d.author_name || "" };
  } catch {
    return null;
  }
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

(async () => {
  const report = {};

  for (const word of targets) {
    const queries = [
      `${word} بلغة الإشارة`,
      `لغة الإشارة ${word}`,
      `${word} لغة الاشارة`,
      `${word} لغة الإشارة المصرية`,
    ];

    const links = [];
    for (const q of queries) {
      try { links.push(...(await searchYoutube(q))); } catch {}
    }

    const unique = [...new Set(links)].slice(0, 35);
    const metas = (await mapLimit(unique, 8, oembed)).filter(Boolean);

    const filtered = metas.filter((m) => {
      const t = m.title;
      const strong = /لغة\s*الإشارة|لغة\s*الاشارة|بلغة\s*الإشارة|بلغة\s*الاشارة/.test(t);
      const exact = hasWord(t, word);
      if (!(strong && exact)) return false;
      if (word === "شرطة" && /مركز\s*الشرطة|قسم\s*الشرطة|محطة\s*الشرطة/.test(t)) return false;
      return true;
    });

    report[word] = filtered;
  }

  console.log(JSON.stringify(report, null, 2));
})();
