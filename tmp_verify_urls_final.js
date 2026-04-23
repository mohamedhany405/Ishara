(async()=>{
  const urls=[
    'https://www.youtube.com/watch?v=pG9fdWR_Qcs',
    'https://www.youtube.com/watch?v=dtrgursVHyY',
    'https://www.youtube.com/watch?v=X4H9UKmKjOY',
    'https://www.youtube.com/watch?v=0dt5x_SaLyM'
  ];
  for(const u of urls){
    try{
      const r=await fetch('https://www.youtube.com/oembed?url='+encodeURIComponent(u)+'&format=json',{headers:{'user-agent':'Mozilla/5.0'}});
      if(!r.ok){
        console.log(u+' | HTTP '+r.status);
        continue;
      }
      const d=await r.json();
      console.log(u);
      console.log(d.title||'');
      console.log(d.author_name||'');
      console.log('---');
    }catch(e){
      console.log(u+' | ERR');
    }
  }
})();
