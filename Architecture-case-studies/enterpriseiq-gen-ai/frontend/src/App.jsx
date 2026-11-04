import { useEffect, useRef, useState } from 'react';
import { confirmSignIn, fetchAuthSession, getCurrentUser, signIn, signOut } from 'aws-amplify/auth';
import { ArrowRight, ArrowUp, BookOpen, Check, ChevronDown, FileText, Layers, LockKeyhole, LogOut, MessageSquare, Plus, ShieldCheck, Sparkles } from 'lucide-react';

const suggestions = [
  { label: 'Disaster recovery', question: 'What is the example disaster recovery RTO?', icon: ShieldCheck },
  { label: 'Access & permissions', question: 'What is the access review policy?', icon: LockKeyhole },
  { label: 'Recovery readiness', question: 'How often are recovery procedures rehearsed?', icon: BookOpen },
];

function Login({ onSuccess }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmation, setConfirmation] = useState('');
  const [newPassword, setNewPassword] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function submit(event) {
    event.preventDefault();
    if (busy) return;
    setError('');
    if (newPassword && password !== confirmation) {
      setError('Your new passwords must match.'); return;
    }
    setBusy(true);
    try {
      const result = newPassword
        ? await confirmSignIn({ challengeResponse: password })
        : await signIn({ username: email.trim(), password, options: { authFlowType: 'USER_SRP_AUTH' } });
      setPassword(''); setConfirmation('');
      if (result.isSignedIn) {
        onSuccess(await getCurrentUser());
      } else if (result.nextStep.signInStep === 'CONFIRM_SIGN_IN_WITH_NEW_PASSWORD_REQUIRED') {
        setNewPassword(true);
      } else {
        setError('This account requires an additional sign-in step. Contact your administrator.');
      }
    } catch (failure) {
      setError(failure.name === 'NotAuthorizedException'
        ? 'Unable to sign in. Check your email and password.'
        : failure.name === 'InvalidPasswordException'
          ? 'Use at least 12 characters with uppercase, lowercase, a number and a symbol.'
          : 'Sign-in could not complete. Check your connection and try again.');
    } finally { setBusy(false); }
  }

  return <section className="login-card" aria-labelledby="login-title">
    <div className="card-icon"><LockKeyhole size={21} /></div>
    <p className="eyebrow">YOUR KNOWLEDGE, CONNECTED</p>
    <h2 id="login-title">{newPassword ? 'Make it your own.' : 'Welcome to your workspace.'}</h2>
    <p className="subtle">{newPassword ? 'Choose a permanent password to finish setting up your account.' : 'Sign in to ask questions and explore your organization’s knowledge.'}</p>
    <form onSubmit={submit}>
      {!newPassword && <label>Work email<input type="email" autoComplete="username" value={email} onChange={e => setEmail(e.target.value)} required disabled={busy} placeholder="you@example.com" /></label>}
      <label>{newPassword ? 'New password' : 'Password'}<input type="password" autoComplete={newPassword ? 'new-password' : 'current-password'} value={password} onChange={e => setPassword(e.target.value)} required disabled={busy} minLength={newPassword ? 12 : undefined} /></label>
      {newPassword && <label>Confirm new password<input type="password" autoComplete="new-password" value={confirmation} onChange={e => setConfirmation(e.target.value)} required disabled={busy} /></label>}
      {error && <p className="error" role="alert">{error}</p>}
      <button className="primary" disabled={busy}>{busy ? 'Connecting…' : newPassword ? 'Set password & continue' : 'Sign in'}<ArrowRight size={17} /></button>
    </form>
    <p className="login-foot"><ShieldCheck size={14} /> Private workspace · Invite-only access</p>
  </section>;
}

function Sources({ sources }) {
  if (!sources.length) return null;
  return <div className="sources"><p className="eyebrow">RETRIEVED SOURCES <span>{sources.length}</span></p>
    {sources.map((source, index) => <details key={`${source}-${index}`}>
      <summary><FileText size={15} /><span>{source.split('/').pop()}</span><ChevronDown size={13} /></summary>
      <p>{source}</p><small>Private document reference. Download access is not enabled.</small>
    </details>)}
  </div>;
}

export default function App({ configured = true, apiUrl }) {
  const [user, setUser] = useState(null);
  const [checking, setChecking] = useState(configured);
  const [messages, setMessages] = useState([]);
  const [question, setQuestion] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [signingOut, setSigningOut] = useState(false);
  const abortRef = useRef(null);
  const feed = useRef(null);
  useEffect(() => {
    if (!configured) return;
    let active = true;
    getCurrentUser().then(value => { if (active) setUser(value); }).catch(() => {}).finally(() => { if (active) setChecking(false); });
    return () => { active = false; abortRef.current?.abort(); };
  }, [configured]);
  useEffect(() => { if (feed.current) feed.current.scrollTop = feed.current.scrollHeight; }, [messages, busy]);

  async function ask(event) {
    event.preventDefault();
    const text = question.trim();
    if (!text || busy || !user) return;
    setError(''); setBusy(true);
    const controller = new AbortController();
    abortRef.current = controller;
    const timeout = setTimeout(() => controller.abort(), 40_000);
    try {
      const session = await fetchAuthSession();
      const token = session.tokens?.accessToken?.toString();
      if (!token) throw new Error('session');
      if (controller.signal.aborted) return;
      const response = await fetch(apiUrl, {
        method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ question: text }), signal: controller.signal, redirect: 'error',
      });
      if (response.status === 401 || response.status === 403) throw new Error('session');
      if (!response.ok) throw new Error(response.status === 429 ? 'throttle' : 'upstream');
      const result = await response.json();
      if (typeof result.answer !== 'string' || !Array.isArray(result.sources) || result.sources.some(s => typeof s !== 'string')) throw new Error('upstream');
      if (!controller.signal.aborted) {
        setMessages(previous => [...previous, { question: text, answer: result.answer, sources: result.sources }]);
        setQuestion('');
      }
    } catch (failure) {
      if (abortRef.current !== controller) return;
      setError(failure.message === 'session' ? 'Your session needs attention. Sign out and sign in again.'
        : failure.message === 'throttle' ? 'The workspace is busy. Wait a moment and try again.'
          : failure.name === 'AbortError' ? 'The request took too long. Please try again.'
            : 'We couldn’t retrieve an answer. Check your connection and try again.');
    } finally {
      clearTimeout(timeout);
      if (abortRef.current === controller) { abortRef.current = null; setBusy(false); }
    }
  }

  async function leave() {
    setSigningOut(true); setError('');
    abortRef.current?.abort(); abortRef.current = null; setBusy(false);
    try { await signOut(); setUser(null); setMessages([]); setQuestion(''); }
    catch { setError('Sign-out did not complete. Please try again.'); }
    finally { setSigningOut(false); }
  }
  function clear() { if (!busy) { setMessages([]); setQuestion(''); setError(''); } }
  return <div className="workspace">
    <aside className="sidebar">
      <a className="brand" href="/" aria-label="EnterpriseIQ home"><span className="brand-mark"><Layers size={23} /></span><span>Enterprise<span className="brand-iq">IQ</span><small>KNOWLEDGE WORKSPACE</small></span></a>
      <button className="new-chat" onClick={clear} disabled={!user || busy}><Plus size={17} /> New conversation<span>↗</span></button>
      <p className="nav-label">WORKSPACE</p>
      <div className="nav-active"><MessageSquare size={17} /> Knowledge assistant<span className="nav-dot" /></div>
      <div className="library"><p className="nav-label">CONNECTED KNOWLEDGE</p><div><BookOpen size={17} /><span>Sample policy library<small>Synthetic demonstration documents</small></span></div><p className="library-note">Disaster recovery & access control</p></div>
      <div className="sidebar-bottom"><ShieldCheck size={19} /><div>Built on your knowledge<small>Answers with source references</small></div></div>
      <div className="profile"><span className="avatar">{user ? (user.signInDetails?.loginId || user.username || 'U')[0].toUpperCase() : 'G'}</span><div>{user ? 'Your workspace' : 'Guest workspace'}<small>{user ? 'Signed in' : 'Sign in to continue'}</small></div>{user && <button title="Sign out" aria-label="Sign out" onClick={leave} disabled={signingOut}><LogOut size={17} /></button>}</div>
    </aside>
    <main>
      <header className="topbar"><span>Workspace <span className="breadcrumb">/</span> <strong>Knowledge assistant</strong></span><span className="environment"><span />DEV WORKSPACE</span></header>
      {!configured ? <div className="center-stage"><section className="login-card"><h1>Connect your workspace</h1><p>Copy frontend/.env.example to frontend/.env.local, set your DEV configuration, and restart the development server.</p></section></div>
        : checking ? <div className="center-stage"><p role="status">Opening your workspace…</p></div>
          : !user ? <div className="center-stage"><Login onSuccess={setUser} /><p className="stage-caption">ENTERPRISEIQ <span>·</span> CLARITY STARTS WITH A QUESTION</p></div>
            : <div className="chat-shell">
              <div className={`chat-feed ${messages.length ? 'has-messages' : ''}`} ref={feed}>
                {!messages.length ? <section className="welcome"><div className="welcome-icon"><Sparkles size={26} /></div><p className="eyebrow">A LITTLE KNOWLEDGE GOES A LONG WAY</p><h1>Good questions.<br /><span>Grounded answers.</span></h1><p className="welcome-description">Find clarity in your organization’s knowledge.<br />Ask a question. Explore the sources. Move forward.</p><div className="suggestions">{suggestions.map(({ label, question: suggestion, icon: Icon }) => <button key={label} onClick={() => setQuestion(suggestion)} disabled={busy}><Icon size={20} /><strong>{label}</strong><span>{suggestion}</span><ArrowRight size={16} /></button>)}</div><p className="scope-note"><BookOpen size={14} /> Currently exploring two synthetic policy documents</p></section>
                  : <div className="thread" role="log" aria-label="Conversation">{messages.map((message, i) => <article className="exchange" key={i}><div className="question-message"><span className="message-label">YOU</span><p>{message.question}</p></div><div className="answer-message"><span className="answer-icon"><Sparkles size={17} /></span><div><span className="message-label">ENTERPRISEIQ <span className="answer-badge"><Check size={10} /> RESPONSE</span></span><p className="answer-text">{message.answer}</p><Sources sources={message.sources} /></div></div></article>)}</div>}
                {busy && <p className="thinking" role="status"><span className="pulse" /> Looking through your knowledge base…</p>}
              </div>
              <div className="composer-area">{error && <p className="error" role="alert">{error}</p>}<form onSubmit={ask} className="composer"><label className="sr-only" htmlFor="question">Ask a question</label><textarea id="question" placeholder="What would you like to know?" rows={2} maxLength={4000} value={question} disabled={busy || signingOut} onChange={e => setQuestion(e.target.value)} onKeyDown={e => { if (e.key === 'Enter' && !e.shiftKey && !e.nativeEvent.isComposing) { e.preventDefault(); e.currentTarget.form.requestSubmit(); } }} /><div className="composer-bottom"><span><LockKeyhole size={12} /> Your knowledge, in context</span><button type="submit" aria-label="Send question" disabled={!question.trim() || busy || signingOut}><ArrowUp size={19} /></button></div></form><p className="composer-note">AI can make mistakes. Check source documents for important decisions.<span>Each question is answered independently.</span></p></div>
            </div>}
      <footer className="app-footer"><span>EnterpriseIQ / AWS GenAI portfolio</span><span><span className="footer-dot" /> Amazon Bedrock</span></footer>
    </main>
  </div>;
}
