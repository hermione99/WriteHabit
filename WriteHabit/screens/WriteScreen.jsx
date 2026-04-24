// Screen 2: Write (editor)
const WriteScreen = () => {
  return (
    <div className="wh">
      <TopBar active="write" right={
        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
          <span className="meta" style={{ fontSize: 11 }}>자동 저장 · 2분 전</span>
          <button className="btn sm">임시저장</button>
          <button className="btn sm accent">발행하기 <span className="arr">→</span></button>
        </div>
      } />

      <div className="wrap-narrow" style={{ paddingTop: 40, paddingBottom: 40 }}>
        {/* Today's prompt slip */}
        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
          paddingBottom: 20, borderBottom: '1px solid var(--rule-soft)', marginBottom: 28,
        }}>
          <div>
            <div className="eyebrow" style={{ marginBottom: 8 }}>오늘의 키워드 · No. 0342</div>
            <div style={{
              fontFamily: 'var(--f-kr-serif)', fontSize: 36, fontWeight: 400,
              letterSpacing: '-0.02em', color: 'var(--ink)'
            }}>
              이별 <span style={{ color: 'var(--ink-faint)', fontFamily: 'var(--f-serif)', fontSize: 22, marginLeft: 8 }}>Farewell</span>
            </div>
          </div>
          <div style={{ textAlign: 'right' }}>
            <div className="meta" style={{ fontSize: 10.5 }}>마감 · 23:59</div>
            <div className="meta" style={{ fontSize: 10.5 }}>14H 32M 남음</div>
          </div>
        </div>

        {/* Title */}
        <input className="field" defaultValue="서른의 이별은 조금 다른 얼굴을 하고 있다"
               style={{
                 fontFamily: 'var(--f-kr-serif)', fontSize: 32, fontWeight: 400,
                 letterSpacing: '-0.02em', padding: '8px 0', borderBottom: 'none',
                 marginBottom: 4,
               }} />
        <div className="rule-soft" style={{ marginBottom: 22 }}></div>

        {/* Editor shell */}
        <div className="editor-shell">
          <div className="editor-toolbar">
            <div className="group">
              <div className="tsel">
                <span>본문</span><span className="chev">▾</span>
              </div>
              <div className="tsel" style={{ marginLeft: 8 }}>
                <span>16px</span><span className="chev">▾</span>
              </div>
            </div>
            <div className="group">
              <button className="tbtn bold active">B</button>
              <button className="tbtn italic">I</button>
              <button className="tbtn under">U</button>
              <button className="tbtn dot"></button>
            </div>
            <div className="group">
              <button className="tbtn">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6">
                  <path d="M4 6h16M4 12h10M4 18h16"/></svg>
              </button>
              <button className="tbtn">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6">
                  <path d="M4 6h16M7 12h10M4 18h16"/></svg>
              </button>
              <button className="tbtn">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6">
                  <circle cx="5" cy="7" r="1.2"/><path d="M9 7h11M9 12h11M9 17h11"/><circle cx="5" cy="12" r="1.2"/><circle cx="5" cy="17" r="1.2"/></svg>
              </button>
            </div>
            <div className="group">
              <button className="tbtn">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6">
                  <path d="M10 14a4 4 0 0 0 5.66 0l3-3a4 4 0 0 0-5.66-5.66l-1 1"/>
                  <path d="M14 10a4 4 0 0 0-5.66 0l-3 3a4 4 0 0 0 5.66 5.66l1-1"/></svg>
              </button>
              <button className="tbtn">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6">
                  <rect x="4" y="5" width="16" height="14"/><path d="M4 15l5-5 5 5M14 13l3-3 3 3"/></svg>
              </button>
            </div>
            <div className="group" style={{ marginLeft: 'auto' }}>
              <button className="tbtn" title="AI 도움">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6">
                  <path d="M12 3l2 5 5 2-5 2-2 5-2-5-5-2 5-2z"/></svg>
              </button>
            </div>
          </div>

          <div className="editor-body">
            <p style={{ margin: '0 0 1.3em' }}>
              이십대의 이별은 세상이 무너지는 일이었는데, 서른이 되고 나니 이별은 조용히 찾아와서 조용히 떠난다.
              떠난 자리에 먼지처럼 쌓이는 감정들을 하나씩 털어내는 것이 더 오래 걸린다는 걸 이제는 안다.
            </p>
            <p style={{ margin: '0 0 1.3em', position: 'relative' }}>
              그는 마지막 인사조차 하지 않았다. 어떤 이별은 말없이 완성된다. 대답 없는 질문들만 남기고.{' '}
              <em className="hl">우리는 헤어졌다는 문장 하나로</em> 설명될 수 없는 것들. 그 사이에 놓인 무수한 오후와, 함께 듣던 노래와, 두 번 다시 웃지 않을 농담 같은 것들.

              {/* floating mini-toolbar over selection */}
              <span className="float-tools" style={{ left: 180, top: '-38px' }}>
                <button className="tbtn bold">B</button>
                <button className="tbtn italic">I</button>
                <button className="tbtn under">U</button>
                <button className="tbtn">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6">
                    <path d="M4 6h16M4 12h10M4 18h16"/></svg>
                </button>
                <button className="tbtn">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6">
                    <path d="M4 6h16M7 12h10M4 18h16"/></svg>
                </button>
                <button className="tbtn">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6">
                    <path d="M10 14a4 4 0 0 0 5.66 0l3-3a4 4 0 0 0-5.66-5.66"/><path d="M14 10a4 4 0 0 0-5.66 0l-3 3a4 4 0 0 0 5.66 5.66"/></svg>
                </button>
              </span>
            </p>
            <p style={{ margin: '0 0 1.3em' }}>
              서른은 이별의 나이다. 청춘의 마지막 정거장에서 많은 것들이 한꺼번에 내린다. 친구들의 연락이 뜸해지고,
              한때 소중했던 취향들이 낯설어진다.<span className="cursor"></span>
            </p>
            <p style={{ margin: 0, color: 'var(--ink-faint)' }}>
              계속 쓰기…
            </p>
          </div>

          <div className="editor-footer">
            <span>글자 · 342 / 제한 없음 · 3분 분량</span>
            <span style={{ display: 'flex', gap: 16 }}>
              <span>공개 · 전체 공개 ▾</span>
              <span>댓글 · 허용 ✓</span>
            </span>
          </div>
        </div>

        {/* Tips */}
        <div style={{ marginTop: 32, display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 24 }}>
          {[
            ['01', '작게 시작하기', '한 문장으로 시작해도 괜찮습니다. 짧은 글이 오래 남습니다.'],
            ['02', '솔직하게', '꾸미지 않은 감정은 언젠가 누군가에게 위로가 됩니다.'],
            ['03', '나의 속도로', '하루에 한 번, 꾸준히. 스트릭이 당신의 기록이 됩니다.'],
          ].map(([n, t, d]) => (
            <div key={n} style={{ borderTop: '1px solid var(--rule)', paddingTop: 14 }}>
              <div className="label" style={{ fontSize: 10, marginBottom: 8 }}>{n} · TIP</div>
              <div style={{ fontFamily: 'var(--f-kr-serif)', fontSize: 16, fontWeight: 700, marginBottom: 6, color: 'var(--ink)' }}>{t}</div>
              <div style={{ fontSize: 12.5, color: 'var(--ink-mute)', lineHeight: 1.6 }}>{d}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

window.WriteScreen = WriteScreen;
