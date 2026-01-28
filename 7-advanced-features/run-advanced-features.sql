-- =====================================================
-- SCRIPT CHẠY TẤT CẢ TÍNH NĂNG NÂNG CAO
-- Hệ thống Quản lý Thư viện - Phiên bản Enterprise
-- =====================================================

PRINT N'=== CÀI ĐẶT CÁC TÍNH NĂNG NÂNG CAO ===';
PRINT N'Thời gian bắt đầu: ' + CONVERT(NVARCHAR, GETDATE(), 120);
PRINT N'';

USE QuanLyThuVien;
GO

-- =====================================================
-- BƯỚC 1: HỆ THỐNG ĐẶT TRƯỚC SÁCH
-- =====================================================
PRINT N'BƯỚC 1: Cài đặt hệ thống đặt trước sách...';
GO
:r "7-advanced-features\01-reservation-system.sql"
GO

-- =====================================================
-- BƯỚC 2: HỆ THỐNG THÔNG BÁO
-- =====================================================
PRINT N'BƯỚC 2: Cài đặt hệ thống thông báo...';
GO
:r "7-advanced-features\02-notification-system.sql"
GO

-- =====================================================
-- BƯỚC 3: HỆ THỐNG NHIỀU CHI NHÁNH
-- =====================================================
PRINT N'BƯỚC 3: Cài đặt hệ thống nhiều chi nhánh...';
GO
:r "7-advanced-features\03-multi-branch-system.sql"
GO

-- =====================================================
-- BƯỚC 4: HỆ THỐNG PHÂN TÍCH VÀ BÁO CÁO NÂNG CAO
-- =====================================================
PRINT N'BƯỚC 4: Cài đặt hệ thống phân tích nâng cao...';
GO
:r "7-advanced-features\04-analytics-reporting.sql"
GO

-- =====================================================
-- BƯỚC 5: HỆ THỐNG BẢO MẬT VÀ PHÂN QUYỀN
-- =====================================================
PRINT N'BƯỚC 5: Cài đặt hệ thống bảo mật và phân quyền...';
GO
:r "7-advanced-features\05-security-permissions.sql"
GO

-- =====================================================
-- BƯỚC 6: HỆ THỐNG TÍCH HỢP API
-- =====================================================
PRINT N'BƯỚC 6: Cài đặt hệ thống tích hợp API...';
GO
:r "7-advanced-features\06-api-integration.sql"
GO

-- =====================================================
-- BƯỚC 7: TẠO DỮ LIỆU MẪU CHO TÍNH NĂNG MỚI
-- =====================================================
PRINT N'BƯỚC 7: Tạo dữ liệu mẫu cho các tính năng mới...';

-- Tạo tài khoản người dùng mẫu
INSERT INTO NGUOI_DUNG (TenDangNhap, MatKhau, MaThe, MaVaiTro) VALUES
('admin', HASHBYTES('SHA2_256', 'admin123'), NULL, 'ADMIN'),
('librarian1', HASHBYTES('SHA2_256', 'lib123'), 'GV2024001', 'LIBRARIAN'),
('staff1', HASHBYTES('SHA2_256', 'staff123'), 'CB2024001', 'STAFF'),
('member1', HASHBYTES('SHA2_256', 'member123'), 'SV2024001', 'MEMBER');

-- Tạo một số đặt trước mẫu
INSERT INTO DAT_TRUOC (MaThe, ISBN, NgayDat, NgayHetHan, TrangThai) VALUES
('SV2024002', '978-0134685991', GETDATE(), DATEADD(DAY, 7, GETDATE()), N'Chờ xử lý'),
('SV2024003', '978-0201633610', DATEADD(DAY, -2, GETDATE()), DATEADD(DAY, 5, GETDATE()), N'Chờ xử lý');

-- Tạo thông báo mẫu
EXEC SP_TaoThongBao @MaThe = 'SV2024001', @LoaiThongBao = 'REMINDER', @ThamSoJSON = '{"HoTen":"Lê Văn Nam"}';

-- Chạy phân tích dữ liệu
EXEC SP_PhanTichXuHuongSach;
EXEC SP_PhanTichNguoiDung;

-- =====================================================
-- BƯỚC 8: KIỂM TRA HỆ THỐNG MỚI
-- =====================================================
PRINT N'BƯỚC 8: Kiểm tra các tính năng mới...';

-- Kiểm tra số lượng bảng mới
SELECT 'Tổng số bảng sau khi nâng cấp' AS ThongTin, COUNT(*) AS SoLuong
FROM sys.tables WHERE type = 'U';

-- Kiểm tra các stored procedure mới
SELECT 'Stored Procedure mới' AS ThongTin, COUNT(*) AS SoLuong
FROM sys.procedures 
WHERE name LIKE 'SP_API_%' OR name LIKE 'SP_Dat%' OR name LIKE 'SP_Chuyen%' OR name LIKE 'SP_PhanTich%';

-- Dashboard nâng cao
SELECT * FROM V_DashboardDieuHanh;

-- Thống kê đặt trước
SELECT 
    'Tổng đặt trước' as LoaiThongKe,
    COUNT(*) as SoLuong
FROM DAT_TRUOC
UNION ALL
SELECT 
    'Đặt trước chờ xử lý',
    COUNT(*)
FROM DAT_TRUOC WHERE TrangThai = N'Chờ xử lý';

-- =====================================================
-- BƯỚC 9: TEST CÁC TÍNH NĂNG MỚI
-- =====================================================
PRINT N'BƯỚC 9: Test các tính năng mới...';

-- Test đặt trước sách
PRINT N'Test đặt trước sách:';
-- Trước tiên làm hết sách để test đặt trước
UPDATE SACH SET SoLuong = 0 WHERE ISBN = '978-8935244829';
EXEC SP_DatTruocSach @MaThe = 'SV2024001', @ISBN = '978-8935244829', @SoNgayGiuCho = 7;

-- Test chuyển sách giữa chi nhánh
PRINT N'Test chuyển sách giữa chi nhánh:';
EXEC SP_ChuyenSachGiuaChiNhanh 
    @ChiNhanhNguon = 'CN001', 
    @ChiNhanhDich = 'CN002', 
    @ISBN = '978-0134685991', 
    @SoLuong = 2,
    @GhiChu = N'Chuyển sách theo yêu cầu';

-- Test API
PRINT N'Test API lấy thông tin sách:';
EXEC SP_API_GetBookInfo @ISBN = '978-0134685991', @Format = 'JSON';

-- Test đăng nhập
PRINT N'Test hệ thống đăng nhập:';
EXEC SP_DangNhap @TenDangNhap = 'admin', @MatKhau = 'admin123', @DiaChiIP = '192.168.1.100';

-- =====================================================
-- HOÀN THÀNH NÂNG CẤP
-- =====================================================
PRINT N'';
PRINT N'=== HOÀN THÀNH NÂNG CẤP HỆ THỐNG ===';
PRINT N'Thời gian hoàn thành: ' + CONVERT(NVARCHAR, GETDATE(), 120);
PRINT N'';
PRINT N'CÁC TÍNH NĂNG MỚI ĐÃ ĐƯỢC THÊM:';
PRINT N'✅ 1. Hệ thống đặt trước sách';
PRINT N'✅ 2. Hệ thống thông báo tự động';
PRINT N'✅ 3. Quản lý nhiều chi nhánh';
PRINT N'✅ 4. Phân tích và báo cáo nâng cao';
PRINT N'✅ 5. Bảo mật và phân quyền';
PRINT N'✅ 6. Tích hợp API và Webhook';
PRINT N'';
PRINT N'HỆ THỐNG HIỆN TẠI CÓ:';
PRINT N'- Quản lý đa chi nhánh với chuyển sách tự động';
PRINT N'- Đặt trước sách khi hết hàng';
PRINT N'- Thông báo qua email/SMS';
PRINT N'- Phân tích xu hướng và hành vi người dùng';
PRINT N'- Bảo mật đa lớp với phân quyền chi tiết';
PRINT N'- API RESTful và Webhook integration';
PRINT N'- Dashboard điều hành thời gian thực';
PRINT N'';
GO