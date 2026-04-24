// Screen 1: Main Feed
const FeedScreen = () => {
  return (
    <div className="wh">
      <TopBar active="browse" />

      <div className="wrap" style={{ paddingTop: 32 }}>
        {/* Daily keyword hero */}
        <section className="kw-hero">
          <div>
            <div className="kw-eyebrow">
              <span className="dash"></span>
              <span>오늘의 키워드 · Daily Keyword · No. 0342</span>
            </div>
            <h1 className="kw-title">
              <span className="kor-serif">이별</span>
              <span style={{ color: 'var(--ink-faint)', fontWeight: 300, fontSize: 54, marginLeft: 18 }}>
                Farewell
              </span>
            </h1>
            <p className="kw-sub">
              우리는 매일 무언가와 헤어진다. 오늘은 당신의 이별을 글로 남겨보세요.
              그 순간의 공기, 감정의 결, 남겨진 자리까지 — 가장 작은 순간이 가장 오래 남습니다.
            </p>
          </div>
          <div className="kw-side">
            <span className="label" style={{ marginBottom: 4 }}>오늘 작성된 글</span>
            <span className="big">1,247</span>
            <span className="meta">마감까지 · 14H 32M</span>
            <button className="btn accent sm" style={{ marginTop: 10, alignSelf: 'flex-end' }}>
              오늘의 글 쓰기 <span className="arr">→</span>
            </button>
          </div>
        </section>

        {/* Filter bar */}
        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          padding: '20px 0 8px'
        }}>
          <div style={{ display: 'flex', gap: 8 }}>
            <span className="chip active">최신</span>
            <span className="chip">인기</span>
            <span className="chip">팔로잉</span>
            <span className="chip">짧은 글</span>
            <span className="chip">긴 글</span>
          </div>
          <div className="meta" style={{ fontSize: 11 }}>정렬 · 최신순 ▾</div>
        </div>

        {/* Feed */}
        <div className="feed">
          {SAMPLE_POSTS.map((p, i) => (
            <article className="entry" key={p.id}>
              <div className="num">
                {String(i + 1).padStart(2, '0')} <span style={{ opacity: 0.5 }}>/ 1247</span>
              </div>
              <div>
                <h3><span className="kor-serif">{p.title}</span></h3>
                <p>{p.body}</p>
                <div className="byline">
                  <div className="avatar" style={{ width: 26, height: 26, fontSize: 11 }}>{p.initial}</div>
                  <span className="author">{p.author}</span>
                  <span className="sep">·</span>
                  <span>@{p.handle}</span>
                  <span className="sep">·</span>
                  <span>{p.time}</span>
                  <span className="sep">·</span>
                  <span>읽기 {p.read}</span>
                </div>
              </div>
              <div className="stats">
                <span className="row">
                  <I.heart style={{ color: p.liked ? 'var(--accent)' : 'currentColor' }} />
                  <span className={p.liked ? 'n on' : 'n'}>{p.likes}</span>
                </span>
                <span className="row">
                  <I.comment /><span className="n">{p.comments}</span>
                </span>
                <span className="row">
                  <I.bookmark /><span className="n">{p.bookmarks}</span>
                </span>
              </div>
            </article>
          ))}
          <div style={{ textAlign: 'center', padding: '32px 0 16px' }}>
            <button className="btn ghost">더 많은 글 보기 <span className="arr">↓</span></button>
          </div>
        </div>
      </div>
    </div>
  );
};

window.FeedScreen = FeedScreen;
