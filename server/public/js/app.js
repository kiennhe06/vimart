/* ============================================================
   app.js — Trang QUẢN TRỊ (Admin) ViMart. JS thuần.
   Khách hàng dùng app Flutter; web này chỉ dành cho admin quản lý sàn.
   Dùng các API /api/admin/* + /api/categories (đều yêu cầu quyền admin).
   ============================================================ */

const app = document.getElementById('app');
const modalRoot = document.getElementById('modalRoot');

const state = { user: null };

const NAV = [
  { key: 'dashboard', icon: '📊', label: 'Tổng quan' },
  { key: 'products', icon: '🛍️', label: 'Sản phẩm' },
  { key: 'users', icon: '👥', label: 'Người dùng' },
  { key: 'orders', icon: '📦', label: 'Đơn hàng' },
  { key: 'categories', icon: '🏷️', label: 'Danh mục' },
];

const STATUS = {
  pending: ['Chờ xác nhận', '#f59e0b'],
  confirmed: ['Đã xác nhận', '#2563eb'],
  shipping: ['Đang giao', '#7c3aed'],
  completed: ['Hoàn thành', '#2e7d32'],
  cancelled: ['Đã hủy', '#d32f2f'],
};

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
  return String(v ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}
function toast(msg) {
  const el = document.getElementById('toast');
  el.textContent = msg;
  el.hidden = false;
  clearTimeout(el._t);
  el._t = setTimeout(() => (el.hidden = true), 2600);
}
function statusChip(s) {
  const [label, color] = STATUS[s] || [s, '#888'];
  return `<span class="status" style="color:${color};background:${color}22">${label}</span>`;
}
function openModal(html) {
  modalRoot.innerHTML = `<div class="overlay" data-action="close-bg"><div class="modal">${html}</div></div>`;
}
function closeModal() { modalRoot.innerHTML = ''; }

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
        <h1>ViMart Admin</h1>
        <p>Trang quản trị sàn — chỉ dành cho admin</p>
        ${message ? `<p style="color:var(--danger)">${escapeHtml(message)}</p>` : ''}
        <form id="loginForm">
          <div class="field"><label>Email</label><input name="email" type="email" required value="admin@vimart.vn"/></div>
          <div class="field"><label>Mật khẩu</label><input name="password" type="password" required/></div>
          <button class="btn btn--primary btn--block" type="submit">Đăng nhập</button>
        </form>
        <p style="margin-top:16px">Tài khoản admin thử: admin@vimart.vn / 123456</p>
      </div>
    </div>`;

  document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const f = e.target;
    try {
      const res = await Api.post('/auth/login', { email: f.email.value.trim(), password: f.password.value });
      if (res.user.role !== 'admin') {
        Api.setToken(null);
        return renderLogin('Tài khoản này không phải admin. Vui lòng dùng tài khoản quản trị.');
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
  const tabs = NAV.map((n) => `
    <div class="tab ${n.key === activeKey ? 'tab--active' : ''}" data-nav="${n.key}">${n.label}</div>`).join('');
  const initial = (state.user.fullName || '?').charAt(0).toUpperCase();

  app.innerHTML = `
    <div class="appwrap">
      <header class="topnav">
        <div class="topnav__brand">Vi<span>Mart</span></div>
        <nav class="tabs">${tabs}</nav>
        <div class="topnav__actions">
          <div class="circle-btn" title="Tìm kiếm">${ic('search', 'i20')}</div>
          <div class="circle-btn" title="Thông báo">${ic('bell', 'i20')}</div>
          <div class="avatar" data-action="logout" title="Đăng xuất (${escapeHtml(state.user.fullName)})">${initial}</div>
        </div>
      </header>
      <main class="content" id="content"><div class="center-msg">Đang tải...</div></main>
    </div>`;
}

// ---------- Định tuyến ----------
function currentKey() {
  const k = (location.hash.replace(/^#\//, '') || 'dashboard');
  return NAV.some((n) => n.key === k) ? k : 'dashboard';
}

async function route() {
  if (!state.user) return renderLogin();
  if (state.user.role !== 'admin') return renderLogin('Tài khoản không có quyền admin.');

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
    <div class="dash__col">${miniCard(ic('box', 'i20'), 'rgba(55,214,122,.16)', '#37d67a', 'Tổng đơn hàng', s.totalOrders, 'up')}
      ${miniCard(ic('bag', 'i20'), 'rgba(244,81,30,.16)', '#ff9a3d', 'Sản phẩm đang bán', s.totalProducts, null)}
      ${categoryDonutCard(products, cats)}</div>
    <div class="dash__col">${vmartCard(s)}${categoryListCard(products, cats)}</div>
  </div>`;
}

/** Thẻ số dư lớn = doanh thu. */
function heroCard(s) {
  return `<div class="hero">
    <div class="hero__tools"><span class="hero__tool">${ic('grid', 'i16')}</span><span class="hero__tool">${ic('file', 'i16')}</span></div>
    <div class="hero__label">Doanh thu (đơn hoàn thành)</div>
    <div class="hero__value">${fmtVnd(s.totalRevenue)}</div>
    <div class="hero__sub">+${s.totalOrders} đơn · ${s.totalUsers} người dùng trên sàn</div>
    <div class="hero__actions">
      <button class="hero__btn hero__btn--dark" data-nav="orders">Xem đơn hàng</button>
      <button class="hero__btn hero__btn--light" data-nav="products">Sản phẩm</button>
    </div>
  </div>`;
}

function miniCard(icon, iconBg, iconColor, label, value, trend) {
  const badge = trend === 'up'
    ? '<span class="pill pill--up">● Hoạt động</span>'
    : (trend === 'down' ? '<span class="pill pill--down">▼</span>' : '');
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
    days.push({ key: d.toISOString().slice(0, 10), label: `${d.getDate()}/${d.getMonth() + 1}`, count: 0 });
  }
  orders.forEach((o) => {
    const k = (o.created_at || '').slice(0, 10);
    const day = days.find((x) => x.key === k);
    if (day) day.count++;
  });
  const max = Math.max(1, ...days.map((d) => d.count));
  const totalWeek = days.reduce((sum, d) => sum + d.count, 0) || 1;
  const hotIdx = days.reduce((best, d, i, a) => (d.count > a[best].count ? i : best), 0);

  const bars = days.map((d, i) => {
    const hot = i === hotIdx && d.count > 0;
    const tag = hot ? `<div class="bar__tag">+${Math.round((d.count / totalWeek) * 100)}%</div>` : '';
    return `<div class="bar-col">
      <div class="bar-wrap">${tag}
        <div class="bar ${hot ? 'bar--hot' : ''}" style="height:${Math.max(8, Math.round((d.count / max) * 100))}%" title="${d.count} đơn"></div>
      </div>
      <div class="bar-lbl">${d.label}</div>
    </div>`;
  }).join('');

  return `<div class="dcard">
    <div class="dcard__head"><h4>Đơn hàng theo ngày</h4><div class="spacer"></div>
      <span class="pill pill--soft">7 ngày</span></div>
    <div class="bars">${bars}</div>
  </div>`;
}

/** Donut: sản phẩm theo danh mục. */
function categoryDonutCard(products, cats) {
  const name = Object.fromEntries(cats.map((c) => [c.id, c.name]));
  const counts = {};
  products.forEach((p) => {
    const n = name[p.categoryId] || 'Khác';
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

  const legend = segs.map((g) => `<div class="legend__row">
    <span class="legend__bar" style="background:${g.color}"></span>
    <div><div class="legend__cap">${escapeHtml(g.n)}</div><div class="legend__pct">${g.pct}%</div></div>
  </div>`).join('');

  return `<div class="dcard">
    <div class="dcard__head"><h4>Sản phẩm theo danh mục</h4></div>
    <div class="donut-wrap">
      <div class="donut" style="background:${gradient}">
        <div class="donut__center"><div class="donut__total">${products.length}</div><div class="donut__cap">Sản phẩm</div></div>
      </div>
      <div class="legend">${legend}</div>
    </div>
  </div>`;
}

/** Danh sách đơn hàng gần đây. */
function recentOrdersCard(orders) {
  const rows = orders.slice(0, 6).map((o) => {
    const [label, color] = STATUS[o.status] || [o.status, '#888'];
    return `<div class="litem">
      <div class="litem__icon" style="background:${color}22;color:${color}">${ic('box', 'i18')}</div>
      <div><div class="litem__name">${escapeHtml(o.code)}</div>
        <div class="litem__sub">${escapeHtml(o.buyer_name || '')} · ${fmtDate(o.created_at).split(' ')[1] || ''}</div></div>
      <div class="spacer"></div>
      <span class="status" style="color:${color};background:${color}22">${label}</span>
      <div class="litem__val" style="color:var(--orange)">${fmtVnd(o.total)}</div>
    </div>`;
  }).join('') || '<div class="muted" style="padding:12px 0">Chưa có đơn hàng nào.</div>';

  return `<div class="dcard">
    <div class="dcard__head"><h4>Đơn hàng gần đây</h4><div class="spacer"></div>
      <span class="pill pill--soft" data-nav="orders" style="cursor:pointer">Xem tất cả</span></div>
    <div class="rowlist">${rows}</div>
  </div>`;
}

/** Thẻ ViMart (mô phỏng thẻ) + số liệu người dùng/shop. */
function vmartCard(s) {
  return `<div class="vcard">
    <div class="vcard__brand">Vi<span>Mart</span> · Sàn TMĐT</div>
    <div class="vcard__num">•••• ${String(s.totalOrders).padStart(4, '0')} ••••</div>
    <div class="vcard__foot">
      <div><div style="opacity:.7;font-size:11px">Người dùng</div><b>${s.totalUsers}</b></div>
      <div><div style="opacity:.7;font-size:11px">Shop</div><b>${s.totalShops}</b></div>
      <div><div style="opacity:.7;font-size:11px">Sản phẩm</div><b>${s.totalProducts}</b></div>
    </div>
  </div>`;
}

/** Danh sách danh mục kèm số sản phẩm (kiểu subscription). */
function categoryListCard(products, cats) {
  const counts = {};
  products.forEach((p) => (counts[p.categoryId] = (counts[p.categoryId] || 0) + 1));
  const rows = cats.map((c, i) => {
    const color = PALETTE[i % PALETTE.length];
    return `<div class="litem">
      <div class="litem__icon" style="background:${color}22;color:${color}">${escapeHtml(c.name.charAt(0))}</div>
      <div><div class="litem__name">${escapeHtml(c.name)}</div>
        <div class="litem__sub">${escapeHtml(c.slug)}</div></div>
      <div class="litem__val">${counts[c.id] || 0} SP</div>
    </div>`;
  }).join('');

  return `<div class="dcard">
    <div class="dcard__head"><h4>Danh mục</h4><div class="spacer"></div>
      <span class="pill pill--soft" data-nav="categories" style="cursor:pointer">Quản lý</span></div>
    <div class="rowlist">${rows}</div>
  </div>`;
}

// ---------- View: Sản phẩm ----------
async function viewProducts(el) {
  const products = await Api.get('/admin/products');
  const rows = products.map((p) => `
    <tr>
      <td><img class="thumb" src="${escapeHtml(p.imageUrl || '')}" onerror="this.style.visibility='hidden'"/></td>
      <td>${escapeHtml(p.name)}</td>
      <td>${escapeHtml(p.shopName)}</td>
      <td><b style="color:var(--orange)">${fmtVnd(p.minPrice)}</b></td>
      <td>${p.totalStock}</td>
      <td>${p.status === 'active'
        ? '<span class="tag tag--on">Đang bán</span>'
        : '<span class="tag tag--off">Đang ẩn</span>'}</td>
      <td style="white-space:nowrap">
        <button class="btn btn--sm" data-action="edit-product" data-id="${p.id}">Sửa</button>
        <button class="btn btn--sm btn--danger" data-action="del-product" data-id="${p.id}" data-name="${escapeHtml(p.name)}">Xóa</button>
      </td>
    </tr>`).join('');

  el.innerHTML = `
    <div class="section-head"><h3>Sản phẩm (${products.length})</h3><div class="spacer"></div>
      <button class="btn btn--primary btn--sm" data-action="add-product">+ Thêm sản phẩm</button></div>
    <div class="panel"><table class="table">
      <thead><tr><th>Ảnh</th><th>Tên</th><th>Shop</th><th>Giá</th><th>Kho</th><th>Trạng thái</th><th></th></tr></thead>
      <tbody>${rows}</tbody></table></div>`;
}

/** 1 dòng nhập phân loại trong form sản phẩm. */
function variantRowHtml(v = {}) {
  return `<div class="var-row">
    <input class="var-name" placeholder="Tên (vd: Đỏ/L)" value="${escapeHtml(v.name || '')}"/>
    <input class="var-price" type="number" placeholder="Giá" value="${v.price ?? ''}"/>
    <input class="var-stock" type="number" placeholder="Kho" value="${v.stock ?? ''}"/>
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
  const variants = detail?.variants?.length ? detail.variants : [{ name: 'Mặc định', price: '', stock: '' }];

  openModal(`
    <button class="modal__close" data-action="close">×</button>
    <h2>${isEdit ? 'Sửa' : 'Thêm'} sản phẩm</h2>
    <p class="modal__sub">Điền thông tin, ảnh và phân loại (giá + tồn kho)</p>
    <form id="prodForm">
      <div class="field"><label>Ảnh sản phẩm</label>
        <div class="row" style="align-items:flex-start;gap:14px">
          <img id="imgPreview" class="thumb-lg" src="${escapeHtml(imageUrl)}" ${imageUrl ? '' : 'style="visibility:hidden"'}/>
          <div style="flex:1">
            <input type="file" id="imgFile" accept="image/*"/>
            <div id="imgStatus" class="muted" style="font-size:12px;margin:6px 0"></div>
            <input id="imgUrl" placeholder="hoặc dán link ảnh https://..." value="${escapeHtml(imageUrl)}"/>
          </div>
        </div>
      </div>
      <div class="field"><label>Tên sản phẩm</label><input name="name" required value="${escapeHtml(detail?.name || '')}"/></div>
      <div class="field"><label>Shop</label><select name="shopId">
        ${shops.map((s) => `<option value="${s.id}" ${s.id === shopId ? 'selected' : ''}>${escapeHtml(s.name)}</option>`).join('')}
      </select></div>
      <div class="field"><label>Danh mục</label><select name="categoryId">
        <option value="">— Không —</option>
        ${cats.map((c) => `<option value="${c.id}" ${c.id === catId ? 'selected' : ''}>${escapeHtml(c.name)}</option>`).join('')}
      </select></div>
      <div class="field"><label>Trạng thái</label><select name="status">
        <option value="active" ${detail?.status !== 'hidden' ? 'selected' : ''}>Đang bán</option>
        <option value="hidden" ${detail?.status === 'hidden' ? 'selected' : ''}>Đang ẩn</option>
      </select></div>
      <div class="field"><label>Mô tả</label><textarea name="description" rows="2">${escapeHtml(detail?.description || '')}</textarea></div>
      <label style="font-size:13px;color:var(--text-2)">Phân loại (giá + tồn kho)</label>
      <div id="variants">${variants.map(variantRowHtml).join('')}</div>
      <button type="button" class="btn btn--sm" data-action="var-add" style="margin:6px 0 14px">+ Thêm phân loại</button>
      <button class="btn btn--primary btn--block" type="submit">Lưu sản phẩm</button>
    </form>`);

  // Upload ảnh khi chọn file
  const preview = document.getElementById('imgPreview');
  const urlInput = document.getElementById('imgUrl');
  document.getElementById('imgFile').addEventListener('change', async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const status = document.getElementById('imgStatus');
    status.textContent = 'Đang tải ảnh...';
    try {
      const url = await Api.uploadImage(file);
      urlInput.value = url;
      preview.src = url;
      preview.style.visibility = 'visible';
      status.textContent = '✅ Đã tải ảnh';
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
      toast('Đã lưu sản phẩm');
      route();
    } catch (err) {
      toast(err.message);
    }
  });
}

// ---------- View: Người dùng ----------
async function viewUsers(el) {
  const users = await Api.get('/admin/users');
  const rows = users.map((u) => `
    <tr>
      <td>${u.id}</td>
      <td>${escapeHtml(u.fullName)}</td>
      <td>${escapeHtml(u.email)}</td>
      <td><span class="tag ${u.role === 'admin' ? 'tag--admin' : 'tag--user'}">${u.role}</span></td>
      <td>${u.shop ? escapeHtml(u.shop.name) : '<span class="muted">—</span>'}</td>
      <td><span class="tag ${u.isActive ? 'tag--on' : 'tag--off'}">${u.isActive ? 'Hoạt động' : 'Đã khóa'}</span></td>
      <td>${u.role === 'admin' ? '' : `<button class="btn btn--sm ${u.isActive ? 'btn--danger' : 'btn--ok'}"
        data-action="toggle-user" data-id="${u.id}" data-active="${u.isActive ? 0 : 1}">
        ${u.isActive ? 'Khóa' : 'Mở khóa'}</button>`}</td>
    </tr>`).join('');

  el.innerHTML = `<div class="panel"><table class="table">
    <thead><tr><th>ID</th><th>Họ tên</th><th>Email</th><th>Vai trò</th><th>Shop</th><th>Trạng thái</th><th></th></tr></thead>
    <tbody>${rows}</tbody></table></div>`;
}

// ---------- View: Đơn hàng ----------
async function viewOrders(el) {
  const orders = await Api.get('/admin/orders'); // trả snake_case từ DB
  if (!orders.length) return (el.innerHTML = '<div class="center-msg">Chưa có đơn hàng nào</div>');
  const rows = orders.map((o) => `
    <tr>
      <td><b>${escapeHtml(o.code)}</b></td>
      <td>${escapeHtml(o.buyer_name)}</td>
      <td>${escapeHtml(o.shop_name)}</td>
      <td>${statusChip(o.status)}</td>
      <td>${o.payment_method === 'cod' ? 'COD' : 'VNPay'}
        ${o.payment_status === 'paid' ? '<span class="tag tag--on">Đã trả</span>' : '<span class="muted">Chưa trả</span>'}</td>
      <td><b style="color:var(--orange)">${fmtVnd(o.total)}</b></td>
      <td class="muted">${fmtDate(o.created_at)}</td>
    </tr>`).join('');

  el.innerHTML = `<div class="panel"><table class="table">
    <thead><tr><th>Mã đơn</th><th>Khách</th><th>Shop</th><th>Trạng thái</th><th>Thanh toán</th><th>Tổng</th><th>Ngày</th></tr></thead>
    <tbody>${rows}</tbody></table></div>`;
}

// ---------- View: Danh mục ----------
async function viewCategories(el) {
  const cats = await Api.get('/categories');
  const rows = cats.map((c) => `<tr><td>${c.id}</td><td>${escapeHtml(c.name)}</td>
    <td class="muted">${escapeHtml(c.slug)}</td><td>${escapeHtml(c.icon || '')}</td></tr>`).join('');

  el.innerHTML = `
    <div class="section-head">
      <h3>Danh mục sản phẩm</h3><div class="spacer"></div>
      <button class="btn btn--primary btn--sm" data-action="add-cat">+ Thêm danh mục</button>
    </div>
    <div class="panel"><table class="table">
      <thead><tr><th>ID</th><th>Tên</th><th>Slug</th><th>Icon</th></tr></thead>
      <tbody>${rows}</tbody></table></div>`;
}

function slugify(str) {
  return (str || '')
    .normalize('NFD').replace(/[̀-ͯ]/g, '') // bỏ dấu tiếng Việt
    .replace(/đ/g, 'd').replace(/Đ/g, 'D')
    .toLowerCase().trim()
    .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
}

function addCategoryModal() {
  openModal(`
    <button class="modal__close" data-action="close">×</button>
    <h2>Thêm danh mục</h2>
    <p class="modal__sub">Tạo nhóm sản phẩm mới cho sàn</p>
    <form id="catForm">
      <div class="field"><label>Tên danh mục</label><input name="name" placeholder="vd: Đồ chơi" required autofocus/></div>
      <div class="field"><label>Slug (tự tạo từ tên, có thể sửa)</label><input name="slug" placeholder="vd: do-choi" required/></div>
      <div class="field"><label>Icon (tên material — không bắt buộc)</label><input name="icon" placeholder="vd: toys"/></div>
      <button class="btn btn--primary btn--block" type="submit">Lưu danh mục</button>
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
      toast('Đã thêm danh mục');
      route();
    } catch (err) {
      toast(err.message);
    }
  });
}

// ---------- Sự kiện ----------
document.addEventListener('click', async (e) => {
  const nav = e.target.closest('[data-nav]');
  if (nav) { location.hash = '#/' + nav.getAttribute('data-nav'); return; }

  const el = e.target.closest('[data-action]');
  if (!el) return;
  const action = el.getAttribute('data-action');

  if (action === 'logout') {
    e.preventDefault();
    if (!confirm('Đăng xuất khỏi trang quản trị?')) return;
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
      await Api.put(`/admin/users/${el.getAttribute('data-id')}/status`,
        { isActive: el.getAttribute('data-active') === '1' });
      toast('Đã cập nhật tài khoản');
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
    if (confirm(`Xóa sản phẩm "${el.getAttribute('data-name')}"?`)) {
      try {
        await Api.del('/admin/products/' + el.getAttribute('data-id'));
        toast('Đã xóa sản phẩm');
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
