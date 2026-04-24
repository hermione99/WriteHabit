// Screen: Admin · Keyword Curation / Scheduling
const AdminKeywordsScreen = () => {
  const scheduled = [
    { date: '04·23', day: '목', word: '이별',   eng: 'FAREWELL',    status: 'live',      by: '운영팀',   posts: 1247 },
    { date: '04·24', day: '금', word: '비',     eng: 'RAIN',        status: 'scheduled', by: '운영팀',   posts: null },
    { date: '04·25', day: '토', word: '주말',   eng: 'WEEKEND',     status: 'scheduled', by: '운영팀',   posts: null },
    { date: '04·26', day: '일', word: '산책',   eng: 'WALK',        status: 'scheduled', by: '이해인',   posts: null },
    { date: '04·27', day: '월', word: '월요일', eng: 'MONDAY',      status: 'scheduled', by: '운영팀',   posts: null },
    { date: '04·28', day: '화', word: '커피',   eng: 'COFFEE',      status: 'draft',     by: '김도현',   posts: null },
    { date: '04·29', day: '수', word: '창가',   eng: 'WINDOWSIDE',  status: 'draft',     by: '운영팀',   posts: null },
    { date: '04·30', day: '목', word: '',       eng: '',            status: 'empty',     by: '',         posts: null },
    { date: '05·01', day: '금', word: '봄밤',   eng: 'SPRING NIGHT',status: 'scheduled', by: '운영팀',   posts: null, fixed: '근로자의 날' },
    { date: '05·02', day: '토', word: '',       eng: '',            status: 'empty',     by: '',         posts: null },
  ];
  const past = [
    { date: '04·22', day: '수', word: '행복', eng: 'HAPPINESS', posts: 1842 },
    { date: '04·21', day: '화', word: '청춘', eng: 'YOUTH',     posts: 2104 },
    { date: '04·20', day: '월', word: '미래', eng: 'FUTURE',    posts: 1567 },
  ];

  const STATUS = {
    live:      { k: 'LIVE',      c: '#d94615' },
    scheduled: { k: 'SCHEDULED', c: '#1b1a15' },
    draft:     { k: 'DRAFT',     c: '#6a6558' },
    empty:     { k: 'EMPTY',     c: '#a09a89' },
  };

  return (
    <div className="wh" style={{ overflow: 'auto' }}>
      <TopBar active="profile" right={
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <span className="chip accent" style={{ fontFamily: 'var(--f-mono)' }}>ADMIN · EDITOR</span>
          <div className="avatar" style={{ width: 32, height: 32, fontSize: 13 }}>운</div>
        </div>
      } />

      <div className="wrap" style={{ paddingTop: 32 }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 32, alignItems: 'end', paddingBottom: 24, borderBottom: '1px solid var(--rule)' }}>
          <div>
            <div className="eyebrow" style={{ marginBottom: 10 }}>CURATION · 키워드 스케줄러</div>
            <h1 style={{ fontFamily: 'var(--f-kr-serif)', fontWeight: 700, fontSize: 44, letterSpacing: '-0.025em', lineHeight: 1, margin: 0, color: 'var(--ink)' }}>
              오늘 이후의 키워드
            </h1>
            <p style={{ fontSize: 14, color: 'var(--ink-mute)', marginTop: 10, maxWidth: '52ch', lineHeight: 1.65 }}>
              편집자가 매일 하나씩 예약 등록합니다. 유저 제안은 검토 후 스케줄에 편입됩니다. 매일 00:00 KST에 오늘의 키워드가 자동 발행됩니다.
            </p>
          </div>
          <div style={{ display: 'flex', gap: 10 }}>
            <button className="btn sm">제안 검토 <span style={{ color: 'var(--accent)', marginLeft: 4 }}>●14</span></button>
            <button className="btn sm solid">＋ 키워드 추가</button>
          </div>
        </div>

        {/* stats strip */}
        <section style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 40, padding: '22px 0', borderBottom: '1px solid var(--rule-soft)' }}>
          {[
            ['예약된 키워드', '42', '일치'],
            ['미배정 슬롯', '6', '일'],
            ['유저 제안 대기', '14', '건'],
            ['최근 30일 평균 참여', '1,584', '편/일'],
            ['다음 발행까지', '14H 32M', ''],
          ].map(([k, v, s]) => (
            <div key={k}>
              <div className="label" style={{ fontSize: 10, marginBottom: 6 }}>{k}</div>
              <div style={{ fontFamily: 'var(--f-latin)', fontWeight: 700, fontSize: 28, letterSpacing: '-0.04em', color: 'var(--ink)', fontVariantNumeric: 'tabular-nums', lineHeight: 1 }}>
                {v} <span style={{ fontSize: 12, color: 'var(--ink-mute)', fontFamily: 'var(--f-kr)', fontWeight: 500, letterSpacing: 0, marginLeft: 2 }}>{s}</span>
              </div>
            </div>
          ))}
        </section>

        {/* Main — schedule table + side panel */}
        <section style={{ display: 'grid', gridTemplateColumns: '1fr 340px', gap: 40, padding: '28px 0' }}>
          <div>
            <div className="col-h">
              <h2>앞으로 14일</h2>
              <span className="meta">DATE · WORD · STATUS · CURATED BY</span>
            </div>

            {/* table header */}
            <div style={{
              display: 'grid', gridTemplateColumns: '90px 1fr 120px 120px 80px',
              gap: 16, padding: '0 0 10px', borderBottom: '1px solid var(--rule)',
            }}>
              {['DATE', 'KEYWORD', 'STATUS', 'CURATED BY', ''].map((h, i) => (
                <span key={i} className="label" style={{ fontSize: 10 }}>{h}</span>
              ))}
            </div>

            {scheduled.map((r, i) => {
              const st = STATUS[r.status];
              const isToday = r.status === 'live';
              const empty = r.status === 'empty';
              return (
                <div key={i} style={{
                  display: 'grid', gridTemplateColumns: '90px 1fr 120px 120px 80px',
                  gap: 16, padding: '16px 0', borderBottom: '1px solid var(--rule-ghost)',
                  alignItems: 'center',
                  background: isToday ? 'var(--accent-soft)' : 'transparent',
                  marginLeft: isToday ? -12 : 0, marginRight: isToday ? -12 : 0,
                  paddingLeft: isToday ? 12 : 0, paddingRight: isToday ? 12 : 0,
                }}>
                  <div>
                    <div style={{ fontFamily: 'var(--f-latin)', fontWeight: 600, fontSize: 14, color: 'var(--ink)', fontVariantNumeric: 'tabular-nums' }}>{r.date}</div>
                    <div className="meta" style={{ fontSize: 10.5 }}>{r.day}요일{isToday ? ' · 오늘' : ''}</div>
                  </div>
                  <div>
                    {empty ? (
                      <button className="btn sm ghost" style={{ borderStyle: 'dashed' }}>＋ 키워드 배정</button>
                    ) : (
                      <div>
                        <div style={{ display: 'flex', alignItems: 'baseline', gap: 12 }}>
                          <span style={{ fontFamily: 'var(--f-kr-serif)', fontWeight: 700, fontSize: 22, letterSpacing: '-0.02em', color: 'var(--ink)' }}>{r.word}</span>
                          <span style={{ fontFamily: 'var(--f-serif)', fontSize: 12, color: 'var(--ink-faint)', letterSpacing: '0.08em' }}>{r.eng}</span>
                          {r.fixed && <span className="chip" style={{ fontSize: 10 }}>📌 {r.fixed}</span>}
                        </div>
                      </div>
                    )}
                  </div>
                  <div>
                    <span className="chip" style={{
                      borderColor: st.c, color: st.c,
                      fontFamily: 'var(--f-latin)', fontSize: 10, letterSpacing: '0.12em'
                    }}>● {st.k}</span>
                  </div>
                  <div style={{ fontFamily: 'var(--f-kr)', fontSize: 12.5, color: empty ? 'var(--ink-faint)' : 'var(--ink-soft)' }}>
                    {r.by || '—'}
                    {r.posts !== null && <div className="meta" style={{ fontSize: 10.5 }}>{r.posts.toLocaleString()} 편</div>}
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    {!empty && <button className="btn sm ghost" style={{ padding: '5px 10px', fontSize: 10 }}>편집</button>}
                  </div>
                </div>
              );
            })}

            {/* Past keywords */}
            <div style={{ marginTop: 40 }}>
              <div className="col-h">
                <h2>최근 발행됨</h2>
                <span className="meta">PUBLISHED</span>
              </div>
              {past.map((r, i) => (
                <div key={i} style={{
                  display: 'grid', gridTemplateColumns: '90px 1fr 120px 120px 80px',
                  gap: 16, padding: '14px 0', borderBottom: '1px solid var(--rule-ghost)',
                  alignItems: 'center', opacity: 0.78,
                }}>
                  <div style={{ fontFamily: 'var(--f-latin)', fontSize: 13, color: 'var(--ink-mute)', fontVariantNumeric: 'tabular-nums' }}>{r.date} · {r.day}</div>
                  <div style={{ display: 'flex', alignItems: 'baseline', gap: 12 }}>
                    <span style={{ fontFamily: 'var(--f-kr-serif)', fontWeight: 700, fontSize: 18, color: 'var(--ink)' }}>{r.word}</span>
                    <span style={{ fontFamily: 'var(--f-serif)', fontSize: 11, color: 'var(--ink-faint)', letterSpacing: '0.08em' }}>{r.eng}</span>
                  </div>
                  <span className="meta" style={{ fontSize: 10.5 }}>● PUBLISHED</span>
                  <span className="meta" style={{ fontSize: 11 }}>{r.posts.toLocaleString()} 편</span>
                  <div style={{ textAlign: 'right' }}>
                    <button className="btn sm ghost" style={{ padding: '5px 10px', fontSize: 10 }}>통계 →</button>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Right — add form + suggestion queue */}
          <aside style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
            <div className="panel">
              <h4>키워드 예약하기</h4>
              <div style={{ marginBottom: 12 }}>
                <div className="label" style={{ fontSize: 10, marginBottom: 4 }}>발행일</div>
                <input className="field" defaultValue="2026·04·30 (목)" />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 12 }}>
                <div>
                  <div className="label" style={{ fontSize: 10, marginBottom: 4 }}>한글</div>
                  <input className="field" placeholder="예) 첫눈" />
                </div>
                <div>
                  <div className="label" style={{ fontSize: 10, marginBottom: 4 }}>영문</div>
                  <input className="field" placeholder="e.g. FIRST SNOW" />
                </div>
              </div>
              <div style={{ marginBottom: 12 }}>
                <div className="label" style={{ fontSize: 10, marginBottom: 4 }}>프롬프트 (선택)</div>
                <textarea className="field" placeholder="오늘의 키워드 아래에 작게 보여줄 안내 문구" style={{ minHeight: 72, resize: 'none' }} />
              </div>
              <div style={{ display: 'flex', gap: 8, marginBottom: 14, flexWrap: 'wrap' }}>
                <span className="chip active">감정</span>
                <span className="chip">계절</span>
                <span className="chip">장소</span>
                <span className="chip">시간</span>
                <span className="chip">관계</span>
              </div>
              <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, color: 'var(--ink-soft)', marginBottom: 14 }}>
                <span style={{ width: 12, height: 12, border: '1px solid var(--ink)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, background: 'var(--ink)', color: 'var(--paper)' }}>✓</span>
                30일 내 중복 자동 방지
              </label>
              <button className="btn accent" style={{ width: '100%', justifyContent: 'center' }}>예약 등록</button>
            </div>

            <div className="panel">
              <h4>유저 제안 대기 · 14</h4>
              {[
                { w: '첫눈', by: '한지우', v: 48 },
                { w: '기차', by: '박서연', v: 31 },
                { w: '편지', by: '정윤',   v: 24 },
                { w: '엄마의 밥상', by: '김도현', v: 18 },
              ].map((s, i) => (
                <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 0', borderBottom: '1px solid var(--rule-ghost)' }}>
                  <div>
                    <div style={{ fontFamily: 'var(--f-kr-serif)', fontWeight: 700, fontSize: 15, color: 'var(--ink)' }}>{s.w}</div>
                    <div className="meta" style={{ fontSize: 10.5 }}>{s.by} · ♥ {s.v}</div>
                  </div>
                  <div style={{ display: 'flex', gap: 4 }}>
                    <button className="btn sm ghost" style={{ padding: '4px 8px', fontSize: 10 }}>✓</button>
                    <button className="btn sm ghost" style={{ padding: '4px 8px', fontSize: 10 }}>✕</button>
                  </div>
                </div>
              ))}
              <button className="btn sm" style={{ width: '100%', justifyContent: 'center', marginTop: 12 }}>전체 보기 →</button>
            </div>

            <div className="panel" style={{ background: 'var(--paper-2)' }}>
              <h4>발행 로직</h4>
              <div style={{ fontFamily: 'var(--f-mono)', fontSize: 11, color: 'var(--ink-soft)', lineHeight: 1.75 }}>
                <div>00:00 KST · 매일 자동 발행</div>
                <div>↓</div>
                <div>scheduled_date = today()</div>
                <div>↓ 없으면</div>
                <div>status = 'empty' · 운영 알림</div>
                <div>↓ 폴백</div>
                <div>과거 인기 키워드 재활용</div>
              </div>
            </div>
          </aside>
        </section>
      </div>
    </div>
  );
};

window.AdminKeywordsScreen = AdminKeywordsScreen;
