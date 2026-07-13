// Astronova — Analysis modules (Map, Transition, Free-will)

// ────────────────────────────────────────────────────────────
// 10 — Astrocartography (relocation map)
// ────────────────────────────────────────────────────────────
function MapScreen() {
  const [pick, setPick] = useState('Dubai');

  // Simplified world map paths — rough continent silhouettes, hand-drawn.
  // Not geographically precise; design fidelity.
  const continents = "M30 100 q40 -50 90 -40 q40 8 60 -20 q40 -30 80 -20 q20 6 30 30 q-10 30 -50 40 q-40 6 -90 -10 q-30 30 -90 25 q-50 -5 -30 -25z M180 110 q50 -40 110 -30 q60 12 80 -10 q50 -50 110 -30 q40 14 50 50 q-30 60 -120 40 q-60 -10 -130 30 q-60 30 -100 0z M320 200 q40 0 50 30 q-10 50 -40 60 q-40 -10 -30 -50z M40 220 q40 -20 80 0 q40 20 30 50 q-30 30 -90 20 q-40 -20 -20 -70z";

  const cities = [
    { name: 'Bengaluru', x: 296, y: 178, asc: '♏', desc: 'Native · self' },
    { name: 'Dubai',     x: 248, y: 158, asc: '♐', desc: 'Sovereign-Creator amplified' },
    { name: 'Singapore', x: 332, y: 192, asc: '♑', desc: 'Capital · stable' },
    { name: 'New York',  x: 110, y: 144, asc: '♋', desc: 'Home → care · soft' },
    { name: 'Tokyo',     x: 372, y: 152, asc: '♓', desc: 'Inner work · public risk' },
    { name: 'London',    x: 200, y: 122, asc: '♌', desc: 'Spotlight · ego cost' },
  ];
  const selected = cities.find(c => c.name === pick) || cities[1];

  // planetary "lines" — gold vertical-ish curves across the map
  const lines = [
    { p: 'Ju MC', d: 'M70 60 Q 250 90 460 80', c: 'oklch(0.80 0.12 75)' },
    { p: 'Ve AS', d: 'M120 50 Q 220 200 360 280', c: 'oklch(0.78 0.09 295)' },
    { p: 'Sa IC', d: 'M30 220 Q 250 240 470 220', c: 'oklch(0.66 0.10 215)' },
    { p: 'Ma AS', d: 'M250 60 Q 280 200 290 290', c: 'oklch(0.66 0.17 25)' },
  ];

  return (
    <div className="astro-screen" style={{ paddingBottom: 90 }}>
      <TopBar eyebrow="ASTROCARTOGRAPHY · ACG/v2" title="Where else." trailing={<IconBtn>⌖</IconBtn>}/>

      {/* Map */}
      <div style={{ padding: '8px 16px 0' }}>
        <div style={{
          background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
          borderRadius: 18, padding: 12, position: 'relative', overflow: 'hidden',
        }}>
          <svg viewBox="0 0 480 300" width="100%" height="auto"
            style={{ display: 'block' }}
          >
            {/* graticule */}
            {Array.from({ length: 9 }).map((_, i) => (
              <line key={'v'+i} x1={i*60} x2={i*60} y1="0" y2="300"
                stroke="var(--hair)" strokeWidth="0.3"/>
            ))}
            {Array.from({ length: 6 }).map((_, i) => (
              <line key={'h'+i} x1="0" x2="480" y1={i*60} y2={i*60}
                stroke="var(--hair)" strokeWidth="0.3"/>
            ))}
            {/* equator */}
            <line x1="0" x2="480" y1="180" y2="180" stroke="var(--fg-4)" strokeWidth="0.5" strokeDasharray="3 4"/>

            {/* continents */}
            <path d={continents} fill="var(--ink-2)" stroke="var(--hair-2)" strokeWidth="0.6"/>

            {/* planetary lines */}
            {lines.map((l, i) => (
              <g key={i}>
                <path d={l.d} fill="none" stroke={l.c} strokeWidth="1.2" strokeDasharray="4 3" opacity="0.85"/>
                <text fontFamily="var(--mono)" fontSize="8" fill={l.c}
                  textAnchor="middle"
                >
                  {/* label placed via dy on a hidden path won't work easily; place text in svg with x/y */}
                </text>
              </g>
            ))}

            {/* labels for lines */}
            <text x="450" y="78" fill="oklch(0.80 0.12 75)" fontFamily="var(--mono)" fontSize="8.5" textAnchor="end">♃ MC</text>
            <text x="365" y="285" fill="oklch(0.78 0.09 295)" fontFamily="var(--mono)" fontSize="8.5" textAnchor="end">♀ AS</text>
            <text x="465" y="218" fill="oklch(0.66 0.10 215)" fontFamily="var(--mono)" fontSize="8.5" textAnchor="end">♄ IC</text>
            <text x="293" y="295" fill="oklch(0.66 0.17 25)" fontFamily="var(--mono)" fontSize="8.5" textAnchor="middle">♂ AS</text>

            {/* city dots */}
            {cities.map(c => {
              const sel = c.name === pick;
              return (
                <g key={c.name} style={{ cursor: 'pointer' }} onClick={() => setPick(c.name)}>
                  {sel && <circle cx={c.x} cy={c.y} r="9" fill="rgba(255,200,120,0.18)"/>}
                  <circle cx={c.x} cy={c.y} r={sel ? 3.5 : 2}
                    fill={sel ? 'var(--gold)' : 'var(--fg)'}
                    stroke={sel ? 'var(--gold)' : 'none'} strokeWidth="0.5"/>
                  <text x={c.x + 6} y={c.y + 3} fontFamily="var(--mono)" fontSize="8"
                    fill={sel ? 'var(--gold)' : 'var(--fg-2)'}>{c.name}</text>
                </g>
              );
            })}
          </svg>
        </div>
      </div>

      {/* Selected city panel */}
      <div style={{ padding: '18px 20px 0' }}>
        <div style={{
          background: 'linear-gradient(180deg, rgba(255,200,120,0.10), transparent)',
          border: '0.5px solid rgba(255,200,120,0.22)',
          borderRadius: 16, padding: 18,
        }}>
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
            <h3 className="serif" style={{ margin: 0, fontSize: 28, letterSpacing: '-0.01em' }}>
              {selected.name}
            </h3>
            <span className="mono" style={{ fontSize: 12, color: 'var(--gold)' }}>
              ASC re-cast → <span className="glyph" style={{ fontSize: 18 }}>{selected.asc}</span>
            </span>
          </div>
          <div style={{ fontSize: 13.5, color: 'var(--fg-2)', marginTop: 8, lineHeight: 1.55 }}>
            {selected.desc}. New ascendant runs Jupiter as 1L — what's already your
            strength gets the room to scale.
          </div>

          <div style={{
            marginTop: 14, display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10,
            fontFamily: 'var(--mono)', fontSize: 11,
          }}>
            <div>
              <div style={{ color: 'var(--fg-3)', fontSize: 9, letterSpacing: '0.16em' }}>ΔASC</div>
              <div style={{ color: 'var(--gold)' }}>+ Jupiter</div>
            </div>
            <div>
              <div style={{ color: 'var(--fg-3)', fontSize: 9, letterSpacing: '0.16em' }}>ΔMC</div>
              <div style={{ color: 'var(--good)' }}>+ public</div>
            </div>
            <div>
              <div style={{ color: 'var(--fg-3)', fontSize: 9, letterSpacing: '0.16em' }}>BLEMISH</div>
              <div style={{ color: 'var(--bad)' }}>excess heat</div>
            </div>
          </div>
        </div>
      </div>

      {/* Comparison row */}
      <div style={{ padding: '18px 20px 0' }}>
        <div className="mono" style={{
          fontSize: 10, letterSpacing: '0.22em', color: 'var(--fg-3)', marginBottom: 10,
        }}>RANKED CANDIDATES</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {[
            { c: 'Dubai',     s: 0.91, n: 'Jupiter MC ▸ +28%' },
            { c: 'Singapore', s: 0.82, n: 'Saturn 10th ▸ +18%' },
            { c: 'Bengaluru', s: 0.74, n: 'baseline · home' },
            { c: 'London',    s: 0.51, n: 'Sun 9th ▸ –22% peace' },
            { c: 'New York',  s: 0.46, n: 'Moon 4th ▸ soft' },
            { c: 'Tokyo',     s: 0.42, n: 'Saturn 1st ▸ heavy' },
          ].map((r, i) => (
            <div key={i} style={{
              background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
              borderRadius: 10, padding: '9px 12px',
              display: 'grid', gridTemplateColumns: '20px 1fr 1fr 60px',
              alignItems: 'center', gap: 10,
              fontFamily: 'var(--mono)', fontSize: 11,
            }}>
              <span style={{ color: 'var(--fg-3)' }}>{String(i+1).padStart(2,'0')}</span>
              <span style={{ color: 'var(--fg)' }}>{r.c}</span>
              <span style={{ color: 'var(--fg-2)', fontSize: 10 }}>{r.n}</span>
              <span style={{
                textAlign: 'right',
                color: r.s > 0.7 ? 'var(--good)' : r.s > 0.5 ? 'var(--warn)' : 'var(--bad)',
              }}>{r.s.toFixed(2)}</span>
            </div>
          ))}
        </div>
      </div>

      <TabBar active="map" />
    </div>
  );
}

// ────────────────────────────────────────────────────────────
// 11 — Dasha Transition (current vs next)
// ────────────────────────────────────────────────────────────
function TransitionScreen() {
  const cur  = { p: 'Jupiter', g: '♃', sign: 'Sa', dur: '16y',  remaining: '04 Oct 26', c: 'var(--gold)',
                 traits: ['Capital flow', 'Public clarity', 'Optimism risk'],
                 score: 0.82 };
  const nxt  = { p: 'Saturn',  g: '♄', sign: 'Pi', dur: '19y',  starts: '04 Oct 26', c: 'var(--cool)',
                 traits: ['Discipline', 'Slow compounding', 'Isolation risk'],
                 score: 0.61 };
  const delta = (nxt.score - cur.score);

  return (
    <div className="astro-screen" style={{ paddingBottom: 90 }}>
      <TopBar eyebrow="MAHA-DASHA · CURRENT ▸ NEXT" title="The shift" trailing={<IconBtn>≡</IconBtn>}/>

      {/* Side-by-side */}
      <div style={{ padding: '8px 20px 0', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        {[cur, nxt].map((d, i) => (
          <div key={i} style={{
            background: i === 0 ? 'rgba(255,200,120,0.08)' : 'rgba(120,180,255,0.06)',
            border: '0.5px solid ' + (i === 0 ? 'rgba(255,200,120,0.22)' : 'rgba(120,180,255,0.18)'),
            borderRadius: 18, padding: 14, minHeight: 200,
          }}>
            <div className="mono" style={{ fontSize: 9, letterSpacing: '0.22em', color: d.c }}>
              {i === 0 ? 'NOW' : 'NEXT'}
            </div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 6 }}>
              <span className="glyph" style={{ fontSize: 44, color: d.c, lineHeight: 1 }}>{d.g}</span>
              <div>
                <div className="serif" style={{ fontSize: 22, color: 'var(--fg)' }}>{d.p}</div>
                <div className="mono" style={{ fontSize: 10, color: 'var(--fg-3)' }}>{d.dur}</div>
              </div>
            </div>
            <div className="mono" style={{ fontSize: 10, color: 'var(--fg-2)', marginTop: 10 }}>
              {i === 0 ? `→ ${cur.remaining}` : `↗ ${nxt.starts}`}
            </div>
            <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 4 }}>
              {d.traits.map((t, j) => (
                <div key={j} style={{
                  fontSize: 11.5, color: 'var(--fg)',
                  display: 'flex', alignItems: 'center', gap: 6,
                }}>
                  <span className="dot" style={{ background: d.c, width: 5, height: 5 }}/>
                  {t}
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>

      {/* Delta strip */}
      <div style={{ padding: '20px 20px 0' }}>
        <div className="mono" style={{
          fontSize: 10, letterSpacing: '0.22em', color: 'var(--fg-3)', marginBottom: 10,
        }}>DELTA</div>
        <div style={{
          background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
          borderRadius: 14, padding: 16,
        }}>
          {[
            { k: 'STRENGTH',    a: '0.82', b: '0.61', d: '−0.21', dc: 'var(--bad)' },
            { k: 'TEMPO',       a: 'fast', b: 'slow', d: '−2 gears',  dc: 'var(--warn)' },
            { k: 'CAPITAL',     a: 'flow', b: 'discipline', d: 'reframe',  dc: 'var(--cool)' },
            { k: 'PUBLIC',      a: 'lit',  b: 'muted', d: '−0.34', dc: 'var(--bad)' },
            { k: 'COMPOUNDING', a: 'low',  b: 'high', d: '+0.40',  dc: 'var(--good)' },
            { k: 'HEALTH RISK', a: 'low',  b: 'med',  d: '+joints', dc: 'var(--warn)' },
          ].map((r, i, arr) => (
            <div key={i} style={{
              display: 'grid', gridTemplateColumns: '110px 1fr 1fr 90px',
              padding: '10px 0', borderBottom: i < arr.length - 1 ? '0.5px solid var(--hair)' : 'none',
              fontFamily: 'var(--mono)', fontSize: 11, alignItems: 'center',
            }}>
              <span style={{ color: 'var(--fg-3)', letterSpacing: '0.1em' }}>{r.k}</span>
              <span style={{ color: 'var(--gold)' }}>{r.a}</span>
              <span style={{ color: 'var(--cool)' }}>{r.b}</span>
              <span style={{ color: r.dc, textAlign: 'right' }}>{r.d}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Strategy CTA */}
      <div style={{ padding: '20px 20px 0' }}>
        <div style={{
          background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
          borderRadius: 14, padding: 18,
        }}>
          <div className="mono" style={{ fontSize: 10, letterSpacing: '0.18em', color: 'var(--gold)' }}>
            MIGRATION CHECKLIST · 134 DAYS
          </div>
          <div className="serif" style={{ fontSize: 20, marginTop: 8, lineHeight: 1.25 }}>
            Frontload everything Jupiter-shaped.
          </div>
          <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 8 }}>
            {[
              'Close one capital round before 04 Oct',
              'Publish hero piece while public is still lit',
              'Lock long contracts at this strength',
              'Pre-book travel for Q4 — Saturn rewards prepared',
            ].map((t, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: 13, color: 'var(--fg)' }}>
                <span style={{
                  width: 16, height: 16, borderRadius: 4,
                  border: '0.5px solid var(--gold)', display: 'inline-flex',
                  alignItems: 'center', justifyContent: 'center',
                  fontSize: 10, color: 'var(--gold)',
                }}>{i+1}</span>
                {t}
              </div>
            ))}
          </div>
        </div>
      </div>

      <TabBar active="time" />
    </div>
  );
}

// ────────────────────────────────────────────────────────────
// 12 — Free-will Bayesian slider
// ────────────────────────────────────────────────────────────
function FreeWillScreen() {
  const [fw, setFw] = useState(0.55);
  // posterior shifts as a function of free will weight
  const eventP = (basePrior, likelihood) => {
    // toy Bayesian blend: posterior = (1-fw)*prior + fw*likelihood-adjusted
    return Math.min(0.97, Math.max(0.05, basePrior * (1 - fw) + likelihood * fw));
  };
  const events = [
    { t: 'Capital round closes',      prior: 0.62, lk: 0.85, c: 'var(--good)' },
    { t: 'Dubai base goes live',      prior: 0.71, lk: 0.88, c: 'var(--gold)' },
    { t: 'Public output peaks',       prior: 0.55, lk: 0.78, c: 'var(--warn)' },
    { t: 'Saturn-shaped slow month',  prior: 0.70, lk: 0.40, c: 'var(--cool)' },
    { t: 'Joint / posture injury',    prior: 0.30, lk: 0.10, c: 'var(--bad)' },
  ];

  return (
    <div className="astro-screen" style={{ paddingBottom: 90 }}>
      <TopBar eyebrow="MODEL · BAYESIAN BLEND" title="How fated is this?" trailing={<IconBtn>?</IconBtn>}/>

      <div style={{ padding: '8px 20px 0' }}>
        <p style={{ color: 'var(--fg-2)', fontSize: 14, lineHeight: 1.55 }}>
          The chart gives <span style={{ color: 'var(--gold)' }}>priors</span>. Your
          actions give <span style={{ color: 'var(--cool)' }}>likelihoods</span>. The
          slider mixes them — you decide where to weigh the model.
        </p>
      </div>

      {/* Slider */}
      <div style={{ padding: '20px 20px 0' }}>
        <div style={{
          background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
          borderRadius: 18, padding: 18,
        }}>
          <div style={{
            display: 'flex', justifyContent: 'space-between',
            fontFamily: 'var(--mono)', fontSize: 10, color: 'var(--fg-3)',
            letterSpacing: '0.18em', marginBottom: 12,
          }}>
            <span>← PRIOR / FATED</span>
            <span>FREE WILL →</span>
          </div>

          {/* the slider track */}
          <div style={{ position: 'relative', height: 36 }}>
            <div style={{
              position: 'absolute', left: 0, right: 0, top: 16, height: 4,
              background: 'linear-gradient(90deg, var(--gold), var(--cool))',
              borderRadius: 4,
            }}/>
            <input type="range" min="0" max="100" value={fw * 100}
              onChange={e => setFw(parseInt(e.target.value, 10) / 100)}
              style={{
                position: 'absolute', inset: 0, width: '100%', opacity: 0, cursor: 'pointer', margin: 0,
              }}
            />
            <div style={{
              position: 'absolute', left: `calc(${fw * 100}% - 14px)`, top: 4,
              width: 28, height: 28, borderRadius: 999, background: 'var(--fg)',
              border: '3px solid var(--ink-1)',
              boxShadow: '0 4px 16px rgba(255,200,120,0.35), 0 0 0 1px var(--hair-2)',
              pointerEvents: 'none',
            }}/>
          </div>

          <div style={{
            marginTop: 8, display: 'flex', justifyContent: 'space-between',
            fontFamily: 'var(--mono)', fontSize: 12,
          }}>
            <span style={{ color: 'var(--gold)' }}>prior  {(1 - fw).toFixed(2)}</span>
            <span className="serif" style={{ fontSize: 18 }}>w = {fw.toFixed(2)}</span>
            <span style={{ color: 'var(--cool)' }}>{fw.toFixed(2)}  agency</span>
          </div>
        </div>
      </div>

      {/* posterior cards */}
      <div style={{ padding: '20px 20px 0' }}>
        <div className="mono" style={{
          fontSize: 10, letterSpacing: '0.22em', color: 'var(--fg-3)', marginBottom: 10,
          display: 'flex', justifyContent: 'space-between',
        }}>
          <span>POSTERIOR · 12-MONTH HORIZON</span>
          <span style={{ color: 'var(--gold)' }}>P = wL + (1−w)π</span>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {events.map((e, i) => {
            const p = eventP(e.prior, e.lk);
            return (
              <div key={i} style={{
                background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
                borderRadius: 12, padding: '12px 14px',
              }}>
                <div style={{
                  display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
                }}>
                  <div style={{ fontSize: 14 }}>{e.t}</div>
                  <div className="mono" style={{ fontSize: 13, color: e.c }}>{p.toFixed(2)}</div>
                </div>
                <div style={{
                  marginTop: 8, height: 6, background: 'var(--ink-2)', borderRadius: 4,
                  position: 'relative', overflow: 'hidden',
                }}>
                  {/* prior marker */}
                  <div style={{
                    position: 'absolute', left: `${e.prior * 100}%`, top: -2, bottom: -2,
                    width: 2, background: 'var(--gold)', opacity: 0.5,
                  }}/>
                  {/* likelihood marker */}
                  <div style={{
                    position: 'absolute', left: `${e.lk * 100}%`, top: -2, bottom: -2,
                    width: 2, background: 'var(--cool)', opacity: 0.5,
                  }}/>
                  {/* posterior fill */}
                  <div style={{
                    width: `${p * 100}%`, height: '100%', background: e.c,
                    transition: 'width 200ms ease',
                  }}/>
                </div>
                <div className="mono" style={{
                  marginTop: 6, fontSize: 9.5, color: 'var(--fg-3)',
                  display: 'flex', justifyContent: 'space-between',
                }}>
                  <span>π {e.prior.toFixed(2)}</span>
                  <span>L {e.lk.toFixed(2)}</span>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      <TabBar active="home" />
    </div>
  );
}

Object.assign(window, { MapScreen, TransitionScreen, FreeWillScreen });
