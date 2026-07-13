// Astronova — Dashboard + Chart
// 05 Home (today), 06 Chart wheel (rotatable)

// ────────────────────────────────────────────────────────────
// 05 — Dashboard / Today
// ────────────────────────────────────────────────────────────
function DashboardScreen() {
  return (
    <div className="astro-screen" style={{ position: 'relative', paddingBottom: 90 }}>
      {/* Top */}
      <div style={{
        paddingTop: 58, padding: '58px 20px 0', display: 'flex',
        justifyContent: 'space-between', alignItems: 'center',
      }}>
        <div>
          <div className="mono" style={{
            fontSize: 10, letterSpacing: '0.22em', color: 'var(--fg-3)',
          }}>SAT · 23 MAY 2026</div>
          <div className="serif" style={{ fontSize: 24, marginTop: 2 }}>Good evening, Arjun.</div>
        </div>
        <div style={{
          width: 38, height: 38, borderRadius: 999, overflow: 'hidden',
          background: 'linear-gradient(135deg, var(--gold), var(--bad))',
          border: '0.5px solid var(--hair-2)',
        }}/>
      </div>

      {/* Persona card */}
      <div style={{ padding: '22px 20px 0' }}>
        <div style={{
          position: 'relative', overflow: 'hidden',
          background: 'linear-gradient(180deg, rgba(255,200,120,0.10), rgba(255,200,120,0.02))',
          border: '0.5px solid var(--hair-2)', borderRadius: 22, padding: 20,
        }}>
          <div className="mono" style={{
            fontSize: 10, letterSpacing: '0.22em', color: 'var(--gold)',
          }}>ARCHETYPE · SYNTHESIS v3</div>
          <div className="serif" style={{
            fontSize: 32, lineHeight: 1.05, marginTop: 8, letterSpacing: '-0.01em',
          }}>
            Sovereign-Creator<br/>
            <span style={{ fontStyle: 'italic', color: 'var(--gold)' }}>+ Capital Engine</span>
          </div>
          <div style={{ marginTop: 14, fontSize: 13, color: 'var(--fg-2)', lineHeight: 1.5 }}>
            Exalted Mars in the 3rd, Jupiter steering money. You build things and people pay for them — that's the whole strategy.
          </div>
          <div style={{ display: 'flex', gap: 8, marginTop: 16, flexWrap: 'wrap' }}>
            {['☉ Leo', '☽ Taurus', 'Asc ♏ Scorpio'].map((s, i) => (
              <span key={i} className="mono" style={{
                fontSize: 11, color: 'var(--fg-2)',
                background: 'var(--ink-2)', border: '0.5px solid var(--hair)',
                padding: '5px 10px', borderRadius: 999,
              }}>{s}</span>
            ))}
          </div>
        </div>
      </div>

      {/* System status pill row */}
      <div style={{ padding: '20px 20px 0' }}>
        <div className="mono" style={{
          fontSize: 10, letterSpacing: '0.22em', color: 'var(--fg-3)', marginBottom: 10,
        }}>SYSTEM STATUS · LIVE</div>
        <div style={{
          background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
          borderRadius: 16, padding: '12px 14px',
          display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10,
        }}>
          <div>
            <div className="mono" style={{ fontSize: 9, color: 'var(--fg-3)', letterSpacing: '0.16em' }}>
              CURRENT DASHA
            </div>
            <div style={{ marginTop: 4, fontSize: 14 }}>
              <span className="glyph" style={{ fontSize: 18, color: 'var(--gold)' }}>♃</span>
              <span className="serif" style={{ marginLeft: 8 }}>Jupiter / Venus</span>
            </div>
            <div className="mono" style={{ fontSize: 10, color: 'var(--fg-3)', marginTop: 2 }}>
              ends 04 Oct 2026 · 134d
            </div>
          </div>
          <div>
            <div className="mono" style={{ fontSize: 9, color: 'var(--fg-3)', letterSpacing: '0.16em' }}>
              UPTIME / STRENGTH
            </div>
            <div style={{ marginTop: 4, fontSize: 14, display: 'flex', alignItems: 'center', gap: 6 }}>
              <span className="dot dot-good live-pulse"/>
              <span className="serif">0.82</span>
              <span className="mono" style={{ fontSize: 10, color: 'var(--good)' }}>+0.07</span>
            </div>
            <div className="mono" style={{ fontSize: 10, color: 'var(--fg-3)', marginTop: 2 }}>
              7 of 9 processes healthy
            </div>
          </div>
        </div>
      </div>

      {/* Today's hypothesis */}
      <div style={{ padding: '20px 20px 0' }}>
        <div className="mono" style={{
          fontSize: 10, letterSpacing: '0.22em', color: 'var(--fg-3)', marginBottom: 10,
        }}>TODAY · HYPOTHESIS</div>
        <div style={{
          background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
          borderRadius: 16, padding: 18,
        }}>
          <div className="mono" style={{ fontSize: 10, color: 'var(--gold)', letterSpacing: '0.1em' }}>
            EVENT · P=0.71 · TRIGGER 23–24 MAY
          </div>
          <div className="serif" style={{ fontSize: 22, marginTop: 8, lineHeight: 1.2 }}>
            Inbound from a capital source.
          </div>
          <p style={{ fontSize: 13, color: 'var(--fg-2)', marginTop: 8, lineHeight: 1.55 }}>
            Transit Jupiter conjunct your natal 11th-lord Mercury. Prior: SpaceXAI thread is warm.
            Reply window opens today, narrows Tuesday.
          </p>
          <div style={{
            marginTop: 14, height: 32, borderRadius: 8,
            background: 'var(--ink-2)', position: 'relative', overflow: 'hidden',
          }}>
            <div style={{
              position: 'absolute', left: '12%', width: '34%', top: 0, bottom: 0,
              background: 'linear-gradient(90deg, transparent, rgba(255,200,120,0.35), transparent)',
            }}/>
            <div className="mono" style={{
              position: 'absolute', inset: 0, display: 'flex', alignItems: 'center',
              justifyContent: 'space-between', padding: '0 10px', fontSize: 9.5,
              color: 'var(--fg-3)', letterSpacing: '0.1em',
            }}>
              <span>FRI</span><span>SAT ●</span><span style={{ color: 'var(--gold)' }}>SUN ●</span>
              <span>MON</span><span>TUE</span><span>WED</span><span>THU</span>
            </div>
          </div>
        </div>
      </div>

      {/* Failure-mode card (constraint-first) */}
      <div style={{ padding: '14px 20px 0' }}>
        <div style={{
          background: 'rgba(150,40,30,0.08)', border: '0.5px solid rgba(220,90,70,0.22)',
          borderRadius: 16, padding: 16,
        }}>
          <div className="mono" style={{ fontSize: 10, color: 'var(--bad)', letterSpacing: '0.16em' }}>
            GUARDRAIL · 12TH HOUSE MERCURY
          </div>
          <div style={{ fontSize: 13.5, marginTop: 8, color: 'var(--fg)', lineHeight: 1.5 }}>
            Your failure mode is <span style={{ color: 'var(--bad)' }}>over-promising on email</span> when excited.
            Draft today, send Monday. Always.
          </div>
        </div>
      </div>

      {/* Action queue */}
      <div style={{ padding: '20px 20px 0' }}>
        <div className="mono" style={{
          fontSize: 10, letterSpacing: '0.22em', color: 'var(--fg-3)', marginBottom: 10,
          display: 'flex', justifyContent: 'space-between',
        }}>
          <span>ACTION QUEUE</span>
          <span style={{ color: 'var(--gold)' }}>3 OPEN</span>
        </div>
        {[
          { d: 'Jun–Jul', t: 'Deploy Dubai base',           p: 'P1', c: 'var(--gold)' },
          { d: 'Oct 04',  t: 'Structure Singapore entity',  p: 'P1', c: 'var(--gold)' },
          { d: 'Nov 12',  t: 'Pause hiring until Sat ingresses', p: 'P2', c: 'var(--cool)' },
        ].map((a, i) => (
          <div key={i} style={{
            display: 'flex', gap: 12, alignItems: 'center',
            padding: '12px 14px', background: 'var(--ink-1)',
            border: '0.5px solid var(--hair)', borderRadius: 12, marginBottom: 8,
          }}>
            <div className="mono" style={{
              fontSize: 10, color: a.c, width: 56, letterSpacing: '0.08em',
            }}>{a.d}</div>
            <div style={{ flex: 1, fontSize: 14, color: 'var(--fg)' }}>{a.t}</div>
            <div className="mono" style={{
              fontSize: 9, color: a.c, border: '0.5px solid ' + a.c,
              padding: '2px 6px', borderRadius: 4,
            }}>{a.p}</div>
          </div>
        ))}
      </div>

      <TabBar active="home" />
    </div>
  );
}

// ────────────────────────────────────────────────────────────
// 06 — Chart wheel (rotatable)
// ────────────────────────────────────────────────────────────
function ChartScreen() {
  const [rot, setRot] = useState(-15);
  const dragRef = useRef(null);

  const onPtrDown = (e) => {
    const el = e.currentTarget;
    const rect = el.getBoundingClientRect();
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;
    const start = Math.atan2(e.clientY - cy, e.clientX - cx) * 180 / Math.PI;
    dragRef.current = { start, rot };
    el.setPointerCapture && el.setPointerCapture(e.pointerId);
  };
  const onPtrMove = (e) => {
    if (!dragRef.current) return;
    const el = e.currentTarget;
    const rect = el.getBoundingClientRect();
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;
    const now = Math.atan2(e.clientY - cy, e.clientX - cx) * 180 / Math.PI;
    setRot(dragRef.current.rot + (now - dragRef.current.start));
  };
  const onPtrUp = () => { dragRef.current = null; };

  const CX = 200, CY = 200, R_OUTER = 160, R_HOUSE = 120, R_PLANET = 90;

  return (
    <div className="astro-screen" style={{ position: 'relative', paddingBottom: 90 }}>
      <TopBar
        eyebrow="VEDIC · D1 RASI"
        title="Natal chart"
        trailing={<>
          <IconBtn>⌖</IconBtn>
          <IconBtn>⇅</IconBtn>
        </>}
      />

      {/* The wheel */}
      <div style={{ padding: '8px 0 0', display: 'flex', justifyContent: 'center' }}>
        <svg
          width={400} height={400} viewBox="0 0 400 400"
          onPointerDown={onPtrDown} onPointerMove={onPtrMove} onPointerUp={onPtrUp}
          style={{ touchAction: 'none', cursor: dragRef.current ? 'grabbing' : 'grab' }}
        >
          <defs>
            <radialGradient id="wheelG" cx="50%" cy="50%" r="50%">
              <stop offset="0%" stopColor="rgba(255,200,120,0.06)"/>
              <stop offset="60%" stopColor="rgba(255,200,120,0.02)"/>
              <stop offset="100%" stopColor="transparent"/>
            </radialGradient>
          </defs>

          <circle cx={CX} cy={CY} r={R_OUTER+8} fill="url(#wheelG)"/>

          <g transform={`rotate(${rot} ${CX} ${CY})`}>
            {/* Outer ring */}
            <circle cx={CX} cy={CY} r={R_OUTER} fill="none" stroke="var(--hair-2)" strokeWidth="0.6"/>
            <circle cx={CX} cy={CY} r={R_HOUSE} fill="none" stroke="var(--hair)" strokeWidth="0.5" strokeDasharray="2 3"/>
            <circle cx={CX} cy={CY} r={45} fill="none" stroke="var(--hair)" strokeWidth="0.5"/>

            {/* 12 house spokes */}
            {Array.from({ length: 12 }).map((_, i) => {
              const a = (i * 30 - 90) * Math.PI / 180;
              return (
                <line key={i}
                  x1={CX + Math.cos(a) * 45} y1={CY + Math.sin(a) * 45}
                  x2={CX + Math.cos(a) * R_OUTER} y2={CY + Math.sin(a) * R_OUTER}
                  stroke="var(--hair)" strokeWidth="0.5"
                />
              );
            })}

            {/* Sign glyphs on ring */}
            {SIGN_LIST.map((s, i) => {
              const a = (i * 30 - 75) * Math.PI / 180;
              return (
                <text key={s}
                  x={CX + Math.cos(a) * (R_OUTER - 14)}
                  y={CY + Math.sin(a) * (R_OUTER - 14)}
                  fill="var(--fg-2)" fontSize="14"
                  fontFamily="var(--serif)"
                  textAnchor="middle" dominantBaseline="middle"
                  transform={`rotate(${-rot} ${CX + Math.cos(a) * (R_OUTER - 14)} ${CY + Math.sin(a) * (R_OUTER - 14)})`}
                >{SIGN_GLYPH[s]}</text>
              );
            })}

            {/* House numbers */}
            {Array.from({ length: 12 }).map((_, i) => {
              const a = (i * 30 - 75) * Math.PI / 180;
              const x = CX + Math.cos(a) * (R_HOUSE - 14);
              const y = CY + Math.sin(a) * (R_HOUSE - 14);
              return (
                <text key={i} x={x} y={y}
                  fill="var(--fg-3)" fontSize="9"
                  fontFamily="var(--mono)"
                  textAnchor="middle" dominantBaseline="middle"
                  transform={`rotate(${-rot} ${x} ${y})`}
                >H{i+1}</text>
              );
            })}

            {/* Planet glyphs at their house positions */}
            {PLANETS.map((pl) => {
              const houseAngle = ((pl.house - 1) * 30 - 75) * Math.PI / 180;
              const x = CX + Math.cos(houseAngle) * R_PLANET;
              const y = CY + Math.sin(houseAngle) * R_PLANET;
              const meta = STATUS_META[pl.status];
              return (
                <g key={pl.p} transform={`rotate(${-rot} ${x} ${y})`}>
                  <circle cx={x} cy={y} r="14" fill="var(--ink-2)" stroke={meta.color} strokeWidth="1"/>
                  <text x={x} y={y+1} fill="var(--fg)" fontSize="16"
                    fontFamily="var(--serif)" textAnchor="middle" dominantBaseline="middle">
                    {PLANET_GLYPH[pl.p]}
                  </text>
                </g>
              );
            })}

            {/* Ascendant marker */}
            {(() => {
              const a = (0 - 90) * Math.PI / 180;
              return (
                <g>
                  <line x1={CX + Math.cos(a) * R_OUTER} y1={CY + Math.sin(a) * R_OUTER}
                        x2={CX + Math.cos(a) * (R_OUTER + 16)} y2={CY + Math.sin(a) * (R_OUTER + 16)}
                        stroke="var(--gold)" strokeWidth="2"/>
                </g>
              );
            })()}
          </g>

          {/* Center label (un-rotated) */}
          <text x={CX} y={CY - 6} textAnchor="middle" fill="var(--fg-3)"
            fontFamily="var(--mono)" fontSize="9" letterSpacing="2">ASC</text>
          <text x={CX} y={CY + 10} textAnchor="middle" fill="var(--gold)"
            fontFamily="var(--serif)" fontSize="22">♏ 04°</text>
        </svg>
      </div>

      <div className="mono" style={{
        textAlign: 'center', fontSize: 10, color: 'var(--fg-3)',
        letterSpacing: '0.2em', marginTop: -10,
      }}>↻ DRAG TO ROTATE</div>

      {/* Status matrix preview */}
      <div style={{ padding: '20px 20px 0' }}>
        <div className="mono" style={{
          fontSize: 10, letterSpacing: '0.22em', color: 'var(--fg-3)', marginBottom: 10,
          display: 'flex', justifyContent: 'space-between',
        }}>
          <span>OPTIMIZATION MATRIX</span>
          <span>9 PROCESSES</span>
        </div>
        <div style={{
          background: 'var(--ink-1)', border: '0.5px solid var(--hair)',
          borderRadius: 14, overflow: 'hidden',
        }}>
          {PLANETS.slice(0, 6).map((pl, i) => {
            const meta = STATUS_META[pl.status];
            return (
              <div key={pl.p} style={{
                display: 'grid', gridTemplateColumns: '24px 1fr 70px 80px 50px',
                gap: 10, alignItems: 'center', padding: '11px 14px',
                borderBottom: i < 5 ? '0.5px solid var(--hair)' : 'none',
                fontFamily: 'var(--mono)', fontSize: 11,
              }}>
                <Glyph name={pl.p} size={16} color={meta.color}/>
                <span style={{ color: 'var(--fg)' }}>{pl.p.toLowerCase()}<span style={{ color: 'var(--fg-3)' }}>.proc</span></span>
                <span style={{ color: 'var(--fg-2)' }}>H{pl.house} · {SIGN_GLYPH[pl.sign]}</span>
                <span style={{ color: meta.color, letterSpacing: '0.08em' }}>{meta.code}</span>
                <span style={{ color: 'var(--fg-2)', textAlign: 'right' }}>{pl.strength.toFixed(2)}</span>
              </div>
            );
          })}
          <div style={{
            padding: '11px 14px', textAlign: 'center', fontFamily: 'var(--mono)',
            fontSize: 11, color: 'var(--gold)',
          }}>view all 9 →</div>
        </div>
      </div>

      <TabBar active="chart" />
    </div>
  );
}

Object.assign(window, { DashboardScreen, ChartScreen });
