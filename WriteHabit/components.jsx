// WriteHabit shared components

const Logo = ({ small }) => (
  <span className="logo" style={small ? { fontSize: 18 } : {}}>
    <span className="w">Write</span><span className="h">Habit</span>
  </span>
);

const Tabs = ({ active = 'write' }) => (
  <nav className="tabs">
    {[
      ['write', 'Write'],
      ['archive', 'Archive'],
      ['browse', 'Browse'],
      ['profile', 'Profile'],
    ].map(([k, label]) => (
      <a key={k} href="#" className={active === k ? 'active' : ''}>{label}</a>
    ))}
  </nav>
);

const ThemeToggle = () => {
  const toggle = () => {
    window.parent.postMessage({ type: '__writehabit_toggle_theme' }, '*');
    window.dispatchEvent(new CustomEvent('__writehabit_toggle_theme'));
  };
  return (
    <button onClick={toggle} title="테마 전환"
      style={{
        width: 32, height: 32, borderRadius: 999,
        border: '1px solid var(--rule-soft)',
        background: 'transparent', color: 'var(--ink-soft)',
        cursor: 'pointer', display: 'inline-flex',
        alignItems: 'center', justifyContent: 'center',
        padding: 0,
      }}>
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6">
        <path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z" />
      </svg>
    </button>
  );
};

const TopBar = ({ active = 'write', right }) => (
  <header className="topbar">
    <div style={{ display: 'flex', alignItems: 'center', gap: 40 }}>
      <Logo />
      <Tabs active={active} />
    </div>
    <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
      {right || (
        <>
          <span className="meta" style={{ fontSize: 11 }}>2026 · 04 · 23 · 목</span>
          <ThemeToggle />
          <button className="btn sm solid">
            <span>글쓰기</span>
            <span className="arr">→</span>
          </button>
          <div className="avatar" style={{ width: 32, height: 32, fontSize: 13 }}>민</div>
        </>
      )}
    </div>
  </header>
);

// Simple SVG icons (monoline, thin)
const I = {
  heart: (p) => (
    <svg {...p} width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6">
      <path d="M12 21s-7-4.5-9.5-9A5.5 5.5 0 0 1 12 6a5.5 5.5 0 0 1 9.5 6C19 16.5 12 21 12 21z" />
    </svg>
  ),
  comment: (p) => (
    <svg {...p} width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6">
      <path d="M4 5h16v11H8l-4 4V5z" />
    </svg>
  ),
  bookmark: (p) => (
    <svg {...p} width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6">
      <path d="M6 3h12v18l-6-4-6 4V3z" />
    </svg>
  ),
  share: (p) => (
    <svg {...p} width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6">
      <path d="M4 12v7h16v-7M12 3v13M8 7l4-4 4 4"/>
    </svg>
  ),
  arrow: (p) => (
    <svg {...p} width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6">
      <path d="M5 12h14M13 6l6 6-6 6"/>
    </svg>
  ),
};

// Placeholder sample posts
const SAMPLE_POSTS = [
  {
    id: 1,
    title: '서른의 이별은 조금 다른 얼굴을 하고 있다',
    body: '이십대의 이별은 세상이 무너지는 일이었는데, 서른이 되고 나니 이별은 조용히 찾아와서 조용히 떠난다. 떠난 자리에 먼지처럼 쌓이는 감정들을 하나씩 털어내는 것이 더 오래 걸린다는 걸 이제는 안다.',
    author: '이해인',
    handle: 'haein',
    initial: '이',
    time: '12분 전',
    read: '3분',
    likes: 42, comments: 7, bookmarks: 12,
    liked: true,
  },
  {
    id: 2,
    title: '마지막 전화',
    body: '전화를 끊는 소리가 이렇게 또렷하게 들린 적이 있었나 싶었다. 딸깍, 하고 세상이 조용해지는 그 순간. 나는 한참을 그 자리에 앉아 있었고, 창밖으로는 비가 오고 있었는지 해가 지고 있었는지 기억이 나지 않는다.',
    author: '정윤',
    handle: 'yoonn',
    initial: '정',
    time: '34분 전',
    read: '2분',
    likes: 28, comments: 3, bookmarks: 5,
  },
  {
    id: 3,
    title: '이별에게도 유통기한이 있다면',
    body: '냉장고에 오래 넣어둔 감정도 언젠가는 상한다. 상한 감정을 붙잡고 있는 것만큼 소모적인 일이 없다는 걸, 나는 서른둘의 봄에 알았다. 그러니까 이제는 놓아주어야 한다. 맛없어진 것들을.',
    author: '김도현',
    handle: 'dohyun',
    initial: '김',
    time: '1시간 전',
    read: '4분',
    likes: 67, comments: 14, bookmarks: 23,
  },
  {
    id: 4,
    title: '버스 정류장에서',
    body: '3번 버스를 기다리는데, 갑자기 네가 타고 내리던 7번 버스가 먼저 도착했다. 나는 타지 않을 거면서도 괜히 일어나서 문 앞까지 걸어갔다. 그리고 다시 자리에 앉았다. 버스는 떠났고, 나도 언젠가 떠날 것이다.',
    author: '박서연',
    handle: 'seoyeon',
    initial: '박',
    time: '2시간 전',
    read: '2분',
    likes: 91, comments: 18, bookmarks: 34,
  },
  {
    id: 5,
    title: '헤어진 뒤 처음으로 혼자 간 식당',
    body: '둘이서만 가던 곳을 혼자 가는 일이 이렇게 어려운 일인 줄 몰랐다. 사장님은 아무것도 묻지 않으셨고, 나는 평소처럼 2인분을 주문할 뻔했다. 김치찌개 1인분이요, 라고 말하는 데 삼 년이 걸렸다.',
    author: '최민재',
    handle: 'minjae',
    initial: '최',
    time: '3시간 전',
    read: '3분',
    likes: 54, comments: 9, bookmarks: 11,
  },
  {
    id: 6,
    title: '관계의 질량 보존 법칙',
    body: '사라진 사랑은 어디로 갈까. 한때 분명히 존재했던 감정의 총량은 어디서 어떻게 다시 나타나는 걸까. 어쩌면 그건 다음 계절, 다음 사람, 아니면 완전히 다른 형태로 내게 돌아올지도 모른다. 에너지처럼.',
    author: '한지우',
    handle: 'jiwoo',
    initial: '한',
    time: '5시간 전',
    read: '5분',
    likes: 38, comments: 6, bookmarks: 14,
  },
];

const KEYWORDS_ARCHIVE = [
  { date: '04·22', word: '행복', count: 1842, eng: 'HAPPINESS' },
  { date: '04·21', word: '청춘', count: 2104, eng: 'YOUTH' },
  { date: '04·20', word: '미래', count: 1567, eng: 'FUTURE' },
  { date: '04·19', word: '고독', count: 1389, eng: 'SOLITUDE' },
  { date: '04·18', word: '기억', count: 1924, eng: 'MEMORY' },
  { date: '04·17', word: '용기', count: 1231, eng: 'COURAGE' },
  { date: '04·16', word: '새벽', count: 1678, eng: 'DAWN' },
  { date: '04·15', word: '후회', count: 1433, eng: 'REGRET' },
  { date: '04·14', word: '설렘', count: 1912, eng: 'FLUTTER' },
  { date: '04·13', word: '침묵', count: 987, eng: 'SILENCE' },
];

Object.assign(window, {
  Logo, Tabs, TopBar, ThemeToggle, I,
  SAMPLE_POSTS, KEYWORDS_ARCHIVE,
});
