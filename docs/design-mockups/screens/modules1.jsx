// Astronova — Analysis modules (System, Loshu, Timeline)

// ────────────────────────────────────────────────────────────
// 07 — System Overview (server-room metaphor)
// ────────────────────────────────────────────────────────────
function SystemScreen() {
  return (
    <div className="astro-screen" style={{ position: 'relative', paddingBottom: 90 }}>
      <TopBar
        eyebrow="ARJUN · CHART/PROD"
        title="System overview"
        trailing={<><IconBtn>⟳</IconBtn><IconBtn>?</IconBtn></>}
      />

      {/* Hero metaphor strip */}
      <div style={{ padding: '14px 20px 0' }}>
        <div className="serif" style={{
          fontSize: 28, lineHeight: 1.1, letterSpacing: '-0.01em',
        }}>
          12 server rooms.<br/>
          <span style={{ fontStyle: 'italic', color: 'var(--gold)' }}>9 daemons.</span>
          <span style={{ color: 'var(--fg-3)' }}> 1 you.</span>
        </div>
        <div style={{ fontSize: 13, color: 'var(--fg-2)', marginTop: 8, lineHeight: 1.55 }}>
          Each house is a domain. Each planet is a long-running process. Some are tuned,
          some are leaking memory — here's the runlist.
        </div>
      </div>

      {/* uptime row */}
      <div style={{ padding: '20px 20px 0' }}>
        <div style={{
          background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
          borderRadius: 14, padding: 14,
          display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10,
        }}>
          {[
            { k: 'OVERALL', v: '0.82', sub: '+0.07 / 30d', c: 'var(--good)' },
            { k: 'INCIDENTS', v: '02',   sub: 'last: 14 Apr', c: 'var(--warn)' },
            { k: 'NEXT DEPLOY', v: '04 Oct', sub: 'Sat ▸ Mer', c: 'var(--cool)' },
          ].map((m, i) => (
            <div key={i}>
              <div className="mono" style={{ fontSize: 9, color: 'var(--fg-3)', letterSpacing: '0.15em' }}>{m.k}</div>
              <div className="serif" style={{ fontSize: 22, color: m.c, marginTop: 2 }}>{m.v}</div>
              <div className="mono" style={{ fontSize: 9.5, color: 'var(--fg-3)' }}>{m.sub}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Process table */}
      <div style={{ padding: '22px 20px 0' }}>
        <div className="mono" style={{
          fontSize: 10, letterSpacing: '0.22em', color: 'var(--fg-3)', marginBottom: 10,
          display: 'flex', justifyContent: 'space-between',
        }}>
          <span>$ ps aux | sort -strength</span>
          <span>9 / 9 RUNNING</span>
        </div>
        <div style={{
          background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
          borderRadius: 14, overflow: 'hidden', fontFamily: 'var(--mono)',
        }}>
          {/* header */}
          <div style={{
            display: 'grid', gridTemplateColumns: '34px 1fr 50px 56px 44px',
            gap: 8, padding: '9px 14px',
            fontSize: 9, color: 'var(--fg-3)', letterSpacing: '0.12em',
            borderBottom: '0.5px solid var(--hair)', background: 'var(--ink-2)',
          }}>
            <span>PID</span><span>PROCESS</span><span>ROOM</span><span>STATUS</span><span style={{ textAlign: 'right' }}>%CPU</span>
          </div>
          {PLANETS.map((p, i) => {
            const meta = STATUS_META[p.status];
            return (
              <div key={p.p} style={{
                display: 'grid', gridTemplateColumns: '34px 1fr 50px 56px 44px',
                gap: 8, padding: '10px 14px', fontSize: 11,
                borderBottom: i < PLANETS.length - 1 ? '0.5px solid var(--hair)' : 'none',
                alignItems: 'center',
              }}>
                <span style={{ color: 'var(--fg-3)' }}>{p.pid}</span>
                <span style={{ color: 'var(--fg)' }}>
                  <span style={{ color: meta.color, marginRight: 6 }}>{PLANET_GLYPH[p.p]}</span>
                  {p.p.toLowerCase()}d
                </span>
                <span style={{ color: 'var(--fg-2)' }}>H{String(p.house).padStart(2,'0')}</span>
                <span style={{ color: meta.color, letterSpacing: '0.08em' }}>{meta.code}</span>
                <span style={{ color: 'var(--fg-2)', textAlign: 'right' }}>
                  {(p.strength * 100).toFixed(0)}
                </span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Rajayoga audit (blemish flags) */}
      <div style={{ padding: '22px 20px 0' }}>
        <div className="mono" style={{
          fontSize: 10, letterSpacing: '0.22em', color: 'var(--fg-3)', marginBottom: 10,
          display: 'flex', justifyContent: 'space-between',
        }}>
          <span>RAJAYOGA AUDIT</span>
          <span style={{ color: 'var(--violet)' }}>3 YOGA · 2 BLEMISH</span>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {[
            { t: 'Gajakesari', d: 'Jupiter+Moon kendra · clean root', s: 'YOGA', c: 'var(--good)' },
            { t: 'Dhana',      d: '2-11 lord exchange · capital flows', s: 'YOGA', c: 'var(--good)' },
            { t: 'Budha-Aditya', d: '☉+☿ co-located · public clarity', s: 'YOGA', c: 'var(--good)' },
            { t: 'Sambandha break', d: 'Venus debilitated cancels luxury Yoga', s: 'FLAG', c: 'var(--bad)' },
            { t: 'Kemadruma residue', d: 'Moon isolated by sign · isolation risk', s: 'FLAG', c: 'var(--warn)' },
          ].map((r, i) => (
            <div key={i} style={{
              background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
              borderRadius: 12, padding: '12px 14px',
              display: 'flex', gap: 12, alignItems: 'center',
            }}>
              <span className="dot" style={{ background: r.c, width: 10, height: 10 }}/>
              <div style={{ flex: 1 }}>
                <div className="serif" style={{ fontSize: 15, color: 'var(--fg)' }}>{r.t}</div>
                <div className="mono" style={{ fontSize: 10.5, color: 'var(--fg-3)', marginTop: 2 }}>{r.d}</div>
              </div>
              <span className="mono" style={{
                fontSize: 9, color: r.c, letterSpacing: '0.08em',
                border: '0.5px solid ' + r.c, padding: '2px 6px', borderRadius: 4,
              }}>{r.s}</span>
            </div>
          ))}
        </div>
      </div>

      <div style={{ padding: '22px 20px 10px' }}>
        <button className="btn-ghost" style={{ width: '100%' }}>Open full audit log</button>
      </div>

      <TabBar active="sys" />
    </div>
  );
}

// ────────────────────────────────────────────────────────────
// 08 — Loshu Grid (numerology)
// ────────────────────────────────────────────────────────────
function LoshuScreen() {
  // counts derived from D.O.B. 14-03-1994 + phone 9845127736
  // Numbers 1-9: count of occurrences
  const counts = { 1:2, 2:1, 3:1, 4:2, 5:1, 6:1, 7:2, 8:0, 9:2 };
  const layout = [4,9,2,3,5,7,8,1,6];

  return (
    <div className="astro-screen" style={{ paddingBottom: 90 }}>
      <TopBar eyebrow="NUMEROLOGY · LOSHU 3×3" title="Number lattice" trailing={<IconBtn>ⓘ</IconBtn>} />

      <div style={{ padding: '8px 20px 0' }}>
        <div style={{ fontSize: 13, color: 'var(--fg-2)', lineHeight: 1.5 }}>
          Eigen-decomposition of <span style={{ color: 'var(--gold)' }}>14·03·1994</span> +
          phone digits. Surplus axes amplify; missing axes are where you compensate.
        </div>
      </div>

      {/* Grid */}
      <div style={{ padding: '24px 20px 0' }}>
        <div style={{
          background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
          borderRadius: 18, padding: 14,
        }}>
          <div style={{
            display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)',
            gap: 8, position: 'relative',
          }}>
            {layout.map(n => {
              const c = counts[n];
              const labels = {
                1:'self', 2:'sense', 3:'logic', 4:'order', 5:'will',
                6:'love', 7:'spirit', 8:'duty', 9:'force',
              };
              const tone = c === 0
                ? { bg:'rgba(180,40,30,0.10)', br:'rgba(220,90,70,0.35)', fg:'var(--bad)', dim: 'var(--bad)' }
                : c >= 2
                ? { bg:'rgba(255,200,120,0.10)', br:'rgba(255,200,120,0.30)', fg:'var(--gold)', dim: 'var(--gold)' }
                : { bg:'var(--ink-2)', br:'var(--hair)', fg:'var(--fg)', dim: 'var(--fg-3)' };
              return (
                <div key={n} style={{
                  aspectRatio: '1/1', borderRadius: 12,
                  background: tone.bg, border: '0.5px solid ' + tone.br,
                  position: 'relative', padding: 10,
                  display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
                }}>
                  <div className="mono" style={{ fontSize: 9, color: tone.dim, letterSpacing: '0.14em' }}>
                    {c === 0 ? 'MISSING' : c >= 2 ? `×${c} SURPLUS` : '×1'}
                  </div>
                  <div style={{ textAlign: 'center', flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <span className="serif" style={{ fontSize: 42, color: tone.fg, lineHeight: 1 }}>
                      {c === 0 ? '·' : n}
                    </span>
                  </div>
                  <div className="mono" style={{
                    fontSize: 9, color: 'var(--fg-3)', textAlign: 'right',
                    textTransform: 'uppercase', letterSpacing: '0.1em',
                  }}>{labels[n]}</div>
                </div>
              );
            })}
          </div>

          {/* Plane summary lines (overlaid axes) */}
          <div style={{
            marginTop: 12, paddingTop: 12, borderTop: '0.5px solid var(--hair)',
            display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8,
            fontFamily: 'var(--mono)', fontSize: 10,
          }}>
            <div>
              <div style={{ color: 'var(--fg-3)', letterSpacing: '0.14em' }}>MIND PLANE</div>
              <div style={{ color: 'var(--gold)', marginTop: 2 }}>4·9·2 → strong</div>
            </div>
            <div>
              <div style={{ color: 'var(--fg-3)', letterSpacing: '0.14em' }}>SOUL PLANE</div>
              <div style={{ color: 'var(--fg)', marginTop: 2 }}>3·5·7 → balanced</div>
            </div>
            <div>
              <div style={{ color: 'var(--fg-3)', letterSpacing: '0.14em' }}>BODY PLANE</div>
              <div style={{ color: 'var(--bad)', marginTop: 2 }}>8·1·6 → broken</div>
            </div>
          </div>
        </div>
      </div>

      {/* Read-out */}
      <div style={{ padding: '20px 20px 0' }}>
        <div className="mono" style={{
          fontSize: 10, letterSpacing: '0.22em', color: 'var(--fg-3)', marginBottom: 10,
        }}>EIGEN-READ</div>
        <div style={{
          background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
          borderRadius: 14, padding: 16,
        }}>
          <div style={{ fontSize: 14, color: 'var(--fg)', lineHeight: 1.55 }}>
            <span className="serif" style={{ fontSize: 18, color: 'var(--gold)' }}>Missing 8</span> — practical follow-through
            is your <span style={{ color: 'var(--bad)' }}>compensation axis</span>. Without an operator-grade #2 next
            to you, infra projects stall after week 6.
          </div>
        </div>
      </div>

      {/* Vector inputs */}
      <div style={{ padding: '20px 20px 0' }}>
        <div className="mono" style={{
          fontSize: 10, letterSpacing: '0.22em', color: 'var(--fg-3)', marginBottom: 10,
        }}>INPUT VECTORS</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {[
            { k: 'DATE', v: '1·4·0·3·1·9·9·4', d: '8 digits' },
            { k: 'PHONE', v: '9·8·4·5·1·2·7·7·3·6', d: '10 digits' },
            { k: 'NAME N', v: 'A·R·J·U·N → 1·9·1·6·5 = 22 ▸ 4', d: 'Chaldean' },
          ].map((v, i) => (
            <div key={i} style={{
              background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
              borderRadius: 10, padding: '10px 14px',
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              fontFamily: 'var(--mono)', fontSize: 11,
            }}>
              <span style={{ color: 'var(--fg-3)', letterSpacing: '0.12em' }}>{v.k}</span>
              <span style={{ color: 'var(--fg)' }}>{v.v}</span>
              <span style={{ color: 'var(--fg-3)' }}>{v.d}</span>
            </div>
          ))}
        </div>
      </div>

      <TabBar active="sys" />
    </div>
  );
}

// ────────────────────────────────────────────────────────────
// 09 — Month-by-month Timeline
// ────────────────────────────────────────────────────────────
function TimelineScreen() {
  const [scrub, setScrub] = useState(4); // current month index in visible window

  const months = [
    { m: 'MAR 26', dasha: 'Ju/Ve', cash: 0.4, events: [] },
    { m: 'APR 26', dasha: 'Ju/Ve', cash: 0.6, events: [{ t: 'Saturn ingress · Pisces', c: 'var(--cool)' }] },
    { m: 'MAY 26', dasha: 'Ju/Ve', cash: 0.5, events: [{ t: 'Inbound · capital', c: 'var(--gold)' }] },
    { m: 'JUN 26', dasha: 'Ju/Ve', cash: 0.85, events: [{ t: 'Deploy Dubai base', c: 'var(--good)' }] },
    { m: 'JUL 26', dasha: 'Ju/Su', cash: 0.92, events: [{ t: 'Sub-dasha shift ▸ Sun', c: 'var(--gold)' }, { t: 'Public output peak', c: 'var(--good)' }] },
    { m: 'AUG 26', dasha: 'Ju/Su', cash: 0.78, events: [] },
    { m: 'SEP 26', dasha: 'Ju/Mo', cash: 0.55, events: [{ t: 'Mars retrograde · stall', c: 'var(--warn)' }] },
    { m: 'OCT 26', dasha: 'Sa/Sa', cash: 0.30, events: [{ t: 'MAHA-DASHA SHIFT ▸ Saturn', c: 'var(--bad)' }, { t: 'Singapore entity', c: 'var(--cool)' }] },
    { m: 'NOV 26', dasha: 'Sa/Sa', cash: 0.25, events: [] },
    { m: 'DEC 26', dasha: 'Sa/Sa', cash: 0.45, events: [{ t: 'Slow-burn restructure', c: 'var(--cool)' }] },
    { m: 'JAN 27', dasha: 'Sa/Sa', cash: 0.50, events: [] },
    { m: 'FEB 27', dasha: 'Sa/Sa', cash: 0.62, events: [{ t: 'Jupiter aspects 10th', c: 'var(--good)' }] },
  ];
  const cur = months[scrub];

  return (
    <div className="astro-screen" style={{ paddingBottom: 90 }}>
      <TopBar eyebrow="MAR 2026 · FEB 2027" title="Timeline" trailing={<IconBtn>⇆</IconBtn>}/>

      {/* Cash curve */}
      <div style={{ padding: '8px 20px 0' }}>
        <div className="mono" style={{
          fontSize: 10, letterSpacing: '0.22em', color: 'var(--fg-3)', marginBottom: 6,
          display: 'flex', justifyContent: 'space-between',
        }}>
          <span>CASH FLOW · MONTH-BY-MONTH</span>
          <span style={{ color: 'var(--gold)' }}>P = priors × dasha</span>
        </div>
        <div style={{
          background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
          borderRadius: 14, padding: '16px 8px 6px', position: 'relative',
        }}>
          <svg viewBox="0 0 360 110" width="100%" height="120">
            {/* gridlines */}
            {[0, 0.5, 1].map((v, i) => (
              <line key={i} x1="0" x2="360" y1={100 - v*90} y2={100 - v*90}
                stroke="var(--hair)" strokeWidth="0.4" strokeDasharray="2 3"/>
            ))}
            {/* polyline */}
            <polyline
              fill="none" stroke="var(--gold)" strokeWidth="1.5"
              points={months.map((mm, i) => `${(i/(months.length-1))*350+5},${100 - mm.cash*90}`).join(' ')}
            />
            {/* area fill */}
            <polygon
              fill="rgba(255,200,120,0.10)"
              points={`5,100 ${months.map((mm, i) => `${(i/(months.length-1))*350+5},${100 - mm.cash*90}`).join(' ')} 355,100`}
            />
            {/* dots */}
            {months.map((mm, i) => {
              const x = (i/(months.length-1))*350+5;
              const y = 100 - mm.cash*90;
              const sel = i === scrub;
              return (
                <g key={i} onClick={() => setScrub(i)} style={{ cursor: 'pointer' }}>
                  <circle cx={x} cy={y} r={sel ? 5 : 2.5} fill={sel ? 'var(--gold)' : 'var(--fg-2)'}/>
                  {sel && <line x1={x} x2={x} y1="0" y2="100" stroke="var(--gold)" strokeWidth="0.6" strokeDasharray="2 2"/>}
                </g>
              );
            })}
          </svg>
          <div style={{
            display: 'grid', gridTemplateColumns: `repeat(${months.length}, 1fr)`, gap: 0,
            fontFamily: 'var(--mono)', fontSize: 8.5, color: 'var(--fg-3)',
            letterSpacing: '0.06em', padding: '0 5px',
          }}>
            {months.map((mm, i) => (
              <div key={i} style={{ textAlign: 'center', color: i === scrub ? 'var(--gold)' : 'var(--fg-3)' }}>
                {mm.m.split(' ')[0]}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Scrubbed month detail */}
      <div style={{ padding: '18px 20px 0' }}>
        <div style={{
          display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
        }}>
          <h2 className="serif" style={{ margin: 0, fontSize: 32, letterSpacing: '-0.01em' }}>{cur.m}</h2>
          <div className="mono" style={{ fontSize: 12, color: 'var(--gold)' }}>
            {cur.dasha} · cash p={cur.cash.toFixed(2)}
          </div>
        </div>
        <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 8 }}>
          {cur.events.length === 0 && (
            <div style={{
              background: 'var(--ink-1)', border: '0.5px dashed var(--hair-2)',
              borderRadius: 12, padding: 14, textAlign: 'center',
              color: 'var(--fg-3)', fontSize: 12.5, fontStyle: 'italic',
            }}>quiet month · model predicts continuity</div>
          )}
          {cur.events.map((e, i) => (
            <div key={i} style={{
              background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
              borderRadius: 12, padding: '12px 14px',
              display: 'flex', gap: 12, alignItems: 'center',
            }}>
              <span className="dot" style={{ background: e.c, width: 10, height: 10 }}/>
              <div style={{ flex: 1, fontSize: 14 }}>{e.t}</div>
              <span className="mono" style={{ fontSize: 10, color: 'var(--fg-3)' }}>→</span>
            </div>
          ))}
        </div>
      </div>

      {/* dasha bar (visualizes maha → antar → pratyantar layers) */}
      <div style={{ padding: '22px 20px 0' }}>
        <div className="mono" style={{
          fontSize: 10, letterSpacing: '0.22em', color: 'var(--fg-3)', marginBottom: 10,
        }}>DASHA STACK</div>
        <div style={{
          background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
          borderRadius: 14, padding: '14px 16px',
        }}>
          {[
            { lvl: 'MAHA',  bar: ['Jupiter', 'Saturn'],   pct: 0.68, c: 'var(--gold)', txt: 'Jupiter 16y' },
            { lvl: 'ANTAR', bar: ['Ve', 'Su', 'Mo'],      pct: 0.40, c: 'var(--cool)', txt: 'Venus 2.4y' },
            { lvl: 'PRATY', bar: ['Mo','Ma','Ra','Ju','Sa'], pct: 0.55, c: 'var(--warn)', txt: 'Mars 49d' },
          ].map((d, i) => (
            <div key={i} style={{ marginBottom: i < 2 ? 12 : 0 }}>
              <div style={{
                display: 'flex', justifyContent: 'space-between',
                fontFamily: 'var(--mono)', fontSize: 10, color: 'var(--fg-3)',
                letterSpacing: '0.14em', marginBottom: 4,
              }}>
                <span>{d.lvl}</span><span>{d.txt}</span>
              </div>
              <div style={{
                height: 14, borderRadius: 4, background: 'var(--ink-2)',
                display: 'flex', overflow: 'hidden',
              }}>
                {d.bar.map((seg, j) => {
                  const w = 100 / d.bar.length;
                  const isHere = (i === 0 && j === 0) || (i === 1 && j === 0) || (i === 2 && j === 1);
                  return (
                    <div key={j} style={{
                      width: w + '%',
                      background: isHere ? d.c : 'transparent',
                      borderRight: j < d.bar.length - 1 ? '0.5px solid var(--hair-2)' : 'none',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      fontFamily: 'var(--mono)', fontSize: 9,
                      color: isHere ? 'var(--ink-0)' : 'var(--fg-3)',
                    }}>{seg}</div>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      </div>

      <TabBar active="time" />
    </div>
  );
}

Object.assign(window, { SystemScreen, LoshuScreen, TimelineScreen });
