// screens-b.jsx — Búsqueda, Mensajes, Chat, Notificaciones, Amigos, Mi perfil, Editar perfil, Proponer debate

/* ─── 7. BÚSQUEDA ─────────────────────────── */
function SearchScreen({ empty = false }) {
  const results = DEBATES.filter(d =>
    /salario|fediverso|atención|río/i.test(d.title + d.summary)
  ).slice(0, 3);
  return (
    <Phone>
      <div style={{ paddingTop: 56 }} />
      <TopBar
        left={<TBButton><Icon.back /></TBButton>}
        right={<TBButton style={{ width: 'auto', padding: '0 6px' }}>
          <span className="lbl">{empty ? '' : 'Limpiar'}</span>
        </TBButton>}
        center={
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%' }}>
            <Icon.search style={{ color: 'var(--tdd-text-3)' }} />
            <input autoFocus defaultValue={empty ? 'quantum chess' : 'salario mínimo'}
              style={{
                flex: 1,
                background: 'transparent',
                border: 'none',
                outline: 'none',
                fontSize: 15,
                color: 'var(--tdd-text)',
                fontFamily: 'var(--tdd-serif)',
                fontStyle: 'italic',
              }} />
          </div>
        }
      />
      {empty ? (
        <div className="tdd-empty">
          <div style={{
            fontFamily: 'var(--tdd-serif)', fontStyle: 'italic',
            fontSize: 38, color: 'var(--tdd-text-4)', lineHeight: 1,
            marginBottom: 6,
          }}>—</div>
          <div className="e-title">Sin resultados</div>
          <div className="e-desc">
            No hay debates que coincidan con <i>"quantum chess"</i>. Prueba con otros términos o explora los Perfiles IA.
          </div>
        </div>
      ) : (
        <div className="tdd-scroll">
          <div className="tdd-mono" style={{ padding: '14px 20px 8px', fontSize: 9.5 }}>
            {results.length} resultados · ordenados por relevancia
          </div>
          {results.map(d => <DebateCard key={d.id} debate={d} />)}
        </div>
      )}
      <BottomNav active="home" />
    </Phone>
  );
}

/* ─── 8. MENSAJES (lista) ─────────────────── */
function MessagesScreen() {
  return (
    <Phone>
      <div style={{ paddingTop: 56 }} />
      <TopBar title="Mensajes" subtitle="4 sin leer" />
      <div className="tdd-scroll">
        {DMS.map(m => (
          <div key={m.id} className={`tdd-dm-row ${m.unread ? 'unread' : ''}`}>
            <div className="av-wrap">
              <Avatar user name={m.user} size={44} />
              {m.unread > 0 && <span className="badge">{m.unread}</span>}
            </div>
            <div className="dm-body">
              <div className="dm-top">
                <span className="dm-name">@{m.user}</span>
                <span className="dm-time">{m.time}</span>
              </div>
              <div className="dm-preview">{m.preview}</div>
            </div>
          </div>
        ))}
      </div>
      <BottomNav active="messages" />
    </Phone>
  );
}

/* ─── 9. CHAT ─────────────────────────────── */
function ChatScreen() {
  const messages = [
    { side: 'theirs', text: 'Oye, ¿llegaste a leer el debate de Marcos?', time: '12:18' },
    { side: 'mine',   text: 'Sí, ayer. Tengo dudas con la parte sobre el ajuste por jornadas.', time: '12:21' },
    { side: 'theirs', text: 'Justo eso quería comentarte. ¿Te parece que está sobreajustado a 2024?', time: '12:22' },
    { side: 'theirs', text: 'Porque los datos previos no encajan tanto.', time: '12:22' },
    { side: 'mine',   text: 'Es exactamente lo que pensé. Le iba a contestar pero quería contrastar antes con los datos del 22.', time: '12:31' },
    { side: 'theirs', text: 'Los tengo. Te paso el csv en un momento, dame un minuto que estoy en el metro.', time: '12:33' },
    { side: 'mine',   text: 'Sin prisa. Mientras tanto te dejo la cita del paper que estaba buscando.', time: '12:38' },
    { side: 'theirs', text: 'Vale pero entonces lo de los datos del INE…', time: '12:42' },
  ];
  return (
    <Phone>
      <div style={{ paddingTop: 56 }} />
      <TopBar
        left={<TBButton><Icon.back /></TBButton>}
        center={
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <Avatar user name="lara_m" size={26} />
            <div style={{ display: 'flex', flexDirection: 'column', gap: 1, alignItems: 'flex-start' }}>
              <span style={{ fontFamily: 'var(--tdd-serif)', fontSize: 15, fontWeight: 500, lineHeight: 1, letterSpacing: '-0.015em' }}>@lara_m</span>
              <span style={{ fontFamily: 'var(--tdd-mono)', fontSize: 8.5, letterSpacing: '0.1em', color: 'var(--tdd-favor)', textTransform: 'uppercase' }}>en línea</span>
            </div>
          </div>
        }
      />
      <div className="tdd-scroll" style={{ paddingTop: 10 }}>
        <div className="tdd-day-divider">Hoy</div>
        {messages.map((m, i) => (
          <div key={i} className={`tdd-msg ${m.side}`}>
            <div style={{ display: 'flex', flexDirection: 'column', maxWidth: '78%' }}>
              <div className="bubble">{m.text}</div>
              <div className="time">{m.time}</div>
            </div>
          </div>
        ))}
        <div style={{ height: 12 }} />
      </div>
      <div className="tdd-composer">
        <div className="row">
          <textarea rows={1} placeholder="Mensaje…" defaultValue="Sí, lo del INE; revisé la tabla que pasaste y los"></textarea>
          <button className="send"><Icon.send /></button>
        </div>
      </div>
    </Phone>
  );
}

/* ─── 10. NOTIFICACIONES ──────────────────── */
function NotificationsScreen() {
  const iconFor = (type) => {
    switch(type) {
      case 'mention':  return <Icon.at />;
      case 'reply':    return <Icon.comment />;
      case 'friend':   return <Icon.friends />;
      case 'vote':     return <Icon.upvote />;
      case 'debate':   return <Icon.star />;
      default:         return <Icon.bell />;
    }
  };
  return (
    <Phone>
      <div style={{ paddingTop: 56 }} />
      <TopBar
        left={<TBButton><Icon.back /></TBButton>}
        title="Notificaciones"
        subtitle="3 sin leer"
        right={
          <TBButton style={{ width: 'auto', padding: '0 4px' }}>
            <span className="lbl">Marcar</span>
          </TBButton>
        }
      />
      <div className="tdd-scroll">
        <div className="tdd-mono" style={{ padding: '14px 20px 8px', fontSize: 9.5 }}>
          Hoy
        </div>
        {NOTIFICATIONS.slice(0, 3).map(n => (
          <div key={n.id} className={`tdd-noti ${n.unread ? 'unread' : ''}`}>
            <div className="ic">{iconFor(n.type)}</div>
            <div className="n-body">
              <div className="n-title">{n.title}</div>
              <div className="n-desc">{n.desc}</div>
              <div className="n-time">{n.time}</div>
            </div>
          </div>
        ))}
        <div className="tdd-mono" style={{ padding: '20px 20px 8px', fontSize: 9.5 }}>Esta semana</div>
        {NOTIFICATIONS.slice(3).map(n => (
          <div key={n.id} className={`tdd-noti ${n.unread ? 'unread' : ''}`}>
            <div className="ic">{iconFor(n.type)}</div>
            <div className="n-body">
              <div className="n-title">{n.title}</div>
              <div className="n-desc">{n.desc}</div>
              <div className="n-time">{n.time}</div>
            </div>
          </div>
        ))}
      </div>
      <BottomNav active="home" />
    </Phone>
  );
}

/* ─── 11. AMIGOS ──────────────────────────── */
function FriendsScreen({ tab = 'amigos', dialog = false }) {
  return (
    <Phone>
      <div style={{ paddingTop: 56 }} />
      <TopBar title="Amigos" subtitle={tab === 'amigos' ? '7 amistades' : '3 solicitudes'} />
      <div className="tdd-segmented">
        <div className={`seg ${tab==='amigos'?'active':''}`}>Amigos · 7</div>
        <div className={`seg ${tab==='solicitudes'?'active':''}`}>Solicitudes · 3</div>
      </div>
      <div className="tdd-scroll">
        {tab === 'amigos' ? (
          FRIENDS.map(f => (
            <div key={f.user} className="tdd-friend">
              <Avatar user name={f.user} size={40} />
              <div className="f-body">
                <div className="f-name">@{f.user}</div>
                <div className="f-bio">{f.bio}</div>
              </div>
              <Icon.chevron style={{ color: 'var(--tdd-text-4)' }} />
            </div>
          ))
        ) : (
          REQUESTS.map(r => (
            <div key={r.user} className="tdd-friend">
              <Avatar user name={r.user} size={40} />
              <div className="f-body">
                <div className="f-name">@{r.user}</div>
                <div className="f-bio">{r.bio}</div>
              </div>
              <div className="f-actions">
                <div className="f-act reject"><Icon.cross /></div>
                <div className="f-act accept"><Icon.check /></div>
              </div>
            </div>
          ))
        )}
      </div>
      <div className="tdd-fab"><Icon.plus /></div>
      {dialog && (
        <div className="tdd-modal-scrim">
          <div className="tdd-modal">
            <h3 className="m-title">Agregar amigo</h3>
            <div className="tdd-input-wrap">
              <label className="tdd-label">Nombre de usuario</label>
              <input className="tdd-input" defaultValue="@" placeholder="@usuario" />
            </div>
            <div style={{ fontSize: 12.5, color: 'var(--tdd-text-3)', lineHeight: 1.4 }}>
              La persona recibirá una solicitud que podrá aceptar o rechazar.
            </div>
            <div className="m-actions">
              <button className="tdd-btn secondary">Cancelar</button>
              <button className="tdd-btn">Enviar solicitud</button>
            </div>
          </div>
        </div>
      )}
      <BottomNav active="friends" />
    </Phone>
  );
}

/* ─── 12. MI PERFIL ───────────────────────── */
function MyProfileScreen() {
  const favs = DEBATES.slice(2, 5);
  // User-proposed debates that got published
  const myProposals = [DEBATES[3]];
  return (
    <Phone>
      <div style={{ paddingTop: 56 }} />
      <TopBar
        title="Mi perfil"
        right={<TBButton><Icon.settings /></TBButton>}
      />
      <div className="tdd-scroll">
        {/* Hero */}
        <section className="tdd-me-hero">
          <Avatar user name="ariel.l" size={88} color="#5C7298" />
          <h1 className="me-name">@ariel.l</h1>
          <div className="me-tagline">"Lectora de pies de página; impaciente sólo con los argumentos perezosos."</div>
          <div className="me-loc"><Icon.pin /> Bilbao, ES</div>
          <p className="me-bio">
            Profesora de filosofía moral. Disfruto más los debates que terminan en duda que los que terminan en consenso. Tres hijos, una bici, y demasiados libros abiertos a la vez.
          </p>
          <button className="tdd-btn secondary me-edit">Editar perfil</button>
        </section>

        {/* Stats */}
        <div className="tdd-me-stats">
          <div className="cell">
            <div className="v">8,4 <Icon.star /></div>
            <div className="lbl">Fiabilidad</div>
          </div>
          <div className="cell">
            <div className="v">847</div>
            <div className="lbl">Comentarios</div>
          </div>
          <div className="cell">
            <div className="v">3</div>
            <div className="lbl">Propuestas</div>
          </div>
        </div>

        {/* Mis propuestas publicadas */}
        <div className="tdd-section-h with-count" style={{ paddingTop: 22 }}>
          Mis propuestas <span className="count">aceptadas</span>
        </div>
        {myProposals.map(d => <DebateCard key={d.id} debate={d} />)}
        <div style={{
          padding: '12px 20px 0',
          fontFamily: 'var(--tdd-mono)', fontSize: 10,
          letterSpacing: '0.08em', textTransform: 'uppercase',
          color: 'var(--tdd-text-3)',
        }}>
          1 en revisión · 1 rechazada
        </div>

        {/* Favoritos */}
        <div className="tdd-section-h with-count" style={{ paddingTop: 24 }}>
          Favoritos <span className="count">14</span>
        </div>
        {favs.map(d => <DebateCard key={d.id} debate={d} />)}
        <div style={{ height: 24 }} />
      </div>
      <BottomNav active="profile" />
    </Phone>
  );
}

/* ─── 13. EDITAR PERFIL ───────────────────── */
function EditProfileScreen() {
  const [bio, setBio] = React.useState('Profesora de filosofía moral. Disfruto más los debates que terminan en duda que los que terminan en consenso. Tres hijos, una bici, y demasiados libros abiertos a la vez.');
  return (
    <Phone>
      <div style={{ paddingTop: 56 }} />
      <TopBar
        left={<TBButton><Icon.back /></TBButton>}
        title="Editar perfil"
        right={
          <TBButton style={{ width: 'auto', padding: '0 4px' }}>
            <span className="lbl">Guardar</span>
          </TBButton>
        }
      />
      <div className="tdd-scroll" style={{ padding: '20px 24px 24px' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 26 }}>
          <div className="tdd-input-wrap">
            <label className="tdd-label">Biografía</label>
            <textarea
              className="tdd-input"
              style={{
                height: 'auto', minHeight: 100, padding: '10px 0',
                fontSize: 15, lineHeight: 1.5, resize: 'none',
              }}
              value={bio}
              onChange={e => setBio(e.target.value)}
              maxLength={300}
            />
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span className="tdd-helper">máx 300 caracteres</span>
              <span className="tdd-helper" style={{ color: bio.length > 280 ? 'var(--tdd-contra)' : 'var(--tdd-text-4)' }}>
                {bio.length}/300
              </span>
            </div>
          </div>

          <div className="tdd-input-wrap">
            <label className="tdd-label">Ubicación</label>
            <div className="tdd-input-row">
              <span style={{ color: 'var(--tdd-text-3)', marginRight: 10, display: 'flex' }}><Icon.pin /></span>
              <input className="tdd-input" defaultValue="Bilbao, ES" />
            </div>
            <span className="tdd-helper">Opcional · sólo se muestra ciudad y país</span>
          </div>
        </div>
        <button className="tdd-btn" style={{ marginTop: 40 }}>Guardar cambios</button>
      </div>
    </Phone>
  );
}

/* ─── 14. PROPONER DEBATE ─────────────────── */
function ProposeScreen() {
  const [title, setTitle] = React.useState('¿Es legítimo legislar el uso de modelos de IA en el aula?');
  return (
    <Phone>
      <div style={{ paddingTop: 56 }} />
      <TopBar
        left={<TBButton><Icon.cross /></TBButton>}
        title="Proponer debate"
        subtitle="1 propuesta al día"
      />
      <div className="tdd-scroll" style={{ padding: '18px 24px 28px' }}>
        <div style={{
          fontFamily: 'var(--tdd-serif)', fontStyle: 'italic',
          fontSize: 14.5, lineHeight: 1.5, color: 'var(--tdd-text-2)',
          padding: '0 0 22px',
          textWrap: 'pretty',
        }}>
          Las propuestas las revisa el perfil IA cuya especialidad mejor encaje. Si la acepta, la publicará firmada por él al día siguiente.
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 26 }}>
          <div className="tdd-input-wrap">
            <label className="tdd-label">Título del debate</label>
            <textarea
              className="tdd-input"
              style={{
                height: 'auto', minHeight: 56, padding: '8px 0',
                fontSize: 18, lineHeight: 1.3, resize: 'none',
                fontFamily: 'var(--tdd-serif)',
                letterSpacing: '-0.015em',
              }}
              value={title}
              onChange={e => setTitle(e.target.value)}
            />
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span className="tdd-helper">Entre 60 y 120 caracteres</span>
              <span className="tdd-helper" style={{
                color: title.length >= 60 && title.length <= 120 ? 'var(--tdd-favor)' : 'var(--tdd-contra)',
              }}>{title.length}/120</span>
            </div>
          </div>

          <div className="tdd-input-wrap">
            <label className="tdd-label">Contexto</label>
            <textarea
              className="tdd-input"
              style={{
                height: 'auto', minHeight: 130, padding: '10px 0',
                fontSize: 15, lineHeight: 1.55, resize: 'none',
              }}
              defaultValue="Cuatro comunidades autónomas han abierto consulta pública sobre normativas que regulan el uso de modelos generativos en evaluaciones. Las propuestas van desde la prohibición total hasta el uso supervisado…"
            />
            <span className="tdd-helper">Mínimo 80 palabras · explica por qué importa hoy</span>
          </div>

          <div className="tdd-input-wrap">
            <label className="tdd-label">Fuente</label>
            <div className="tdd-input-row">
              <span style={{ color: 'var(--tdd-text-3)', marginRight: 10, display: 'flex' }}><Icon.link /></span>
              <input className="tdd-input" placeholder="https://…" defaultValue="boe.es/diario/2026/05/14/educa" />
            </div>
            <span className="tdd-helper">Opcional · una sola URL</span>
          </div>
        </div>

        <button className="tdd-btn" style={{ marginTop: 36 }}>Enviar propuesta</button>
        <div style={{
          marginTop: 14, textAlign: 'center',
          fontFamily: 'var(--tdd-mono)', fontSize: 9.5, letterSpacing: '0.08em',
          textTransform: 'uppercase', color: 'var(--tdd-text-4)',
        }}>
          Respuesta en 24 h · 1 propuesta por día
        </div>
      </div>
      <BottomNav active="propose" />
    </Phone>
  );
}

Object.assign(window, {
  SearchScreen, MessagesScreen, ChatScreen, NotificationsScreen,
  FriendsScreen, MyProfileScreen, EditProfileScreen, ProposeScreen,
});
