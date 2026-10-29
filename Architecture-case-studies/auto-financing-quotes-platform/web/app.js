const $ = id => document.getElementById(id);
const money = (cents,digits=0) => new Intl.NumberFormat("en-US",{style:"currency",currency:"USD",maximumFractionDigits:digits}).format(cents/100);
const esc = value => String(value??"").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
let session,estimate,quoteInput,saveKey,saving=false,toastTimer,refreshing=false;
const names={quote:"Quote studio",saved:"Saved quotes",events:"Event pipeline",inbox:"Notification inbox",architecture:"Architecture"};
function toast(message){$("toast").textContent=message;$("toast").hidden=false;clearTimeout(toastTimer);toastTimer=setTimeout(()=>$("toast").hidden=true,5500);}
async function api(path,body,headers={}){
 const response=await fetch(path,{method:body===undefined?"GET":"POST",headers:{"Content-Type":"application/json",...headers},...(body===undefined?{}:{body:JSON.stringify(body)})});
 if(response.redirected){location.reload();throw new Error("Session expired. Sign in again.");}
 const result=await response.json();if(!response.ok)throw new Error(result.error||"Request failed.");return result;
}
async function preview(){
 $("form-error").textContent="";
 try{const value=Object.fromEntries(new FormData($("quote-form")));const result=await api("/api/quotes/preview",value);
 estimate=result;quoteInput=value;saveKey=crypto.randomUUID();$("payment").textContent=money(result.monthly_payment_cents);
 $("principal").textContent=money(result.principal_cents);$("apr").textContent=result.apr+"%";
 $("total").textContent=money(result.monthly_payment_cents*result.term_months);
 $("estimate-summary").textContent=result.term_months+" monthly payments · "+result.pricing_version;$("save-button").disabled=false;return true;
 }catch(error){estimate=null;$("save-button").disabled=true;$("form-error").textContent=error.message;return false;}
}
function navigation(){const selected=names[location.hash.slice(1)]?location.hash.slice(1):"quote";
 document.querySelectorAll(".page").forEach(node=>node.hidden=node.id!=="page-"+selected);
 document.querySelectorAll("nav a").forEach(node=>node.classList.toggle("active",node.dataset.page===selected));
 $("page-name").textContent=names[selected];refresh();
}
const empty=message=>'<div class="empty">'+message+'</div>';
const badge=(text,type="")=>'<span class="pill '+type+'">'+esc(text)+'</span>';
function renderQuotes(quotes){$("nav-count").textContent=quotes.length;
 $("saved-list").innerHTML=quotes.length?quotes.map(q=>'<article class="card saved-card"><div>'+badge(Date.now()/1000>q.expires_at?"Expired":"Saved")+'<h3>'+esc(q.vehicle)+'</h3><p>'+q.term_months+' months · '+esc(q.apr)+'% APR · '+money(q.principal_cents)+' financed</p><p>Quote '+esc(q.id.slice(0,8))+' · '+esc(q.pricing_version)+' · '+new Date(q.created_at*1000).toLocaleDateString()+'</p></div><div class="saved-payment">'+money(q.monthly_payment_cents,2)+'<small>estimated per month</small></div></article>').join(""):empty('Your next possibility starts here.<br><a href="#quote">Create your first estimate →</a>');
}
function renderEvents(events){$("events-body").innerHTML=events.length?events.map(e=>'<tr><td><strong>'+esc(e.event_type)+'</strong><small><code>'+esc(e.quote_id.slice(0,8))+' / '+esc(e.event_id.slice(0,8))+'</code></small></td><td>'+new Date(e.created_at*1000).toLocaleTimeString([],{hour:"2-digit",minute:"2-digit"})+'</td><td>'+e.attempts+'</td><td>'+badge(e.published_at?"Published":"Pending",e.published_at?"":"pending")+(e.last_error?'<small>'+esc(e.last_error)+'</small>':"")+'</td><td>'+badge(e.notification_status||"Waiting",e.notification_status==="ACCEPTED"?"":"pending")+'</td></tr>').join(""):'<tr><td colspan="5">Save a quote to create your first committed event.</td></tr>';}
async function refresh(){if(!session||refreshing)return;refreshing=true;
 try{const [quotes,events,system,inbox]=await Promise.all([api("/api/quotes"),api("/api/events"),api("/api/system"),api("/api/inbox")]);
 renderQuotes(quotes.quotes);renderEvents(events.events);$("pending-count").textContent=system.pending;$("oldest-age").textContent=system.oldest_age_seconds+"s";
 document.querySelectorAll("[data-fault]").forEach(button=>button.setAttribute("aria-pressed",!!system.faults[button.dataset.fault]));
 $("inbox-list").innerHTML=inbox.messages.length?inbox.messages.map(m=>'<article class="card mail-card"><span class="pill">SIMULATED EMAIL ACCEPTED</span><h3>'+esc(m.subject)+'</h3><small>'+new Date(m.created_at*1000).toLocaleString()+'</small><pre>'+esc(m.body)+'</pre></article>').join(""):empty(inbox.note||"No notifications yet. Save a quote to see the asynchronous workflow.");
 if(session.mode!=="local")$("inbox-description").textContent="AWS sends to your verified account email. SES acceptance is distinct from final delivery.";
 }catch(error){console.warn(error.message);}finally{refreshing=false;}
}
$("quote-form").addEventListener("submit",async event=>{event.preventDefault();if(await preview())toast("Estimate updated with versioned demo pricing rules.");});
$("term_months").addEventListener("input",()=>{$("term-label").textContent=$("term_months").value+" months";});
for(const event of ["input","change"])$("quote-form").addEventListener(event,()=>{estimate=null;$("save-button").disabled=true;});
$("save-button").addEventListener("click",async()=>{if(!estimate||saving)return;saving=true;$("save-button").disabled=true;
 try{const result=await api("/api/quotes",quoteInput,{"Idempotency-Key":saveKey});toast(result.created?"Quote committed. Notification will follow through the outbox.":"Already saved. No duplicate quote was created.");await refresh();}
 catch(error){toast(error.message+" Retry uses the same save key.");}finally{saving=false;$("save-button").disabled=!estimate;}});
document.querySelectorAll("[data-fault]").forEach(button=>button.addEventListener("click",async()=>{button.disabled=true;
 try{await api("/api/demo/fault",{name:button.dataset.fault,enabled:button.getAttribute("aria-pressed")!=="true"});await refresh();toast("Local failure control updated.");}
 catch(error){toast(error.message);}finally{button.disabled=false;}}));
window.addEventListener("hashchange",navigation);
async function boot(){try{session=await api("/api/session");$("user-name").textContent=session.name;$("user-email").textContent=session.email;
 $("region").textContent=session.region;$("environment").textContent=session.mode==="local"?"Local simulation":"AWS deployment";
 $("demo-banner").hidden=session.mode!=="local";$("lab-controls").hidden=session.mode!=="local";await preview();navigation();setInterval(refresh,3000);
 }catch(error){$("form-error").textContent=error.message;toast("Cannot connect: "+error.message);}}
boot();

