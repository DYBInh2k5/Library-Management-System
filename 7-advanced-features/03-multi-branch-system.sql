-- =====================================================
-- HỆ THỐNG NHIỀU CHI NHÁNH (MULTI-BRANCH SYSTEM)
-- =====================================================

USE QuanLyThuVien;
GO

-- =====================================================
-- 1. TẠO BẢNG CHI NHÁNH
-- =====================================================

-- Bảng chi nhánh thư viện
CREATE TABLE CHI_NHANH (
    MaChiNhanh CHAR(10) PRIMARY KEY,
    TenChiNhanh NVARCHAR(100) NOT NULL,
    DiaChi NVARCHAR(200) NOT NULL,
    SoDienThoai VARCHAR(15),
    Email VARCHAR(100),
    ThuThu NVARCHAR(100), -- Thủ thư trưởng
    TrangThai BIT DEFAULT 1, -- 1: Hoạt động, 0: Tạm đóng
    NgayMoCua DATE DEFAULT GETDATE(),
    GioMoCua TIME DEFAULT '08:00',
    GioDongCua TIME DEFAULT '17:00',
    CONSTRAINT UK_ChiNhanh_Ten UNIQUE (TenChiNhanh)
);

-- Bảng kho sách theo chi nhánh
CREATE TABLE KHO_SACH_CHI_NHANH (
    MaChiNhanh CHAR(10),
    ISBN VARCHAR(20),
    SoLuong INT NOT NULL DEFAULT 0,
    SoLuongToiThieu INT DEFAULT 5, -- Ngưỡng cảnh báo hết sách
    ViTri NVARCHAR(50), -- Vị trí sách trong kho (Kệ A1, Tầng 2, v.v.)
    NgayCapNhatCuoi DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (MaChiNhanh, ISBN),
    CONSTRAINT FK_KhoSach_ChiNhanh FOREIGN KEY (MaChiNhanh) REFERENCES CHI_NHANH(MaChiNhanh),
    CONSTRAINT FK_KhoSach_Sach FOREIGN KEY (ISBN) REFERENCES SACH(ISBN),
    CONSTRAINT CK_KhoSach_SoLuong CHECK (SoLuong >= 0)
);

-- Bảng chuyển sách giữa chi nhánh
CREATE TABLE CHUYEN_SACH_CHI_NHANH (
    MaChuyen INT IDENTITY(1,1) PRIMARY KEY,
    ChiNhanhNguon CHAR(10) NOT NULL,
    ChiNhanhDich CHAR(10) NOT NULL,
    ISBN VARCHAR(20) NOT NULL,
    SoLuong INT NOT NULL,
    NgayYeuCau DATE DEFAULT GETDATE(),
    NgayGui DATE,
    NgayNhan DATE,
    TrangThai NVARCHAR(20) DEFAULT N'Chờ xử lý',
    NguoiYeuCau NVARCHAR(50),
    NguoiGui NVARCHAR(50),
    NguoiNhan NVARCHAR(50),
    GhiChu NVARCHAR(200),
    CONSTRAINT FK_ChuyenSach_ChiNhanhNguon FOREIGN KEY (ChiNhanhNguon) REFERENCES CHI_NHANH(MaChiNhanh),
    CONSTRAINT FK_ChuyenSach_ChiNhanhDich FOREIGN KEY (ChiNhanhDich) REFERENCES CHI_NHANH(MaChiNhanh),
    CONSTRAINT FK_ChuyenSach_Sach FOREIGN KEY (ISBN) REFERENCES SACH(ISBN),
    CONSTRAINT CK_ChuyenSach_TrangThai CHECK (TrangThai IN (N'Chờ xử lý', N'Đã gửi', N'Đã nhận', N'Hủy bỏ')),
    CONSTRAINT CK_ChuyenSach_SoLuong CHECK (SoLuong > 0)
);

GO-- ==
===================================================
-- 2. CHÈN DỮ LIỆU CHI NHÁNH MẪU
-- =====================================================

INSERT INTO CHI_NHANH (MaChiNhanh, TenChiNhanh, DiaChi, SoDienThoai, Email, ThuThu) VALUES
('CN001', N'Thư viện Trung tâm', N'144 Xuân Thủy, Cầu Giấy, Hà Nội', '024-3754-7506', 'central@library.edu.vn', N'Nguyễn Văn Thư'),
('CN002', N'Thư viện Cơ sở 2', N'1 Đại Cồ Việt, Hai Bà Trưng, Hà Nội', '024-3869-2222', 'branch2@library.edu.vn', N'Trần Thị Lan'),
('CN003', N'Thư viện Khu A', N'Khu A, Đại học Quốc gia Hà Nội', '024-3754-1234', 'khua@library.edu.vn', N'Lê Văn Nam'),
('CN004', N'Thư viện Tây Nguyên', N'Buôn Ma Thuột, Đắk Lắk', '0262-3853-333', 'taynguyen@library.edu.vn', N'Phạm Văn Sơn');

-- Phân bổ sách cho các chi nhánh
INSERT INTO KHO_SACH_CHI_NHANH (MaChiNhanh, ISBN, SoLuong, ViTri) 
SELECT 'CN001', ISBN, SoLuong, N'Kệ A' + CAST(ROW_NUMBER() OVER (ORDER BY ISBN) AS NVARCHAR(10))
FROM SACH;

INSERT INTO KHO_SACH_CHI_NHANH (MaChiNhanh, ISBN, SoLuong, ViTri) 
SELECT 'CN002', ISBN, CASE WHEN SoLuong > 2 THEN SoLuong/2 ELSE 1 END, N'Kệ B' + CAST(ROW_NUMBER() OVER (ORDER BY ISBN) AS NVARCHAR(10))
FROM SACH;

INSERT INTO KHO_SACH_CHI_NHANH (MaChiNhanh, ISBN, SoLuong, ViTri) 
SELECT 'CN003', ISBN, CASE WHEN SoLuong > 3 THEN SoLuong/3 ELSE 1 END, N'Kệ C' + CAST(ROW_NUMBER() OVER (ORDER BY ISBN) AS NVARCHAR(10))
FROM SACH WHERE ISBN IN (SELECT TOP 5 ISBN FROM SACH);

-- =====================================================
-- 3. STORED PROCEDURE QUẢN LÝ CHI NHÁNH
-- =====================================================

CREATE OR ALTER PROCEDURE SP_ChuyenSachGiuaChiNhanh
    @ChiNhanhNguon CHAR(10),
    @ChiNhanhDich CHAR(10),
    @ISBN VARCHAR(20),
    @SoLuong INT,
    @GhiChu NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Kiểm tra chi nhánh tồn tại
        IF NOT EXISTS (SELECT 1 FROM CHI_NHANH WHERE MaChiNhanh = @ChiNhanhNguon AND TrangThai = 1)
        BEGIN
            RAISERROR(N'Chi nhánh nguồn không tồn tại hoặc đã đóng!', 16, 1);
            RETURN;
        END
        
        IF NOT EXISTS (SELECT 1 FROM CHI_NHANH WHERE MaChiNhanh = @ChiNhanhDich AND TrangThai = 1)
        BEGIN
            RAISERROR(N'Chi nhánh đích không tồn tại hoặc đã đóng!', 16, 1);
            RETURN;
        END
        
        -- Kiểm tra số lượng sách đủ không
        IF NOT EXISTS (
            SELECT 1 FROM KHO_SACH_CHI_NHANH 
            WHERE MaChiNhanh = @ChiNhanhNguon AND ISBN = @ISBN AND SoLuong >= @SoLuong
        )
        BEGIN
            RAISERROR(N'Chi nhánh nguồn không đủ sách để chuyển!', 16, 1);
            RETURN;
        END
        
        -- Tạo yêu cầu chuyển sách
        INSERT INTO CHUYEN_SACH_CHI_NHANH (ChiNhanhNguon, ChiNhanhDich, ISBN, SoLuong, NguoiYeuCau, GhiChu)
        VALUES (@ChiNhanhNguon, @ChiNhanhDich, @ISBN, @SoLuong, SYSTEM_USER, @GhiChu);
        
        COMMIT TRANSACTION;
        
        SELECT 
            N'Tạo yêu cầu chuyển sách thành công!' AS ThongBao,
            SCOPE_IDENTITY() AS MaChuyen;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE SP_XacNhanChuyenSach
    @MaChuyen INT,
    @HanhDong NVARCHAR(20) -- 'GUI', 'NHAN', 'HUY'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @ChiNhanhNguon CHAR(10), @ChiNhanhDich CHAR(10), @ISBN VARCHAR(20), @SoLuong INT;
        
        SELECT @ChiNhanhNguon = ChiNhanhNguon, @ChiNhanhDich = ChiNhanhDich, 
               @ISBN = ISBN, @SoLuong = SoLuong
        FROM CHUYEN_SACH_CHI_NHANH 
        WHERE MaChuyen = @MaChuyen;
        
        IF @ChiNhanhNguon IS NULL
        BEGIN
            RAISERROR(N'Không tìm thấy yêu cầu chuyển sách!', 16, 1);
            RETURN;
        END
        
        IF @HanhDong = N'GUI'
        BEGIN
            -- Giảm số lượng ở chi nhánh nguồn
            UPDATE KHO_SACH_CHI_NHANH
            SET SoLuong = SoLuong - @SoLuong,
                NgayCapNhatCuoi = GETDATE()
            WHERE MaChiNhanh = @ChiNhanhNguon AND ISBN = @ISBN;
            
            -- Cập nhật trạng thái
            UPDATE CHUYEN_SACH_CHI_NHANH
            SET TrangThai = N'Đã gửi',
                NgayGui = GETDATE(),
                NguoiGui = SYSTEM_USER
            WHERE MaChuyen = @MaChuyen;
        END
        ELSE IF @HanhDong = N'NHAN'
        BEGIN
            -- Tăng số lượng ở chi nhánh đích
            IF EXISTS (SELECT 1 FROM KHO_SACH_CHI_NHANH WHERE MaChiNhanh = @ChiNhanhDich AND ISBN = @ISBN)
            BEGIN
                UPDATE KHO_SACH_CHI_NHANH
                SET SoLuong = SoLuong + @SoLuong,
                    NgayCapNhatCuoi = GETDATE()
                WHERE MaChiNhanh = @ChiNhanhDich AND ISBN = @ISBN;
            END
            ELSE
            BEGIN
                INSERT INTO KHO_SACH_CHI_NHANH (MaChiNhanh, ISBN, SoLuong, ViTri)
                VALUES (@ChiNhanhDich, @ISBN, @SoLuong, N'Kệ mới');
            END
            
            -- Cập nhật trạng thái
            UPDATE CHUYEN_SACH_CHI_NHANH
            SET TrangThai = N'Đã nhận',
                NgayNhan = GETDATE(),
                NguoiNhan = SYSTEM_USER
            WHERE MaChuyen = @MaChuyen;
        END
        
        COMMIT TRANSACTION;
        SELECT N'Xác nhận chuyển sách thành công!' AS ThongBao;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO