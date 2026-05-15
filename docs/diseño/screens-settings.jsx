// screens-settings.jsx — Ajustes, Notificaciones, Apariencia, Privacidad

/* ─── Atoms ─────────────────────────────────── */
function SHeader({ children, side }) {
  return (
    <div className="tdd-settings-header">
      <span>{children}</span>
      <span className="rule" />
      {side && <span style={{ color: 'var(--tdd-text-4)' }}>{side}</span>}
    </div>
  );
}
function SRow({ icon, label, sub, value, chev = true, danger = false, control }) {
  return (
    <div className={`tdd-settings-row ${danger ? 'danger' : ''}`}>
      {icon && <div className="ic">{icon}</div>}
      <div className="text">
        <div className="lbl">{label}</div>
        {sub && <div className="sub">{sub}</div>}
      </div>
      {value && <span className="val">{value}</span>}
      {control}
      {chev && !control && <Icon.chevron className="chev" />}
    </div>
  );
}
function SGroup({ children }) {
  return <div className="tdd-settings-group">{children}</div>;
}
function Toggle({ on }) {
  return <div className={`tdd-toggle ${on ? 'on' : ''}`} />;
}
function Radio({ options, value }) {
  return (
    <div className="tdd-radio-row">
      {options.map(o => (
        <button key={o.id} className={`opt ${o.id === value ? 'active' : ''}`}>
          {o.icon}{o.label}
        </button>
      ))}
    </div>
  );
}

/* ─── 15. AJUSTES (índice) ──────────────────── */
function SettingsScreen() {
  return (
    <Phone>
      <div style={{ paddingTop: 56 }} />
      <TopBar
        left={<TBButton><Icon.back /></TBButton>}
        title="Ajustes"
        right={null}
        notifBadge={false}
      />
      <div className="tdd-scroll">
        {/* Account preview */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 12,
          padding: '18px 20px', borderBottom: '0.5px solid var(--tdd-border)',
        }}>
          <Avatar user name="ariel.l" size={48} color="#5C7298" />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontFamily: 'var(--tdd-serif)', fontSize: 17, fontWeight: 500, letterSpacing: '-0.015em' }}>@ariel.l</div>
            <div className="tdd-mono" style={{ marginTop: 2 }}>ariel.l@correo.com</div>
          </div>
        </div>

        <SHeader>Cuenta</SHeader>
        <SGroup>
          <SRow icon={<Icon.at />}      label="Correo electrónico" value="ariel.l@…" />
          <SRow icon={<Icon.eye />}     label="Contraseña"          sub="Cambiada hace 3 meses" />
          <SRow icon={<Icon.user />}    label="Sesiones activas"    value="2 dispositivos" />
        </SGroup>

        <SHeader>Preferencias</SHeader>
        <SGroup>
          <SRow icon={<Icon.bell />}     label="Notificaciones" value="4 activas" />
          <SRow icon={<Icon.moon />}     label="Apariencia"     value="Auto" />
          <SRow icon={<Icon.type />}     label="Idioma"         value="Español" />
        </SGroup>

        <SHeader>Privacidad</SHeader>
        <SGroup>
          <SRow icon={<Icon.message />}  label="Quién puede escribirme" value="Amigos" />
          <SRow icon={<Icon.cross />}    label="Cuentas bloqueadas"     value="2" />
          <SRow icon={<Icon.external />} label="Descargar mis datos"    sub="Recibes el archivo por correo" />
        </SGroup>

        <SHeader>TDD</SHeader>
        <SGroup>
          <SRow icon={<Icon.star />}     label="Versión"          value="1.4.0 · 218" chev={false} />
          <SRow icon={<Icon.link />}     label="Términos y condiciones" />
          <SRow icon={<Icon.link />}     label="Política de privacidad" />
          <SRow icon={<Icon.comment />}  label="Comunicar un problema" />
        </SGroup>

        <SHeader>Sesión</SHeader>
        <SGroup>
          <SRow icon={<Icon.logout />}   label="Cerrar sesión"    danger chev={false} />
          <SRow icon={<Icon.cross />}    label="Eliminar cuenta"  sub="Acción permanente" danger />
        </SGroup>

        <div className="tdd-settings-footer">
          <div className="ver">TDD · Tu Debate Diario · v1.4.0</div>
        </div>
      </div>
      <BottomNav active="profile" />
    </Phone>
  );
}

/* ─── 16. NOTIFICACIONES (preferencias) ─────── */
function NotifSettingsScreen() {
  return (
    <Phone>
      <div style={{ paddingTop: 56 }} />
      <TopBar
        left={<TBButton><Icon.back /></TBButton>}
        title="Notificaciones"
        subtitle="4 activas · 4 silenciadas"
        right={null}
        notifBadge={false}
      />
      <div className="tdd-scroll">
        <div style={{
          padding: '18px 20px 14px',
          fontFamily: 'var(--tdd-serif)', fontStyle: 'italic',
          fontSize: 14.5, lineHeight: 1.45,
          color: 'var(--tdd-text-2)',
          borderBottom: '0.5px solid var(--tdd-border)',
          textWrap: 'pretty',
        }}>
          Decide qué te molesta y qué no. Las que silenciamos siguen apareciendo en la pestaña — sólo no te avisamos.
        </div>

        <SHeader>Actividad sobre tus comentarios</SHeader>
        <SGroup>
          <SRow label="Respuestas"      sub="Cuando alguien responde a un comentario tuyo" chev={false} control={<Toggle on />} />
          <SRow label="Votos"           sub="Resúmenes diarios — máximo uno por día"        chev={false} control={<Toggle />} />
          <SRow label="Menciones"       sub="Cuando alguien te etiqueta con @"              chev={false} control={<Toggle on />} />
        </SGroup>

        <SHeader>Debates</SHeader>
        <SGroup>
          <SRow label="Nuevos debates de tus perfiles" sub="Las 8 voces que sigues, una a una" chev={false} control={<Toggle on />} />
          <SRow label="Estado de tus propuestas"      sub="Aceptada · en revisión · rechazada" chev={false} control={<Toggle on />} />
        </SGroup>

        <SHeader>Comunidad</SHeader>
        <SGroup>
          <SRow label="Mensajes directos"        chev={false} control={<Toggle on />} />
          <SRow label="Solicitudes de amistad"   chev={false} control={<Toggle on />} />
        </SGroup>

        <SHeader>Resumen y silencio</SHeader>
        <SGroup>
          <SRow label="Resumen diario por correo"  sub="A las 8:00 — debates del día y respuestas" chev={false} control={<Toggle />} />
          <SRow label="Horario de silencio"        value="22:00 — 08:00" />
        </SGroup>

        <div style={{ height: 28 }} />
      </div>
      <BottomNav active="profile" />
    </Phone>
  );
}

/* ─── 17. APARIENCIA ────────────────────────── */
function AppearanceScreen() {
  return (
    <Phone>
      <div style={{ paddingTop: 56 }} />
      <TopBar
        left={<TBButton><Icon.back /></TBButton>}
        title="Apariencia"
        right={null}
        notifBadge={false}
      />
      <div className="tdd-scroll">
        <SHeader>Tema</SHeader>
        <Radio
          value="claro"
          options={[
            { id: 'auto',   label: 'Auto' },
            { id: 'claro',  label: 'Claro', icon: <Icon.sun style={{ marginRight: 4 }} /> },
            { id: 'oscuro', label: 'Oscuro', icon: <Icon.moon style={{ marginRight: 4 }} /> },
          ]}
        />
        <div style={{
          margin: '0 20px 16px',
          padding: '12px 14px',
          background: 'var(--tdd-bg-elev)',
          border: '0.5px solid var(--tdd-border)',
          borderRadius: 6,
          fontFamily: 'var(--tdd-mono)', fontSize: 10,
          letterSpacing: '0.08em', textTransform: 'uppercase',
          color: 'var(--tdd-text-3)',
          lineHeight: 1.5,
        }}>
          Auto sigue el sistema operativo. El modo oscuro se activa entre 21:00 y 07:00 cuando hay luz tenue.
        </div>

        <SHeader>Tamaño de texto</SHeader>
        <Radio
          value="estandar"
          options={[
            { id: 'compacto', label: 'Compacto' },
            { id: 'estandar', label: 'Estándar' },
            { id: 'comodo',   label: 'Cómodo' },
          ]}
        />
        <div style={{
          margin: '0 20px 16px',
          padding: '16px',
          border: '0.5px solid var(--tdd-border)',
          borderRadius: 6,
        }}>
          <div style={{
            fontFamily: 'var(--tdd-serif)', fontSize: 19, fontWeight: 500,
            letterSpacing: '-0.018em', lineHeight: 1.2, textWrap: 'pretty',
          }}>
            La atención ya no es escasa: es un recurso minado.
          </div>
          <div style={{
            fontSize: 13.5, lineHeight: 1.5, color: 'var(--tdd-text-2)',
            marginTop: 8, textWrap: 'pretty',
          }}>
            Vista previa del cuerpo de un debate, con el tamaño elegido.
          </div>
        </div>

        <SHeader>Lectura</SHeader>
        <SGroup>
          <SRow label="Reducir movimiento" sub="Desactiva las animaciones secundarias" chev={false} control={<Toggle />} />
          <SRow label="Negro absoluto"     sub="Sólo en modo oscuro · ahorra batería en OLED" chev={false} control={<Toggle />} />
          <SRow label="Cursivas en serif"  sub="Mantén la cursiva editorial en los taglines"  chev={false} control={<Toggle on />} />
        </SGroup>

        <div style={{ height: 28 }} />
      </div>
      <BottomNav active="profile" />
    </Phone>
  );
}

/* ─── 18. PRIVACIDAD ────────────────────────── */
function PrivacyScreen() {
  return (
    <Phone>
      <div style={{ paddingTop: 56 }} />
      <TopBar
        left={<TBButton><Icon.back /></TBButton>}
        title="Privacidad"
        right={null}
        notifBadge={false}
      />
      <div className="tdd-scroll">
        <SHeader>Quién puede escribirme</SHeader>
        <Radio
          value="amigos"
          options={[
            { id: 'todos',  label: 'Todos' },
            { id: 'amigos', label: 'Amigos' },
            { id: 'nadie',  label: 'Nadie' },
          ]}
        />

        <SHeader>Quién puede mencionarme</SHeader>
        <Radio
          value="todos"
          options={[
            { id: 'todos',  label: 'Todos' },
            { id: 'amigos', label: 'Amigos' },
          ]}
        />

        <SHeader>Visibilidad del perfil</SHeader>
        <Radio
          value="todos"
          options={[
            { id: 'todos',  label: 'Todos' },
            { id: 'amigos', label: 'Amigos' },
            { id: 'priv',   label: 'Privado' },
          ]}
        />

        <SHeader>Datos</SHeader>
        <SGroup>
          <SRow label="Mejorar TDD con uso anónimo"   sub="Métricas agregadas y reportes de error" chev={false} control={<Toggle on />} />
          <SRow label="Personalizar mi feed por interés" sub="Ordena los debates según tus posiciones previas" chev={false} control={<Toggle />} />
        </SGroup>

        <SHeader>Acciones</SHeader>
        <SGroup>
          <SRow icon={<Icon.cross />}    label="Cuentas bloqueadas" value="2" />
          <SRow icon={<Icon.external />} label="Descargar mis datos" sub="Te lo enviamos en 24 h por correo" />
          <SRow icon={<Icon.logout />}   label="Eliminar todos mis comentarios" danger />
        </SGroup>

        <div style={{ height: 28 }} />
      </div>
      <BottomNav active="profile" />
    </Phone>
  );
}

Object.assign(window, {
  SettingsScreen, NotifSettingsScreen, AppearanceScreen, PrivacyScreen,
  SHeader, SRow, SGroup, Toggle, Radio,
});
