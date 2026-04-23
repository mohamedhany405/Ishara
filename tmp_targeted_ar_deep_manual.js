const words = ["ماء", "شرطة", "نعم"];

async function fetchText(url){
  const r = await fetch(url, { headers: { "user-agent": "Mozilla/5.0" } });
  if(!r.ok) return "";
  return await r.text();
}

async function searchYoutube(q){
  const html = await fetchText("https://www.youtube.com/results?search_query=" + encodeURIComponent(q));
  const ids = [...html.matchAll(/"videoId":"([A-Za-z0-9_-]{11})"/g)].map(m => m[1]);
  return [...new Set(ids)].slice(0, 20).map(id => `https://www.youtube.com/watch?v=${id}`);
}

async function oembed(u){
  try{
    const r = await fetch("https://www.youtube.com/oembed?url=" + encodeURIComponent(u) + "&format=json", { headers: { "user-agent": "Mozilla/5.0" } });
    if(!r.ok) return null;
    const d = await r.json();
    return { url: u, title: d.title || "", channel: d.author_name || "" };
  }catch{return null;}
}

(async()=>{
  const out = {};

  for(const w of words){
    const queries = [
      `${w} بلغة الإشارة`,
      `${w} بلغة الاشارة`,
      `لغة الإشارة ${w}`,
      `لغة الاشارة ${w}`,
      `${w} لغة الإشارة المصرية`,
      `${w} بلغه الاشاره`,
      `${w} لغة الاشارة للصم`,
      `كلمة ${w} بلغة الاشارة`,
      `اشارة ${w} للصم`,
      `${w} او لا بلغة الاشارة`
    ];

    const links=[];
    for(const q of queries){
      try{ links.push(...(await searchYoutube(q))); }catch{}
    }

    const unique=[...new Set(links)].slice(0, 70);
    const metas=[];
    for(const u of unique){
      const m = await oembed(u);
      if(m) metas.push(m);
    }

    out[w] = metas;
  }

  console.log(JSON.stringify(out, null, 2));
})();
