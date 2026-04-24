// WriteHabit - Real Working Website
const { useState, useEffect } = React;

// Sample Data
const SAMPLE_KEYWORDS = [
    { date: '04·23', word: '이별', eng: 'FAREWELL', count: 1247 },
    { date: '04·22', word: '행복', eng: 'HAPPINESS', count: 1842 },
    { date: '04·21', word: '청춘', eng: 'YOUTH', count: 2104 },
    { date: '04·20', word: '미래', eng: 'FUTURE', count: 1567 },
    { date: '04·19', word: '고독', eng: 'SOLITUDE', count: 1389 },
];

const SAMPLE_POSTS = [
    { id: 1, title: '서른의 이별은 조금 다른 얼굴을 하고 있다', body: '이십대의 이별은 세상이 무너지는 일이었는데, 서른이 되고 나니 이별은 조용히 찾아와서 조용히 떠난다...', author: '이해인', handle: 'haein', initial: '이', time: '12분 전', read: '3분', likes: 42, comments: 7, liked: true },
    { id: 2, title: '마지막 전화', body: '전화를 끊는 소리가 이렇게 또렷하게 들린 적이 있었나 싶었다. 딸깍, 하고 세상이 조용해지는 그 순간...', author: '정윤', handle: 'yoonn', initial: '정', time: '34분 전', read: '2분', likes: 28, comments: 3 },
    { id: 3, title: '이별에게도 유통기한이 있다면', body: '냉장고에 오래 넣어둔 감정도 언젠가는 상한다. 상한 감정을 붙잡고 있는 것만큼 소모적인 일이 없다...', author: '김도현', handle: 'dohyun', initial: '김', time: '1시간 전', read: '4분', likes: 67, comments: 14 },
];

const SAMPLE_COMMENTS = [
    { id: 1, author: '박서연', initial: '박', time: '2시간 전', body: '이 글을 읽고 나도 모르게 눈물이 났어요. 정말 공감됩니다.' },
    { id: 2, author: '김민수', initial: '김', time: '1시간 전', body: '서른의 이별은 정말 다르더라고요. 조용한 슬픔...' },
];

// Logo Component
const Logo = ({ size }) =>
    React.createElement('a', { href: '#', className: 'logo', style: size ? { fontSize: size } : {} },
        React.createElement('span', { className: 'w' }, 'Write'),
        React.createElement('span', { className: 'h' }, 'Habit')
    );

// TopBar Component
const TopBar = ({ activeTab, onTabChange, user }) => {
    const tabs = [['feed', 'Browse'], ['write', 'Write'], ['archive', 'Archive'], ['profile', 'Profile']];
    
    return React.createElement('header', { className: 'topbar' },
        React.createElement('div', { style: { display: 'flex', alignItems: 'center', gap: 40 } },
            React.createElement(Logo),
            React.createElement('nav', { className: 'tabs' },
                tabs.map(([key, label]) =>
                    React.createElement('a', {
                        key,
                        href: '#',
                        className: activeTab === key ? 'active' : '',
                        onClick: (e) => { e.preventDefault(); onTabChange(key); }
                    }, label)
                )
            )
        ),
        React.createElement('div', { style: { display: 'flex', alignItems: 'center', gap: 16 } },
            React.createElement('span', { style: { fontFamily: 'var(--f-mono)', fontSize: 11, color: 'var(--ink-mute)' } }, 
                new Date().toLocaleDateString('ko-KR', { year: 'numeric', month: '2-digit', day: '2-digit', weekday: 'short' }).replace(/\./g, ' · ')
            ),
            user ? React.createElement('div', { className: 'avatar', style: { width: 32, height: 32, fontSize: 13, cursor: 'pointer' }, onClick: () => onTabChange('profile') }, user.initial) :
                React.createElement('a', { href: '#', className: 'btn sm', onClick: (e) => { e.preventDefault(); onTabChange('login'); } }, '로그인')
        )
    );
};

// Feed Screen
const FeedScreen = ({ onPostClick, onWriteClick }) => {
    const [posts, setPosts] = useState(SAMPLE_POSTS);
    const [filter, setFilter] = useState('최신');
    
    const handleLike = (id, e) => {
        e.stopPropagation();
        setPosts(posts.map(p => p.id === id ? { ...p, liked: !p.liked, likes: p.liked ? p.likes - 1 : p.likes + 1 } : p));
    };

    const chips = ['최신', '인기', '팔로잉', '짧은 글', '긴 글'];

    return React.createElement('div', { className: 'wrap' },
        // Keyword Hero
        React.createElement('section', { className: 'kw-hero' },
            React.createElement('div', null,
                React.createElement('div', { className: 'kw-eyebrow' },
                    React.createElement('span', { className: 'dash' }),
                    React.createElement('span', null, "오늘의 키워드 · Daily Keyword · No. 0342")
                ),
                React.createElement('h1', { className: 'kw-title' },
                    React.createElement('span', { className: 'kor' }, '이별'),
                    React.createElement('span', { style: { color: 'var(--ink-faint)', fontWeight: 300, fontSize: 54, marginLeft: 18 } }, 'Farewell')
                ),
                React.createElement('p', { className: 'kw-sub' },
                    '우리는 매일 무언가와 헤어진다. 오늘은 당신의 이별을 글로 남겨보세요. 그 순간의 공기, 감정의 결, 남겨진 자리까지 — 가장 작은 순간이 가장 오래 남습니다.'
                )
            ),
            React.createElement('div', { className: 'kw-side' },
                React.createElement('span', { className: 'label', style: { marginBottom: 4 } }, '오늘 작성된 글'),
                React.createElement('span', { className: 'big' }, '1,247'),
                React.createElement('span', { style: { fontFamily: 'var(--f-mono)', fontSize: 11, color: 'var(--ink-mute)' } }, '마감까지 · 14H 32M'),
                React.createElement('button', { className: 'btn accent sm', style: { marginTop: 10, alignSelf: 'flex-end' }, onClick: onWriteClick },
                    '오늘의 글 쓰기 ', React.createElement('span', { className: 'arr' }, '→')
                )
            )
        ),
        // Filter Bar
        React.createElement('div', { style: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '20px 0 8px' } },
            React.createElement('div', { style: { display: 'flex', gap: 8 } },
                chips.map(chip => 
                    React.createElement('span', { 
                        key: chip, 
                        className: `chip ${filter === chip ? 'active' : ''}`,
                        onClick: () => setFilter(chip)
                    }, chip)
                )
            ),
            React.createElement('div', { style: { fontFamily: 'var(--f-mono)', fontSize: 11, color: 'var(--ink-mute)' } }, '정렬 · 최신순 ▾')
        ),
        // Feed
        React.createElement('div', { className: 'feed' },
            posts.map((post, idx) =>
                React.createElement('article', { 
                    className: 'entry', 
                    key: post.id,
                    onClick: () => onPostClick(post)
                },
                    React.createElement('div', { className: 'num' }, String(idx + 1).padStart(2, '0')),
                    React.createElement('div', null,
                        React.createElement('h3', null, React.createElement('span', { className: 'kor' }, post.title)),
                        React.createElement('p', null, post.body),
                        React.createElement('div', { className: 'byline' },
                            React.createElement('span', { className: 'author' }, post.author),
                            React.createElement('span', null, '·'),
                            React.createElement('span', null, '@' + post.handle),
                            React.createElement('span', null, '·'),
                            React.createElement('span', null, post.read)
                        )
                    ),
                    React.createElement('div', { className: 'stats' },
                        React.createElement('div', { className: 'row', onClick: (e) => handleLike(post.id, e) },
                            React.createElement('span', null, '♥'),
                            React.createElement('span', { className: post.liked ? 'n on' : 'n' }, post.likes)
                        ),
                        React.createElement('div', { className: 'row' },
                            React.createElement('span', null, '💬'),
                            React.createElement('span', { className: 'n' }, post.comments)
                        )
                    )
                )
            )
        )
    );
};

// Write Screen
const WriteScreen = ({ user }) => {
    const [content, setContent] = useState('');
    const [charCount, setCharCount] = useState(0);
    const [saved, setSaved] = useState(false);
    const [publishing, setPublishing] = useState(false);
    
    const today = SAMPLE_KEYWORDS[0];
    
    useEffect(() => {
        const draft = localStorage.getItem('writeDraft');
        if (draft) {
            setContent(draft);
            setCharCount(draft.length);
        }
    }, []);
    
    const handleInput = (e) => {
        const text = e.target.value;
        setContent(text);
        setCharCount(text.length);
        setSaved(false);
    };
    
    const handlePublish = () => {
        if (!content.trim()) return alert('내용을 입력해주세요.');
        setPublishing(true);
        setTimeout(() => {
            alert('글이 발행되었습니다! 🎉');
            localStorage.removeItem('writeDraft');
            setContent('');
            setCharCount(0);
            setPublishing(false);
        }, 800);
    };
    
    const handleSave = () => {
        localStorage.setItem('writeDraft', content);
        setSaved(true);
        setTimeout(() => setSaved(false), 2000);
    };

    return React.createElement('div', { className: 'wrap' },
        React.createElement('div', { className: 'kw-hero' },
            React.createElement('div', null,
                React.createElement('div', { className: 'kw-eyebrow' },
                    React.createElement('span', { className: 'dash' }),
                    React.createElement('span', null, "TODAY'S KEYWORD")
                ),
                React.createElement('h1', { className: 'kw-title' },
                    React.createElement('span', { className: 'kor' }, today.word)
                ),
                React.createElement('p', { className: 'kw-sub' },
                    '우리는 매일 무언가와 헤어진다. 오늘은 당신의 이별을 글로 남겨 보세요.'
                )
            ),
            React.createElement('div', { className: 'kw-side' },
                React.createElement('span', { className: 'big' }, 'NO. 0342'),
                React.createElement('span', { className: 'small' }, today.eng)
            )
        ),
        React.createElement('div', { className: 'editor-shell' },
            React.createElement('div', { className: 'editor-toolbar' },
                React.createElement('div', { className: 'group' },
                    React.createElement('button', { className: 'tbtn bold' }, 'B'),
                    React.createElement('button', { className: 'tbtn italic' }, 'I'),
                    React.createElement('button', { className: 'tbtn' }, 'U')
                ),
                React.createElement('div', { className: 'group' },
                    React.createElement('button', { className: 'tbtn' }, '16px ▾')
                )
            ),
            React.createElement('textarea', {
                className: 'editor-body',
                placeholder: '여기에 글을 써보세요...',
                value: content,
                onChange: handleInput
            }),
            React.createElement('div', { className: 'editor-footer' },
                React.createElement('span', null, charCount, ' / 2000'),
                React.createElement('div', { style: { display: 'flex', gap: 12, alignItems: 'center' } },
                    saved && React.createElement('span', { style: { color: 'var(--ink-mute)', fontSize: 11 } }, '임시저장됨 ✓'),
                    React.createElement('button', { className: 'btn ghost', onClick: handleSave }, '임시저장'),
                    React.createElement('button', { className: 'btn solid', onClick: handlePublish, disabled: publishing }, 
                        publishing ? '발행 중...' : '발행하기'
                    )
                )
            )
        )
    );
};

// Archive Screen
const ArchiveScreen = () => {
    return React.createElement('div', { className: 'wrap' },
        React.createElement('div', { style: { marginBottom: 32 } },
            React.createElement('span', { className: 'eyebrow' }, 'ARCHIVE'),
            React.createElement('h2', { style: { fontFamily: 'var(--f-serif)', fontSize: 28, fontWeight: 600, marginTop: 8 } },
                '키워드 아카이브'
            )
        ),
        SAMPLE_KEYWORDS.map((kw) =>
            React.createElement('div', { className: 'kw-row', key: kw.date },
                React.createElement('span', { className: 'kdate' }, kw.date),
                React.createElement('span', { className: 'kword' },
                    React.createElement('span', { className: 'kor' }, kw.word)
                ),
                React.createElement('span', { className: 'kcount' },
                    kw.count.toLocaleString(),
                    React.createElement('small', null, kw.eng)
                )
            )
        )
    );
};

// Profile Screen
const ProfileScreen = ({ user }) => {
    if (!user) {
        return React.createElement('div', { className: 'wrap', style: { textAlign: 'center', paddingTop: 100 } },
            React.createElement('h2', { style: { fontFamily: 'var(--f-serif)', marginBottom: 16 } }, '로그인이 필요합니다'),
            React.createElement('button', { className: 'btn solid', onClick: () => window.location.hash = 'login' }, '로그인하기')
        );
    }
    
    return React.createElement('div', { className: 'wrap' },
        React.createElement('div', { className: 'profile-header' },
            React.createElement('div', { className: 'avatar' }, user.initial),
            React.createElement('h2', null, user.name),
            React.createElement('span', { className: 'handle' }, '@' + user.handle)
        ),
        React.createElement('div', { className: 'profile-stats' },
            React.createElement('div', { className: 'stat' },
                React.createElement('div', { className: 'value' }, '184'),
                React.createElement('div', { className: 'label' }, '작성한 글')
            ),
            React.createElement('div', { className: 'stat' },
                React.createElement('div', { className: 'value' }, '2.3k'),
                React.createElement('div', { className: 'label' }, '팔로워')
            ),
            React.createElement('div', { className: 'stat' },
                React.createElement('div', { className: 'value' }, '42'),
                React.createElement('div', { className: 'label' }, '연속 작성')
            )
        )
    );
};

// Detail Screen
const DetailScreen = ({ post, onBack, user }) => {
    const [comments, setComments] = useState(SAMPLE_COMMENTS);
    const [newComment, setNewComment] = useState('');
    
    const handleSubmitComment = (e) => {
        e.preventDefault();
        if (!newComment.trim()) return;
        const comment = { 
            id: Date.now(), 
            author: user ? user.name : '익명', 
            initial: user ? user.initial : '?',
            time: '방금', 
            body: newComment 
        };
        setComments([...comments, comment]);
        setNewComment('');
    };

    if (!post) return null;

    return React.createElement('div', { className: 'wrap' },
        React.createElement('button', { 
            className: 'btn ghost sm', 
            onClick: onBack,
            style: { marginBottom: 20 }
        }, '← 뒤로'),
        React.createElement('div', { className: 'detail-header' },
            React.createElement('h1', null, React.createElement('span', { className: 'kor' }, post.title)),
            React.createElement('div', { className: 'byline', style: { marginTop: 16 } },
                React.createElement('span', { className: 'author' }, post.author),
                React.createElement('span', null, '@' + post.handle),
                React.createElement('span', null, '·'),
                React.createElement('span', null, post.time)
            )
        ),
        React.createElement('div', { className: 'detail-body' },
            React.createElement('p', null, post.body),
            React.createElement('p', null, post.body + ' ' + post.body)
        ),
        React.createElement('div', { className: 'comments-section' },
            React.createElement('h3', null, '댓글 ', comments.length),
            comments.map(c =>
                React.createElement('div', { className: 'comment', key: c.id },
                    React.createElement('div', { className: 'avatar', style: { width: 44, height: 44 } }, c.initial || c.author[0]),
                    React.createElement('div', null,
                        React.createElement('div', { className: 'c-head' },
                            React.createElement('span', { className: 'c-author' }, c.author),
                            React.createElement('span', { className: 'c-time' }, c.time)
                        ),
                        React.createElement('div', { className: 'c-body' }, c.body)
                    )
                )
            ),
            React.createElement('form', { className: 'comment-input', onSubmit: handleSubmitComment },
                React.createElement('div', { className: 'avatar', style: { width: 44, height: 44 } }, user ? user.initial : '?'),
                React.createElement('input', {
                    type: 'text',
                    placeholder: '댓글을 입력하세요...',
                    value: newComment,
                    onChange: (e) => setNewComment(e.target.value)
                }),
                React.createElement('button', { className: 'btn sm', type: 'submit' }, '작성')
            )
        )
    );
};

// Login Screen
const LoginScreen = ({ onLogin, onBack }) => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [loading, setLoading] = useState(false);
    
    const handleSubmit = (e) => {
        e.preventDefault();
        if (!email || !password) return;
        setLoading(true);
        setTimeout(() => {
            onLogin({ email, name: '글쓰기 민', handle: 'writer_min', initial: '민' });
            setLoading(false);
        }, 800);
    };

    return React.createElement('div', { className: 'login-container' },
        React.createElement('div', { className: 'login-box' },
            React.createElement('div', { style: { display: 'flex', justifyContent: 'center', marginBottom: 32 } },
                React.createElement(Logo, { size: 28 })
            ),
            React.createElement('h2', null, '로그인'),
            React.createElement('p', { className: 'subtitle' }, 'WriteHabit에 오신 것을 환영합니다'),
            React.createElement('form', { onSubmit: handleSubmit },
                React.createElement('input', {
                    type: 'email',
                    placeholder: '이메일',
                    value: email,
                    onChange: (e) => setEmail(e.target.value),
                    required: true
                }),
                React.createElement('input', {
                    type: 'password',
                    placeholder: '비밀번호',
                    value: password,
                    onChange: (e) => setPassword(e.target.value),
                    required: true
                }),
                React.createElement('button', { className: 'btn solid', type: 'submit', disabled: loading },
                    loading ? '로그인 중...' : '로그인'
                )
            ),
            React.createElement('div', { className: 'divider' },
                React.createElement('span', null, '또는')
            ),
            React.createElement('button', { className: 'btn ghost', onClick: onBack, type: 'button' }, '둘러보기')
        )
    );
};

// Main App
const App = () => {
    const [activeTab, setActiveTab] = useState('feed');
    const [selectedPost, setSelectedPost] = useState(null);
    const [user, setUser] = useState(null);
    
    useEffect(() => {
        const saved = localStorage.getItem('user');
        if (saved) setUser(JSON.parse(saved));
    }, []);
    
    const handleLogin = (userData) => {
        setUser(userData);
        localStorage.setItem('user', JSON.stringify(userData));
        setActiveTab('feed');
    };
    
    const handleLogout = () => {
        setUser(null);
        localStorage.removeItem('user');
    };
    
    const handlePostClick = (post) => {
        setSelectedPost(post);
        setActiveTab('detail');
    };
    
    const handleBack = () => {
        setSelectedPost(null);
        setActiveTab('feed');
    };

    const renderContent = () => {
        switch(activeTab) {
            case 'feed': return React.createElement(FeedScreen, { onPostClick: handlePostClick, onWriteClick: () => setActiveTab('write') });
            case 'write': return React.createElement(WriteScreen, { user });
            case 'archive': return React.createElement(ArchiveScreen);
            case 'profile': return React.createElement(ProfileScreen, { user });
            case 'detail': return React.createElement(DetailScreen, { post: selectedPost, onBack: handleBack, user });
            case 'login': return React.createElement(LoginScreen, { onLogin: handleLogin, onBack: () => setActiveTab('feed') });
            default: return React.createElement(FeedScreen, { onPostClick: handlePostClick, onWriteClick: () => setActiveTab('write') });
        }
    };

    return React.createElement('div', { className: 'wh' },
        activeTab !== 'login' && React.createElement(TopBar, { 
            activeTab: activeTab === 'detail' ? 'feed' : activeTab, 
            onTabChange: setActiveTab,
            user 
        }),
        React.createElement('main', null, renderContent())
    );
};

// Render
const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(React.createElement(App));
