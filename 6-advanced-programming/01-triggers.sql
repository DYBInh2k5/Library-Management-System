-- =====================================================
-- TRIGGERS cho Hệ thống Quản lý Thư viện
-- =====================================================

USE QuanLyThuVien;
GO

-- =====================================================
-- 1. TRIGGER TỰ ĐỘNG CẬP NHẬT SỐ LƯỢNG SÁCH
-- =====================================================

-- Trigger giảm số lượng sách khi có phiếu mượn mới
CREATE OR ALTER TRIGGER TRG_MuonSach_GiamSoLuong
ON MUON_TRA
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Cập nhật số lượng sách (giảm 1)
    UPDATE SACH 
    SET SoLuong = SoLuong - 1
    FROM SACH s
    INNER JOIN inserted i ON s.ISBN = i.ISBN
    WHERE s.SoLuong > 0;
    
    -- Kiểm tra nếu số lượng sách không đủ
    IF EXISTS (
        SELECT 1 
        FROM SACH s
        INNER JOIN inserted i ON s.ISBN = i.ISBN
        WHERE s.SoLuong < 0
    )
    BEGIN
        RAISERROR(N'Không đủ sách để cho mượn!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    
    PRINT N'Đã cập nhật số lượng sách sau khi mượn.';
END;
GO

-- Trigger tăng số lượng sách khi trả sách
CREATE OR ALTER TRIGGER TRG_TraSach_TangSoLuong
ON MUON_TRA
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Chỉ xử lý khi trạng thái chuyển từ 'Đang mượn' sang 'Đã trả'
    IF UPDATE(TrangThai) OR UPDATE(NgayThucTeTra)
    BEGIN
        UPDATE SACH 
        SET SoLuong = SoLuong + 1
        FROM SACH s
        INNER JOIN inserted i ON s.ISBN = i.ISBN
        INNER JOIN deleted d ON i.ISBN = d.ISBN AND i.MaThe = d.MaThe AND i.NgayMuon = d.NgayMuon
        WHERE i.TrangThai = N'Đã trả' 
            AND d.TrangThai IN (N'Đang mượn', N'Quá hạn')
            AND i.NgayThucTeTra IS NOT NULL;
            
        PRINT N'Đã cập nhật số lượng sách sau khi trả.';
    END
END;
GO

-- =====================================================
-- 2. TRIGGER TỰ ĐỘNG CẬP NHẬT TRẠNG THÁI QUÁ HẠN
-- =====================================================

CREATE OR ALTER TRIGGER TRG_CapNhatTrangThaiQuaHan
ON MUON_TRA
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Cập nhật trạng thái quá hạn cho các sách chưa trả và đã quá hạn
    UPDATE MUON_TRA
    SET TrangThai = N'Quá hạn'
    FROM MUON_TRA mt
    INNER JOIN inserted i ON mt.MaThe = i.MaThe AND mt.ISBN = i.ISBN AND mt.NgayMuon = i.NgayMuon
    WHERE mt.NgayHenTra < GETDATE()
        AND mt.NgayThucTeTra IS NULL
        AND mt.TrangThai = N'Đang mượn';
        
    IF @@ROWCOUNT > 0
        PRINT N'Đã cập nhật trạng thái quá hạn cho các sách.';
END;
GO

-- =====================================================
-- 3. TRIGGER KIỂM TRA QUY TẮC NGHIỆP VỤ
-- =====================================================

-- Trigger kiểm tra số lượng sách được mượn tối đa
CREATE OR ALTER TRIGGER TRG_KiemTraSoLuongMuonToiDa
ON MUON_TRA
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SoSachDangMuon INT;
    DECLARE @LoaiThanhVien NVARCHAR(20);
    DECLARE @MaThe CHAR(15);
    DECLARE @GioiHanMuon INT;
    
    -- Lấy thông tin từ bản ghi vừa chèn
    SELECT @MaThe = MaThe FROM inserted;
    SELECT @LoaiThanhVien = LoaiThanhVien FROM THANH_VIEN WHERE MaThe = @MaThe;
    
    -- Xác định giới hạn mượn theo loại thành viên
    SET @GioiHanMuon = CASE 
        WHEN @LoaiThanhVien = N'Sinh viên' THEN 3
        WHEN @LoaiThanhVien = N'Giảng viên' THEN 10
        WHEN @LoaiThanhVien = N'Cán bộ' THEN 5
        ELSE 2
    END;
    
    -- Đếm số sách đang mượn
    SELECT @SoSachDangMuon = COUNT(*)
    FROM MUON_TRA
    WHERE MaThe = @MaThe AND TrangThai IN (N'Đang mượn', N'Quá hạn');
    
    -- Kiểm tra vượt quá giới hạn
    IF @SoSachDangMuon > @GioiHanMuon
    BEGIN
        RAISERROR(N'Thành viên %s đã vượt quá giới hạn mượn sách (%d cuốn)!', 16, 1, @MaThe, @GioiHanMuon);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- Trigger kiểm tra thành viên có sách quá hạn
CREATE OR ALTER TRIGGER TRG_KiemTraSachQuaHan
ON MUON_TRA
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MaThe CHAR(15);
    SELECT @MaThe = MaThe FROM inserted;
    
    -- Kiểm tra xem thành viên có sách quá hạn không
    IF EXISTS (
        SELECT 1 
        FROM MUON_TRA 
        WHERE MaThe = @MaThe 
            AND TrangThai = N'Quá hạn'
            AND NgayThucTeTra IS NULL
    )
    BEGIN
        RAISERROR(N'Thành viên %s có sách quá hạn chưa trả, không được mượn thêm!', 16, 1, @MaThe);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- =====================================================
-- 4. TRIGGER AUDIT LOG (GHI LẠI LỊCH SỬ THAY ĐỔI)
-- =====================================================

-- Tạo bảng audit log
CREATE TABLE AUDIT_LOG (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(50),
    Operation NVARCHAR(10),
    RecordID NVARCHAR(50),
    OldValues NVARCHAR(MAX),
    NewValues NVARCHAR(MAX),
    ChangedBy NVARCHAR(100) DEFAULT SYSTEM_USER,
    ChangedDate DATETIME DEFAULT GETDATE()
);
GO

-- Trigger audit cho bảng SACH
CREATE OR ALTER TRIGGER TRG_Audit_SACH
ON SACH
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- INSERT
    IF EXISTS(SELECT * FROM inserted) AND NOT EXISTS(SELECT * FROM deleted)
    BEGIN
        INSERT INTO AUDIT_LOG (TableName, Operation, RecordID, NewValues)
        SELECT 'SACH', 'INSERT', ISBN, 
               CONCAT('TenSach:', TenSach, '; SoLuong:', SoLuong, '; GiaTien:', GiaTien)
        FROM inserted;
    END
    
    -- UPDATE  
    IF EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted)
    BEGIN
        INSERT INTO AUDIT_LOG (TableName, Operation, RecordID, OldValues, NewValues)
        SELECT 'SACH', 'UPDATE', i.ISBN,
               CONCAT('TenSach:', d.TenSach, '; SoLuong:', d.SoLuong, '; GiaTien:', d.GiaTien),
               CONCAT('TenSach:', i.TenSach, '; SoLuong:', i.SoLuong, '; GiaTien:', i.GiaTien)
        FROM inserted i
        INNER JOIN deleted d ON i.ISBN = d.ISBN;
    END
    
    -- DELETE
    IF NOT EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted)
    BEGIN
        INSERT INTO AUDIT_LOG (TableName, Operation, RecordID, OldValues)
        SELECT 'SACH', 'DELETE', ISBN,
               CONCAT('TenSach:', TenSach, '; SoLuong:', SoLuong, '; GiaTien:', GiaTien)
        FROM deleted;
    END
END;
GO

-- =====================================================
-- 5. TEST CÁC TRIGGER
-- =====================================================

PRINT N'=== TEST TRIGGER ===';

-- Test trigger mượn sách
PRINT N'Test 1: Mượn sách mới';
SELECT SoLuong FROM SACH WHERE ISBN = '978-8935244836';

INSERT INTO MUON_TRA (MaThe, ISBN, NgayMuon, NgayHenTra, TrangThai)
VALUES ('SV2024001', '978-8935244836', GETDATE(), DATEADD(DAY, 30, GETDATE()), N'Đang mượn');

SELECT SoLuong FROM SACH WHERE ISBN = '978-8935244836';

-- Test trigger trả sách
PRINT N'Test 2: Trả sách';
UPDATE MUON_TRA 
SET TrangThai = N'Đã trả', NgayThucTeTra = GETDATE()
WHERE MaThe = 'SV2024001' AND ISBN = '978-8935244836' AND NgayMuon = (
    SELECT MAX(NgayMuon) FROM MUON_TRA 
    WHERE MaThe = 'SV2024001' AND ISBN = '978-8935244836'
);

SELECT SoLuong FROM SACH WHERE ISBN = '978-8935244836';

PRINT N'Hoàn thành test trigger!';
GO