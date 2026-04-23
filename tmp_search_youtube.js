(async () => {
  const query = 'Arabic sign language hello YouTube';
  const url = 'https://duckduckgo.com/html/?q=' + encodeURIComponent(query);

  const response = await fetch(url, {
    headers: { 'user-agent': 'Mozilla/5.0' },
  });

  const html = await response.text();
  const regex = /https?:\/\/(?:www\.)?(?:youtube\.com|youtu\.be)[^"'<>\s]+/gi;
  const links = [...html.matchAll(regex)].map((m) => m[0]);
  const unique = [...new Set(links)];

  console.log('status', response.status);
  console.log('htmlLength', html.length);
  console.log('youtubeLinks', unique.length);
  console.log(unique.slice(0, 20).join('\n'));
})();
