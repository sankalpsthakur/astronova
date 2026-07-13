// Astronova — Onboarding screens
// 01 Splash, 02 Birth data, 03 Phone (Loshu), 04 Context priors

// ────────────────────────────────────────────────────────────
// 01 — Splash / cold open
// ────────────────────────────────────────────────────────────
function SplashScreen() {
  return (
    <div className="astro-screen starfield" style={{ position: 'relative' }}>
      {/* Constellation arc */}
      <svg width="100%" height="100%" viewBox="0 0 402 874" style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
      }}>
        <defs>
          <radialGradient id="splashGlow" cx="50%" cy="40%" r="50%">
            <stop offset="0%" stopColor="rgba(255,200,120,0.18)"/>
            <stop offset="100%" stopColor="rgba(255,200,120,0)"/>
          </radialGradient>
        </defs>
        <circle cx="201" cy="350" r="280" fill="url(#splashGlow)"/>
        {/* Outer ring */}
        <circle cx="201" cy="350" r="160" fill="none" stroke="rgba(244,237,224,0.10)" strokeWidth="0.5"/>
        <circle cx="201" cy="350" r="120" fill="none" stroke="rgba(244,237,224,0.06)" strokeWidth="0.5" strokeDasharray="2 4"/>
        {/* 12 ticks */}
        {Array.from({ length: 12 }).map((_, i) => {
          const a = (i * 30 - 90) * Math.PI / 180;
          const x1 = 201 + Math.cos(a) * 156;
          const y1 = 350 + Math.sin(a) * 156;
          const x2 = 201 + Math.cos(a) * 164;
          const y2 = 350 + Math.sin(a) * 164;
          return <line key={i} x1={x1} y1={y1} x2={x2} y2={y2} stroke="rgba(244,237,224,0.3)" strokeWidth="0.6"/>;
        })}
        {/* Planet dots on ring */}
        {[
          { a: 30,  s: 4, c: 'oklch(0.74 0.11 145)' },
          { a: 95,  s: 5, c: 'oklch(0.80 0.12 75)' },
          { a: 165, s: 3, c: 'oklch(0.78 0.13 65)' },
          { a: 220, s: 4, c: 'oklch(0.66 0.17 25)' },
          { a: 300, s: 3, c: 'oklch(0.74 0.08 215)' },
        ].map((d, i) => {
          const a = (d.a - 90) * Math.PI / 180;
          return <circle key={i} cx={201 + Math.cos(a)*160} cy={350 + Math.sin(a)*160} r={d.s} fill={d.c}/>;
        })}
      </svg>

      {/* Center mark */}
      <div style={{
        position: 'absolute', left: 0, right: 0, top: 290,
        textAlign: 'center', color: 'var(--fg)',
      }}>
        <div className="mono live-pulse" style={{
          fontSize: 10, letterSpacing: '0.4em', color: 'var(--gold)',
        }}>SYSTEM ACQUIRING</div>
        <div className="serif" style={{
          fontSize: 13, color: 'var(--fg-2)', marginTop: 6, fontStyle: 'italic',
        }}>9 processes · 12 houses · 1 you</div>
      </div>

      {/* Wordmark + CTA block */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '0 28px 56px',
      }}>
        <div className="mono" style={{
          fontSize: 10, letterSpacing: '0.32em', color: 'var(--fg-3)', marginBottom: 14,
        }}>v.26.05 · DELHI MERIDIAN</div>
        <h1 className="serif" style={{
          margin: 0, fontSize: 64, lineHeight: 0.92, color: 'var(--fg)', letterSpacing: '-0.02em',
        }}>
          Astro<span style={{ fontStyle: 'italic', color: 'var(--gold)' }}>nova</span>
        </h1>
        <p style={{
          margin: '14px 0 28px', color: 'var(--fg-2)', fontSize: 15, lineHeight: 1.45,
          maxWidth: 300,
        }}>
          A working model of your life — derived from sky, number, and timing.
          Engineered, not divined.
        </p>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <button className="btn-gold">Begin calibration  →</button>
          <button style={{
            background: 'transparent', border: 'none', color: 'var(--fg-2)',
            fontFamily: 'var(--sans)', fontSize: 14, height: 40, cursor: 'pointer',
          }}>I have an account</button>
        </div>
      </div>
    </div>
  );
}

// ────────────────────────────────────────────────────────────
// 02 — Birth data entry
// ────────────────────────────────────────────────────────────
function BirthScreen() {
  return (
    <div className="astro-screen">
      <TopBar
        eyebrow="STEP 01 / 04"
        title="Birth coordinates"
        leading={<IconBtn>‹</IconBtn>}
      />
      <div style={{ padding: '28px 20px 0' }}>
        <h1 className="serif" style={{
          margin: 0, fontSize: 38, lineHeight: 1.05, letterSpacing: '-0.015em',
        }}>
          When and where<br/>did you arrive.
        </h1>
        <p style={{ color: 'var(--fg-2)', marginTop: 12, fontSize: 14, lineHeight: 1.5 }}>
          The chart resolves to within 2 arcminutes. Wrong time, wrong life — get it from a
          birth certificate if you can.
        </p>
      </div>

      {/* Form */}
      <div style={{ padding: '32px 20px 24px', display: 'flex', flexDirection: 'column', gap: 14 }}>
        {[
          { label: 'DATE',  v: '14 March 1994',     pid: 'date' },
          { label: 'TIME',  v: '04 : 47 : 12  IST', pid: 'time', detail: '±0:02' },
          { label: 'PLACE', v: 'Bengaluru, IN',     pid: 'geo',  detail: '12.97°N · 77.59°E' },
        ].map((f, i) => (
          <div key={i} style={{
            background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
            borderRadius: 16, padding: '14px 16px',
            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          }}>
            <div>
              <div className="mono" style={{ fontSize: 9, letterSpacing: '0.22em', color: 'var(--fg-3)' }}>
                {f.label}
              </div>
              <div className="serif" style={{ fontSize: 22, marginTop: 4, color: 'var(--fg)' }}>{f.v}</div>
            </div>
            {f.detail && (
              <div className="mono" style={{ fontSize: 10, color: 'var(--gold)', textAlign: 'right' }}>
                {f.detail}
              </div>
            )}
          </div>
        ))}
      </div>

      {/* Note */}
      <div style={{
        margin: '0 20px', padding: '14px 16px',
        background: 'rgba(255,210,140,0.06)',
        border: '0.5px solid rgba(255,210,140,0.18)',
        borderRadius: 14, display: 'flex', gap: 12, alignItems: 'flex-start',
      }}>
        <span className="glyph" style={{ fontSize: 18, color: 'var(--gold)' }}>◆</span>
        <div style={{ fontSize: 12.5, color: 'var(--fg-2)', lineHeight: 1.5 }}>
          Time precision tracks the <span style={{ color: 'var(--gold)' }}>ascendant</span>, which rotates ~1° every 4 min.
          A vague time degrades every downstream prediction.
        </div>
      </div>

      <div style={{ padding: '32px 20px 80px' }}>
        <button className="btn-gold" style={{ width: '100%' }}>Continue  →</button>
      </div>
    </div>
  );
}

// ────────────────────────────────────────────────────────────
// 03 — Phone number (feeds Loshu)
// ────────────────────────────────────────────────────────────
function PhoneScreen() {
  const digits = '9 8 4 5 1 2 7 7 3 6';
  return (
    <div className="astro-screen">
      <TopBar eyebrow="STEP 02 / 04" title="Loshu vector" leading={<IconBtn>‹</IconBtn>} />
      <div style={{ padding: '28px 20px 0' }}>
        <h1 className="serif" style={{ margin: 0, fontSize: 38, lineHeight: 1.05, letterSpacing: '-0.015em' }}>
          Your phone is<br/>part of you now.
        </h1>
        <p style={{ color: 'var(--fg-2)', marginTop: 12, fontSize: 14, lineHeight: 1.5 }}>
          We feed its digits into the Loshu grid as a supplementary vector. Privacy: hashed, never dialled.
        </p>
      </div>

      {/* Phone field */}
      <div style={{ padding: '28px 20px 8px' }}>
        <div style={{
          background: 'var(--ink-1)', border: '0.5px solid var(--hair-2)',
          borderRadius: 16, padding: '20px 18px',
        }}>
          <div className="mono" style={{ fontSize: 9, letterSpacing: '0.22em', color: 'var(--fg-3)' }}>+91 INDIA</div>
          <div className="mono" style={{ fontSize: 26, marginTop: 6, color: 'var(--fg)', letterSpacing: '0.06em' }}>
            {digits}<span className="live-pulse" style={{ color: 'var(--gold)' }}>|</span>
          </div>
        </div>
      </div>

      {/* Live Loshu preview */}
      <div style={{ padding: '24px 20px 0' }}>
        <div className="mono" style={{
          fontSize: 10, letterSpacing: '0.22em', color: 'var(--fg-3)', marginBottom: 10,
        }}>LIVE LOSHU PREVIEW · 3×3</div>
        <div style={{
          background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
          borderRadius: 16, padding: 18,
          display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 6,
        }}>
          {[4,9,2,3,5,7,8,1,6].map(n => {
            const counts = { 1:2, 2:1, 3:0, 4:1, 5:1, 6:1, 7:2, 8:1, 9:1 };
            const c = counts[n];
            return (
              <div key={n} style={{
                aspectRatio: '1/1', borderRadius: 10,
                background: c === 0 ? 'rgba(102,30,30,0.16)' : c >= 2 ? 'rgba(180,140,60,0.12)' : 'var(--ink-2)',
                border: '0.5px solid ' + (c === 0 ? 'rgba(200,60,60,0.4)' : 'var(--hair)'),
                position: 'relative',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <span className="serif" style={{
                  fontSize: 26, color: c === 0 ? 'var(--bad)' : c >= 2 ? 'var(--gold)' : 'var(--fg)',
                }}>{n}</span>
                {c > 0 && (
                  <span className="mono" style={{
                    position: 'absolute', top: 6, right: 8, fontSize: 9, color: 'var(--fg-3)',
                  }}>×{c}</span>
                )}
              </div>
            );
          })}
        </div>
        <div className="mono" style={{
          marginTop: 12, fontSize: 11, color: 'var(--fg-2)', lineHeight: 1.5,
        }}>
          missing → <span style={{ color: 'var(--bad)' }}>[3]</span>  ·
          surplus → <span style={{ color: 'var(--gold)' }}>[1, 7]</span>  ·
          plane → <span style={{ color: 'var(--cool)' }}>thought</span>
        </div>
      </div>

      <div style={{ padding: '32px 20px 80px' }}>
        <button className="btn-gold" style={{ width: '100%' }}>Continue  →</button>
      </div>
    </div>
  );
}

// ────────────────────────────────────────────────────────────
// 04 — Context priors (real-world rooting)
// ────────────────────────────────────────────────────────────
function ContextScreen() {
  const tags = [
    { t: 'Building a company',      on: true,  k: 'forge' },
    { t: 'Raising capital',         on: true,  k: 'cap' },
    { t: 'Considering relocation',  on: true,  k: 'reloc' },
    { t: 'Career transition',       on: false, k: 'job' },
    { t: 'New relationship',        on: false, k: 'rel' },
    { t: 'Health rebuild',          on: false, k: 'body' },
    { t: 'Buying property',         on: false, k: 'home' },
    { t: 'Writing / public output', on: true,  k: 'voice' },
    { t: 'Legal / litigation',      on: false, k: 'law' },
  ];
  return (
    <div className="astro-screen">
      <TopBar eyebrow="STEP 03 / 04" title="Real-world priors" leading={<IconBtn>‹</IconBtn>} />
      <div style={{ padding: '28px 20px 0' }}>
        <h1 className="serif" style={{ margin: 0, fontSize: 36, lineHeight: 1.05, letterSpacing: '-0.015em' }}>
          What is the chart<br/><span style={{ fontStyle: 'italic', color: 'var(--gold)' }}>actually</span> running on?
        </h1>
        <p style={{ color: 'var(--fg-2)', marginTop: 12, fontSize: 14, lineHeight: 1.5 }}>
          Without context, predictions are vapor. Pick what's loaded — we'll prior the Bayesian engine.
        </p>
      </div>

      <div style={{ padding: '26px 20px 0', display: 'flex', flexWrap: 'wrap', gap: 8 }}>
        {tags.map(t => (
          <Chip key={t.k} active={t.on}>{t.t}</Chip>
        ))}
      </div>

      {/* Free-text */}
      <div style={{ padding: '28px 20px 0' }}>
        <div className="mono" style={{
          fontSize: 10, letterSpacing: '0.22em', color: 'var(--fg-3)', marginBottom: 10,
        }}>OPEN FIELD · NLP PARSE</div>
        <div style={{
          background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
          borderRadius: 14, padding: 16, minHeight: 96,
          color: 'var(--fg-2)', fontSize: 13.5, lineHeight: 1.55, fontStyle: 'italic',
        }}>
          "Running Forge (infra co) + advising Visusta. SpaceXAI email last week.
          Looking at Dubai base by Q3, Singapore entity by Oct."
        </div>
        <div className="mono" style={{
          marginTop: 10, fontSize: 11, color: 'var(--fg-3)',
        }}>
          extracted → <span style={{ color: 'var(--gold)' }}>3 ventures · 2 geos · 1 inbound</span>
        </div>
      </div>

      <div style={{ padding: '32px 20px 80px' }}>
        <button className="btn-gold" style={{ width: '100%' }}>Compute chart  →</button>
      </div>
    </div>
  );
}

Object.assign(window, { SplashScreen, BirthScreen, PhoneScreen, ContextScreen });
