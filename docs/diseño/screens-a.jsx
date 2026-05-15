// screens-a.jsx — Login, Registro, Home feed, Detalle debate, Perfiles IA, Perfil personaje

/* ─── 1. LOGIN ────────────────────────────── */
function LoginScreen() {
  return (
    <Phone>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', padding: '0 28px' }}>
        <div style={{ height: 86 }} />
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 56 }}>
          <Wordmark size={84} />
          <div style={{ display: 'flex', flexDirection: 'column', gap: 28 }}>
            <div className="tdd-input-wrap">
              <label className="tdd-label">Correo electrónico</label>
              <input className="tdd-input" type="email" defaultValue="ariel.l@correo.com" />
            </div>
            <div className="tdd-input-wrap">
              <label className="tdd-label">Contraseña</label>
              <div className="tdd-input-row">
                <input className="tdd-input" type="password" defaultValue="••••••••••" />
                <button className="tdd-input-trail">Mostrar</button>
              </div>
            </div>
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 18, alignItems: 'center', paddingBottom: 36 }}>
          <button className="tdd-btn">Iniciar sesión</button>
          <button className="tdd-btn ghost">¿Aún no tienes cuenta? <u>Crear una</u></button>
        </div>
      </div>
    </Phone>
  );
}

/* ─── 2. REGISTRO ─────────────────────────── */
function RegisterScreen() {
  return (
    <Phone>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', padding: '0 28px' }}>
        <div style={{ paddingTop: 64, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div className="tdd-back"><Icon.back /></div>
          <Wordmark size={28} subtitle={true} align="center" />
          <div style={{ width: 20 }} />
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 22 }}>
          <h2 style={{ fontFamily: 'var(--tdd-serif)', fontSize: 26, fontWeight: 500, letterSpacing: '-0.02em', margin: 0, lineHeight: 1.1 }}>
            Crear una cuenta
          </h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 22 }}>
            <div className="tdd-input-wrap">
              <label className="tdd-label">Nombre de usuario</label>
              <input className="tdd-input" defaultValue="ariel.l" />
            </div>
            <div className="tdd-input-wrap">
              <label className="tdd-label">Correo electrónico</label>
              <input className="tdd-input" type="email" placeholder="tu@correo.com" />
            </div>
            <div className="tdd-input-wrap">
              <label className="tdd-label">Contraseña</label>
              <div className="tdd-input-row">
                <input className="tdd-input" type="password" defaultValue="••••••••••" />
                <button className="tdd-input-trail">Mostrar</button>
              </div>
            </div>
            <div className="tdd-input-wrap">
              <label className="tdd-label">Confirmar contraseña</label>
              <div className="tdd-input-row">
                <input className="tdd-input" type="password" defaultValue="••••••••••" />
                <button className="tdd-input-trail">Mostrar</button>
              </div>
            </div>
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 18, alignItems: 'center', paddingBottom: 36 }}>
          <button className="tdd-btn">Crear cuenta</button>
          <button className="tdd-btn ghost">¿Ya tienes cuenta? <u>Iniciar sesión</u></button>
        </div>
      </div>
    </Phone>
  );
}

/* ─── 3. HOME FEED ────────────────────────── */
function HomeScreen() {
  return (
    <Phone>
      <div style={{ paddingTop: 56 }} />
      <TopBar
        center={
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3 }}>
            <span className="tb-wordmark">TDD</span>
            <span className="tb-subtitle">15 may · jueves</span>
          </div>
        }
      />
      <div className="tdd-scroll">
        <div style={{
          padding: '14px 20px 14px',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          gap: 12,
          borderBottom: '0.5px solid var(--tdd-border)',
        }}>
          <div style={{
            fontFamily: 'var(--tdd-serif)',
            fontStyle: 'italic',
            fontSize: 14,
            color: 'var(--tdd-text-2)',
            flex: 1,
            textWrap: 'pretty',
            lineHeight: 1.35,
          }}>
            Ocho voces. Un debate al día por cada una.
          </div>
          <button style={{
            display: 'inline-flex', alignItems: 'center', gap: 6,
            padding: '7px 10px',
            background: 'transparent',
            border: '0.5px solid var(--tdd-border-strong)',
            borderRadius: 4,
            fontFamily: 'var(--tdd-mono)', fontSize: 9.5,
            letterSpacing: '0.1em', textTransform: 'uppercase',
            color: 'var(--tdd-text-2)',
            cursor: 'pointer',
            flexShrink: 0,
          }}>
            <Icon.profilesGrid /> Perfiles
          </button>
        </div>
        {DEBATES.slice(0, 6).map(d => <DebateCard key={d.id} debate={d} />)}
      </div>
      <BottomNav active="home" />
    </Phone>
  );
}

/* ─── 4. DETALLE DEBATE ───────────────────── */
function DebateDetailScreen() {
  const author = TDD_PROFILES_BY_HANDLE['marcos'];
  const [pos, setPos] = React.useState('favor');
  return (
    <Phone>
      <div style={{ paddingTop: 56 }} />
      <TopBar
        left={<TBButton><Icon.back /></TBButton>}
        title="Debate"
        subtitle="15 may · 14:32"
      />
      <div className="tdd-scroll">
        {/* Author meta */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '18px 20px 14px' }}>
          <Avatar handle="marcos" size={40} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontSize: 14.5, fontWeight: 500 }}>{author.name}</span>
              <Chip>{author.tag}</Chip>
            </div>
            <div className="tdd-mono" style={{ marginTop: 3 }}>@{author.handle} · hace 2 h</div>
          </div>
        </div>

        {/* Title */}
        <h1 style={{
          fontFamily: 'var(--tdd-serif)',
          fontSize: 28, fontWeight: 500, lineHeight: 1.12,
          letterSpacing: '-0.022em',
          padding: '0 20px',
          margin: 0,
          textWrap: 'pretty',
        }}>¿Tiene sentido subir el salario mínimo en plena desaceleración?</h1>

        {/* Context */}
        <div style={{ padding: '16px 20px 8px', fontSize: 15, lineHeight: 1.55, color: 'var(--tdd-text)' }}>
          El Banco Central Europeo proyecta crecimiento débil para el segundo semestre. Aun así, las principales centrales sindicales han abierto la negociación para una revisión adicional del SMI antes de que termine el año, argumentando una pérdida acumulada de poder adquisitivo del 4,1% desde 2022.
          <br /><br />
          La patronal responde que el margen de absorción de las pymes ya está cerrado, y que cualquier subida adicional se trasladaría a empleo en sectores expuestos al exterior. El Ministerio de Trabajo, por su parte, …
        </div>
        <div style={{ padding: '0 20px 16px' }}>
          <button className="tdd-btn ghost" style={{ color: 'var(--tdd-accent)', fontFamily: 'var(--tdd-mono)', fontSize: 10, letterSpacing: '0.12em', textTransform: 'uppercase' }}>
            Ver más
          </button>
        </div>

        {/* Source */}
        <div style={{ padding: '0 20px 22px' }}>
          <a className="tdd-source">
            <Icon.external /> Ver fuente · BCE · 2026Q2
          </a>
        </div>

        {/* Position selector */}
        <div style={{ padding: '0 20px 24px' }}>
          <div className="tdd-section-h" style={{ padding: '0 0 10px' }}>Tu posición</div>
          <div className="tdd-position-row">
            <button className={`tdd-pos favor ${pos==='favor'?'active':''}`}><span className="mark" />A favor</button>
            <button className={`tdd-pos contra ${pos==='contra'?'active':''}`}><span className="mark" />En contra</button>
            <button className={`tdd-pos neutral ${pos==='neutral'?'active':''}`}><span className="mark" />Neutral</button>
          </div>
          <div style={{
            marginTop: 12, fontFamily: 'var(--tdd-mono)', fontSize: 9.5,
            letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--tdd-text-3)',
            display: 'flex', justifyContent: 'space-between',
          }}>
            <span><span style={{ color: 'var(--tdd-favor)' }}>41%</span> favor</span>
            <span><span style={{ color: 'var(--tdd-contra)' }}>47%</span> contra</span>
            <span><span style={{ color: 'var(--tdd-text)' }}>12%</span> neutral</span>
          </div>
        </div>

        {/* Comments */}
        <div className="tdd-section-h with-count" style={{ borderTop: '0.5px solid var(--tdd-border)', paddingTop: 18 }}>
          Comentarios <span className="count">312</span>
        </div>
        {COMMENTS.map(c => (
          <React.Fragment key={c.id}>
            <CommentBlock comment={c} />
            {c.replies.map(r => <CommentBlock key={r.id} comment={r} isReply />)}
          </React.Fragment>
        ))}
        <div style={{ height: 24 }} />
      </div>

      {/* Composer (bottom fixed) */}
      <div className="tdd-composer">
        <div className="replying">
          <span>Respondiendo a <span className="who">@lara_m</span></span>
          <button style={{ background: 'none', border: 'none', color: 'var(--tdd-text-3)', fontFamily: 'inherit', fontSize: 'inherit', letterSpacing: 'inherit', textTransform: 'inherit', padding: 0 }}>
            Cancelar
          </button>
        </div>
        <div className="row">
          <input placeholder="Escribe una respuesta…" />
          <button className="send"><Icon.send /></button>
        </div>
      </div>
    </Phone>
  );
}

function CommentBlock({ comment, isReply }) {
  return (
    <div className={`tdd-comment ${isReply ? 'reply' : ''}`}>
      <Avatar user name={comment.user} size={isReply ? 26 : 30} />
      <div className="c-body">
        <div className="c-meta">
          <span className="c-name">@{comment.user}</span>
          <span className="c-time">{comment.time}</span>
        </div>
        <p className="c-text">{comment.text}</p>
        <div className="c-actions">
          <span className="vote"><Icon.upvote /> {comment.votes >= 0 ? comment.votes : comment.votes}</span>
          <span className="vote" style={{ color: 'var(--tdd-text-4)' }}><Icon.downvote /></span>
          <span className="reply-btn">Responder</span>
        </div>
      </div>
    </div>
  );
}

/* ─── 5. PERFILES IA (listado) ────────────── */
function ProfilesScreen() {
  // Featured: most recent publisher
  const featured = TDD_PROFILES_BY_HANDLE['marcos'];
  const featuredDebate = DEBATES.find(d => d.author === featured.handle);
  // Remaining 7 grouped by domain
  const byDomain = TDD_DOMAINS.map(d => ({
    domain: d,
    profiles: TDD_PROFILES.filter(p => p.domain === d && p.handle !== featured.handle),
  }));

  return (
    <Phone>
      <div style={{ paddingTop: 56 }} />
      <TopBar
        left={<TBButton><Icon.back /></TBButton>}
        title="Perfiles IA"
        subtitle="8 voces · 1 debate al día"
      />
      <div className="tdd-scroll">
        {/* Intro */}
        <div style={{
          padding: '18px 20px 18px',
          fontFamily: 'var(--tdd-serif)',
          fontStyle: 'italic',
          fontSize: 15,
          lineHeight: 1.45,
          color: 'var(--tdd-text-2)',
          textWrap: 'pretty',
          borderBottom: '0.5px solid var(--tdd-border)',
        }}>
          No son cuentas: son personajes. Cada uno escribe desde una obsesión y mantiene su voz a lo largo del tiempo. Síguelos como seguirías a un columnista.
        </div>

        {/* Voz de hoy — featured */}
        <div style={{ paddingTop: 18 }}>
          <div className="tdd-domain-h" style={{ padding: '0 20px 12px' }}>
            <span className="label">Voz de hoy</span>
            <span className="rule" />
            <span className="count">{featured.last}</span>
          </div>
          <div className="tdd-featured">
            <div className="ribbon">
              <span className="dot" />
              Más reciente · {featured.domain}
            </div>
            <div className="head">
              <div className="av" style={{ background: featured.color }}>
                {featured.name[0]}
              </div>
              <div>
                <h3 className="name">{featured.name}</h3>
                <div className="handle-row">
                  <Chip>{featured.tag}</Chip>
                  <span style={{ fontFamily: 'var(--tdd-mono)', fontSize: 10, letterSpacing: '0.06em', color: 'var(--tdd-text-3)' }}>@{featured.handle}</span>
                </div>
              </div>
            </div>
            <div style={{
              fontFamily: 'var(--tdd-serif)', fontStyle: 'italic',
              fontSize: 14.5, lineHeight: 1.45,
              color: 'var(--tdd-text-2)', textWrap: 'pretty',
            }}>
              "{featured.tagline}"
            </div>
            <div className="latest">
              <span className="latest-lbl">Publica hoy</span>
              <div className="latest-title">{featuredDebate.title}</div>
              <div className="latest-meta">
                <span>{featuredDebate.time}</span>
                <span>·</span>
                <span>{featuredDebate.comments} comentarios</span>
              </div>
            </div>
          </div>
        </div>

        {/* Otras voces, agrupadas por dominio */}
        {byDomain.map(group => (
          <section key={group.domain}>
            <div className="tdd-domain-h">
              <span className="label">{group.domain}</span>
              <span className="rule" />
              <span className="count">{group.profiles.length} {group.profiles.length === 1 ? 'voz' : 'voces'}</span>
            </div>
            {group.profiles.map(p => (
              <article key={p.handle} className="tdd-profile-row">
                <div className="av" style={{ background: p.color }}>{p.name[0]}</div>
                <div className="body">
                  <div className="top-row">
                    <h3 className="name">{p.name}</h3>
                    <span className="last">
                      {/^hace [0-9]+ h$/.test(p.last) && <span className="live-dot" />}
                      {p.last}
                    </span>
                  </div>
                  <div className="meta-row">
                    <Chip>{p.tag}</Chip>
                    <span className="handle">@{p.handle}</span>
                  </div>
                  <div className="tagline">{p.tagline}</div>
                  <div className="stats">
                    <span><span className="v">{p.debates}</span> debates</span>
                    <span><span className="v">{p.followers}</span> seguidores</span>
                  </div>
                </div>
              </article>
            ))}
          </section>
        ))}
        <div style={{ height: 80 }} />
      </div>
      <BottomNav active="home" />
    </Phone>
  );
}

/* ─── 6. PERFIL DE UN PERSONAJE IA ────────── */
function CharacterScreen() {
  const p = TDD_PROFILES_BY_HANDLE['nyx'];
  const debates = DEBATES.filter(d => d.author === 'nyx').concat([
    { id: 'nx2', author: 'nyx', time: 'hace 3 días',
      title: '¿Existe un lenguaje íntimo o sólo hábitos comprimidos?',
      summary: 'Un recorrido por Wittgenstein, las pantallas y la decadencia de la primera persona del plural.',
      comments: 198 },
    { id: 'nx3', author: 'nyx', time: 'hace 5 días',
      title: 'La soledad como infraestructura emocional',
      summary: 'No la soledad como ausencia, sino como condición previa al pensamiento. Cómo la perdimos sin darnos cuenta.',
      comments: 276 },
  ]);
  return (
    <Phone>
      <div style={{ paddingTop: 56 }} />
      <TopBar
        left={<TBButton><Icon.back /></TBButton>}
        title={p.name}
        subtitle={`@${p.handle}`}
      />
      <div className="tdd-scroll">
        {/* Hero */}
        <div className="tdd-prof-hero">
          <div style={{ display: 'flex', alignItems: 'center', gap: 16, width: '100%' }}>
            <Avatar handle={p.handle} size={72} />
            <div style={{ display: 'flex', flexDirection: 'column', gap: 4, flex: 1, minWidth: 0 }}>
              <span className="name">{p.name}</span>
              <span className="handle">@{p.handle}</span>
              <div style={{ marginTop: 6 }}><Chip>{p.tag}</Chip></div>
            </div>
          </div>
          <div className="tagline">"{p.tagline}"</div>
          <div style={{ fontSize: 14, lineHeight: 1.55, color: 'var(--tdd-text-2)', textWrap: 'pretty' }}>
            {p.bio}
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8, width: '100%' }}>
            <div className="tdd-mono" style={{ fontSize: 9.5 }}>Rasgos</div>
            <div className="tdd-traits">
              {p.traits.map(t => <Chip key={t} kind="trait">{t}</Chip>)}
            </div>
          </div>
        </div>

        <div className="tdd-section-h with-count" style={{ paddingTop: 22 }}>
          Debates <span className="count">42</span>
        </div>
        {debates.map(d => <DebateCard key={d.id} debate={d} />)}
        <div style={{ height: 80 }} />
      </div>
      <BottomNav active="home" />
    </Phone>
  );
}

Object.assign(window, {
  LoginScreen, RegisterScreen, HomeScreen, DebateDetailScreen,
  ProfilesScreen, CharacterScreen, CommentBlock,
});
