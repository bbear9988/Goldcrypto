    const txId = `TX${Date.now().toString().slice(-6)}`;
    const txSender = {
        id: txId,
        userId: sender.id,
        username: sender.username,
        type: 'TRANSFER_OUT',
        amount: Number(amount),
        status: 'SUCCESS',
        method: 'INTERNAL',
        description: `Chuyển tiền tới @${receiver.username}: ${note || 'Chuyển khoản nội bộ'}`,
        createdAt: new Date().toLocaleString('vi-VN')
    };

    transactions.unshift(txSender);

    res.json({
        success: true,
        message: `Chuyển thành công ${Number(amount).toLocaleString('vi-VN')} VNĐ cho @${receiver.username}`,
        senderNewBalance: sender.balance,
        transaction: txSender
    });
});

// ==================== API DÀNH CHO ADMIN ====================

app.post('/api/admin/login', (req, res) => {
    const { username, password } = req.body;
    if (username === 'admin' && password === '123') {
        return res.json({ success: true, token: 'fake-jwt-token-123' });
    }
    return res.status(401).json({ success: false, message: 'Sai tài khoản hoặc mật khẩu' });
});

app.get('/api/admin/overview', authMiddleware, (req, res) => {
    const totalBalance = users.reduce((sum, u) => sum + u.balance, 0);
    res.json({
        success: true,
        data: {
            totalUsers: users.length,
            activeUsers: users.filter(u => u.status === 'ACTIVE').length,
            onlineUsers: users.filter(u => u.isOnline).length,
            totalTransactions: transactions.length,
            totalBalance: totalBalance
        }
    });
});

app.get('/api/admin/users', authMiddleware, (req, res) => {
    res.json({ success: true, data: users });
});

app.get('/api/admin/transactions', authMiddleware, (req, res) => {
    res.json({ success: true, data: transactions });
});

app.get('/admin', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});

app.listen(PORT, () => {
    console.log(`🚀 Server Admin Finance đang chạy tại: http://localhost:${PORT}`);
});
EOF

pkill -f node && node server.js &
cat << 'EOF' > public/index.html
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ví Điện Tử Finance App</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body class="bg-gray-100 text-gray-800 font-sans pb-12">

    <!-- Header TopBar -->
    <header class="bg-blue-600 text-white p-4 shadow-md sticky top-0 z-50">
        <div class="max-w-md mx-auto flex justify-between items-center">
            <div class="flex items-center space-x-2">
                <i class="fa-solid fa-wallet text-2xl"></i>
                <h1 class="font-bold text-lg">Finance Wallet</h1>
            </div>
            <!-- Chuyển Đổi User để Test -->
            <select id="user-selector" onchange="changeUser()" class="bg-blue-700 text-white text-xs px-2 py-1.5 rounded border border-blue-500 outline-none">
                <option value="101">TK: nguyenvana</option>
                <option value="102">TK: tranvanb</option>
                <option value="103">TK: lethic</option>
            </select>
        </div>
    </header>

    <main class="max-w-md mx-auto p-4 space-y-4">
        
        <!-- Thẻ Số Dư -->
        <div class="bg-gradient-to-r from-blue-600 to-indigo-700 rounded-2xl p-6 text-white shadow-xl relative overflow-hidden">
            <p class="text-xs text-blue-200 uppercase font-semibold">Tài khoản chính</p>
            <h2 id="user-name" class="text-lg font-bold mt-0.5">nguyenvana</h2>
            <div class="mt-4">
                <p class="text-xs text-blue-200">Số dư khả dụng</p>
                <p id="user-balance" class="text-3xl font-extrabold tracking-tight mt-0.5">5.000.000 VNĐ</p>
            </div>
            <i class="fa-solid fa-building-columns absolute right-4 bottom-4 text-6xl text-white/10"></i>
        </div>

        <!-- Phím Thao Tác Nhanh -->
        <div class="grid grid-cols-2 gap-3">
            <button onclick="openModal('deposit-modal')" class="bg-white p-4 rounded-xl shadow-sm border border-gray-200 flex items-center space-x-3 hover:bg-gray-50 active:scale-95 transition">
                <div class="w-10 h-10 rounded-full bg-green-100 text-green-600 flex items-center justify-center font-bold">
                    <i class="fa-solid fa-qrcode text-lg"></i>
                </div>
                <div class="text-left">
                    <p class="font-bold text-sm">Nạp Tiền</p>
                    <p class="text-xs text-gray-400">Chuyển khoản / QR</p>
                </div>
            </button>

            <button onclick="openModal('transfer-modal')" class="bg-white p-4 rounded-xl shadow-sm border border-gray-200 flex items-center space-x-3 hover:bg-gray-50 active:scale-95 transition">
                <div class="w-10 h-10 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center font-bold">
                    <i class="fa-solid fa-paper-plane text-sm"></i>
                </div>
                <div class="text-left">
                    <p class="font-bold text-sm">Chuyển Tiền</p>
                    <p class="text-xs text-gray-400">Nội bộ ví</p>
                </div>
            </button>
        </div>

        <!-- Thông báo Trạng Thái -->
        <div id="alert-msg" class="hidden p-3 rounded-xl text-sm text-center font-medium"></div>

    </main>

    <!-- MODAL 1: NẠP TIỀN NGÂN HÀNG -->
    <div id="deposit-modal" class="fixed inset-0 bg-black/60 hidden items-center justify-center p-4 z-50">
        <div class="bg-white rounded-2xl w-full max-w-sm p-5 space-y-4">
            <div class="flex justify-between items-center border-b pb-2">
                <h3 class="font-bold text-gray-800">Nạp Tiền Qua Ngân Hàng</h3>
                <button onclick="closeModal('deposit-modal')" class="text-gray-400 hover:text-gray-600"><i class="fa-solid fa-xmark text-lg"></i></button>
            </div>
            <form onsubmit="handleDeposit(event)" class="space-y-3">
                <div>
                    <label class="block text-xs font-semibold text-gray-600 mb-1">Chọn Ngân Hàng</label>
                    <select id="dep-bank" class="w-full p-2.5 border rounded-lg text-sm bg-gray-50">
                        <option value="MBBank">MBBank (Quân Đội)</option>
                        <option value="Vietcombank">Vietcombank</option>
                        <option value="Techcombank">Techcombank</option>
                    </select>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-gray-600 mb-1">Số Tiền Nạp (VNĐ)</label>
                    <input type="number" id="dep-amount" min="10000" step="10000" value="100000" required class="w-full p-2.5 border rounded-lg text-sm">
                </div>
                <!-- Ảnh QR Minh Họa VietQR -->
                <div class="text-center bg-gray-50 p-3 rounded-lg border border-dashed">
                    <p class="text-xs text-gray-500 mb-2">Quét mã QR để chuyển khoản nhanh</p>
                    <img id="qr-code-img" src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=VCB-123456789" class="w-32 h-32 mx-auto rounded shadow-sm">
                </div>
                <button type="submit" class="w-full py-2.5 bg-green-600 text-white font-bold text-sm rounded-lg hover:bg-green-700 transition">Xác Nhận Đã Chuyển Tiền</button>
            </form>
        </div>
    </div>

    <!-- MODAL 2: CHUYỂN TIỀN NỘI BỘ -->
    <div id="transfer-modal" class="fixed inset-0 bg-black/60 hidden items-center justify-center p-4 z-50">
        <div class="bg-white rounded-2xl w-full max-w-sm p-5 space-y-4">
            <div class="flex justify-between items-center border-b pb-2">
                <h3 class="font-bold text-gray-800">Chuyển Tiền Cho Tài Khoản Khác</h3>
                <button onclick="closeModal('transfer-modal')" class="text-gray-400 hover:text-gray-600"><i class="fa-solid fa-xmark text-lg"></i></button>
            </div>
            <form onsubmit="handleTransfer(event)" class="space-y-3">
                <div>
                    <label class="block text-xs font-semibold text-gray-600 mb-1">Tài khoản người nhận (Username)</label>
                    <input type="text" id="trf-receiver" placeholder="Ví dụ: tranvanb" required class="w-full p-2.5 border rounded-lg text-sm">
                </div>
                <div>
                    <label class="block text-xs font-semibold text-gray-600 mb-1">Số tiền chuyển (VNĐ)</label>
                    <input type="number" id="trf-amount" min="1000" required class="w-full p-2.5 border rounded-lg text-sm">
                </div>
                <div>
                    <label class="block text-xs font-semibold text-gray-600 mb-1">Lời nhắn</label>
                    <input type="text" id="trf-note" value="Chuyển tiền" class="w-full p-2.5 border rounded-lg text-sm">
                </div>
                <button type="submit" class="w-full py-2.5 bg-blue-600 text-white font-bold text-sm rounded-lg hover:bg-blue-700 transition">Xác Nhận Chuyển Tiền</button>
            </form>
        </div>
    </div>

    <script>
        let currentUserId = 101;

        const usersData = {
            101: { name: 'nguyenvana', balance: 5000000 },
            102: { name: 'tranvanb', balance: 1200000 },
            103: { name: 'lethic', balance: 350000 }
        };

        function changeUser() {
            currentUserId = Number(document.getElementById('user-selector').value);
            updateUI();
        }

        function updateUI() {
            const user = usersData[currentUserId];
            document.getElementById('user-name').textContent = user.name;
            document.getElementById('user-balance').textContent = user.balance.toLocaleString('vi-VN') + ' VNĐ';
        }

        function openModal(id) { document.getElementById(id).classList.remove('hidden'); document.getElementById(id).classList.add('flex'); }
        function closeModal(id) { document.getElementById(id).classList.add('hidden'); document.getElementById(id).classList.remove('flex'); }

        function showAlert(msg, isSuccess) {
            const el = document.getElementById('alert-msg');
            el.textContent = msg;
            el.className = `p-3 rounded-xl text-sm text-center font-medium block ${isSuccess ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`;
            setTimeout(() => el.classList.add('hidden'), 4000);
        }

        async function handleDeposit(e) {
            e.preventDefault();
            const amount = Number(document.getElementById('dep-amount').value);
            const bankName = document.getElementById('dep-bank').value;

            try {
                const res = await fetch('/api/user/deposit', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ userId: currentUserId, amount, bankName, accountNumber: '99998888' })
                });
                const data = await res.json();
                if (data.success) {
                    usersData[currentUserId].balance = data.newBalance;
                    updateUI();
                    closeModal('deposit-modal');
                    showAlert(data.message, true);
                } else { showAlert(data.message, false); }
            } catch (err) { showAlert('Lỗi kết nối máy chủ!', false); }
        }

        async function handleTransfer(e) {
            e.preventDefault();
            const receiverUsername = document.getElementById('trf-receiver').value;
            const amount = Number(document.getElementById('trf-amount').value);
            const note = document.getElementById('trf-note').value;

            try {
                const res = await fetch('/api/user/transfer', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ senderId: currentUserId, receiverUsername, amount, note })
                });
                const data = await res.json();
                if (data.success) {
                    usersData[currentUserId].balance = data.senderNewBalance;
                    updateUI();
                    closeModal('transfer-modal');
                    showAlert(data.message, true);
                } else { showAlert(data.message, false); }
            } catch (err) { showAlert('Lỗi kết nối máy chủ!', false); }
        }

        updateUI();
    </script>
</body>
</html>
EOF

cat << 'EOF' > server.js
const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

let users = [
    { id: 101, username: 'nguyenvana', email: 'nguyenvana@gmail.com', balance: 5000000, status: 'ACTIVE', isOnline: true, lastActive: 'Vừa xong' },
    { id: 102, username: 'tranvanb', email: 'tranvanb@gmail.com', balance: 1200000, status: 'ACTIVE', isOnline: true, lastActive: '2 phút trước' },
    { id: 103, username: 'lethic', email: 'lethic@gmail.com', balance: 350000, status: 'ACTIVE', isOnline: false, lastActive: '15 phút trước' }
];

let transactions = [
    { id: 'TX1001', userId: 101, username: 'nguyenvana', type: 'DEPOSIT', amount: 2000000, status: 'SUCCESS', method: 'BANK_TRANSFER', description: 'Nạp tiền qua Vietcombank', createdAt: new Date().toLocaleString('vi-VN') }
];

const authMiddleware = (req, res, next) => {
    const token = req.headers['authorization']?.split(' ')[1];
    if (!token || token !== 'fake-jwt-token-123') {
        return res.status(401).json({ success: false, message: 'Token không hợp lệ' });
    }
    next();
};

app.post('/api/user/deposit', (req, res) => {
    const { userId, amount, bankName, accountNumber } = req.body;
    const user = users.find(u => u.id === Number(userId));
    if (!user) return res.status(404).json({ success: false, message: 'Người dùng không tồn tại' });
    if (!amount || amount < 10000) return res.status(400).json({ success: false, message: 'Tối thiểu 10.000 VNĐ' });

    user.balance += Number(amount);
    const newTx = {
        id: `TX${Date.now().toString().slice(-6)}`,
        userId: user.id,
        username: user.username,
        type: 'DEPOSIT',
        amount: Number(amount),
        status: 'SUCCESS',
        method: `BANK (${bankName || 'MBBank'})`,
        description: `Nạp tiền từ STK ${accountNumber || 'xxxx'}`,
        createdAt: new Date().toLocaleString('vi-VN')
    };
    transactions.unshift(newTx);

    res.json({ success: true, message: `Nạp thành công ${Number(amount).toLocaleString('vi-VN')} VNĐ!`, newBalance: user.balance, transaction: newTx });
});

app.post('/api/user/transfer', (req, res) => {
    const { senderId, receiverUsername, amount, note } = req.body;
    const sender = users.find(u => u.id === Number(senderId));
    const receiver = users.find(u => u.username === receiverUsername);

    if (!sender || !receiver) return res.status(404).json({ success: false, message: 'Tài khoản không tồn tại' });
    if (sender.id === receiver.id) return res.status(400).json({ success: false, message: 'Không thể tự chuyển cho chính mình' });
    if (sender.balance < Number(amount)) return res.status(400).json({ success: false, message: 'Số dư không đủ' });

    sender.balance -= Number(amount);
    receiver.balance += Number(amount);

    const txSender = {
        id: `TX${Date.now().toString().slice(-6)}`,
        userId: sender.id,
        username: sender.username,
        type: 'TRANSFER_OUT',
        amount: Number(amount),
        status: 'SUCCESS',
        method: 'INTERNAL',
        description: `Chuyển tới @${receiver.username}: ${note || 'Chuyển tiền'}`,
        createdAt: new Date().toLocaleString('vi-VN')
    };
    transactions.unshift(txSender);

    res.json({ success: true, message: `Chuyển thành công ${Number(amount).toLocaleString('vi-VN')} VNĐ cho @${receiver.username}`, senderNewBalance: sender.balance, transaction: txSender });
});

app.post('/api/admin/login', (req, res) => {
    const { username, password } = req.body;
    if (username === 'admin' && password === '123') return res.json({ success: true, token: 'fake-jwt-token-123' });
    return res.status(401).json({ success: false, message: 'Sai tài khoản hoặc mật khẩu' });
});

app.get('/api/admin/overview', authMiddleware, (req, res) => {
    res.json({
        success: true,
        data: {
            totalUsers: users.length,
            activeUsers: users.filter(u => u.status === 'ACTIVE').length,
            onlineUsers: users.filter(u => u.isOnline).length,
            totalTransactions: transactions.length,
            totalBalance: users.reduce((sum, u) => sum + u.balance, 0)
        }
    });
});

app.get('/api/admin/users', authMiddleware, (req, res) => res.json({ success: true, data: users }));
app.get('/api/admin/transactions', authMiddleware, (req, res) => res.json({ success: true, data: transactions }));

app.get('/admin', (req, res) => res.sendFile(path.join(__dirname, 'public', 'admin.html')));
app.get('*', (req, res) => res.sendFile(path.join(__dirname, 'public', 'index.html')));

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server đang chạy tại cổng ${PORT}`);
});
EOF

pkill -f node && node server.js &
pkill -f node && node server.js &
cat << 'EOF' > server.js
const express = require('express');
const path = require('path');
const app = express();
const PORT = 8080;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

let users = [
    { id: 101, username: 'nguyenvana', email: 'nguyenvana@gmail.com', balance: 5000000, status: 'ACTIVE', isOnline: true, lastActive: 'Vừa xong' },
    { id: 102, username: 'tranvanb', email: 'tranvanb@gmail.com', balance: 1200000, status: 'ACTIVE', isOnline: true, lastActive: '2 phút trước' },
    { id: 103, username: 'lethic', email: 'lethic@gmail.com', balance: 350000, status: 'ACTIVE', isOnline: false, lastActive: '15 phút trước' }
];

let transactions = [
    { id: 'TX1001', userId: 101, username: 'nguyenvana', type: 'DEPOSIT', amount: 2000000, status: 'SUCCESS', method: 'BANK_TRANSFER', description: 'Nạp tiền qua Vietcombank', createdAt: new Date().toLocaleString('vi-VN') }
];

const authMiddleware = (req, res, next) => {
    const token = req.headers['authorization']?.split(' ')[1];
    if (!token || token !== 'fake-jwt-token-123') {
        return res.status(401).json({ success: false, message: 'Token không hợp lệ' });
    }
    next();
};

app.post('/api/user/deposit', (req, res) => {
    const { userId, amount, bankName, accountNumber } = req.body;
    const user = users.find(u => u.id === Number(userId));
    if (!user) return res.status(404).json({ success: false, message: 'Người dùng không tồn tại' });
    if (!amount || amount < 10000) return res.status(400).json({ success: false, message: 'Tối thiểu 10.000 VNĐ' });

    user.balance += Number(amount);
    const newTx = {
        id: `TX${Date.now().toString().slice(-6)}`,
        userId: user.id,
        username: user.username,
        type: 'DEPOSIT',
        amount: Number(amount),
        status: 'SUCCESS',
        method: `BANK (${bankName || 'MBBank'})`,
        description: `Nạp tiền từ STK ${accountNumber || 'xxxx'}`,
        createdAt: new Date().toLocaleString('vi-VN')
    };
    transactions.unshift(newTx);

    res.json({ success: true, message: `Nạp thành công ${Number(amount).toLocaleString('vi-VN')} VNĐ!`, newBalance: user.balance, transaction: newTx });
});

app.post('/api/user/transfer', (req, res) => {
    const { senderId, receiverUsername, amount, note } = req.body;
    const sender = users.find(u => u.id === Number(senderId));
    const receiver = users.find(u => u.username === receiverUsername);

    if (!sender || !receiver) return res.status(404).json({ success: false, message: 'Tài khoản không tồn tại' });
    if (sender.id === receiver.id) return res.status(400).json({ success: false, message: 'Không thể tự chuyển cho chính mình' });
    if (sender.balance < Number(amount)) return res.status(400).json({ success: false, message: 'Số dư không đủ' });

    sender.balance -= Number(amount);
    receiver.balance += Number(amount);

    const txSender = {
        id: `TX${Date.now().toString().slice(-6)}`,
        userId: sender.id,
        username: sender.username,
        type: 'TRANSFER_OUT',
        amount: Number(amount),
        status: 'SUCCESS',
        method: 'INTERNAL',
        description: `Chuyển tới @${receiver.username}: ${note || 'Chuyển tiền'}`,
        createdAt: new Date().toLocaleString('vi-VN')
    };
    transactions.unshift(txSender);

    res.json({ success: true, message: `Chuyển thành công ${Number(amount).toLocaleString('vi-VN')} VNĐ cho @${receiver.username}`, senderNewBalance: sender.balance, transaction: txSender });
});

app.post('/api/admin/login', (req, res) => {
    const { username, password } = req.body;
    if (username === 'admin' && password === '123') return res.json({ success: true, token: 'fake-jwt-token-123' });
    return res.status(401).json({ success: false, message: 'Sai tài khoản hoặc mật khẩu' });
});

app.get('/api/admin/overview', authMiddleware, (req, res) => {
    res.json({
        success: true,
        data: {
            totalUsers: users.length,
            activeUsers: users.filter(u => u.status === 'ACTIVE').length,
            onlineUsers: users.filter(u => u.isOnline).length,
            totalTransactions: transactions.length,
            totalBalance: users.reduce((sum, u) => sum + u.balance, 0)
        }
    });
});

app.get('/api/admin/users', authMiddleware, (req, res) => res.json({ success: true, data: users }));
app.get('/api/admin/transactions', authMiddleware, (req, res) => res.json({ success: true, data: transactions }));

app.get('/admin', (req, res) => res.sendFile(path.join(__dirname, 'public', 'admin.html')));
app.get('*', (req, res) => res.sendFile(path.join(__dirname, 'public', 'index.html')));

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server đang chạy tại cổng ${PORT}`);
});
EOF

pkill -f node && node server.js &
ifconfig
node server.js
npx localtunnel --port 8080
pkill -f node && node server.js & sleep 2 && npx localtunnel --port 8080
pkill -f node; node server.js & sleep 2 && ssh -R 80:localhost:8080 serveo.net
pkill -f node; node server.js & sleep 2 && ssh -R 80:localhost:8080 serveo.net
apk add openssh-client && ssh -R 80:localhost:8080 serveo.net
ssh -R 80:localhost:8080 serveo.net
pkill -f node && node server.js & sleep 2 && apk add curl && curl -s https://bin.equinox.io/c/b4P3k2pWnkp/ngrok-v3-stable-linux-arm64.tgz | tar -xz -C /usr/local/bin && ngrok http 8080
pkill -f node; node server.js
pkill -f node; node server.js
git config --global user.name "bbear9988" && git init && git add . && git commit -m "First commit" && git branch -M main && git remote add origin https://github.com/bbear9988/Goldcrypto.git && git push -u origin main
apk add git && git config --global user.name "bbear9988" && git init && git add . && git commit -m "First commit" && git branch -M main && git remote add origin https://github.com/bbear9988/Goldcrypto.git && git push -u origin main
