// Screen 6: Login / Signup
const LoginScreen = () => {
  return (
    <div className="wh" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr' }}>
      {/* LEFT: keyword side */}
      <aside style={{
        background: 'var(--paper-2)',
        padding: '56px 52px',
        display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
        borderRight: '1px solid var(--rule-soft)',
      }}>
        <Logo />

        <div>
          <div className="eyebrow" style={{ marginBottom: 14 }}>오늘의 키워드 · 2026·04·23 · NO. 0342</div>
          <div style={{
            fontFamily: 'var(--f-kr-serif)', fontWeight: 700, fontSize: 96,
            letterSpacing: '-0.03em', lineHeight: 0.95, color: 'var(--ink)', margin: 0,
          }}>
            이별
          </div>
          <div style={{ fontFamily: 'var(--f-serif)', fontSize: 28, color: 'var(--ink-faint)', letterSpacing: '0.05em', marginTop: 4 }}>
            FAREWELL
          </div>

          <p style={{ fontFamily: 'var(--f-kr-serif)', fontSize: 17, lineHeight: 1.8, color: 'var(--ink-soft)', marginTop: 36, maxWidth: '36ch' }}>
            하루에 한 번,<br/>
            하나의 키워드에<br/>
            당신의 문장을 남겨보세요.
          </p>

          <div style={{ display: 'flex', gap: 40, marginTop: 56, paddingTop: 24, borderTop: '1px solid var(--rule-soft)' }}>
            {[['342', '일째'], ['28,419', '명의 작가'], ['428K', '편의 글']].map(([n, l]) => (
              <div key={l}>
                <div style={{ fontFamily: 'var(--f-latin)', fontWeight: 700, fontSize: 24, letterSpacing: '-0.03em', color: 'var(--ink)' }}>{n}</div>
                <div className="meta" style={{ fontSize: 10.5, marginTop: 2 }}>{l}</div>
              </div>
            ))}
          </div>
        </div>

        <div className="meta" style={{ fontSize: 10.5 }}>© 2026 WriteHabit · v1.0.2</div>
      </aside>

      {/* RIGHT: form */}
      <main style={{
        padding: '56px 80px',
        display: 'flex', flexDirection: 'column', justifyContent: 'center',
      }}>
        <div style={{ maxWidth: 380 }}>
          <div className="eyebrow" style={{ marginBottom: 12 }}>LOGIN · 로그인</div>
          <h2 style={{
            fontFamily: 'var(--f-kr-serif)', fontWeight: 700, fontSize: 40,
            letterSpacing: '-0.025em', lineHeight: 1.1, margin: '0 0 10px', color: 'var(--ink)',
          }}>
            다시 만나서<br/>반갑습니다.
          </h2>
          <p style={{ color: 'var(--ink-mute)', fontSize: 14, margin: '0 0 40px' }}>
            어제의 당신이 남긴 글이 기다리고 있어요.
          </p>

          <div style={{ marginBottom: 20 }}>
            <div className="label" style={{ fontSize: 10, marginBottom: 6 }}>01 · EMAIL</div>
            <input className="field" defaultValue="minji@writehabit.kr" />
          </div>
          <div style={{ marginBottom: 32 }}>
            <div className="label" style={{ fontSize: 10, marginBottom: 6 }}>02 · PASSWORD</div>
            <input className="field" type="password" defaultValue="··············" />
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 10, fontSize: 12 }}>
              <label style={{ display: 'inline-flex', alignItems: 'center', gap: 8, color: 'var(--ink-soft)' }}>
                <span style={{ width: 12, height: 12, border: '1px solid var(--ink)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, background: 'var(--ink)', color: 'var(--paper)' }}>✓</span>
                로그인 상태 유지
              </label>
              <a href="#" style={{ color: 'var(--ink-mute)', textDecoration: 'underline', textUnderlineOffset: 3 }}>비밀번호 찾기</a>
            </div>
          </div>

          <button className="btn solid" style={{ width: '100%', justifyContent: 'center', padding: '14px 20px', fontSize: 13 }}>
            로그인 <span className="arr">→</span>
          </button>

          <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '28px 0', color: 'var(--ink-faint)', fontFamily: 'var(--f-mono)', fontSize: 10.5 }}>
            <span className="rule-soft" style={{ flex: 1 }}></span>
            <span>OR</span>
            <span className="rule-soft" style={{ flex: 1 }}></span>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <button className="btn" style={{ justifyContent: 'center' }}>Google</button>
            <button className="btn" style={{ justifyContent: 'center' }}>Apple</button>
          </div>

          <p style={{ marginTop: 36, fontSize: 12.5, color: 'var(--ink-mute)', textAlign: 'center' }}>
            아직 계정이 없으신가요? <a href="#" style={{ color: 'var(--ink)', fontWeight: 600, textDecoration: 'underline', textUnderlineOffset: 3 }}>회원가입</a>
          </p>
        </div>
      </main>
    </div>
  );
};

window.LoginScreen = LoginScreen;
