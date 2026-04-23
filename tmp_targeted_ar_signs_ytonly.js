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

async function fetchText(url, retries = 2) {
  for (let i = 0; i <= retries; i++) {
    try {
      const res = await fetch(url, { headers: { "user-agent": "Mozilla/5.0" } });
      if (!res.ok) return "";
      return await res.text();
    } catch (e) {
      if (i === retries) throw e;
    }
  }
  return "";
}

async function searchYoutube(query) {
  const html = await fetchText("https://www.youtube.com/results?search_query=" + encodeURIComponent(query));
  const ids = [...html.matchAll(/"videoId":"([A-Za-z0-9_-]{11})"/g)].map((m) => m[1]);
  return [...new Set(ids)].slice(0, 30).map((id) => `https://www.youtube.com/watch?v=${id}`);
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
      `${word} لغة الاشارة العربية`,
      `اشارات لغة الإشارة ${word}`,
      `لغة الاشارة كلمات ${word}`
    ];

    const links = [];
    for (const q of queries) {
      try {
        const a = await searchYoutube(q);
        links.push(...a);
      } catch {}
    }

    const unique = [...new Set(links)].slice(0, 120);
    const accepted = [];
    const all = [];

    for (const u of unique) {
      const meta = await oembedTitle(u);
      if (!meta) continue;
      const t = meta.title;
      const signStrong = /لغة\s*الإشارة|لغة\s*الاشارة|بلغة\s*الإشارة|بلغة\s*الاشارة/.test(t);
      const signWeak = /اشارات|إشارات|اشاره|إشارة/.test(t);
      const hasExact = hasWord(t, word);

      all.push({ url: u, title: t, channel: meta.channel, hasExact, signStrong, signWeak });
      if (hasExact && (signStrong || signWeak)) {
        accepted.push({ url: u, title: t, channel: meta.channel, signStrong, signWeak });
      }
    }

    report[word] = {
      accepted,
      sampleTop: all.slice(0, 20)
    };
  }

  console.log(JSON.stringify(report, null, 2));
})();
