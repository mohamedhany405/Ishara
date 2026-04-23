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

async function fetchText(url) {
  const r = await fetch(url, { headers: { "user-agent": "Mozilla/5.0" } });
  if (!r.ok) return "";
  return await r.text();
}

async function searchYoutube(q) {
  const html = await fetchText("https://www.youtube.com/results?search_query=" + encodeURIComponent(q));
  const ids = [...html.matchAll(/"videoId":"([A-Za-z0-9_-]{11})"/g)].map((m) => m[1]);
  return [...new Set(ids)].slice(0, 12).map((id) => `https://www.youtube.com/watch?v=${id}`);
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
  const final = {};
  for (const w of words) {
    const queries = [
      `${w} بلغة الإشارة`,
      `${w} بلغة الاشارة`,
      `لغة الإشارة ${w}`,
      `لغة الاشارة ${w}`,
      `${w} لغة الإشارة المصرية`,
      `${w} لغة الاشارة للصم`,
      `كلمة ${w} بلغة الاشارة`,
      `${w} او لا بلغة الاشارة`
    ];

    const links = [];
    for (const q of queries) {
      try { links.push(...(await searchYoutube(q))); } catch {}
    }

    const unique = [...new Set(links)].slice(0, 40);
    const metas = (await mapLimit(unique, 8, oembed)).filter(Boolean);

    const filtered = metas.filter((m) => {
      const t = m.title;
      const strong = /لغة\s*الإشارة|لغة\s*الاشارة|بلغة\s*الإشارة|بلغة\s*الاشارة/.test(t);
      const exact = hasWord(t, w);
      if (!(strong && exact)) return false;
      if (w === "شرطة" && /مركز\s*الشرطة|قسم\s*الشرطة|محطة\s*الشرطة/.test(t)) return false;
      return true;
    });

    final[w] = {
      filtered,
      sample: metas.slice(0, 20)
    };
  }

  const fs = await import("node:fs/promises");
  await fs.writeFile("tmp_targeted_ar_results.json", JSON.stringify(final, null, 2), "utf8");
  console.log("written tmp_targeted_ar_results.json");
})();
