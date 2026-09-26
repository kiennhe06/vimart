/* ============================================================
   app.js — Trang QUẢN TRỊ (Admin) ViMart. JS thuần.
   Khách hàng dùng app Flutter; web này chỉ dành cho admin quản lý sàn.
   Dùng các API /api/admin/* + /api/categories (đều yêu cầu quyền admin).
   ============================================================ */

const app = document.getElementById('app');
const modalRoot = document.getElementById('modalRoot');

const state = { user: null };

// ---------- Song ngữ (i18n) — Việt / Anh ----------
// Helper inline: L('tiếng Việt', 'English') trả về theo ngôn ngữ đang chọn.
let lang = localStorage.getItem('vimart_admin_lang') || 'vi';
function L(vi, en) {
  return lang === 'en' ? en : vi;
}
function setLang(code) {
  lang = code;
  localStorage.setItem('vimart_admin_lang', code);
  route();
}

// ---------- Giao diện (theme) — Theo hệ thống / Sáng / Tối ----------
// Lưu "ý muốn" (system/light/dark); resolve "system" theo hệ điều hành rồi gán
// data-theme trên <html> để CSS đảo bảng màu (KHÔNG đảo màu thủ công).
let themePref = localStorage.getItem('vimart_admin_theme') || 'system';
const _themeMql = window.matchMedia('(prefers-color-scheme: dark)');
function applyTheme() {
  const resolved = themePref === 'system' ? (_themeMql.matches ? 'dark' : 'light') : themePref;
  document.documentElement.setAttribute('data-theme', resolved);
}
function setTheme(pref) {
  themePref = pref;
  localStorage.setItem('vimart_admin_theme', pref);
  applyTheme();
  route();
}
_themeMql.addEventListener('change', () => {
  if (themePref === 'system') applyTheme();
});
applyTheme();

/** Công tắc Giao diện (tái dùng .lang-switch): Theo hệ thống / Sáng / Tối. */
function themeSwitch() {
  const opt = (pref, icon, label) =>
    `<button class="lang-pill lang-pill--icon ${themePref === pref ? 'lang-pill--on' : ''}" data-action="theme-${pref}" title="${label}" aria-label="${label}">${ic(icon, 'i18')}</button>`;
  return `<div class="lang-switch" role="group" title="${L('Giao diện', 'Appearance')}">
    ${opt('system', 'monitor', L('Theo hệ thống', 'System'))}
    ${opt('light', 'sun', L('Sáng', 'Light'))}
    ${opt('dark', 'moon', L('Tối', 'Dark'))}
  </div>`;
}

// ---------- Trạng thái dùng chung (skeleton / empty / error) ----------
/** Khung xương khi đang tải (thay màn hình đứng im bằng skeleton). */
function skeletonView(rows = 5) {
  const line = (w) => `<div class="sk" style="width:${w}"></div>`;
  const card = `<div class="sk-card"><div class="sk-row">${line('42px')}<div style="flex:1;display:grid;gap:8px">${line('60%')}${line('35%')}</div>${line('72px')}</div></div>`;
  return `<div aria-busy="true" aria-label="${L('Đang tải', 'Loading')}">${Array.from({ length: rows }, () => card).join('')}</div>`;
}

/** Trạng thái rỗng / lỗi dùng chung. */
function stateView({ icon = 'box', title, message, action, error = false }) {
  const btn = action
    ? `<button class="btn btn--ghost btn--sm" data-action="${action.do}">${escapeHtml(action.label)}</button>`
    : '';
  return `<div class="state ${error ? 'state--error' : ''}">
    <div class="state__icon">${ic(icon, 'i22')}</div>
    ${title ? `<div class="state__title">${escapeHtml(title)}</div>` : ''}
    <div>${escapeHtml(message || '')}</div>
    ${btn}
  </div>`;
}

const NAV = [
  { key: 'dashboard', icon: '📊' },
  { key: 'products', icon: '🛍️' },
  { key: 'users', icon: '👥' },
  { key: 'orders', icon: '📦' },
  { key: 'categories', icon: '🏷️' },
];
// Nhãn menu theo ngôn ngữ.
function navLabel(key) {
  return (
    {
      dashboard: L('Tổng quan', 'Overview'),
      products: L('Sản phẩm', 'Products'),
      users: L('Người dùng', 'Users'),
      orders: L('Đơn hàng', 'Orders'),
      categories: L('Danh mục', 'Categories'),
    }[key] || key
  );
}

// Chỉ giữ màu theo trạng thái; nhãn lấy động qua statusLabel().
const STATUS_COLOR = {
  pending: '#f59e0b',
  confirmed: '#2563eb',
  shipping: '#7c3aed',
  completed: '#2e7d32',
  cancelled: '#d32f2f',
};
function statusLabel(s) {
  return (
    {
      pending: L('Chờ xác nhận', 'Pending'),
      confirmed: L('Đã xác nhận', 'Confirmed'),
      shipping: L('Đang giao', 'Shipping'),
      completed: L('Hoàn thành', 'Completed'),
      cancelled: L('Đã hủy', 'Cancelled'),
    }[s] || s
  );
}

// ---------- Bộ icon SVG (nét mảnh, đồng bộ kiểu Lucide) ----------
const ICONS = {
  search: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
  bell: '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a2 2 0 0 0 3.4 0"/>',
  grid: '<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/>',
  file: '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/>',
  box: '<path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><path d="m3.3 7 8.7 5 8.7-5"/><path d="M12 22V12"/>',
  bag: '<path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"/><path d="M3 6h18"/><path d="M16 10a4 4 0 0 1-8 0"/>',
  sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
  moon: '<path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/>',
  monitor: '<rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/>',
  chevronL: '<path d="m15 18-6-6 6-6"/>',
  chevronR: '<path d="m9 18 6-6-6-6"/>',
};

// Kỳ đang xem của dashboard: chế độ (tuần/tháng) + độ lệch (0 = hiện tại,
// -1 = kỳ trước...). Điều khiển CHUNG cho biểu đồ đơn + doanh thu.
const chartView = { mode: 'week', offset: 0 };

/** Kỳ hiện tại (theo chartView): hàm kiểm tra ngày thuộc kỳ + tiêu đề hiển thị. */
function currentPeriod() {
  const now = new Date();
  const fmtD = (dt) => new Date(dt).toLocaleDateString(lang === 'en' ? 'en-GB' : 'vi-VN');
  if (chartView.mode === 'month') {
    const year = now.getFullYear() + chartView.offset;
    return { inRange: (d) => d.getFullYear() === year, title: `${L('Năm', 'Year')} ${year}` };
  }
  const end = new Date(now);
  end.setHours(0, 0, 0, 0);
  end.setDate(end.getDate() + chartView.offset * 7);
  const start = new Date(end);
  start.setDate(end.getDate() - 6);
  const endOfDay = new Date(end);
  endOfDay.setHours(23, 59, 59, 999);
  return {
    inRange: (d) => d >= start && d <= endOfDay,
    title: `${start.getDate()}/${start.getMonth() + 1} – ${fmtD(end)}`,
  };
}

/** Doanh thu (đơn hoàn thành) + số đơn trong kỳ hiện tại. */
function periodRevenue(orders) {
  const { inRange } = currentPeriod();
  let rev = 0;
  let cnt = 0;
  (orders || []).forEach((o) => {
    if (!o.created_at) return;
    if (!inRange(new Date(o.created_at))) return;
    cnt++;
    if (o.status === 'completed') rev += Number(o.total) || 0;
  });
  return { rev, cnt };
}
function ic(name, cls = 'i18') {
  return `<svg class="ic ${cls}" viewBox="0 0 24 24">${ICONS[name] || ''}</svg>`;
}

// ---------- Tiện ích ----------
const fmtVnd = (n) => new Intl.NumberFormat('vi-VN').format(n || 0) + '₫';
const fmtDate = (s) => (s ? new Date(s).toLocaleString('vi-VN') : '');
function escapeHtml(v) {
  return String(v ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
function toast(msg) {
  const el = document.getElementById('toast');
  el.textContent = msg;
  el.hidden = false;
  clearTimeout(el._t);
  el._t = setTimeout(() => (el.hidden = true), 2600);
}
function statusChip(s) {
  const color = STATUS_COLOR[s] || '#888';
  return `<span class="status" style="color:${color};background:${color}22">${statusLabel(s)}</span>`;
}
function openModal(html) {
  modalRoot.innerHTML = `<div class="overlay" data-action="close-bg"><div class="modal">${html}</div></div>`;
}
function closeModal() {
  modalRoot.innerHTML = '';
}

// ---------- Đăng nhập ----------
async function loadUser() {
  if (!Api.getToken()) return (state.user = null);
  try {
    state.user = await Api.get('/auth/me');
  } catch {
    Api.setToken(null);
    state.user = null;
  }
}

function renderLogin(message) {
  app.innerHTML = `
    <div class="login-wrap">
      <div class="login-card">
        <div class="login-lang">
          <button class="lang-pill ${lang === 'vi' ? 'lang-pill--on' : ''}" data-action="lang-vi">VI</button>
          <button class="lang-pill ${lang === 'en' ? 'lang-pill--on' : ''}" data-action="lang-en">EN</button>
        </div>
        <h1>ViMart Admin</h1>
        <p>${L('Trang quản trị sàn — chỉ dành cho admin', 'Marketplace admin panel — admins only')}</p>
        ${message ? `<p style="color:var(--danger)">${escapeHtml(message)}</p>` : ''}
        <form id="loginForm">
          <div class="field"><label>${L('Email', 'Email')}</label><input name="email" type="email" required value="admin@vimart.vn"/></div>
          <div class="field"><label>${L('Mật khẩu', 'Password')}</label><input name="password" type="password" required/></div>
          <button class="btn btn--primary btn--block" type="submit">${L('Đăng nhập', 'Sign in')}</button>
        </form>
        <p style="margin-top:16px">${L('Tài khoản admin thử', 'Demo admin account')}: admin@vimart.vn / 123456</p>
      </div>
    </div>`;

  document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const f = e.target;
    try {
      const res = await Api.post('/auth/login', {
        email: f.email.value.trim(),
        password: f.password.value,
      });
      if (res.user.role !== 'admin') {
        Api.setToken(null);
        return renderLogin(
          L(
            'Tài khoản này không phải admin. Vui lòng dùng tài khoản quản trị.',
            'This account is not an admin. Please use an administrator account.'
          )
        );
      }
      Api.setToken(res.token);
      state.user = res.user;
      if (!location.hash) location.hash = '#/dashboard';
      route();
    } catch (err) {
      renderLogin(err.message);
    }
  });
}

// ---------- Khung dashboard ----------
function renderShell(activeKey) {
  const tabs = NAV.map(
    (n) => `
    <div class="tab ${n.key === activeKey ? 'tab--active' : ''}" data-nav="${n.key}">${navLabel(n.key)}</div>`
  ).join('');
  const initial = (state.user.fullName || '?').charAt(0).toUpperCase();

  app.innerHTML = `
    <div class="appwrap">
      <header class="topnav">
        <div class="topnav__brand">Vi<span>Mart</span></div>
        <nav class="tabs">${tabs}</nav>
        <div class="topnav__actions">
          <div class="lang-switch" title="${L('Ngôn ngữ', 'Language')}">
            <button class="lang-pill ${lang === 'vi' ? 'lang-pill--on' : ''}" data-action="lang-vi">VI</button>
            <button class="lang-pill ${lang === 'en' ? 'lang-pill--on' : ''}" data-action="lang-en">EN</button>
          </div>
          ${themeSwitch()}
          <div class="avatar" data-action="logout" title="${L('Đăng xuất', 'Sign out')} (${escapeHtml(state.user.fullName)})">${initial}</div>
        </div>
      </header>
      <main class="content" id="content">${skeletonView()}</main>
    </div>`;
}

// ---------- Định tuyến ----------
function currentKey() {
  const k = location.hash.replace(/^#\//, '') || 'dashboard';
  return NAV.some((n) => n.key === k) ? k : 'dashboard';
}

async function route() {
  if (!state.user) return renderLogin();
  if (state.user.role !== 'admin')
    return renderLogin(
      L('Tài khoản không có quyền admin.', 'This account has no admin permission.')
    );

  const key = currentKey();
  renderShell(key);
  const content = document.getElementById('content');
  try {
    if (key === 'dashboard') await viewDashboard(content);
    else if (key === 'products') await viewProducts(content);
    else if (key === 'users') await viewUsers(content);
    else if (key === 'orders') await viewOrders(content);
    else if (key === 'categories') await viewCategories(content);
  } catch (err) {
    content.innerHTML = stateView({
      icon: 'bell',
      title: L('Có lỗi xảy ra', 'Something went wrong'),
      message: err.message,
      action: { do: 'reload', label: L('Thử lại', 'Retry') },
      error: true,
    });
  }
}

// ---------- View: Tổng quan (dashboard nhiều thẻ, có biểu đồ) ----------
const PALETTE = ['#f4511e', '#ff9a3d', '#2bb3a3', '#4c7cf3', '#a05ff0', '#ff5c8a', '#12b76a'];

async function viewDashboard(el) {
  const [s, orders, products, cats] = await Promise.all([
    Api.get('/admin/stats'),
    Api.get('/admin/orders'),
    Api.get('/admin/products'),
    Api.get('/categories'),
  ]);
  state.dashOrders = orders; // để re-render biểu đồ khi đổi kỳ
  state.dashStats = s; // giữ số liệu tổng (all-time) cho hero

  el.innerHTML = `<div class="dash">
    <div class="dash__col">${heroCard()}${revenueFlowCard(orders)}${recentOrdersCard(orders)}</div>
    <div class="dash__col">${miniCard(ic('box', 'i20'), 'rgba(55,214,122,.16)', '#37d67a', L('Tổng đơn hàng', 'Total orders'), s.totalOrders)}
      ${miniCard(ic('bag', 'i20'), 'rgba(244,81,30,.16)', '#ff9a3d', L('Sản phẩm đang bán', 'Active products'), s.totalProducts)}
      ${categoryDonutCard(products, cats)}</div>
    <div class="dash__col">${vmartCard(s)}${categoryListCard(products, cats)}</div>
  </div>`;
}

/** Thẻ số dư lớn = doanh thu. */
function heroCard() {
  const { title } = currentPeriod();
  const { rev, cnt } = periodRevenue(state.dashOrders);
  return `<div class="hero" id="heroCard">
    <div class="hero__label">${L('Doanh thu (đơn hoàn thành)', 'Revenue (completed orders)')} · ${title}</div>
    <div class="hero__value">${fmtVnd(rev)}</div>
    <div class="hero__sub">${L(`${cnt} đơn trong kỳ · Tổng: ${fmtVnd(state.dashStats?.totalRevenue || 0)}`, `${cnt} orders in period · All-time: ${fmtVnd(state.dashStats?.totalRevenue || 0)}`)}</div>
    <div class="hero__actions">
      <button class="hero__btn hero__btn--dark" data-nav="orders">${L('Xem đơn hàng', 'View orders')}</button>
      <button class="hero__btn hero__btn--light" data-nav="products">${L('Sản phẩm', 'Products')}</button>
    </div>
  </div>`;
}

function miniCard(icon, iconBg, iconColor, label, value) {
  return `<div class="mini">
    <div class="mini__row">
      <div class="mini__icon" style="background:${iconBg};color:${iconColor}">${icon}</div>
      <div class="mini__label">${label}</div>
    </div>
    <div class="mini__value">${value}</div>
  </div>`;
}

/** Biểu đồ cột số đơn theo kỳ — Ngày (7 ngày) hoặc Tháng (12 tháng/năm),
 *  có điều hướng ◀ ▶ để xem lại các tuần/tháng/năm trước. */
function revenueFlowCard(orders) {
  const now = new Date();
  const isMonth = chartView.mode === 'month';
  const fmtD = (dt) => new Date(dt).toLocaleDateString(lang === 'en' ? 'en-GB' : 'vi-VN');
  const buckets = [];
  let title;

  if (isMonth) {
    // 12 tháng của năm (now.year + offset); offset tính theo NĂM.
    const year = now.getFullYear() + chartView.offset;
    for (let m = 0; m < 12; m++) {
      buckets.push({
        match: (d) => d.getFullYear() === year && d.getMonth() === m,
        label: `${m + 1}`,
        count: 0,
      });
    }
    title = `${L('Năm', 'Year')} ${year}`;
  } else {
    // 7 ngày kết thúc tại (hôm nay + offset tuần); offset tính theo TUẦN.
    const end = new Date(now);
    end.setHours(0, 0, 0, 0);
    end.setDate(end.getDate() + chartView.offset * 7);
    for (let i = 6; i >= 0; i--) {
      const d = new Date(end);
      d.setDate(end.getDate() - i);
      const y = d.getFullYear();
      const mo = d.getMonth();
      const da = d.getDate();
      buckets.push({
        match: (x) => x.getFullYear() === y && x.getMonth() === mo && x.getDate() === da,
        label: `${da}/${mo + 1}`,
        at: new Date(d),
        count: 0,
      });
    }
    title = `${buckets[0].label} – ${fmtD(buckets[6].at)}`;
  }

  orders.forEach((o) => {
    if (!o.created_at) return;
    const d = new Date(o.created_at);
    const b = buckets.find((x) => x.match(d));
    if (b) b.count++;
  });

  const max = Math.max(1, ...buckets.map((b) => b.count));
  const total = buckets.reduce((sum, b) => sum + b.count, 0);
  const hotIdx = buckets.reduce((best, b, i, a) => (b.count > a[best].count ? i : best), 0);
  const canNext = chartView.offset < 0; // không xem tương lai

  const bars = buckets
    .map((b, i) => {
      const hot = i === hotIdx && b.count > 0;
      return `<div class="bar-col">
      <div class="bar-wrap">
        <div class="bar-val ${hot ? 'bar-val--hot' : ''}">${b.count}</div>
        <div class="bar ${hot ? 'bar--hot' : ''}" style="height:${b.count > 0 ? Math.max(14, Math.round((b.count / max) * 82)) : 6}%"></div>
      </div>
      <div class="bar-lbl">${b.label}</div>
    </div>`;
    })
    .join('');

  const modeBtn = (m, label) =>
    `<button class="lang-pill ${chartView.mode === m ? 'lang-pill--on' : ''}" data-action="chart-mode-${m}">${label}</button>`;

  return `<div class="dcard" id="chartCard">
    <div class="dcard__head">
      <div>
        <h4>${L('Đơn hàng', 'Orders')}</h4>
        <div class="dcard__sub">${title} · ${L(`${total} đơn`, `${total} orders`)}</div>
      </div>
      <div class="spacer"></div>
      <div class="lang-switch">${modeBtn('week', L('Ngày', 'Day'))}${modeBtn('month', L('Tháng', 'Month'))}</div>
    </div>
    <div class="bars">${bars}</div>
    <div class="chart-nav">
      <button class="chart-navbtn" data-action="chart-prev" title="${L('Kỳ trước', 'Previous')}" aria-label="${L('Kỳ trước', 'Previous')}">${ic('chevronL', 'i18')}</button>
      ${chartView.offset !== 0 ? `<button class="chart-today" data-action="chart-today">${L('Hiện tại', 'Now')}</button>` : ''}
      <button class="chart-navbtn" data-action="chart-next" ${canNext ? '' : 'disabled'} title="${L('Kỳ sau', 'Next')}" aria-label="${L('Kỳ sau', 'Next')}">${ic('chevronR', 'i18')}</button>
    </div>
  </div>`;
}

/** Vẽ lại thẻ biểu đồ + doanh thu khi đổi kỳ (không tải lại toàn dashboard). */
function rerenderChart() {
  const chart = document.getElementById('chartCard');
  if (chart) chart.outerHTML = revenueFlowCard(state.dashOrders || []);
  const hero = document.getElementById('heroCard');
  if (hero) hero.outerHTML = heroCard();
}

/** Donut: sản phẩm theo danh mục. */
function categoryDonutCard(products, cats) {
  const name = Object.fromEntries(cats.map((c) => [c.id, c.name]));
  const counts = {};
  products.forEach((p) => {
    const n = name[p.categoryId] || L('Khác', 'Other');
    counts[n] = (counts[n] || 0) + 1;
  });
  const entries = Object.entries(counts).sort((a, b) => b[1] - a[1]);
  const total = products.length || 1;

  let acc = 0;
  const stops = [];
  const segs = entries.map(([n, v], i) => {
    const color = PALETTE[i % PALETTE.length];
    const start = (acc / total) * 100;
    acc += v;
    const end = (acc / total) * 100;
    stops.push(`${color} ${start}% ${end}%`);
    return { n, v, color, pct: Math.round((v / total) * 100) };
  });
  const gradient = stops.length ? `conic-gradient(${stops.join(',')})` : '#eee';

  const legend = segs
    .map(
      (g) => `<div class="legend__row">
    <span class="legend__bar" style="background:${g.color}"></span>
    <div><div class="legend__cap">${escapeHtml(g.n)}</div><div class="legend__pct">${g.pct}%</div></div>
  </div>`
    )
    .join('');

  return `<div class="dcard">
    <div class="dcard__head"><h4>${L('Sản phẩm theo danh mục', 'Products by category')}</h4></div>
    <div class="donut-wrap">
      <div class="donut" style="background:${gradient}">
        <div class="donut__center"><div class="donut__total">${products.length}</div><div class="donut__cap">${L('Sản phẩm', 'Products')}</div></div>
      </div>
      <div class="legend">${legend}</div>
    </div>
  </div>`;
}

/** Danh sách đơn hàng gần đây. */
function recentOrdersCard(orders) {
  const rows =
    orders
      .slice(0, 6)
      .map((o) => {
        const color = STATUS_COLOR[o.status] || '#888';
        return `<div class="litem">
      <div class="litem__icon" style="background:${color}22;color:${color}">${ic('box', 'i18')}</div>
      <div><div class="litem__name">${escapeHtml(o.code)}</div>
        <div class="litem__sub">${escapeHtml(o.buyer_name || '')} · ${o.created_at ? new Date(o.created_at).toLocaleDateString(lang === 'en' ? 'en-GB' : 'vi-VN') : ''}</div></div>
      <div class="spacer"></div>
      <span class="status" style="color:${color};background:${color}22">${statusLabel(o.status)}</span>
      <div class="litem__val" style="color:var(--orange)">${fmtVnd(o.total)}</div>
    </div>`;
      })
      .join('') ||
    `<div class="muted" style="padding:12px 0">${L('Chưa có đơn hàng nào.', 'No orders yet.')}</div>`;

  return `<div class="dcard">
    <div class="dcard__head"><h4>${L('Đơn hàng gần đây', 'Recent orders')}</h4><div class="spacer"></div>
      <span class="pill pill--soft" data-nav="orders" style="cursor:pointer">${L('Xem tất cả', 'View all')}</span></div>
    <div class="rowlist">${rows}</div>
  </div>`;
}

/** Thẻ tổng quan sàn — số liệu chính, rõ ràng (không mô phỏng thẻ thanh toán). */
function vmartCard(s) {
  const stat = (label, value) =>
    `<div class="ov__stat"><div class="ov__num">${value ?? 0}</div><div class="ov__lbl">${label}</div></div>`;
  return `<div class="vcard">
    <div class="vcard__brand">Vi<span>Mart</span> · ${L('Tổng quan sàn', 'Platform overview')}</div>
    <div class="ov__grid">
      ${stat(L('Người dùng', 'Users'), s.totalUsers)}
      ${stat(L('Cửa hàng', 'Shops'), s.totalShops)}
      ${stat(L('Sản phẩm', 'Products'), s.totalProducts)}
      ${stat(L('Đơn hàng', 'Orders'), s.totalOrders)}
    </div>
  </div>`;
}

/** Danh sách danh mục kèm số sản phẩm (kiểu subscription). */
function categoryListCard(products, cats) {
  const counts = {};
  products.forEach((p) => (counts[p.categoryId] = (counts[p.categoryId] || 0) + 1));
  const rows = cats
    .map((c, i) => {
      const color = PALETTE[i % PALETTE.length];
      return `<div class="litem">
      <div class="litem__icon" style="background:${color}22;color:${color}">${escapeHtml(c.name.charAt(0))}</div>
      <div><div class="litem__name">${escapeHtml(c.name)}</div>
        <div class="litem__sub">${escapeHtml(c.slug)}</div></div>
      <div class="litem__val">${L(`${counts[c.id] || 0} SP`, `${counts[c.id] || 0} items`)}</div>
    </div>`;
    })
    .join('');

  return `<div class="dcard">
    <div class="dcard__head"><h4>${L('Danh mục', 'Categories')}</h4><div class="spacer"></div>
      <span class="pill pill--soft" data-nav="categories" style="cursor:pointer">${L('Quản lý', 'Manage')}</span></div>
    <div class="rowlist">${rows}</div>
  </div>`;
}

// ---------- View: Sản phẩm ----------
async function viewProducts(el) {
  const products = await Api.get('/admin/products');
  const rows = products
    .map(
      (p) => `
    <tr>
      <td><img class="thumb" src="${escapeHtml(p.imageUrl || '')}" onerror="this.style.visibility='hidden'"/></td>
      <td>${escapeHtml(p.name)}</td>
      <td>${escapeHtml(p.shopName)}</td>
      <td><b style="color:var(--orange)">${fmtVnd(p.minPrice)}</b></td>
      <td>${p.totalStock}</td>
      <td>${
        p.status === 'active'
          ? `<span class="tag tag--on">${L('Đang bán', 'Active')}</span>`
          : `<span class="tag tag--off">${L('Đang ẩn', 'Hidden')}</span>`
      }</td>
      <td style="white-space:nowrap">
        <button class="btn btn--sm" data-action="edit-product" data-id="${p.id}">${L('Sửa', 'Edit')}</button>
        <button class="btn btn--sm btn--danger" data-action="del-product" data-id="${p.id}" data-name="${escapeHtml(p.name)}">${L('Xóa', 'Delete')}</button>
      </td>
    </tr>`
    )
    .join('');

  el.innerHTML = `
    <div class="section-head"><h3>${L('Sản phẩm', 'Products')} (${products.length})</h3><div class="spacer"></div>
      <button class="btn btn--primary btn--sm" data-action="add-product">+ ${L('Thêm sản phẩm', 'Add product')}</button></div>
    <div class="panel"><table class="table">
      <thead><tr><th>${L('Ảnh', 'Image')}</th><th>${L('Tên', 'Name')}</th><th>Shop</th><th>${L('Giá', 'Price')}</th><th>${L('Kho', 'Stock')}</th><th>${L('Trạng thái', 'Status')}</th><th></th></tr></thead>
      <tbody>${rows}</tbody></table></div>`;
}

/** 1 dòng nhập phân loại trong form sản phẩm. */
function variantRowHtml(v = {}) {
  return `<div class="var-row">
    <input class="var-name" placeholder="${L('Tên (vd: Đỏ/L)', 'Name (e.g. Red/L)')}" value="${escapeHtml(v.name || '')}"/>
    <input class="var-price" type="number" placeholder="${L('Giá', 'Price')}" value="${v.price ?? ''}"/>
    <input class="var-stock" type="number" placeholder="${L('Kho', 'Stock')}" value="${v.stock ?? ''}"/>
    <button type="button" class="btn btn--sm btn--danger" data-action="var-remove">×</button>
  </div>`;
}

/** Modal thêm / sửa sản phẩm (kèm upload ảnh). */
async function productFormModal(prodId) {
  const isEdit = !!prodId;
  const [shops, cats, detail] = await Promise.all([
    Api.get('/admin/shops'),
    Api.get('/categories'),
    isEdit ? Api.get('/products/' + prodId) : Promise.resolve(null),
  ]);

  const imageUrl = detail?.imageUrl || '';
  const shopId = detail?.shop?.id ?? (shops[0] ? shops[0].id : '');
  const catId = detail?.categoryId ?? '';
  const variants = detail?.variants?.length
    ? detail.variants
    : [{ name: 'Mặc định', price: '', stock: '' }];

  openModal(`
    <button class="modal__close" data-action="close">×</button>
    <h2>${isEdit ? L('Sửa sản phẩm', 'Edit product') : L('Thêm sản phẩm', 'Add product')}</h2>
    <p class="modal__sub">${L('Điền thông tin, ảnh và phân loại (giá + tồn kho)', 'Fill in details, image and variants (price + stock)')}</p>
    <form id="prodForm">
      <div class="field"><label>${L('Ảnh sản phẩm', 'Product image')}</label>
        <div class="row" style="align-items:flex-start;gap:14px">
          <img id="imgPreview" class="thumb-lg" src="${escapeHtml(imageUrl)}" ${imageUrl ? '' : 'style="visibility:hidden"'}/>
          <div style="flex:1">
            <input type="file" id="imgFile" accept="image/*"/>
            <div id="imgStatus" class="muted" style="font-size:12px;margin:6px 0"></div>
            <input id="imgUrl" placeholder="${L('hoặc dán link ảnh https://...', 'or paste image link https://...')}" value="${escapeHtml(imageUrl)}"/>
          </div>
        </div>
      </div>
      <div class="field"><label>${L('Tên sản phẩm', 'Product name')}</label><input name="name" required value="${escapeHtml(detail?.name || '')}"/></div>
      <div class="field"><label>Shop</label><select name="shopId">
        ${shops.map((s) => `<option value="${s.id}" ${s.id === shopId ? 'selected' : ''}>${escapeHtml(s.name)}</option>`).join('')}
      </select></div>
      <div class="field"><label>${L('Danh mục', 'Category')}</label><select name="categoryId">
        <option value="">${L('— Không —', '— None —')}</option>
        ${cats.map((c) => `<option value="${c.id}" ${c.id === catId ? 'selected' : ''}>${escapeHtml(c.name)}</option>`).join('')}
      </select></div>
      <div class="field"><label>${L('Trạng thái', 'Status')}</label><select name="status">
        <option value="active" ${detail?.status !== 'hidden' ? 'selected' : ''}>${L('Đang bán', 'Active')}</option>
        <option value="hidden" ${detail?.status === 'hidden' ? 'selected' : ''}>${L('Đang ẩn', 'Hidden')}</option>
      </select></div>
      <div class="field"><label>${L('Mô tả', 'Description')}</label><textarea name="description" rows="2">${escapeHtml(detail?.description || '')}</textarea></div>
      <label style="font-size:13px;color:var(--text-2)">${L('Phân loại (giá + tồn kho)', 'Variants (price + stock)')}</label>
      <div id="variants">${variants.map(variantRowHtml).join('')}</div>
      <button type="button" class="btn btn--sm" data-action="var-add" style="margin:6px 0 14px">+ ${L('Thêm phân loại', 'Add variant')}</button>
      <button class="btn btn--primary btn--block" type="submit">${L('Lưu sản phẩm', 'Save product')}</button>
    </form>`);

  // Upload ảnh khi chọn file
  const preview = document.getElementById('imgPreview');
  const urlInput = document.getElementById('imgUrl');
  document.getElementById('imgFile').addEventListener('change', async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const status = document.getElementById('imgStatus');
    status.textContent = L('Đang tải ảnh...', 'Uploading image...');
    try {
      const url = await Api.uploadImage(file);
      urlInput.value = url;
      preview.src = url;
      preview.style.visibility = 'visible';
      status.textContent = L('✅ Đã tải ảnh', '✅ Image uploaded');
    } catch (err) {
      status.textContent = '❌ ' + err.message;
    }
  });
  // Cập nhật preview khi dán link
  urlInput.addEventListener('input', () => {
    preview.src = urlInput.value;
    preview.style.visibility = urlInput.value ? 'visible' : 'hidden';
  });

  document.getElementById('prodForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const f = e.target;
    const variantEls = [...document.querySelectorAll('#variants .var-row')];
    const vars = variantEls.map((row) => ({
      name: row.querySelector('.var-name').value.trim() || 'Mặc định',
      price: Number(row.querySelector('.var-price').value || 0),
      stock: Number(row.querySelector('.var-stock').value || 0),
    }));
    const body = {
      shopId: Number(f.shopId.value),
      categoryId: f.categoryId.value ? Number(f.categoryId.value) : null,
      name: f.name.value.trim(),
      description: f.description.value.trim() || null,
      imageUrl: urlInput.value.trim() || null,
      status: f.status.value,
      variants: vars,
    };
    try {
      if (isEdit) await Api.put('/admin/products/' + prodId, body);
      else await Api.post('/admin/products', body);
      closeModal();
      toast(L('Đã lưu sản phẩm', 'Product saved'));
      route();
    } catch (err) {
      toast(err.message);
    }
  });
}

// ---------- View: Người dùng ----------
async function viewUsers(el) {
  const users = await Api.get('/admin/users');
  const rows = users
    .map(
      (u) => `
    <tr>
      <td>${u.id}</td>
      <td>${escapeHtml(u.fullName)}</td>
      <td>${escapeHtml(u.email)}</td>
      <td><span class="tag ${u.role === 'admin' ? 'tag--admin' : 'tag--user'}">${u.role}</span></td>
      <td>${u.shop ? escapeHtml(u.shop.name) : '<span class="muted">—</span>'}</td>
      <td><span class="tag ${u.isActive ? 'tag--on' : 'tag--off'}">${u.isActive ? L('Hoạt động', 'Active') : L('Đã khóa', 'Locked')}</span></td>
      <td>${
        u.role === 'admin'
          ? ''
          : `<button class="btn btn--sm ${u.isActive ? 'btn--danger' : 'btn--ok'}"
        data-action="toggle-user" data-id="${u.id}" data-active="${u.isActive ? 0 : 1}">
        ${u.isActive ? L('Khóa', 'Lock') : L('Mở khóa', 'Unlock')}</button>`
      }</td>
    </tr>`
    )
    .join('');

  el.innerHTML = `<div class="panel"><table class="table">
    <thead><tr><th>ID</th><th>${L('Họ tên', 'Full name')}</th><th>Email</th><th>${L('Vai trò', 'Role')}</th><th>Shop</th><th>${L('Trạng thái', 'Status')}</th><th></th></tr></thead>
    <tbody>${rows}</tbody></table></div>`;
}

// ---------- View: Đơn hàng ----------
// Bộ lọc đơn hàng (giữ giữa các lần xem): trạng thái, khoảng ngày, tìm nhanh.
const orderFilter = { status: '', from: '', to: '', q: '' };

/** Lọc + vẽ lại phần thân bảng đơn hàng theo bộ lọc hiện tại. */
function renderOrdersTable() {
  const f = orderFilter;
  const q = f.q.trim().toLowerCase();
  const from = f.from ? new Date(f.from + 'T00:00:00') : null;
  const to = f.to ? new Date(f.to + 'T23:59:59.999') : null;
  const list = (state.allOrders || []).filter((o) => {
    if (f.status && o.status !== f.status) return false;
    const d = o.created_at ? new Date(o.created_at) : null;
    if (from && (!d || d < from)) return false;
    if (to && (!d || d > to)) return false;
    if (q && !`${o.code} ${o.buyer_name || ''} ${o.shop_name || ''}`.toLowerCase().includes(q))
      return false;
    return true;
  });

  const count = document.getElementById('ordersCount');
  if (count) count.textContent = L(`${list.length} đơn`, `${list.length} orders`);
  const body = document.getElementById('ordersBody');
  if (!body) return;
  if (!list.length) {
    body.innerHTML = `<tr><td colspan="7" class="muted" style="padding:28px;text-align:center">${L('Không có đơn khớp bộ lọc', 'No orders match the filter')}</td></tr>`;
    return;
  }
  body.innerHTML = list
    .map(
      (o) => `
    <tr>
      <td><b>${escapeHtml(o.code)}</b></td>
      <td>${escapeHtml(o.buyer_name)}</td>
      <td>${escapeHtml(o.shop_name)}</td>
      <td>${statusChip(o.status)}</td>
      <td>${o.payment_method === 'cod' ? 'COD' : 'VNPay'}
        ${o.payment_status === 'paid' ? `<span class="tag tag--on">${L('Đã trả', 'Paid')}</span>` : `<span class="muted">${L('Chưa trả', 'Unpaid')}</span>`}</td>
      <td><b style="color:var(--orange)">${fmtVnd(o.total)}</b></td>
      <td class="muted">${fmtDate(o.created_at)}</td>
    </tr>`
    )
    .join('');
}

async function viewOrders(el) {
  const orders = await Api.get('/admin/orders'); // trả snake_case từ DB
  state.allOrders = orders;
  if (!orders.length)
    return (el.innerHTML = stateView({
      icon: 'box',
      title: L('Chưa có đơn hàng', 'No orders yet'),
      message: L('Đơn hàng của sàn sẽ hiển thị ở đây.', 'Marketplace orders will appear here.'),
    }));

  const statuses = ['pending', 'confirmed', 'shipping', 'completed', 'cancelled'];
  const statusOpts = [`<option value="">${L('Tất cả trạng thái', 'All statuses')}</option>`]
    .concat(
      statuses.map(
        (s) =>
          `<option value="${s}" ${orderFilter.status === s ? 'selected' : ''}>${statusLabel(s)}</option>`
      )
    )
    .join('');

  el.innerHTML = `
    <div class="toolbar">
      <select id="fStatus">${statusOpts}</select>
      <span class="toolbar__lbl">${L('Từ', 'From')}</span>
      <input id="fFrom" type="date" value="${orderFilter.from}" />
      <span class="toolbar__lbl">${L('đến', 'to')}</span>
      <input id="fTo" type="date" value="${orderFilter.to}" />
      <input id="fQ" type="search" placeholder="${L('Tìm mã / khách / shop', 'Search code / customer / shop')}" value="${escapeHtml(orderFilter.q)}" style="min-width:200px" />
      <button class="btn btn--ghost btn--sm" data-action="orders-clear">${L('Xóa lọc', 'Clear')}</button>
      <span class="tb-sep"></span>
      <span class="toolbar__count" id="ordersCount"></span>
    </div>
    <div class="panel"><table class="table">
    <thead><tr><th>${L('Mã đơn', 'Order')}</th><th>${L('Khách', 'Customer')}</th><th>Shop</th><th>${L('Trạng thái', 'Status')}</th><th>${L('Thanh toán', 'Payment')}</th><th>${L('Tổng', 'Total')}</th><th>${L('Ngày', 'Date')}</th></tr></thead>
    <tbody id="ordersBody"></tbody></table></div>`;

  document.getElementById('fStatus').addEventListener('change', (e) => {
    orderFilter.status = e.target.value;
    renderOrdersTable();
  });
  document.getElementById('fFrom').addEventListener('change', (e) => {
    orderFilter.from = e.target.value;
    renderOrdersTable();
  });
  document.getElementById('fTo').addEventListener('change', (e) => {
    orderFilter.to = e.target.value;
    renderOrdersTable();
  });
  document.getElementById('fQ').addEventListener('input', (e) => {
    orderFilter.q = e.target.value;
    renderOrdersTable();
  });
  renderOrdersTable();
}

// ---------- View: Danh mục ----------
async function viewCategories(el) {
  const cats = await Api.get('/categories');
  const rows = cats
    .map(
      (c) => `<tr><td>${c.id}</td><td>${escapeHtml(c.name)}</td>
    <td class="muted">${escapeHtml(c.slug)}</td><td>${escapeHtml(c.icon || '')}</td></tr>`
    )
    .join('');

  el.innerHTML = `
    <div class="section-head">
      <h3>${L('Danh mục sản phẩm', 'Product categories')}</h3><div class="spacer"></div>
      <button class="btn btn--primary btn--sm" data-action="add-cat">+ ${L('Thêm danh mục', 'Add category')}</button>
    </div>
    <div class="panel"><table class="table">
      <thead><tr><th>ID</th><th>${L('Tên', 'Name')}</th><th>Slug</th><th>Icon</th></tr></thead>
      <tbody>${rows}</tbody></table></div>`;
}

function slugify(str) {
  return (str || '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '') // bỏ dấu tiếng Việt
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function addCategoryModal() {
  openModal(`
    <button class="modal__close" data-action="close">×</button>
    <h2>${L('Thêm danh mục', 'Add category')}</h2>
    <p class="modal__sub">${L('Tạo nhóm sản phẩm mới cho sàn', 'Create a new product group for the marketplace')}</p>
    <form id="catForm">
      <div class="field"><label>${L('Tên danh mục', 'Category name')}</label><input name="name" placeholder="${L('vd: Đồ chơi', 'e.g. Toys')}" required autofocus/></div>
      <div class="field"><label>${L('Slug (tự tạo từ tên, có thể sửa)', 'Slug (auto from name, editable)')}</label><input name="slug" placeholder="${L('vd: do-choi', 'e.g. toys')}" required/></div>
      <div class="field"><label>${L('Icon (tên material — không bắt buộc)', 'Icon (material name — optional)')}</label><input name="icon" placeholder="${L('vd: toys', 'e.g. toys')}"/></div>
      <button class="btn btn--primary btn--block" type="submit">${L('Lưu danh mục', 'Save category')}</button>
    </form>`);

  const form = document.getElementById('catForm');
  let slugEdited = false;
  form.slug.addEventListener('input', () => (slugEdited = true));
  form.name.addEventListener('input', () => {
    if (!slugEdited) form.slug.value = slugify(form.name.value);
  });

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const f = e.target;
    try {
      await Api.post('/categories', {
        name: f.name.value.trim(),
        slug: f.slug.value.trim(),
        icon: f.icon.value.trim() || null,
      });
      closeModal();
      toast(L('Đã thêm danh mục', 'Category added'));
      route();
    } catch (err) {
      toast(err.message);
    }
  });
}

// ---------- Sự kiện ----------
document.addEventListener('click', async (e) => {
  const nav = e.target.closest('[data-nav]');
  if (nav) {
    location.hash = '#/' + nav.getAttribute('data-nav');
    return;
  }

  const el = e.target.closest('[data-action]');
  if (!el) return;
  const action = el.getAttribute('data-action');

  if (action === 'lang-vi') {
    if (lang !== 'vi') setLang('vi');
  } else if (action === 'lang-en') {
    if (lang !== 'en') setLang('en');
  } else if (action === 'theme-system') {
    setTheme('system');
  } else if (action === 'theme-light') {
    setTheme('light');
  } else if (action === 'theme-dark') {
    setTheme('dark');
  } else if (action === 'reload') {
    route();
  } else if (action === 'chart-prev') {
    chartView.offset -= 1;
    rerenderChart();
  } else if (action === 'chart-next') {
    if (chartView.offset < 0) chartView.offset += 1;
    rerenderChart();
  } else if (action === 'chart-today') {
    chartView.offset = 0;
    rerenderChart();
  } else if (action === 'orders-clear') {
    orderFilter.status = '';
    orderFilter.from = '';
    orderFilter.to = '';
    orderFilter.q = '';
    route();
  } else if (action === 'chart-mode-week' || action === 'chart-mode-month') {
    const mode = action === 'chart-mode-month' ? 'month' : 'week';
    if (chartView.mode !== mode) {
      chartView.mode = mode;
      chartView.offset = 0;
      rerenderChart();
    }
  } else if (action === 'logout') {
    e.preventDefault();
    if (!confirm(L('Đăng xuất khỏi trang quản trị?', 'Sign out of the admin panel?'))) return;
    Api.setToken(null);
    state.user = null;
    location.hash = '';
    renderLogin();
  } else if (action === 'close') {
    closeModal();
  } else if (action === 'close-bg') {
    if (e.target === el) closeModal();
  } else if (action === 'toggle-user') {
    try {
      await Api.put(`/admin/users/${el.getAttribute('data-id')}/status`, {
        isActive: el.getAttribute('data-active') === '1',
      });
      toast(L('Đã cập nhật tài khoản', 'Account updated'));
      route();
    } catch (err) {
      toast(err.message);
    }
  } else if (action === 'add-cat') {
    addCategoryModal();
  } else if (action === 'add-product') {
    productFormModal();
  } else if (action === 'edit-product') {
    productFormModal(el.getAttribute('data-id'));
  } else if (action === 'del-product') {
    if (
      confirm(
        L(
          `Xóa sản phẩm "${el.getAttribute('data-name')}"?`,
          `Delete product "${el.getAttribute('data-name')}"?`
        )
      )
    ) {
      try {
        await Api.del('/admin/products/' + el.getAttribute('data-id'));
        toast(L('Đã xóa sản phẩm', 'Product deleted'));
        route();
      } catch (err) {
        toast(err.message);
      }
    }
  } else if (action === 'var-add') {
    const box = document.getElementById('variants');
    if (box) box.insertAdjacentHTML('beforeend', variantRowHtml());
  } else if (action === 'var-remove') {
    const row = el.closest('.var-row');
    const box = document.getElementById('variants');
    if (row && box && box.children.length > 1) row.remove();
  }
});

window.addEventListener('hashchange', route);

// ---------- Khởi động ----------
(async function init() {
  await loadUser();
  route();
})();
