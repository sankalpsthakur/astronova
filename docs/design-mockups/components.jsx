// Astronova — shared primitives
// All components attached to window for cross-script availability.

const { useState, useEffect, useRef, useMemo, useCallback } = React;

// ─── Glyph maps ──────────────────────────────────────────────
const PLANET_GLYPH = {
  Sun: '☉', Moon: '☽', Mars: '♂', Mercury: '☿',
  Jupiter: '♃', Venus: '♀', Saturn: '♄',
  Rahu: '☊', Ketu: '☋',
};
const SIGN_GLYPH = {
  Aries: '♈', Taurus: '♉', Gemini: '♊', Cancer: '♋',
  Leo: '♌', Virgo: '♍', Libra: '♎', Scorpio: '♏',
  Sagittarius: '♐', Capricorn: '♑', Aquarius: '♒', Pisces: '♓',
};
const SIGN_LIST = Object.keys(SIGN_GLYPH);

// Canonical Vedic strength matrix for demo data
const PLANETS = [
  { p: 'Sun',     sign: 'Leo',         house: 10, status: 'own',   strength: 0.88, pid: '0001', deg: '14°22\'' },
  { p: 'Moon',    sign: 'Taurus',      house:  7, status: 'exalt', strength: 0.94, pid: '0002', deg: '03°45\'' },
  { p: 'Mars',    sign: 'Capricorn',   house:  3, status: 'exalt', strength: 0.91, pid: '0003', deg: '28°11\'' },
  { p: 'Mercury', sign: 'Virgo',       house: 11, status: 'own',   strength: 0.86, pid: '0004', deg: '09°02\'' },
  { p: 'Jupiter', sign: 'Sagittarius', house:  2, status: 'own',   strength: 0.82, pid: '0005', deg: '17°38\'' },
  { p: 'Venus',   sign: 'Virgo',       house: 11, status: 'debil', strength: 0.31, pid: '0006', deg: '21°06\'' },
  { p: 'Saturn',  sign: 'Pisces',      house:  5, status: 'neut',  strength: 0.54, pid: '0007', deg: '06°50\'' },
  { p: 'Rahu',    sign: 'Aries',       house:  6, status: 'neut',  strength: 0.62, pid: '0008', deg: '12°14\'' },
  { p: 'Ketu',    sign: 'Libra',       house: 12, status: 'neut',  strength: 0.58, pid: '0009', deg: '12°14\'' },
];

const STATUS_META = {
  exalt: { label: 'Exalted',     color: 'var(--good)', code: 'EXLT', dot: 'dot-good' },
  own:   { label: 'Own sign',    color: 'var(--warn)', code: 'OWN ', dot: 'dot-warn' },
  neut:  { label: 'Neutral',     color: 'var(--cool)', code: 'NEUT', dot: 'dot-cool' },
  debil: { label: 'Debilitated', color: 'var(--bad)',  code: 'DBLT', dot: 'dot-bad' },
};

// ─── Glyph component ─────────────────────────────────────────
function Glyph({ name, size = 18, color = 'var(--fg)' }) {
  const g = PLANET_GLYPH[name] || SIGN_GLYPH[name] || name;
  return (
    <span className="glyph" style={{ fontSize: size, color, lineHeight: 1, display: 'inline-block' }}>
      {g}
    </span>
  );
}

// ─── Status dot + label ──────────────────────────────────────
function StatusBadge({ status }) {
  const m = STATUS_META[status] || STATUS_META.neut;
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
      <span className={`dot ${m.dot}`} />
      <span className="mono" style={{ fontSize: 10, color: 'var(--fg-2)', letterSpacing: '0.06em' }}>
        {m.code}
      </span>
    </span>
  );
}

// ─── Section eyebrow header ─────────────────────────────────
function SectionHead({ eyebrow, title, action }) {
  return (
    <div style={{ padding: '24px 20px 14px' }}>
      {eyebrow && (
        <div className="mono" style={{
          fontSize: 10, letterSpacing: '0.22em', color: 'var(--fg-3)',
          textTransform: 'uppercase', marginBottom: 8,
        }}>{eyebrow}</div>
      )}
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 12 }}>
        <h2 className="serif" style={{ margin: 0, fontSize: 30, lineHeight: 1.05, color: 'var(--fg)' }}>
          {title}
        </h2>
        {action && <div className="mono" style={{ fontSize: 11, color: 'var(--fg-2)' }}>{action}</div>}
      </div>
    </div>
  );
}

// ─── Mono key/value row ─────────────────────────────────────
function DataRow({ k, v, vColor, dim }) {
  return (
    <div style={{
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      padding: '8px 0', borderBottom: '0.5px solid var(--hair)',
      fontFamily: 'var(--mono)', fontSize: 12, color: dim ? 'var(--fg-3)' : 'var(--fg)',
    }}>
      <span style={{ color: 'var(--fg-3)', letterSpacing: '0.04em' }}>{k}</span>
      <span style={{ color: vColor || 'inherit' }}>{v}</span>
    </div>
  );
}

// ─── Pill chip ──────────────────────────────────────────────
function Chip({ children, active, onClick, glyph }) {
  return (
    <button onClick={onClick} style={{
      background: active ? 'var(--fg)' : 'transparent',
      color: active ? 'var(--ink-0)' : 'var(--fg-2)',
      border: '0.5px solid ' + (active ? 'var(--fg)' : 'var(--hair-2)'),
      borderRadius: 999,
      padding: '8px 14px',
      fontFamily: 'var(--sans)',
      fontSize: 12,
      fontWeight: 500,
      cursor: 'pointer',
      display: 'inline-flex',
      alignItems: 'center',
      gap: 6,
      letterSpacing: '-0.005em',
      whiteSpace: 'nowrap',
    }}>
      {glyph && <span className="glyph" style={{ fontSize: 14 }}>{glyph}</span>}
      {children}
    </button>
  );
}

// ─── Tab bar (bottom) ───────────────────────────────────────
function TabBar({ active, onChange }) {
  const tabs = [
    { id: 'home',    label: 'Today',    icon: '◐' },
    { id: 'chart',   label: 'Chart',    icon: '☉' },
    { id: 'time',    label: 'Timeline', icon: '◷' },
    { id: 'map',     label: 'Map',      icon: '◯' },
    { id: 'sys',     label: 'System',   icon: '▤' },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      height: 78, paddingBottom: 22,
      borderTop: '0.5px solid var(--hair)',
      background: 'rgba(11,10,8,0.85)',
      backdropFilter: 'blur(20px) saturate(180%)',
      WebkitBackdropFilter: 'blur(20px) saturate(180%)',
      display: 'flex', alignItems: 'center', justifyContent: 'space-around',
      zIndex: 30,
    }}>
      {tabs.map(t => (
        <button key={t.id} onClick={() => onChange && onChange(t.id)} style={{
          background: 'transparent', border: 'none', cursor: 'pointer',
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
          color: active === t.id ? 'var(--gold)' : 'var(--fg-3)',
          fontFamily: 'var(--sans)', fontSize: 10,
          padding: '6px 10px',
        }}>
          <span className="glyph" style={{ fontSize: 18, lineHeight: 1 }}>{t.icon}</span>
          <span style={{ letterSpacing: '0.04em' }}>{t.label}</span>
        </button>
      ))}
    </div>
  );
}

// ─── Top bar (in-screen, replaces IOSNavBar) ────────────────
function TopBar({ title, leading, trailing, eyebrow }) {
  return (
    <div style={{
      paddingTop: 58, paddingLeft: 20, paddingRight: 20, paddingBottom: 6,
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        {leading}
        <div>
          {eyebrow && <div className="mono" style={{
            fontSize: 9, letterSpacing: '0.22em', color: 'var(--fg-3)', textTransform: 'uppercase',
          }}>{eyebrow}</div>}
          <div className="serif" style={{ fontSize: 18, color: 'var(--fg)' }}>{title}</div>
        </div>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>{trailing}</div>
    </div>
  );
}

// ─── Round icon button ──────────────────────────────────────
function IconBtn({ children, onClick, active }) {
  return (
    <button onClick={onClick} style={{
      width: 36, height: 36, borderRadius: 999,
      background: active ? 'var(--ink-2)' : 'transparent',
      border: '0.5px solid var(--hair-2)',
      color: 'var(--fg)',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      cursor: 'pointer', padding: 0,
    }}>{children}</button>
  );
}

// Helper exports
Object.assign(window, {
  Glyph, StatusBadge, SectionHead, DataRow, Chip, TabBar, TopBar, IconBtn,
  PLANET_GLYPH, SIGN_GLYPH, SIGN_LIST, PLANETS, STATUS_META,
});
