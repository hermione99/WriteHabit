// Screen 5: Archive (keyword history)
const ArchiveScreen = () => {
  // Build 14x7 calendar grid (98 days)
  const today = 30; // today's index in grid
  const grid = Array.from({ length: 98 }, (_, i) => {
    if (i === today) return 'today';
    if (i > today) return 'future';
    const r = Math.sin(i * 2.1) + Math.cos(i * 0.7);
    return r > 0.3 ? 'on' : r > -0.5 ? 'on-light' : 'none';
  });

  return (
    <div className="wh">
      <TopBar active="archive" />

      <div className="wrap" style={{ paddingTop: 36, paddingLeft: 56, paddingRight: 56 }}>
        <section style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 40, alignItems: 'end', paddingBottom: 24, borderBottom: '1px solid var(--rule)' }}>
          <div>
            <div className="eyebrow" style={{ marginBottom: 10 }}>ARCHIVE · 342 DAYS · 428,932 WRITINGS</div>
            <h1 style={{
              fontFamily: 'var(--f-kr-serif)', fontWeight: 700, fontSize: 56,
              letterSpacing: '-0.025em', lineHeight: 1, margin: 0, color: 'var(--ink)',
            }}>
              키워드 아카이브
            </h1>
            <p style={{ fontSize: 14, color: 'var(--ink-mute)', marginTop: 14, maxWidth: '48ch', lineHeight: 1.65 }}>
              2025년 5월 17일부터 매일 하나씩, 342개의 키워드가 쌓였습니다. 한 글자, 한 단어, 하나의 감정에 대한 기록.
            </p>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <div className="tsel" style={{ padding: '8px 12px' }}>연도 · 2026 ▾</div>
            <div className="tsel" style={{ padding: '8px 12px' }}>월 · 04 ▾</div>
            <div className="tsel" style={{ padding: '8px 12px' }}>정렬 · 최신 ▾</div>
          </div>
        </section>

        {/* Two-column: calendar + list */}
        <section style={{ display: 'grid', gridTemplateColumns: '420px 1fr', gap: 56, paddingTop: 32 }}>
          <div>
            <div className="col-h">
              <h2>지난 98일</h2>
              <span className="meta">2026·01·15 → 04·23</span>
            </div>
            <div className="cal">
              {grid.map((s, i) => {
                if (s === 'today') {
                  return <div key={i} className="d today">●</div>;
                }
                if (s === 'future') {
                  return <div key={i} className="d" style={{ opacity: 0.25 }}></div>;
                }
                return <div key={i} className={`d ${s}`}></div>;
              })}
            </div>
            <div style={{ display: 'flex', gap: 14, marginTop: 16, fontFamily: 'var(--f-mono)', fontSize: 10.5, color: 'var(--ink-mute)', alignItems: 'center' }}>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}><span className="d" style={{ width: 10, height: 10, background: 'var(--accent)', display: 'block' }}></span>오늘</span>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}><span className="d" style={{ width: 10, height: 10, background: 'var(--ink)', display: 'block' }}></span>작성함</span>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}><span className="d" style={{ width: 10, height: 10, background: 'var(--paper-3)', display: 'block' }}></span>읽기만</span>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}><span className="d" style={{ width: 10, height: 10, border: '1px solid var(--rule-ghost)', display: 'block' }}></span>미작성</span>
            </div>

            {/* Most written word */}
            <div style={{ marginTop: 32 }}>
              <div className="col-h"><h2>가장 많이 쓴 키워드</h2></div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                {[
                  ['YOUTH', '청춘', 12],
                  ['MEMORY', '기억', 9],
                  ['DAWN', '새벽', 7],
                  ['SILENCE', '침묵', 6],
                ].map(([e, k, n], i) => (
                  <div key={i} style={{
                    border: '1px solid var(--rule-ghost)', padding: 16,
                    display: 'flex', justifyContent: 'space-between', alignItems: 'center'
                  }}>
                    <div>
                      <div className="meta" style={{ fontSize: 9.5 }}>{e}</div>
                      <div style={{ fontFamily: 'var(--f-kr-serif)', fontWeight: 700, fontSize: 22, letterSpacing: '-0.02em' }}>{k}</div>
                    </div>
                    <div style={{ fontFamily: 'var(--f-latin)', fontWeight: 700, fontSize: 22, color: 'var(--accent)', fontVariantNumeric: 'tabular-nums' }}>
                      {n}<span style={{ fontSize: 11, color: 'var(--ink-mute)', fontWeight: 500, marginLeft: 2 }}>회</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div>
            <div className="col-h">
              <h2>최근 키워드</h2>
              <span className="meta">DATE · WORD · WRITINGS</span>
            </div>
            <div>
              {KEYWORDS_ARCHIVE.map((k, i) => (
                <div className="kw-row" key={i}>
                  <span className="kdate">2026·{k.date}</span>
                  <div>
                    <div className="kword">
                      <span className="kor-serif">{k.word}</span>
                      <span style={{ marginLeft: 14, color: 'var(--ink-faint)', fontFamily: 'var(--f-serif)', fontSize: 14, letterSpacing: '0.08em' }}>{k.eng}</span>
                    </div>
                    <div className="meta" style={{ fontSize: 10.5, marginTop: 2 }}>
                      NO. {String(341 - i).padStart(4, '0')} · {i === 0 ? '작성함 ✓' : Math.random() > 0.4 ? '작성함 ✓' : '미작성 —'}
                    </div>
                  </div>
                  <div>
                    <div className="kcount">{k.count.toLocaleString()}
                      <small>글</small>
                    </div>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <button className="btn sm ghost">읽기 <span className="arr">→</span></button>
                  </div>
                </div>
              ))}
              <div style={{ textAlign: 'center', padding: '28px 0 8px' }}>
                <button className="btn ghost">더 오래된 키워드 보기 <span className="arr">↓</span></button>
              </div>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
};

window.ArchiveScreen = ArchiveScreen;
