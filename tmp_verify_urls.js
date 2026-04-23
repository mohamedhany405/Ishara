(async()=>{
  const urls=[
    'https://www.youtube.com/watch?v=sxU3WlDaGbY',
    'https://www.youtube.com/watch?v=JDofZ1ESnIk',
    'https://www.youtube.com/watch?v=pG9fdWR_Qcs'
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
