/**
 * CPPW Static Offender Database Search Integration
 * Appends static database entries to search results on the main search page.
 */
(function(){'use strict';
var STATIC_DB=[
  {id:"CPPW-2024-00183",name:{surName:"MACKAY",givenName:"Joshua",middleName:"Robbie",suffix:null},age:"37",aliases:[{surName:"Mackay",givenName:"Josh",middleName:null,suffix:null},{surName:"Mackay",givenName:"J.R.",middleName:null,suffix:null}],offence:"Indecent treatment of a child under 16 (x3 counts)",riskLevel:"Moderate-High",compliance:"Compliant",jurisdiction:"Queensland",locations:[{streetAddress:"Unit 4, 72 Boundary Street",city:"West End",state:"QLD",zipCode:"4101",type:"R",name:"RESIDENCE"}],offenderUri:"database/offender-001-joshua-robbie-mackay.html",imageUri:""},
  {id:"CPPW-2024-00295",name:{surName:"BARRETT",givenName:"Michael",middleName:"James",suffix:null},age:"45",aliases:[{surName:"Barrett",givenName:"Mike",middleName:null,suffix:null}],offence:"Possession of child exploitation material (x2 counts)",riskLevel:"Moderate",compliance:"Compliant — Incarcerated",jurisdiction:"New South Wales",locations:[{streetAddress:"Silverwater Correctional Complex",city:"Silverwater",state:"NSW",zipCode:"2128",type:"R",name:"RESIDENCE"}],offenderUri:"database/offender-002-michael-james-barrett.html",imageUri:""},
  {id:"CPPW-2025-00047",name:{surName:"NGUYEN",givenName:"Daniel",middleName:"Lee",suffix:null},age:"34",aliases:[{surName:"Nguyen",givenName:"Dan",middleName:null,suffix:null}],offence:"Sexual assault; Procure person under 16 (x2 counts)",riskLevel:"High",compliance:"Compliant — Incarcerated",jurisdiction:"Victoria",locations:[{streetAddress:"Port Phillip Prison",city:"Truganina",state:"VIC",zipCode:"3029",type:"R",name:"RESIDENCE"}],offenderUri:"database/offender-003-daniel-lee-nguyen.html",imageUri:""},
  {id:"CPPW-2023-00712",name:{surName:"WILSON",givenName:"Peter",middleName:"Anthony",suffix:null},age:"56",aliases:[{surName:"Wilson",givenName:"Pete",middleName:null,suffix:null}],offence:"Maintaining a sexual relationship with a child",riskLevel:"High",compliance:"Compliant — Incarcerated",jurisdiction:"South Australia",locations:[{streetAddress:"Mobilong Prison",city:"Murray Bridge",state:"SA",zipCode:"5253",type:"R",name:"RESIDENCE"}],offenderUri:"database/offender-004-peter-anthony-wilson.html",imageUri:""},
  {id:"CPPW-2025-00381",name:{surName:"CAMPBELL",givenName:"Shane",middleName:"Robert",suffix:null},age:"41",aliases:[{surName:"Campbell",givenName:"Shane",middleName:null,suffix:null}],offence:"Indecent assault (x4 counts); Fail to comply with reporting",riskLevel:"Moderate",compliance:"Non-Compliant — Warrant Issued",jurisdiction:"Western Australia",locations:[{streetAddress:"last known — 18 Brown Street",city:"Fremantle",state:"WA",zipCode:"6160",type:"R",name:"RESIDENCE"}],offenderUri:"database/offender-005-shane-robert-campbell.html",imageUri:""}
];

function matchQuery(offender,query){
  if(!query||!query.firstName||!query.lastName)return false;
  var fn=query.firstName.toLowerCase().trim(),ln=query.lastName.toLowerCase().trim();
  var ofn=(offender.name.givenName||'').toLowerCase(),oln=(offender.name.surName||'').toLowerCase();
  if(ln&&oln.indexOf(ln)===-1)return false;
  if(fn&&ofn.indexOf(fn)===-1){
    var aliasMatch=(offender.aliases||[]).some(function(a){return(a.givenName||'').toLowerCase().indexOf(fn)!==-1;});
    if(!aliasMatch)return false;
  }
  return true;
}

function buildOffenderLinkStatic(nameObj,offenderUri){
  var name=(nameObj.surName||'No Surname')+', '+nameObj.givenName+(nameObj.middleName?' '+nameObj.middleName:'')+(nameObj.suffix?' '+nameObj.suffix:'');
  return '<a href="'+offenderUri+'" target="_blank" title="View offender details" style="font-weight:700;">'+name+'</a><br/><span style="font-size:11px;color:#666;font-family:monospace;">[CPPW Database]</span>';
}

function injectStaticResults(firstName,lastName){
  var query={firstName:firstName,lastName:lastName};
  var matches=STATIC_DB.filter(function(o){return matchQuery(o,query);});
  if(matches.length===0)return;
  try{
    var tbl=$('#nsopwdt').DataTable();
    matches.forEach(function(off){
      var aliases=(off.aliases||[]).map(function(a){return(a.surName||'')+', '+(a.givenName||'')+(a.middleName?' '+a.middleName:'');}).join('<br/>')||'None';
      var locations=(off.locations||[]).map(function(loc){return(loc.streetAddress||'')+'<br/>'+(loc.city||'N/A')+', '+(loc.state||'')+' '+((loc.zipCode||'')+'<br/><strong>')+((loc.type==='R')?'RESIDENCE':(loc.type==='E'?'EMPLOYMENT':loc.type))+'</strong>';}).join('<br/><br/>');
      tbl.row.add([buildOffenderLinkStatic(off.name,off.offenderUri),off.age||'N/A',aliases,locations]);
    });
    tbl.draw();
    var countEl=$('.dataTables_info');
    if(countEl.length)countEl.append(' <span style="color:#AC1A06;font-weight:700;">(+ '+matches.length+' from CPPW Database)</span>');
  }catch(e){console.log('CPPW DB inject error:',e);}
}

// Poll for DataTable ready then hook
var poll=setInterval(function(){
  if(typeof $!=='undefined'&&$.fn&&$.fn.DataTable){
    try{var tbl=$('#nsopwdt').DataTable();if(tbl&&typeof tbl.row==='function'){clearInterval(poll);setupHook();}}catch(e){}
  }
},500);

function setupHook(){
  // Hook search forms
  var oldPS=(window.NSOPWSearchByNameForm||{}).performSearch;
  if(oldPS){window.NSOPWSearchByNameForm._origPS=oldPS;window.NSOPWSearchByNameForm.performSearch=function(s){localStorage.setItem('db_fn',$('#firstname').val()||'');localStorage.setItem('db_ln',$('#lastname').val()||'');oldPS.call(window.NSOPWSearchByNameForm,s);};}
  // Check localStorage on load
  var fn=localStorage.getItem('db_fn')||localStorage.getItem('firstname')||'';
  var ln=localStorage.getItem('db_ln')||localStorage.getItem('lastname')||'';
  if(fn||ln)setTimeout(function(){injectStaticResults(fn,ln);},1500);
}
console.log('[CPPW Database] Search integration loaded — '+STATIC_DB.length+' static records');
})();
