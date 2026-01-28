-- =====================================================
-- HỆ THỐNG ĐẶT TRƯỚC SÁCH (RESERVATION SYSTEM)
-- =====================================================

USE QuanLyThuVien;
GO

-- =====================================================
-- 1. TẠO BẢNG ĐẶT TRƯỚC
-- =====================================================

-- Bảng đặt trước sách
CREATE TABLE DAT_TRUOC (
    MaDatTruoc INT IDENTITY(1,1) PRIMARY KEY,
    MaThe CHAR(15) NOT NULL,
    ISBN VARCHAR(20) NOT NULL,
    NgayDat DATE NOT NULL DEFAULT GETDATE(),
    NgayHetHan DATE NOT NULL,
    TrangThai NVARCHAR(20) NOT NULL DEFAULT N'Chờ xử lý',
    GhiChu NVARCHAR(200),
    NgayXuLy DATE,
    NguoiXuLy NVARCHAR(50),
    CONSTRAINT FK_DatTruoc_ThanhVien FOREIGN KEY (MaThe) REFERENCES THANH_VIEN(MaThe),
    CONSTRAINT FK_DatTruoc_Sach FOREIGN KEY (ISBN) REFERENCES SACH(ISBN),
    CONSTRAINT CK_DatTruoc_TrangThai CHECK (TrangThai IN (N'Chờ xử lý', N'Đã xử lý', N'Hủy bỏ', N'Hết hạn')),
    CONSTRAINT CK_DatTruoc_NgayHetHan CHECK (NgayHetHan >= NgayDat)
);

-- Index cho hiệu suất
CREATE INDEX IX_DatTruoc_MaThe ON DAT_TRUOC(MaThe);
CREATE INDEX IX_DatTruoc_ISBN ON DAT_TRUOC(ISBN);
CREATE INDEX IX_DatTruoc_TrangThai ON DAT_TRUOC(TrangThai);
CREATE INDEX IX_DatTruoc_NgayDat ON DAT_TRUOC(NgayDat);

GO-- 
=====================================================
-- 2. STORED PROCEDURE ĐẶT TRƯỚC SÁCH
-- =====================================================

CREATE OR ALTER PROCEDURE SP_DatTruocSach
    @MaThe CHAR(15),
    @ISBN VARCHAR(20),
    @SoNgayGiuCho INT = 7
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Kiểm tra thành viên và sách tồn tại
        IF NOT EXISTS (SELECT 1 FROM THANH_VIEN WHERE MaThe = @MaThe)
        BEGIN
            RAISERROR(N'Mã thẻ không tồn tại!', 16, 1);
            RETURN;
        END
        
        IF NOT EXISTS (SELECT 1 FROM SACH WHERE ISBN = @ISBN)
        BEGIN
            RAISERROR(N'Sách không tồn tại!', 16, 1);
            RETURN;
        END
        
        -- Kiểm tra sách còn hàng (nếu còn thì không cần đặt trước)
        IF EXISTS (SELECT 1 FROM SACH WHERE ISBN = @ISBN AND SoLuong > 0)
        BEGIN
            RAISERROR(N'Sách còn hàng, có thể mượn trực tiếp!', 16, 1);
            RETURN;
        END
        
        -- Kiểm tra đã đặt trước chưa
        IF EXISTS (
            SELECT 1 FROM DAT_TRUOC 
            WHERE MaThe = @MaThe AND ISBN = @ISBN 
                AND TrangThai = N'Chờ xử lý'
        )
        BEGIN
            RAISERROR(N'Bạn đã đặt trước sách này rồi!', 16, 1);
            RETURN;
        END
        
        -- Thêm đặt trước
        INSERT INTO DAT_TRUOC (MaThe, ISBN, NgayDat, NgayHetHan, TrangThai)
        VALUES (@MaThe, @ISBN, GETDATE(), DATEADD(DAY, @SoNgayGiuCho, GETDATE()), N'Chờ xử lý');
        
        COMMIT TRANSACTION;
        
        SELECT 
            N'Đặt trước sách thành công!' AS ThongBao,
            @MaThe AS MaThe,
            s.TenSach,
            GETDATE() AS NgayDat,
            DATEADD(DAY, @SoNgayGiuCho, GETDATE()) AS NgayHetHan
        FROM SACH s WHERE s.ISBN = @ISBN;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =====================================================
-- 3. STORED PROCEDURE XỬ LÝ ĐẶT TRƯỚC
-- =====================================================

CREATE OR ALTER PROCEDURE SP_XuLyDatTruoc
    @MaDatTruoc INT,
    @HanhDong NVARCHAR(20), -- 'XU_LY' hoặc 'HUY_BO'
    @GhiChu NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @MaThe CHAR(15), @ISBN VARCHAR(20);
        
        -- Lấy thông tin đặt trước
        SELECT @MaThe = MaThe, @ISBN = ISBN
        FROM DAT_TRUOC 
        WHERE MaDatTruoc = @MaDatTruoc AND TrangThai = N'Chờ xử lý';
        
        IF @MaThe IS NULL
        BEGIN
            RAISERROR(N'Không tìm thấy đơn đặt trước hợp lệ!', 16, 1);
            RETURN;
        END
        
        IF @HanhDong = N'XU_LY'
        BEGIN
            -- Kiểm tra sách có sẵn không
            IF NOT EXISTS (SELECT 1 FROM SACH WHERE ISBN = @ISBN AND SoLuong > 0)
            BEGIN
                RAISERROR(N'Sách chưa có sẵn để xử lý đặt trước!', 16, 1);
                RETURN;
            END
            
            -- Tự động tạo phiếu mượn
            EXEC SP_MuonSach @MaThe = @MaThe, @ISBN = @ISBN, @SoNgayMuon = 30;
            
            -- Cập nhật trạng thái đặt trước
            UPDATE DAT_TRUOC
            SET TrangThai = N'Đã xử lý',
                NgayXuLy = GETDATE(),
                NguoiXuLy = SYSTEM_USER,
                GhiChu = @GhiChu
            WHERE MaDatTruoc = @MaDatTruoc;
        END
        ELSE IF @HanhDong = N'HUY_BO'
        BEGIN
            UPDATE DAT_TRUOC
            SET TrangThai = N'Hủy bỏ',
                NgayXuLy = GETDATE(),
                NguoiXuLy = SYSTEM_USER,
                GhiChu = @GhiChu
            WHERE MaDatTruoc = @MaDatTruoc;
        END
        
        COMMIT TRANSACTION;
        
        SELECT N'Xử lý đặt trước thành công!' AS ThongBao;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO