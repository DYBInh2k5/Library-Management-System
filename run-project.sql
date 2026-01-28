-- =====================================================
-- SCRIPT CHẠY TOÀN BỘ DỰ ÁN HỆ THỐNG QUẢN LÝ THƯ VIỆN
-- Phiên bản: Cơ bản + Tùy chọn nâng cấp Enterprise
-- Thực hiện theo đúng thứ tự để đảm bảo hệ thống hoạt động chính xác
-- =====================================================

PRINT N'=== HỆ THỐNG QUẢN LÝ THƯ VIỆN ===';
PRINT N'Phiên bản: Cơ bản với tùy chọn nâng cấp Enterprise';
PRINT N'Thời gian bắt đầu: ' + CONVERT(NVARCHAR, GETDATE(), 120);
PRINT N'';

-- Tùy chọn: Đặt thành 1 để tự động nâng cấp lên Enterprise
DECLARE @NangCapEnterprise BIT = 0; -- Thay đổi thành 1 để nâng cấp tự động

PRINT N'Chế độ cài đặt: ' + CASE WHEN @NangCapEnterprise = 1 THEN N'Enterprise (Đầy đủ)' ELSE N'Cơ bản' END;
PRINT N'';

-- =====================================================
-- BƯỚC 1: TẠO CƠ SỞ DỮ LIỆU VÀ CÁC BẢNG
-- =====================================================
PRINT N'BƯỚC 1: Tạo cơ sở dữ liệu và cấu trúc bảng...';
GO
:r "5-sql-implementation\01-create-database.sql"
GO

-- =====================================================
-- BƯỚC 2: CHÈN DỮ LIỆU MẪU
-- =====================================================
PRINT N'BƯỚC 2: Chèn dữ liệu mẫu...';
GO
:r "5-sql-implementation\02-insert-sample-data.sql"
GO

-- =====================================================
-- BƯỚC 3: TẠO CÁC TRIGGER
-- =====================================================
PRINT N'BƯỚC 3: Tạo các trigger tự động...';
GO
:r "6-advanced-programming\01-triggers.sql"
GO

-- =====================================================
-- BƯỚC 4: TẠO CÁC STORED PROCEDURE
-- =====================================================
PRINT N'BƯỚC 4: Tạo các stored procedure...';
GO
:r "6-advanced-programming\02-stored-procedures.sql"
GO

-- =====================================================
-- BƯỚC 5: TẠO CÁC VIEW
-- =====================================================
PRINT N'BƯỚC 5: Tạo các view báo cáo...';
GO
:r "6-advanced-programming\03-views.sql"
GO

-- =====================================================
-- BƯỚC 6: TẠO CÁC TRANSACTION
-- =====================================================
PRINT N'BƯỚC 6: Tạo các transaction phức tạp...';
GO
:r "6-advanced-programming\04-transactions.sql"
GO

-- =====================================================
-- BƯỚC 7: KIỂM TRA HỆ THỐNG
-- =====================================================
PRINT N'BƯỚC 7: Kiểm tra hệ thống hoạt động...';

USE QuanLyThuVien;
GO

-- Kiểm tra số lượng bảng
SELECT 'Tổng số bảng' AS ThongTin, COUNT(*) AS SoLuong
FROM sys.tables
WHERE type = 'U';

-- Kiểm tra số lượng trigger
SELECT 'Tổng số trigger' AS ThongTin, COUNT(*) AS SoLuong
FROM sys.triggers
WHERE parent_class = 1;

-- Kiểm tra số lượng stored procedure
SELECT 'Tổng số stored procedure' AS ThongTin, COUNT(*) AS SoLuong
FROM sys.procedures
WHERE type = 'P';

-- Kiểm tra số lượng view
SELECT 'Tổng số view' AS ThongTin, COUNT(*) AS SoLuong
FROM sys.views;

-- Hiển thị dashboard tổng quan
SELECT * FROM V_DashboardTongQuan;

-- =====================================================
-- BƯỚC 8: TEST CHỨC NĂNG CƠ BẢN
-- =====================================================
PRINT N'BƯỚC 8: Test các chức năng cơ bản...';

-- Test mượn sách
PRINT N'Test mượn sách:';
EXEC SP_MuonSach @MaThe = 'SV2024003', @ISBN = '978-8935244829', @SoNgayMuon = 30;

-- Test tìm kiếm sách
PRINT N'Test tìm kiếm sách:';
EXEC SP_TimKiemSach @TuKhoa = N'Java', @ChiLaySachConHang = 1;

-- Test báo cáo
PRINT N'Test báo cáo thống kê:';
EXEC SP_BaoCaoThongKe @LoaiBaoCao = N'SACH_DUOC_MUON_NHIEU';

-- =====================================================
-- HOÀN THÀNH CÀI ĐẶT PHIÊN BẢN CƠ BẢN
-- =====================================================
PRINT N'';
PRINT N'=== HOÀN THÀNH CÀI ĐẶT PHIÊN BẢN CƠ BẢN ===';
PRINT N'Thời gian hoàn thành: ' + CONVERT(NVARCHAR, GETDATE(), 120);
PRINT N'';
PRINT N'Hệ thống Quản lý Thư viện (Phiên bản cơ bản) đã được cài đặt thành công!';
PRINT N'';

-- =====================================================
-- TÙY CHỌN NÂNG CẤP LÊN ENTERPRISE
-- =====================================================
IF @NangCapEnterprise = 1
BEGIN
    PRINT N'=== BẮT ĐẦU NÂNG CẤP LÊN ENTERPRISE ===';
    PRINT N'Đang cài đặt các tính năng nâng cao...';
    PRINT N'';
    
    -- Chạy script nâng cấp Enterprise
    :r "7-advanced-features\run-advanced-features.sql"
    
    PRINT N'';
    PRINT N'=== HOÀN THÀNH NÂNG CẤP ENTERPRISE ===';
    PRINT N'Hệ thống đã được nâng cấp lên phiên bản Enterprise!';
END
ELSE
BEGIN
    PRINT N'💡 NÂNG CẤP LÊN ENTERPRISE:';
    PRINT N'Để sử dụng các tính năng nâng cao, chạy lệnh sau:';
    PRINT N':r "7-advanced-features\run-advanced-features.sql"';
    PRINT N'';
    PRINT N'Hoặc đặt @NangCapEnterprise = 1 ở đầu file này và chạy lại.';
END

PRINT N'';
PRINT N'📚 HƯỚNG DẪN SỬ DỤNG:';
PRINT N'- Phiên bản cơ bản: Xem user-guide.md';
PRINT N'- Phiên bản Enterprise: Xem advanced-user-guide.md';
PRINT N'- Tài liệu chi tiết: Xem project-summary.md';
PRINT N'';

-- =====================================================
-- THỐNG KÊ CUỐI CÙNG
-- =====================================================
PRINT N'📊 THỐNG KÊ HỆ THỐNG:';
SELECT 'Tổng số bảng' AS ThongTin, COUNT(*) AS SoLuong FROM sys.tables WHERE type = 'U'
UNION ALL
SELECT 'Stored Procedures', COUNT(*) FROM sys.procedures WHERE type = 'P'
UNION ALL
SELECT 'Views', COUNT(*) FROM sys.views
UNION ALL
SELECT 'Triggers', COUNT(*) FROM sys.triggers WHERE parent_class = 1;

PRINT N'';
PRINT N'🎉 CÀI ĐẶT HOÀN TẤT! HỆ THỐNG SẴN SÀNG SỬ DỤNG!';
PRINT N'';
GO