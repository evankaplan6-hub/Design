// Final battery chart (option C, revised). Writes an SVG string.
function batteryChart(pts, chargeFrom, markLabel){ markLabel=markLabel||'Plugged in';
 const W=372,H=72,PW=W-8, x=i=>i/96*PW, y=v=>H-v/100*H;
 const p2=(a)=>a.map(([i,v])=>[x(i),y(v)]);
 function smooth(p){const n=p.length;if(n<2)return '';const dx=[],m=[],t=[];for(let i=0;i<n-1;i++){dx.push(p[i+1][0]-p[i][0]);m.push((p[i+1][1]-p[i][1])/dx[i])}
 t[0]=m[0];t[n-1]=m[n-2];for(let i=1;i<n-1;i++)t[i]=(m[i-1]*m[i]<=0)?0:3*(dx[i-1]+dx[i])/((2*dx[i]+dx[i-1])/m[i-1]+(dx[i]+2*dx[i-1])/m[i]);
 let d=`M${p[0][0].toFixed(1)},${p[0][1].toFixed(1)}`;for(let i=0;i<n-1;i++){const h=dx[i]/3;d+=` C${(p[i][0]+h).toFixed(1)},${(p[i][1]+t[i]*h).toFixed(1)} ${(p[i+1][0]-h).toFixed(1)},${(p[i+1][1]-t[i+1]*h).toFixed(1)} ${p[i+1][0].toFixed(1)},${p[i+1][1].toFixed(1)}`}return d}
 let s=`<line x1="0" x2="${PW}" y1="${H}" y2="${H}" stroke="var(--line)"/>`;
 // runs of real readings; gaps get a faint dotted bridge (asleep, no readings)
 const runs=[];let cur=[];pts.forEach((v,i)=>{if(v==null){if(cur.length)runs.push(cur);cur=[]}else cur.push([i,v])});if(cur.length)runs.push(cur);
  for(const run of runs){
    const ds=run.filter((_,k)=>k%3==0||k==run.length-1);
  if(ds.length>1)s+=`<path d="${smooth(p2(ds))}" fill="none" stroke="var(--t1)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>`;
 }
 // key points
 let lowI=Math.round(chargeFrom);const low=pts[lowI]; const end=[...pts].reverse().find(v=>v!=null);
 if(markLabel==='Unplugged'){s+=`<circle cx="${x(lowI)}" cy="${y(low)}" r="3" fill="var(--t1)"/><text x="${x(lowI)}" y="${y(low)-9}" text-anchor="middle">${markLabel}</text>`;}
 else{s+=`<circle cx="${x(lowI)}" cy="${y(low)}" r="3" fill="var(--t1)"/><text x="${x(lowI)}" y="${y(low)}" text-anchor="end" style="fill:var(--t1)" dx="-9" dy="4">${Math.round(low)}%</text><text x="${x(lowI)+10}" y="${y(low)+4}">${markLabel}</text>`;}
 s+=`<circle cx="${x(96)}" cy="${y(end)}" r="3.5" fill="var(--t1)"/>`;
 for(const [t,i,a] of [['6 PM',0,'start'],['6 AM',48,'middle'],['Now',96,'end']])s+=`<text x="${x(i)}" y="${H+16}" text-anchor="${a}">${t}</text>`;
 return `<svg width="${W}" height="${H+22}" viewBox="0 -8 ${W} ${H+30}" style="display:block;margin-top:12px;overflow:visible">${s}</svg>`;
}
