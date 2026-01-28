# Hướng dẫn Sử dụng Hệ thống Quản lý Thư viện

## 🚀 Bắt đầu nhanh

### 1. Cài đặt hệ thống

#### Phiên bản cơ bản
```sql
-- Chạy file này để cài đặt phiên bản cơ bản
:r "run-project.sql"
```

#### Phiên bản Enterprise (Nâng cao)
```sql
-- Bước 1: Cài đặt phiên bản cơ bản
:r "run-project.sql"

-- Bước 2: Nâng cấp lên Enterprise
:r "7-advanced-features/run-advanced-features.sql"
```

### 2. Kiểm tra cài đặt
```sql
USE QuanLyThuVien;

-- Phiên bản cơ bản
SELECT * FROM V_DashboardTongQuan;

-- Phiên bản Enterprise
SELECT * FROM V_DashboardDieuHanh;
```

## 📖 Các chức năng chính

### 1. QUẢN LÝ MƯỢN TRẢ SÁCH

#### Mượn sách đơn lẻ
```sql
-- Mượn 1 cuốn sách trong 30 ngày
EXEC SP_MuonSach 
    @MaThe = 'SV2024001',
    @ISBN = '978-0134685991',
    @SoNgayMuon = 30;
```

#### Mượn nhiều sách cùng lúc
```sql
-- Mượn nhiều sách cùng lúc (tiết kiệm thời gian)
EXEC SP_MuonNhieuSach 
    @MaThe = 'GV2024001',
    @DanhSachISBN = '978-0134685991,978-8935244850,978-8935244867',
    @SoNgayMuon = 45;
```

#### Trả sách
```sql
-- Trả sách đơn lẻ
EXEC SP_TraSach 
    @MaThe = 'SV2024001',
    @ISBN = '978-0134685991';

-- Trả nhiều sách và tự động tính tiền phạt
EXEC SP_XuLyTraSachVaTinhPhat 
    @MaThe = 'GV2024001',
    @DanhSachISBN = '978-0134685991,978-8935244850';
```

#### Gia hạn sách
```sql
-- Gia hạn thêm 15 ngày
EXEC SP_GiaHanSach 
    @MaThe = 'SV2024001',
    @ISBN = '978-0134685991',
    @SoNgayGiaHan = 15;
```

### 2. TÌM KIẾM VÀ TRUY VẤN

#### Tìm kiếm sách đa điều kiện
```sql
-- Tìm theo từ khóa
EXEC SP_TimKiemSach @TuKhoa = N'Java';

-- Tìm theo thể loại
EXEC SP_TimKiemSach @MaTheLoai = 'TL001';

-- Tìm sách còn hàng của tác giả cụ thể
EXEC SP_TimKiemSach 
    @MaTacGia = 'TG001',
    @ChiLaySachConHang = 1;

-- Tìm kiếm kết hợp nhiều điều kiện
EXEC SP_TimKiemSach 
    @TuKhoa = N'lập trình',
    @MaTheLoai = 'TL001',
    @NamXuatBan = 2021,
    @ChiLaySachConHang = 1;
```

#### Xem thông tin chi tiết
```sql
-- Thông tin sách đầy đủ
SELECT * FROM V_ThongTinSachChiTiet 
WHERE TenSach LIKE N'%Java%';

-- Sách đang được mượn
SELECT * FROM V_SachDangDuocMuon
ORDER BY SoNgayConLai;

-- Thống kê thành viên
SELECT * FROM V_ThongKeThanhVien
WHERE LoaiThanhVien = N'Sinh viên';
```

### 3. BÁO CÁO VÀ THỐNG KÊ

#### Báo cáo tự động
```sql
-- Top sách được mượn nhiều nhất
EXEC SP_BaoCaoThongKe @LoaiBaoCao = N'SACH_DUOC_MUON_NHIEU';

-- Thành viên tích cực nhất
EXEC SP_BaoCaoThongKe @LoaiBaoCao = N'THANH_VIEN_TICH_CUC';

-- Danh sách sách quá hạn
EXEC SP_BaoCaoThongKe @LoaiBaoCao = N'SACH_QUA_HAN';

-- Báo cáo theo khoảng thời gian
EXEC SP_BaoCaoThongKe 
    @LoaiBaoCao = N'SACH_DUOC_MUON_NHIEU',
    @TuNgay = '2024-01-01',
    @DenNgay = '2024-03-31';
```

#### Dashboard và thống kê nhanh
```sql
-- Dashboard tổng quan
SELECT * FROM V_DashboardTongQuan;

-- Thống kê sách phổ biến
SELECT TOP 10 * FROM V_ThongKeSachPhoBien 
ORDER BY SoLanMuon DESC;

-- Báo cáo tài chính theo tháng
SELECT * FROM V_BaoCaoTaiChinh 
ORDER BY Nam DESC, Thang DESC;

-- Sách cần mua thêm
SELECT * FROM V_SachCanMuaThem
ORDER BY DeXuat DESC;
```

### 4. TRUY VẤN NÂNG CAO

#### Tìm sách theo nhiều tiêu chí
```sql
-- Sách của tác giả Việt Nam xuất bản sau 2020
SELECT s.*, tg.HoTen, tg.QuocTich
FROM SACH s
JOIN VIET_SACH vs ON s.ISBN = vs.ISBN
JOIN TAC_GIA tg ON vs.MaTacGia = tg.MaTacGia
WHERE tg.QuocTich = N'Việt Nam' 
    AND s.NamXuatBan >= 2020;

-- Thành viên chưa mượn sách nào
SELECT tv.*
FROM THANH_VIEN tv
LEFT JOIN MUON_TRA mt ON tv.MaThe = mt.MaThe
WHERE mt.MaThe IS NULL;

-- Sách được mượn nhiều nhất theo thể loại
SELECT 
    tl.TenTheLoai,
    s.TenSach,
    COUNT(*) as SoLanMuon
FROM THE_LOAI tl
JOIN THUOC_THE_LOAI ttl ON tl.MaTheLoai = ttl.MaTheLoai
JOIN SACH s ON ttl.ISBN = s.ISBN
JOIN MUON_TRA mt ON s.ISBN = mt.ISBN
GROUP BY tl.TenTheLoai, s.TenSach
ORDER BY tl.TenTheLoai, SoLanMuon DESC;
```

#### Phân tích xu hướng
```sql
-- Xu hướng mượn sách theo tháng
SELECT 
    YEAR(NgayMuon) as Nam,
    MONTH(NgayMuon) as Thang,
    COUNT(*) as SoLanMuon,
    COUNT(DISTINCT MaThe) as SoThanhVienMuon
FROM MUON_TRA
GROUP BY YEAR(NgayMuon), MONTH(NgayMuon)
ORDER BY Nam DESC, Thang DESC;

-- Thành viên có xu hướng trả muộn
SELECT 
    tv.MaThe,
    tv.HoTen,
    COUNT(*) as TongSoLanMuon,
    COUNT(CASE WHEN mt.NgayThucTeTra > mt.NgayHenTra THEN 1 END) as SoLanTraMuon,
    CAST(COUNT(CASE WHEN mt.NgayThucTeTra > mt.NgayHenTra THEN 1 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as TyLeTraMuon
FROM THANH_VIEN tv
JOIN MUON_TRA mt ON tv.MaThe = mt.MaThe
WHERE mt.NgayThucTeTra IS NOT NULL
GROUP BY tv.MaThe, tv.HoTen
HAVING COUNT(*) >= 3
ORDER BY TyLeTraMuon DESC;
```

## 🔧 Quản trị hệ thống

### 1. Đồng bộ dữ liệu định kỳ
```sql
-- Chạy đồng bộ thủ công
EXEC SP_DongBoDuLieuDinhKy;

-- Thiết lập job tự động (chạy hàng ngày lúc 2:00 AM)
EXEC SP_TaoJobDongBoDinhKy;
```

### 2. Kiểm tra log và audit
```sql
-- Xem log thay đổi gần đây
SELECT TOP 20 * FROM AUDIT_LOG 
ORDER BY ChangedDate DESC;

-- Log thay đổi của bảng cụ thể
SELECT * FROM AUDIT_LOG 
WHERE TableName = 'SACH' 
    AND ChangedDate >= DATEADD(DAY, -7, GETDATE())
ORDER BY ChangedDate DESC;
```

### 3. Bảo trì và tối ưu
```sql
-- Kiểm tra hiệu suất index
SELECT 
    OBJECT_NAME(ius.object_id) AS TableName,
    i.name AS IndexName,
    ius.user_seeks,
    ius.user_scans,
    ius.user_lookups,
    ius.user_updates
FROM sys.dm_db_index_usage_stats ius
JOIN sys.indexes i ON ius.object_id = i.object_id AND ius.index_id = i.index_id
WHERE OBJECT_NAME(ius.object_id) IN ('SACH', 'MUON_TRA', 'THANH_VIEN')
ORDER BY TableName, IndexName;

-- Thống kê dung lượng bảng
SELECT 
    t.name AS TableName,
    SUM(p.rows) AS RowCount,
    SUM(a.total_pages) * 8 AS TotalSpaceKB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id
JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.name IN ('SACH', 'MUON_TRA', 'THANH_VIEN', 'TAC_GIA', 'NHA_XUAT_BAN')
GROUP BY t.name
ORDER BY UsedSpaceKB DESC;
```

## ⚠️ Lưu ý quan trọng

### Quy tắc nghiệp vụ
1. **Giới hạn mượn sách**:
   - Sinh viên: 3 cuốn
   - Giảng viên: 10 cuốn  
   - Cán bộ: 5 cuốn

2. **Thời gian mượn mặc định**: 30 ngày

3. **Tiền phạt**: 5,000đ/ngày trả muộn

4. **Ràng buộc**: Không được mượn thêm nếu có sách quá hạn

### Xử lý lỗi thường gặp
```sql
-- Lỗi: Không đủ sách để mượn
-- Kiểm tra số lượng sách hiện có
SELECT ISBN, TenSach, SoLuong FROM SACH WHERE ISBN = 'your_isbn';

-- Lỗi: Vượt quá giới hạn mượn
-- Kiểm tra số sách đang mượn
SELECT COUNT(*) FROM MUON_TRA 
WHERE MaThe = 'your_mathe' AND TrangThai IN (N'Đang mượn', N'Quá hạn');

-- Lỗi: Có sách quá hạn
-- Xem danh sách sách quá hạn
SELECT * FROM V_SachDangDuocMuon 
WHERE MaThe = 'your_mathe' AND TinhTrang = N'Quá hạn';
```

## 📞 Hỗ trợ

Nếu gặp vấn đề, hãy kiểm tra:
1. **Log lỗi**: Xem thông báo lỗi chi tiết
2. **Audit log**: Kiểm tra AUDIT_LOG table
3. **Dashboard**: Sử dụng V_DashboardTongQuan để tổng quan
4. **Documentation**: Đọc kỹ project-summary.md

---
*Hệ thống được thiết kế để dễ sử dụng và mở rộng. Mọi thao tác đều có validation và error handling đầy đủ.*

## 🌟 Tính năng Enterprise (Nâng cao)

Để sử dụng các tính năng nâng cao, vui lòng xem [Advanced User Guide](advanced-user-guide.md):

### ✨ Tính năng mới
- **Đặt trước sách** - Đặt trước khi hết hàng
- **Quản lý đa chi nhánh** - Chuyển sách giữa các chi nhánh
- **Hệ thống thông báo** - Email/SMS tự động
- **Phân tích nâng cao** - AI-powered analytics
- **Bảo mật đa lớp** - Role-based access control
- **API Integration** - RESTful API và Webhook

### 🚀 Quick Start Enterprise
```sql
-- Đặt trước sách
EXEC SP_DatTruocSach @MaThe = 'SV2024001', @ISBN = '978-0134685991';

-- Chuyển sách giữa chi nhánh
EXEC SP_ChuyenSachGiuaChiNhanh 
    @ChiNhanhNguon = 'CN001', @ChiNhanhDich = 'CN002', 
    @ISBN = '978-0134685991', @SoLuong = 2;

-- Đăng nhập với phân quyền
EXEC SP_DangNhap @TenDangNhap = 'admin', @MatKhau = 'admin123';

-- API lấy thông tin sách
EXEC SP_API_GetBookInfo @ISBN = '978-0134685991', @Format = 'JSON';
```

---
*Để có trải nghiệm đầy đủ, khuyến nghị sử dụng phiên bản Enterprise với đầy đủ tính năng hiện đại.*