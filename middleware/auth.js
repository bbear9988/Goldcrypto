const jwt = require('jsonwebtoken');
const { db } = require('../config');

const JWT_SECRET = process.env.JWT_SECRET || 'SECRET_KEY_FINANCIAL_ADMIN_2026';

const verifyAdminToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, message: 'Yêu cầu Token xác thực!' });
  }

  jwt.verify(token, JWT_SECRET, (err, admin) => {
    if (err) {
      return res.status(403).json({ success: false, message: 'Token không hợp lệ hoặc đã hết hạn!' });
    }
    req.user = admin;
    next();
  });
};

const checkPermission = (requiredPermission) => {
  return async (req, res, next) => {
    try {
      const adminId = req.user.id;
      const permissions = await db('admin_users')
        .join('roles', 'admin_users.role_id', '=', 'roles.id')
        .join('role_permissions', 'roles.id', '=', 'role_permissions.role_id')
        .join('permissions', 'role_permissions.permission_id', '=', 'permissions.id')
        .where('admin_users.id', adminId)
        .pluck('permissions.code');

      if (!permissions.includes(requiredPermission)) {
        return res.status(403).json({
          success: false,
          message: `Từ chối truy cập: Tài khoản cần quyền [${requiredPermission}]`
        });
      }
      next();
    } catch (error) {
      return res.status(500).json({ success: false, message: 'Lỗi kiểm tra quyền', error: error.message });
    }
  };
};

module.exports = { verifyAdminToken, checkPermission, JWT_SECRET };
