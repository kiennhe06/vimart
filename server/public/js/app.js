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
};
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
          <div class="circle-btn" title="${L('Tìm kiếm', 'Search')}">${ic('search', 'i20')}</div>
          <div class="circle-btn" title="${L('Thông báo', 'Notifications')}">${ic('bell', 'i20')}</div>
          <div class="avatar" data-action="logout" title="${L('Đăng xuất', 'Sign out')} (${escapeHtml(state.user.fullName)})">${initial}</div>
        </div>
      </header>
      <main class="content" id="content"><div class="center-msg">${L('Đang tải...', 'Loading...')}</div></main>
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
    content.innerHTML = `<div class="center-msg">${escapeHtml(err.message)}</div>`;
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

  el.innerHTML = `<div class="dash">
    <div class="dash__col">${heroCard(s)}${revenueFlowCard(orders)}${recentOrdersCard(orders)}</div>
    <div class="dash__col">${miniCard(ic('box', 'i20'), 'rgba(55,214,122,.16)', '#37d67a', L('Tổng đơn hàng', 'Total orders'), s.totalOrders, 'up')}
      ${miniCard(ic('bag', 'i20'), 'rgba(244,81,30,.16)', '#ff9a3d', L('Sản phẩm đang bán', 'Active products'), s.totalProducts, null)}
      ${categoryDonutCard(products, cats)}</div>
    <div class="dash__col">${vmartCard(s)}${categoryListCard(products, cats)}</div>
  </div>`;
}

/** Thẻ số dư lớn = doanh thu. */
function heroCard(s) {
  return `<div class="hero">
    <div class="hero__tools"><span class="hero__tool">${ic('grid', 'i16')}</span><span class="hero__tool">${ic('file', 'i16')}</span></div>
    <div class="hero__label">${L('Doanh thu (đơn hoàn thành)', 'Revenue (completed orders)')}</div>
    <div class="hero__value">${fmtVnd(s.totalRevenue)}</div>
    <div class="hero__sub">${L(`+${s.totalOrders} đơn · ${s.totalUsers} người dùng trên sàn`, `+${s.totalOrders} orders · ${s.totalUsers} users on the platform`)}</div>
    <div class="hero__actions">
      <button class="hero__btn hero__btn--dark" data-nav="orders">${L('Xem đơn hàng', 'View orders')}</button>
      <button class="hero__btn hero__btn--light" data-nav="products">${L('Sản phẩm', 'Products')}</button>
    </div>
  </div>`;
}

function miniCard(icon, iconBg, iconColor, label, value, trend) {
  const badge =
    trend === 'up'
      ? `<span class="pill pill--up">● ${L('Hoạt động', 'Active')}</span>`
      : trend === 'down'
        ? '<span class="pill pill--down">▼</span>'
        : '';
  return `<div class="mini">
    <div class="mini__row">
      <div class="mini__icon" style="background:${iconBg};color:${iconColor}">${icon}</div>
      <div class="mini__label">${label}</div>
      <div class="spacer" style="flex:1"></div>${badge}
    </div>
    <div class="mini__value">${value}</div>
  </div>`;
}

/** Biểu đồ cột: số đơn theo 7 ngày gần nhất. */
function revenueFlowCard(orders) {
  const days = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    days.push({
      key: d.toISOString().slice(0, 10),
      label: `${d.getDate()}/${d.getMonth() + 1}`,
      count: 0,
    });
  }
  orders.forEach((o) => {
    const k = (o.created_at || '').slice(0, 10);
    const day = days.find((x) => x.key === k);
    if (day) day.count++;
  });
  const max = Math.max(1, ...days.map((d) => d.count));
  const totalWeek = days.reduce((sum, d) => sum + d.count, 0) || 1;
  const hotIdx = days.reduce((best, d, i, a) => (d.count > a[best].count ? i : best), 0);

  const bars = days
    .map((d, i) => {
      const hot = i === hotIdx && d.count > 0;
      const tag = hot
        ? `<div class="bar__tag">+${Math.round((d.count / totalWeek) * 100)}%</div>`
        : '';
      return `<div class="bar-col">
      <div class="bar-wrap">${tag}
        <div class="bar ${hot ? 'bar--hot' : ''}" style="height:${Math.max(8, Math.round((d.count / max) * 100))}%" title="${L(`${d.count} đơn`, `${d.count} orders`)}"></div>
      </div>
      <div class="bar-lbl">${d.label}</div>
    </div>`;
    })
    .join('');

  return `<div class="dcard">
    <div class="dcard__head"><h4>${L('Đơn hàng theo ngày', 'Orders by day')}</h4><div class="spacer"></div>
      <span class="pill pill--soft">${L('7 ngày', '7 days')}</span></div>
    <div class="bars">${bars}</div>
  </div>`;
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
        <div class="litem__sub">${escapeHtml(o.buyer_name || '')} · ${fmtDate(o.created_at).split(' ')[1] || ''}</div></div>
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

/** Thẻ ViMart (mô phỏng thẻ) + số liệu người dùng/shop. */
function vmartCard(s) {
  return `<div class="vcard">
    <div class="vcard__brand">Vi<span>Mart</span> · ${L('Sàn TMĐT', 'Marketplace')}</div>
    <div class="vcard__num">•••• ${String(s.totalOrders).padStart(4, '0')} ••••</div>
    <div class="vcard__foot">
      <div><div style="opacity:.7;font-size:11px">${L('Người dùng', 'Users')}</div><b>${s.totalUsers}</b></div>
      <div><div style="opacity:.7;font-size:11px">${L('Shop', 'Shops')}</div><b>${s.totalShops}</b></div>
      <div><div style="opacity:.7;font-size:11px">${L('Sản phẩm', 'Products')}</div><b>${s.totalProducts}</b></div>
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
async function viewOrders(el) {
  const orders = await Api.get('/admin/orders'); // trả snake_case từ DB
  if (!orders.length)
    return (el.innerHTML = `<div class="center-msg">${L('Chưa có đơn hàng nào', 'No orders yet')}</div>`);
  const rows = orders
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

  el.innerHTML = `<div class="panel"><table class="table">
    <thead><tr><th>${L('Mã đơn', 'Order')}</th><th>${L('Khách', 'Customer')}</th><th>Shop</th><th>${L('Trạng thái', 'Status')}</th><th>${L('Thanh toán', 'Payment')}</th><th>${L('Tổng', 'Total')}</th><th>${L('Ngày', 'Date')}</th></tr></thead>
    <tbody>${rows}</tbody></table></div>`;
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
