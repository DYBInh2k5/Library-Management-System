# Contributing to Library Management System

Chúng tôi rất hoan nghênh các đóng góp từ cộng đồng! Dưới đây là hướng dẫn để bạn có thể đóng góp vào dự án.

## 🚀 Cách đóng góp

### 1. Fork Repository
- Fork repository này về tài khoản GitHub của bạn
- Clone fork về máy local của bạn

```bash
git clone https://github.com/your-username/Library-Management-System.git
cd Library-Management-System
```

### 2. Tạo Branch mới
```bash
git checkout -b feature/ten-tinh-nang-moi
# hoặc
git checkout -b bugfix/sua-loi-xyz
```

### 3. Thực hiện thay đổi
- Viết code theo coding standards
- Test kỹ lưỡng các thay đổi
- Cập nhật documentation nếu cần

### 4. Commit và Push
```bash
git add .
git commit -m "feat: thêm tính năng ABC"
git push origin feature/ten-tinh-nang-moi
```

### 5. Tạo Pull Request
- Tạo Pull Request từ branch của bạn về main branch
- Mô tả chi tiết những thay đổi bạn đã thực hiện
- Liên kết với issue tương ứng (nếu có)

## 📝 Coding Standards

### SQL Code
- Sử dụng UPPER CASE cho SQL keywords
- Sử dụng meaningful names cho tables, columns, procedures
- Comment code phức tạp
- Tuân thủ naming convention hiện tại

### Documentation
- Cập nhật README.md nếu thêm tính năng mới
- Viết comment bằng tiếng Việt cho dễ hiểu
- Cập nhật user guide khi cần thiết

## 🐛 Báo cáo Bug

Khi báo cáo bug, vui lòng cung cấp:
- Mô tả chi tiết về bug
- Các bước để reproduce
- Expected behavior vs Actual behavior
- Screenshots (nếu có)
- Môi trường (SQL Server version, OS, etc.)

## 💡 Đề xuất tính năng

Trước khi implement tính năng mới:
- Tạo issue để thảo luận
- Đảm bảo tính năng phù hợp với mục tiêu dự án
- Thiết kế database schema nếu cần
- Viết test cases

## 🔍 Code Review Process

1. Tất cả Pull Request cần được review
2. Đảm bảo code chạy được trên SQL Server 2016+
3. Kiểm tra performance impact
4. Verify documentation được cập nhật

## 📋 Types of Contributions

### 🆕 Tính năng mới
- Hệ thống báo cáo mới
- Tích hợp với external services
- Mobile app support
- Performance improvements

### 🐛 Bug fixes
- Sửa lỗi logic
- Cải thiện error handling
- Security fixes

### 📚 Documentation
- Cải thiện README
- Thêm examples
- Dịch sang ngôn ngữ khác

### 🧪 Testing
- Thêm test cases
- Performance testing
- Security testing

## 🏷️ Commit Message Format

Sử dụng conventional commits:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types:
- `feat`: Tính năng mới
- `fix`: Sửa bug
- `docs`: Cập nhật documentation
- `style`: Formatting, missing semicolons, etc
- `refactor`: Code refactoring
- `test`: Thêm tests
- `chore`: Maintenance tasks

Examples:
```
feat(api): thêm endpoint lấy thống kê sách
fix(trigger): sửa lỗi cập nhật số lượng sách
docs(readme): cập nhật hướng dẫn cài đặt
```

## 🤝 Code of Conduct

- Tôn trọng tất cả contributors
- Sử dụng ngôn ngữ tích cực và xây dựng
- Tập trung vào việc cải thiện dự án
- Giúp đỡ newcomers

## 📞 Liên hệ

Nếu có câu hỏi, vui lòng:
- Tạo issue trên GitHub
- Email: binh.vd01500@sinhvien.hoasen.edu.vn
- Discord: [your-discord-server]

Cảm ơn bạn đã quan tâm đến dự án! 🙏