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
