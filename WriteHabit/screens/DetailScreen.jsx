// Screen 3: Post detail + comments
const DetailScreen = () => {
  return (
    <div className="wh">
      <TopBar active="browse" />

      <div className="wrap" style={{ paddingTop: 36, paddingLeft: 56, paddingRight: 56, display: 'grid', gridTemplateColumns: '1fr 280px', gap: 56 }}>
        {/* Main article */}
        <article>
          {/* breadcrumb */}
          <div className="meta" style={{ marginBottom: 24, display: 'flex', gap: 8 }}>
            <span>ARCHIVE</span><span className="dot">/</span>
            <span>KW 0342 · 이별 · FAREWELL</span><span className="dot">/</span>
            <span style={{ color: 'var(--ink)' }}>POST · 0037</span>
          </div>

          {/* title */}
          <h1 style={{
            fontFamily: 'var(--f-kr-serif)', fontWeight: 700,
            fontSize: 48, lineHeight: 1.2, letterSpacing: '-0.025em',
            margin: '0 0 20px', color: 'var(--ink)',
          }}>
            서른의 이별은 조금<br/>다른 얼굴을 하고 있다
          </h1>

          {/* byline */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 14, paddingBottom: 28, borderBottom: '1px solid var(--rule)', marginBottom: 36 }}>
            <div className="avatar">이</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: 'var(--f-kr)', fontWeight: 600, fontSize: 14 }}>이해인 <span style={{ color: 'var(--ink-mute)', fontWeight: 400, marginLeft: 6 }}>@haein</span></div>
              <div className="meta" style={{ fontSize: 11, marginTop: 2 }}>2026·04·23 · 14:32 · 읽기 3분 · 342자</div>
            </div>
            <button className="btn sm">＋ 팔로우</button>
          </div>

          {/* body */}
          <div style={{
            fontFamily: 'var(--f-kr-serif)', fontSize: 18, lineHeight: 1.95,
            color: 'var(--ink-soft)', letterSpacing: '-0.005em', maxWidth: '62ch',
          }}>
            <p style={{ margin: '0 0 1.4em' }}>
              이십대의 이별은 세상이 무너지는 일이었는데, 서른이 되고 나니 이별은 조용히 찾아와서 조용히 떠난다.
              떠난 자리에 먼지처럼 쌓이는 감정들을 하나씩 털어내는 것이 더 오래 걸린다는 걸 이제는 안다.
            </p>
            <p style={{ margin: '0 0 1.4em' }}>
              그는 마지막 인사조차 하지 않았다. 어떤 이별은 말없이 완성된다. 대답 없는 질문들만 남기고.
              우리는 헤어졌다는 문장 하나로 설명될 수 없는 것들. 그 사이에 놓인 무수한 오후와, 함께 듣던 노래와,
              두 번 다시 웃지 않을 농담 같은 것들.
            </p>
            <blockquote style={{
              margin: '1.6em 0', padding: '8px 0 8px 24px',
              borderLeft: '2px solid var(--accent)',
              fontStyle: 'italic', color: 'var(--ink)', fontSize: 19,
            }}>
              이별은 사람이 떠나는 일이 아니라, 그 사람과 살던 내가 한 명 더 죽는 일이다.
            </blockquote>
            <p style={{ margin: '0 0 1.4em' }}>
              서른은 이별의 나이다. 청춘의 마지막 정거장에서 많은 것들이 한꺼번에 내린다. 친구들의 연락이 뜸해지고,
              한때 소중했던 취향들이 낯설어진다. 부모의 전화에 처음으로 불안을 느끼고, 내가 누구였는지를 자주 잊는다.
            </p>
            <p style={{ margin: '0 0 1.4em' }}>
              그래도 아침은 온다. 커피를 내리고, 창문을 열고, 오늘도 한 줄을 쓴다.
              이별 다음에 오는 것은 새로운 만남이 아니라, 이별을 견딘 나 자신이라는 걸 이제 안다.
            </p>
          </div>

          {/* actions bar */}
          <div style={{
            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            marginTop: 44, padding: '16px 0', borderTop: '1px solid var(--rule)', borderBottom: '1px solid var(--rule)',
          }}>
            <div style={{ display: 'flex', gap: 16 }}>
              {[['♥', '좋아요', 42, true], ['💬', '댓글', 7, false], ['🔖', '저장', 12, false], ['↗', '공유', null, false]].map(([e, l, n, active], i) => (
                <button key={i} className={`btn sm ${active ? 'accent' : ''}`} style={{ gap: 8 }}>
                  <span style={{ fontFamily: 'var(--f-mono)', fontSize: 14 }}>{e}</span>
                  <span>{l}</span>
                  {n !== null && <span style={{ fontFamily: 'var(--f-latin)', fontVariantNumeric: 'tabular-nums', color: 'inherit', opacity: 0.7 }}>{n}</span>}
                </button>
              ))}
            </div>
            <span className="meta">POST · 0037 / 1247</span>
          </div>

          {/* emoji reactions strip */}
          <div style={{ marginTop: 18, display: 'flex', gap: 6, alignItems: 'center' }}>
            <span className="label" style={{ marginRight: 6 }}>반응</span>
            {[['♥', 42], ['✨', 18], ['🌧', 12], ['🕯', 8], ['☕', 5]].map(([e, n]) => (
              <span key={e} className="chip">
                <span style={{ fontSize: 13 }}>{e}</span>
                <span style={{ fontFamily: 'var(--f-latin)', fontVariantNumeric: 'tabular-nums' }}>{n}</span>
              </span>
            ))}
            <span className="chip" style={{ color: 'var(--ink-faint)' }}>＋</span>
          </div>

          {/* comments */}
          <div style={{ marginTop: 44 }}>
            <div className="col-h">
              <h2>댓글 <span style={{ fontFamily: 'var(--f-latin)', color: 'var(--ink-mute)', fontSize: 14, marginLeft: 6 }}>7</span></h2>
              <span className="meta">최신순 ▾</span>
            </div>

            {/* comment form */}
            <div style={{ display: 'grid', gridTemplateColumns: '36px 1fr', gap: 14, marginBottom: 12 }}>
              <div className="avatar">민</div>
              <div>
                <textarea className="field" placeholder="이 글에 대한 생각을 남겨주세요"
                  style={{ borderBottom: '1px solid var(--rule-soft)', minHeight: 60, resize: 'none', padding: '10px 0' }} />
                <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 10 }}>
                  <span className="meta">마크다운 지원</span>
                  <button className="btn sm solid">댓글 남기기</button>
                </div>
              </div>
            </div>

            {[
              { n: '정윤', i: '정', t: '2분 전', body: '마지막 문단에서 울컥했어요. "이별을 견딘 나 자신" 이 문장이 오래 남을 것 같습니다.' },
              { n: '김도현', i: '김', t: '18분 전', body: '서른의 이별에 대한 묘사가 너무 구체적이고 솔직해서 좋았습니다. 덕분에 제 경험이 다시 떠올랐어요.' },
              { n: '박서연', i: '박', t: '1시간 전', body: '조용히 찾아와서 조용히 떠난다는 표현, 문장이 너무 정확해서 한참 멈춰 있었습니다.' },
            ].map((c, i) => (
              <div className="comment" key={i}>
                <div className="avatar">{c.i}</div>
                <div>
                  <div className="c-head">
                    <span className="c-author">{c.n}</span>
                    <span className="c-time">{c.t}</span>
                  </div>
                  <div className="c-body">{c.body}</div>
                  <div className="c-actions">
                    <span>♥ 좋아요 {i === 0 ? 12 : i === 1 ? 5 : 2}</span>
                    <span>답글</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </article>

        {/* Sidebar */}
        <aside style={{ position: 'sticky', top: 40, alignSelf: 'start', display: 'flex', flexDirection: 'column', gap: 20 }}>
          <div className="panel">
            <h4>오늘의 키워드</h4>
            <div style={{ fontFamily: 'var(--f-kr-serif)', fontWeight: 700, fontSize: 32, letterSpacing: '-0.02em', lineHeight: 1, color: 'var(--ink)' }}>이별</div>
            <div className="meta" style={{ fontSize: 10.5, marginTop: 6 }}>FAREWELL · NO. 0342</div>
            <div className="rule-soft" style={{ margin: '14px 0' }} />
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, color: 'var(--ink-soft)' }}>
              <span>오늘 작성</span>
              <span className="num" style={{ fontWeight: 600 }}>1,247</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, color: 'var(--ink-soft)', marginTop: 6 }}>
              <span>현재 읽는 중</span>
              <span className="num" style={{ fontWeight: 600 }}>84</span>
            </div>
            <button className="btn sm accent" style={{ width: '100%', justifyContent: 'center', marginTop: 16 }}>
              나도 쓰기 <span className="arr">→</span>
            </button>
          </div>

          <div className="panel">
            <h4>작가 소개</h4>
            <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
              <div className="avatar" style={{ width: 44, height: 44, fontSize: 17 }}>이</div>
              <div>
                <div style={{ fontWeight: 600, fontSize: 14 }}>이해인</div>
                <div className="meta" style={{ fontSize: 10.5 }}>@haein</div>
              </div>
            </div>
            <p style={{ fontSize: 12.5, color: 'var(--ink-mute)', lineHeight: 1.6, margin: '12px 0' }}>
              서울에서 글을 씁니다. 조용한 감정과 사소한 장면을 기록하는 일을 좋아합니다.
            </p>
            <div style={{ display: 'flex', gap: 16, fontFamily: 'var(--f-mono)', fontSize: 11, color: 'var(--ink-mute)' }}>
              <span><span style={{ color: 'var(--ink)' }}>184</span> 글</span>
              <span><span style={{ color: 'var(--ink)' }}>2.3k</span> 팔로워</span>
              <span><span style={{ color: 'var(--ink)' }}>312</span> 팔로잉</span>
            </div>
            <button className="btn sm" style={{ width: '100%', justifyContent: 'center', marginTop: 14 }}>＋ 팔로우</button>
          </div>

          <div className="panel">
            <h4>이 키워드 다른 글</h4>
            {SAMPLE_POSTS.slice(1, 4).map(p => (
              <div key={p.id} style={{ padding: '10px 0', borderBottom: '1px solid var(--rule-ghost)' }}>
                <div style={{ fontFamily: 'var(--f-kr-serif)', fontSize: 13.5, fontWeight: 700, color: 'var(--ink)', letterSpacing: '-0.01em', marginBottom: 4 }}>
                  {p.title}
                </div>
                <div className="meta" style={{ fontSize: 10.5 }}>{p.author} · ♥ {p.likes}</div>
              </div>
            ))}
          </div>
        </aside>
      </div>
    </div>
  );
};

window.DetailScreen = DetailScreen;
