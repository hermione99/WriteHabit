// Screen 4: Profile
const ProfileScreen = () => {
  // 30-day streak
  const streakData = Array.from({ length: 30 }, (_, i) => {
    if (i === 29) return 'today';
    const r = Math.sin(i * 3.7) + Math.cos(i * 1.3);
    return r > -0.4 ? 'on' : 'off';
  });

  return (
    <div className="wh">
      <TopBar active="profile" />

      <div className="wrap" style={{ paddingTop: 40, paddingLeft: 56, paddingRight: 56 }}>
        {/* Header */}
        <section style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 48, alignItems: 'end', paddingBottom: 28, borderBottom: '1px solid var(--rule)' }}>
          <div style={{ display: 'flex', gap: 24, alignItems: 'center' }}>
            <div className="avatar" style={{ width: 84, height: 84, fontSize: 36, fontFamily: 'var(--f-kr-serif)' }}>민</div>
            <div>
              <div className="eyebrow" style={{ marginBottom: 8 }}>WRITER · SINCE 2024·11</div>
              <h1 style={{
                fontFamily: 'var(--f-kr-serif)', fontWeight: 700, fontSize: 44,
                letterSpacing: '-0.02em', lineHeight: 1, margin: 0, color: 'var(--ink)',
              }}>
                김민지
              </h1>
              <div style={{ marginTop: 8, display: 'flex', gap: 12, alignItems: 'center', color: 'var(--ink-mute)', fontSize: 13 }}>
                <span className="meta">@minji</span>
                <span className="dot">/</span>
                <span>매일 한 줄, 주로 저녁에. 조용한 것들에 대해 씁니다.</span>
              </div>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 10 }}>
            <button className="btn sm ghost">공유</button>
            <button className="btn sm">설정</button>
            <button className="btn sm solid">새 글 쓰기 <span className="arr">→</span></button>
          </div>
        </section>

        {/* Stats grid */}
        <section style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 40, padding: '28px 0', borderBottom: '1px solid var(--rule-soft)' }}>
          {[
            ['누적 글', '184', '편'],
            ['총 분량', '62,340', '자'],
            ['받은 ♥', '3,842', ''],
            ['팔로워', '2,304', ''],
            ['현재 스트릭', '47', '일'],
          ].map(([k, v, s]) => (
            <div key={k}>
              <div className="label" style={{ fontSize: 10, marginBottom: 8 }}>{k}</div>
              <div style={{
                fontFamily: 'var(--f-latin)', fontWeight: 700, fontSize: 34,
                letterSpacing: '-0.04em', color: 'var(--ink)', fontVariantNumeric: 'tabular-nums',
                lineHeight: 1,
              }}>
                {v} <span style={{ fontSize: 13, color: 'var(--ink-mute)', fontFamily: 'var(--f-kr)', fontWeight: 500, letterSpacing: 0, marginLeft: 4 }}>{s}</span>
              </div>
            </div>
          ))}
        </section>

        {/* Streak chart */}
        <section style={{ padding: '28px 0', borderBottom: '1px solid var(--rule-soft)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16, alignItems: 'baseline' }}>
            <div>
              <div className="eyebrow">연속 작성 · WRITING STREAK</div>
              <div style={{ fontFamily: 'var(--f-kr-serif)', fontSize: 22, fontWeight: 700, marginTop: 4, color: 'var(--ink)' }}>
                47일 연속 기록 중 <span style={{ color: 'var(--accent)', fontFamily: 'var(--f-latin)', fontSize: 18, marginLeft: 8 }}>● 오늘 완료</span>
              </div>
            </div>
            <div style={{ display: 'flex', gap: 10 }}>
              <span className="chip active">30일</span>
              <span className="chip">90일</span>
              <span className="chip">1년</span>
            </div>
          </div>
          <div className="streak">
            {streakData.map((s, i) => (
              <div key={i} className={`b ${s}`} style={{
                height: s === 'off' ? 12 : s === 'on' ? 30 + ((i * 7) % 40) : 74,
              }} />
            ))}
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8, fontFamily: 'var(--f-mono)', fontSize: 10, color: 'var(--ink-mute)' }}>
            <span>04·24</span><span>04·29</span><span>05·04</span><span>05·09</span><span>05·14</span><span>05·19</span><span>오늘</span>
          </div>
        </section>

        {/* Tabs + posts */}
        <section style={{ padding: '28px 0' }}>
          <div style={{ display: 'flex', gap: 20, marginBottom: 20, borderBottom: '1px solid var(--rule-ghost)' }}>
            {[['글', 184, true], ['저장', 56], ['좋아요', 412], ['팔로잉', 312], ['팔로워', 2304]].map(([k, n, a], i) => (
              <button key={i} className="tbtn" style={{
                width: 'auto', height: 'auto', padding: '10px 2px',
                borderRadius: 0, borderBottom: a ? '1.5px solid var(--ink)' : 'none',
                color: a ? 'var(--ink)' : 'var(--ink-mute)',
                fontFamily: 'var(--f-kr)', fontWeight: a ? 600 : 500, fontSize: 13,
                letterSpacing: '-0.005em',
              }}>
                {k} <span style={{ fontFamily: 'var(--f-latin)', color: 'var(--ink-faint)', marginLeft: 4 }}>{n}</span>
              </button>
            ))}
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 0 }}>
            {SAMPLE_POSTS.slice(0, 4).map((p, i) => (
              <article key={p.id} style={{
                padding: 24,
                borderRight: i % 2 === 0 ? '1px solid var(--rule-ghost)' : 'none',
                borderBottom: '1px solid var(--rule-ghost)',
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 10 }}>
                  <span className="meta" style={{ fontSize: 10.5 }}>
                    KW · {['이별','청춘','새벽','후회'][i]} · 0{340 + i}
                  </span>
                  <span className="meta" style={{ fontSize: 10.5 }}>
                    {['04·23','04·21','04·16','04·15'][i]}
                  </span>
                </div>
                <h3 style={{
                  fontFamily: 'var(--f-kr-serif)', fontWeight: 700, fontSize: 19,
                  letterSpacing: '-0.02em', lineHeight: 1.3, margin: '0 0 10px', color: 'var(--ink)',
                }}>{p.title}</h3>
                <p style={{
                  fontSize: 13, color: 'var(--ink-mute)', lineHeight: 1.65, margin: 0,
                  display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
                }}>
                  {p.body}
                </p>
                <div style={{ display: 'flex', gap: 14, marginTop: 14, fontFamily: 'var(--f-mono)', fontSize: 10.5, color: 'var(--ink-mute)' }}>
                  <span>♥ <span style={{ color: 'var(--ink)' }}>{p.likes}</span></span>
                  <span>💬 <span style={{ color: 'var(--ink)' }}>{p.comments}</span></span>
                  <span>🔖 <span style={{ color: 'var(--ink)' }}>{p.bookmarks}</span></span>
                  <span style={{ marginLeft: 'auto' }}>{p.read} 읽기</span>
                </div>
              </article>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
};

window.ProfileScreen = ProfileScreen;
