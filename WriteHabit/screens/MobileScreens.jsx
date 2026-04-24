// Screen 7: Mobile feed (iOS-ish shell drawn in CSS)
const MobileFeed = () => {
  return (
    <div className="wh" style={{ background: '#cbc6b8', padding: 32 }}>
      <div style={{
        margin: '0 auto',
        width: 360, height: 740,
        background: 'var(--paper)',
        borderRadius: 44,
        border: '10px solid #1b1a15',
        overflow: 'hidden',
        position: 'relative',
        boxShadow: '0 20px 60px rgba(0,0,0,0.18)',
      }}>
        {/* status bar */}
        <div style={{
          height: 42, display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '14px 24px 4px', fontFamily: 'var(--f-latin)', fontSize: 13, fontWeight: 600, color: 'var(--ink)'
        }}>
          <span>9:41</span>
          <div style={{ width: 100, height: 26, background: '#1b1a15', borderRadius: 999, marginTop: -4 }}></div>
          <span style={{ display: 'inline-flex', gap: 4, alignItems: 'center' }}>
            <span style={{ fontSize: 10 }}>􀙇</span>
            <span style={{ width: 20, height: 10, border: '1px solid var(--ink)', borderRadius: 2, position: 'relative' }}>
              <span style={{ position: 'absolute', inset: 1, background: 'var(--ink)', width: '80%' }}></span>
            </span>
          </span>
        </div>

        {/* top */}
        <div style={{ padding: '12px 20px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Logo small />
          <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
            <span style={{ fontSize: 16 }}>🔔</span>
            <div className="avatar" style={{ width: 28, height: 28, fontSize: 11 }}>민</div>
          </div>
        </div>

        {/* keyword card */}
        <div style={{
          margin: '16px 20px 0',
          padding: '18px 20px',
          background: 'var(--paper-2)',
          border: '1px solid var(--rule-soft)',
          borderRadius: 4,
        }}>
          <div className="eyebrow" style={{ fontSize: 9, marginBottom: 8 }}>TODAY · 04·23 · NO. 0342</div>
          <div style={{ fontFamily: 'var(--f-kr-serif)', fontWeight: 700, fontSize: 44, letterSpacing: '-0.02em', lineHeight: 1, color: 'var(--ink)' }}>
            이별
          </div>
          <div style={{ fontFamily: 'var(--f-serif)', fontSize: 14, color: 'var(--ink-faint)', letterSpacing: '0.05em', marginTop: 2 }}>FAREWELL</div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 14 }}>
            <span className="meta" style={{ fontSize: 10 }}>1,247 편 · 14H 남음</span>
            <button className="btn sm accent" style={{ fontSize: 10.5, padding: '6px 10px' }}>쓰기 →</button>
          </div>
        </div>

        {/* posts */}
        <div style={{ padding: '4px 20px 12px', overflow: 'hidden' }}>
          {SAMPLE_POSTS.slice(0, 4).map((p, i) => (
            <div key={p.id} style={{ padding: '14px 0', borderBottom: '1px solid var(--rule-ghost)' }}>
              <div style={{ display: 'flex', gap: 10, alignItems: 'center', marginBottom: 8 }}>
                <div className="avatar" style={{ width: 22, height: 22, fontSize: 10 }}>{p.initial}</div>
                <span style={{ fontSize: 11.5, fontWeight: 600, color: 'var(--ink)' }}>{p.author}</span>
                <span className="meta" style={{ fontSize: 10 }}>· {p.time}</span>
              </div>
              <h3 style={{
                fontFamily: 'var(--f-kr-serif)', fontWeight: 700, fontSize: 15,
                letterSpacing: '-0.02em', lineHeight: 1.25, margin: '0 0 5px', color: 'var(--ink)',
              }}>{p.title}</h3>
              <p style={{
                fontSize: 12, color: 'var(--ink-mute)', lineHeight: 1.6, margin: 0,
                display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
              }}>{p.body}</p>
              <div style={{ display: 'flex', gap: 14, marginTop: 10, fontFamily: 'var(--f-mono)', fontSize: 10, color: 'var(--ink-mute)' }}>
                <span style={{ color: p.liked ? 'var(--accent)' : 'inherit' }}>♥ {p.likes}</span>
                <span>💬 {p.comments}</span>
                <span>🔖 {p.bookmarks}</span>
              </div>
            </div>
          ))}
        </div>

        {/* tab bar */}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0,
          borderTop: '1px solid var(--rule-soft)', background: 'var(--paper)',
          padding: '10px 24px 28px',
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        }}>
          {[['✎', 'Write', true], ['▤', 'Archive'], ['☷', 'Browse'], ['◉', 'Profile']].map(([icon, l, a], i) => (
            <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3, color: a ? 'var(--ink)' : 'var(--ink-faint)' }}>
              <span style={{ fontSize: 18, fontFamily: 'var(--f-latin)' }}>{icon}</span>
              <span style={{ fontFamily: 'var(--f-latin)', fontSize: 9.5, letterSpacing: '0.1em', textTransform: 'uppercase', fontWeight: 500 }}>{l}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

// Mobile writing screen
const MobileWrite = () => {
  return (
    <div className="wh" style={{ background: '#cbc6b8', padding: 32 }}>
      <div style={{
        margin: '0 auto',
        width: 360, height: 740,
        background: 'var(--paper)',
        borderRadius: 44,
        border: '10px solid #1b1a15',
        overflow: 'hidden',
        position: 'relative',
        boxShadow: '0 20px 60px rgba(0,0,0,0.18)',
      }}>
        <div style={{
          height: 42, display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '14px 24px 4px', fontFamily: 'var(--f-latin)', fontSize: 13, fontWeight: 600, color: 'var(--ink)'
        }}>
          <span>9:41</span>
          <div style={{ width: 100, height: 26, background: '#1b1a15', borderRadius: 999, marginTop: -4 }}></div>
          <span>100%</span>
        </div>

        <div style={{ padding: '12px 20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid var(--rule-ghost)' }}>
          <span style={{ fontFamily: 'var(--f-mono)', fontSize: 13 }}>✕</span>
          <span className="eyebrow" style={{ fontSize: 10 }}>NO. 0342 · 이별</span>
          <span style={{ fontSize: 11, fontWeight: 600, color: 'var(--accent)' }}>발행</span>
        </div>

        <div style={{ padding: '20px' }}>
          <div className="meta" style={{ fontSize: 9.5, marginBottom: 6 }}>자동저장 · 2분 전 · 342자</div>
          <div style={{
            fontFamily: 'var(--f-kr-serif)', fontSize: 22, fontWeight: 700,
            letterSpacing: '-0.02em', lineHeight: 1.25, color: 'var(--ink)', marginBottom: 14,
            paddingBottom: 12, borderBottom: '1px solid var(--rule-ghost)'
          }}>
            서른의 이별은<br/>조금 다른 얼굴을 하고 있다
          </div>
          <div style={{
            fontFamily: 'var(--f-kr)', fontSize: 14, lineHeight: 1.8,
            color: 'var(--ink-soft)',
          }}>
            <p style={{ margin: '0 0 1em' }}>
              이십대의 이별은 세상이 무너지는 일이었는데, 서른이 되고 나니 이별은 조용히 찾아와서 조용히 떠난다.
            </p>
            <p style={{ margin: '0 0 1em' }}>
              떠난 자리에 먼지처럼 쌓이는 감정들을 하나씩 털어내는 것이 더 오래 걸린다는 걸 이제는 안다.
              어떤 이별은 말없이 완성된다<span className="cursor"></span>
            </p>
          </div>
        </div>

        {/* mini toolbar at bottom */}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0,
          borderTop: '1px solid var(--rule-soft)', background: 'var(--paper-2)',
          padding: '10px 14px 30px',
          display: 'flex', gap: 2, alignItems: 'center',
          overflow: 'hidden',
        }}>
          {['B', 'I', 'U', '•', '❝', '↔', '🖼', '✨'].map((c, i) => (
            <span key={i} className="tbtn" style={{
              fontStyle: c === 'I' ? 'italic' : 'normal',
              fontWeight: c === 'B' ? 700 : 500,
              textDecoration: c === 'U' ? 'underline' : 'none',
              fontSize: 13,
            }}>{c}</span>
          ))}
          <span style={{ marginLeft: 'auto', fontFamily: 'var(--f-mono)', fontSize: 10, color: 'var(--ink-mute)' }}>3분 분량</span>
        </div>
      </div>
    </div>
  );
};

window.MobileFeed = MobileFeed;
window.MobileWrite = MobileWrite;
