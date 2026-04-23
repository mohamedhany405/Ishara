(async () => {
  const q = 'ماء بلغة الاشارة site:youtube.com/watch';
  const u = 'https://duckduckgo.com/html/?q=' + encodeURIComponent(q);
  const r = await fetch(u, { headers: { 'user-agent': 'Mozilla/5.0' } });
  const t = await r.text();
  console.log('status', r.status, 'len', t.length);
  console.log(t.slice(0, 700));
  console.log('has uddg', /uddg=/.test(t));
  console.log('href count', [...t.matchAll(/href="([^"]+)"/gi)].length);
})();
