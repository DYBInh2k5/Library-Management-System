# Hướng dẫn Sử dụng Tính năng Nâng cao - Phiên bản Enterprise

## 🚀 Cài đặt phiên bản Enterprise

### Yêu cầu hệ thống
- SQL Server 2016+ (khuyến nghị 2019+)
- Tối thiểu 4GB RAM
- 10GB dung lượng trống

### Cài đặt
```sql
-- Bước 1: Cài đặt phiên bản cơ bản
:r "run-project.sql"

-- Bước 2: Nâng cấp lên Enterprise
:r "7-advanced-features\run-advanced-features.sql"
```

## 📚 1. HỆ THỐNG ĐẶT TRƯỚC SÁCH

### Đặt trước sách khi hết hàng
```sql
-- Đặt trước sách trong 7 ngày
EXEC SP_DatTruocSach 
    @MaThe = 'SV2024001',
    @ISBN = '978-0134685991',
    @SoNgayGiuCho = 7;
```

### Xử lý đặt trước
```sql
-- Xử lý đơn đặt trước (khi sách có sẵn)
EXEC SP_XuLyDatTruoc 
    @MaDatTruoc = 1,
    @HanhDong = N'XU_LY',
    @GhiChu = N'Sách đã có sẵn';

-- Hủy đơn đặt trước
EXEC SP_XuLyDatTruoc 
    @MaDatTruoc = 2,
    @HanhDong = N'HUY_BO',
    @GhiChu = N'Thành viên không cần nữa';
```

### Xem danh sách đặt trước
```sql
-- Tất cả đặt trước đang chờ
SELECT 
    dt.MaDatTruoc,
    tv.HoTen,
    s.TenSach,
    dt.NgayDat,
    dt.NgayHetHan,
    dt.TrangThai
FROM DAT_TRUOC dt
JOIN THANH_VIEN tv ON dt.MaThe = tv.MaThe
JOIN SACH s ON dt.ISBN = s.ISBN
WHERE dt.TrangThai = N'Chờ xử lý'
ORDER BY dt.NgayDat;
```

## 🔔 2. HỆ THỐNG THÔNG BÁO

### Tạo thông báo tự động
```sql
-- Tạo thông báo nhắc nhở trả sách
EXEC SP_TaoThongBao 
    @MaThe = 'SV2024001',
    @LoaiThongBao = 'REMINDER',
    @ThamSoJSON = '{"HoTen":"Lê Văn Nam","TenSach":"Clean Code"}',
    @KenhGui = N'Email';
```

### Xem thông báo
```sql
-- Thông báo chưa gửi
SELECT * FROM THONG_BAO 
WHERE TrangThai = N'Chưa gửi'
ORDER BY NgayTao DESC;

-- Thông báo của thành viên cụ thể
SELECT * FROM THONG_BAO 
WHERE MaThe = 'SV2024001'
ORDER BY NgayTao DESC;
```

### Quản lý mẫu thông báo
```sql
-- Thêm mẫu thông báo mới
INSERT INTO MAU_THONG_BAO (TenMau, LoaiThongBao, TieuDeMau, NoiDungMau, ThamSo)
VALUES (N'Chúc mừng sinh nhật', N'BIRTHDAY',
        N'Chúc mừng sinh nhật {HoTen}!',
        N'Chúc mừng sinh nhật {HoTen}! Thư viện tặng bạn voucher giảm giá 20% tiền phạt.',
        N'{"HoTen": "Tên thành viên"}');
```

## 🏢 3. HỆ THỐNG NHIỀU CHI NHÁNH

### Quản lý chi nhánh
```sql
-- Xem thông tin tất cả chi nhánh
SELECT * FROM CHI_NHANH WHERE TrangThai = 1;

-- Xem kho sách theo chi nhánh
SELECT 
    cn.TenChiNhanh,
    s.TenSach,
    kscn.SoLuong,
    kscn.ViTri
FROM KHO_SACH_CHI_NHANH kscn
JOIN CHI_NHANH cn ON kscn.MaChiNhanh = cn.MaChiNhanh
JOIN SACH s ON kscn.ISBN = s.ISBN
WHERE cn.MaChiNhanh = 'CN001'
ORDER BY s.TenSach;
```

### Chuyển sách giữa chi nhánh
```sql
-- Tạo yêu cầu chuyển sách
EXEC SP_ChuyenSachGiuaChiNhanh 
    @ChiNhanhNguon = 'CN001',
    @ChiNhanhDich = 'CN002',
    @ISBN = '978-0134685991',
    @SoLuong = 3,
    @GhiChu = N'Chi nhánh 2 cần bổ sung';

-- Xác nhận gửi sách
EXEC SP_XacNhanChuyenSach @MaChuyen = 1, @HanhDong = N'GUI';

-- Xác nhận nhận sách
EXEC SP_XacNhanChuyenSach @MaChuyen = 1, @HanhDong = N'NHAN';
```

### Báo cáo chuyển sách
```sql
-- Lịch sử chuyển sách
SELECT 
    cscn.*,
    cn1.TenChiNhanh as ChiNhanhNguon,
    cn2.TenChiNhanh as ChiNhanhDich,
    s.TenSach
FROM CHUYEN_SACH_CHI_NHANH cscn
JOIN CHI_NHANH cn1 ON cscn.ChiNhanhNguon = cn1.MaChiNhanh
JOIN CHI_NHANH cn2 ON cscn.ChiNhanhDich = cn2.MaChiNhanh
JOIN SACH s ON cscn.ISBN = s.ISBN
ORDER BY cscn.NgayYeuCau DESC;
```

## 📊 4. PHÂN TÍCH VÀ BÁO CÁO NÂNG CAO

### Chạy phân tích dữ liệu
```sql
-- Phân tích xu hướng sách theo tháng
EXEC SP_PhanTichXuHuongSach @Thang = 3, @Nam = 2024;

-- Phân tích hành vi người dùng
EXEC SP_PhanTichNguoiDung @Thang = 3, @Nam = 2024;
```

### Dashboard điều hành
```sql
-- Dashboard tổng quan nâng cao
SELECT * FROM V_DashboardDieuHanh;

-- Xu hướng theo tháng
SELECT * FROM V_XuHuongTheoThang 
WHERE Nam = 2024 
ORDER BY Nam DESC, Thang DESC;
```

### Báo cáo xu hướng sách
```sql
-- Top 10 sách phổ biến tháng này
SELECT TOP 10 
    s.TenSach,
    xhs.SoLanMuon,
    xhs.DiemPhoBien,
    xhs.XepHang
FROM XU_HUONG_SACH xhs
JOIN SACH s ON xhs.ISBN = s.ISBN
WHERE xhs.Thang = MONTH(GETDATE()) AND xhs.Nam = YEAR(GETDATE())
ORDER BY xhs.XepHang;
```

### Phân tích người dùng
```sql
-- Thành viên tích cực nhất
SELECT TOP 10
    tv.HoTen,
    ptn.SoLanMuon,
    ptn.MucDoTichCuc,
    ptn.TheLoaiYeuThich
FROM PHAN_TICH_NGUOI_DUNG ptn
JOIN THANH_VIEN tv ON ptn.MaThe = tv.MaThe
WHERE ptn.Thang = MONTH(GETDATE()) AND ptn.Nam = YEAR(GETDATE())
ORDER BY ptn.SoLanMuon DESC;
```

## 🔐 5. HỆ THỐNG BẢO MẬT VÀ PHÂN QUYỀN

### Đăng nhập hệ thống
```sql
-- Đăng nhập
EXEC SP_DangNhap 
    @TenDangNhap = 'librarian1',
    @MatKhau = 'lib123',
    @DiaChiIP = '192.168.1.100',
    @ThietBi = N'Chrome on Windows 10';
```

### Kiểm tra quyền hạn
```sql
-- Kiểm tra quyền của người dùng
EXEC SP_KiemTraQuyen 
    @TenDangNhap = 'librarian1',
    @MaQuyen = 'BOOK_ADD';

-- Xem tất cả quyền của vai trò
SELECT 
    vt.TenVaiTro,
    qh.TenQuyen,
    qh.MoTa,
    qh.Nhom
FROM VAI_TRO vt
JOIN VAI_TRO_QUYEN vtq ON vt.MaVaiTro = vtq.MaVaiTro
JOIN QUYEN_HAN qh ON vtq.MaQuyen = qh.MaQuyen
WHERE vt.MaVaiTro = 'LIBRARIAN'
ORDER BY qh.Nhom, qh.TenQuyen;
```

### Quản lý người dùng
```sql
-- Tạo tài khoản mới
INSERT INTO NGUOI_DUNG (TenDangNhap, MatKhau, MaThe, MaVaiTro)
VALUES ('newuser', HASHBYTES('SHA2_256', 'password123'), 'SV2024005', 'MEMBER');

-- Xem lịch sử đăng nhập
SELECT TOP 20 * FROM LICH_SU_DANG_NHAP 
ORDER BY ThoiGianDangNhap DESC;

-- Khóa tài khoản
UPDATE NGUOI_DUNG 
SET TrangThai = 0, NgayKhoa = GETDATE()
WHERE TenDangNhap = 'baduser';
```

## 🌐 6. HỆ THỐNG API VÀ TÍCH HỢP

### Sử dụng API
```sql
-- Lấy thông tin sách qua API (JSON)
EXEC SP_API_GetBookInfo @ISBN = '978-0134685991', @Format = 'JSON';

-- Mượn sách qua API
EXEC SP_API_BorrowBook 
    @MaThe = 'SV2024001',
    @ISBN = '978-0134685991',
    @SoNgayMuon = 30,
    @APIKey = 'library_api_key_2024';
```

### Quản lý API
```sql
-- Xem thống kê API
SELECT * FROM V_API_Statistics;

-- Xem log API gần đây
SELECT TOP 20 * FROM API_LOG 
ORDER BY ThoiGianGoi DESC;

-- Cấu hình API mới
INSERT INTO API_CONFIG (TenAPI, URL, APIKey, MoTa)
VALUES ('NewService', 'https://api.example.com', 'your_api_key', N'Dịch vụ mới');
```

### Webhook
```sql
-- Đăng ký webhook mới
INSERT INTO WEBHOOK_SUBSCRIPTION (TenSuKien, URL, Secret)
VALUES ('member_registered', 'https://your-app.com/webhooks/member', 'secret_key');

-- Trigger webhook thủ công
EXEC SP_TriggerWebhook 
    @SuKien = 'book_borrowed',
    @DuLieu = 'SV2024001';
```

## 📈 7. MONITORING VÀ MAINTENANCE

### Kiểm tra hiệu suất
```sql
-- Thống kê sử dụng index
SELECT 
    OBJECT_NAME(ius.object_id) AS TableName,
    i.name AS IndexName,
    ius.user_seeks + ius.user_scans + ius.user_lookups AS TotalReads,
    ius.user_updates AS TotalWrites
FROM sys.dm_db_index_usage_stats ius
JOIN sys.indexes i ON ius.object_id = i.object_id AND ius.index_id = i.index_id
WHERE OBJECT_NAME(ius.object_id) LIKE '%SACH%' OR OBJECT_NAME(ius.object_id) LIKE '%MUON_TRA%'
ORDER BY TotalReads DESC;
```

### Backup và bảo trì
```sql
-- Backup database
BACKUP DATABASE QuanLyThuVien 
TO DISK = 'C:\Backup\QuanLyThuVien_Full.bak'
WITH FORMAT, INIT, COMPRESSION;

-- Kiểm tra tính toàn vẹn
DBCC CHECKDB('QuanLyThuVien');

-- Cập nhật thống kê
UPDATE STATISTICS SACH;
UPDATE STATISTICS MUON_TRA;
```

### Dọn dẹp dữ liệu
```sql
-- Xóa log cũ (giữ lại 3 tháng)
DELETE FROM API_LOG WHERE ThoiGianGoi < DATEADD(MONTH, -3, GETDATE());
DELETE FROM LICH_SU_DANG_NHAP WHERE ThoiGianDangNhap < DATEADD(MONTH, -3, GETDATE());

-- Xóa đặt trước đã hết hạn
DELETE FROM DAT_TRUOC 
WHERE TrangThai = N'Chờ xử lý' AND NgayHetHan < DATEADD(DAY, -7, GETDATE());
```

## 🎯 8. BEST PRACTICES

### Bảo mật
- Thay đổi mật khẩu mặc định
- Sử dụng HTTPS cho API
- Định kỳ review quyền hạn người dùng
- Monitor các hoạt động bất thường

### Hiệu suất
- Định kỳ rebuild index
- Monitor query performance
- Sử dụng connection pooling
- Cache dữ liệu thường xuyên truy cập

### Backup
- Backup hàng ngày
- Test restore procedure
- Lưu trữ backup ở nhiều nơi
- Document recovery procedures

---
*Phiên bản Enterprise cung cấp đầy đủ tính năng cho thư viện hiện đại với khả năng mở rộng cao và tích hợp đa dạng.*