-- =====================================================
-- HỆ THỐNG BẢO MẬT VÀ PHÂN QUYỀN
-- =====================================================

USE QuanLyThuVien;
GO

-- =====================================================
-- 1. TẠO BẢNG NGƯỜI DÙNG VÀ QUYỀN HẠN
-- =====================================================

-- Bảng vai trò
CREATE TABLE VAI_TRO (
    MaVaiTro CHAR(10) PRIMARY KEY,
    TenVaiTro NVARCHAR(50) NOT NULL,
    MoTa NVARCHAR(200),
    TrangThai BIT DEFAULT 1
);

-- Bảng quyền hạn
CREATE TABLE QUYEN_HAN (
    MaQuyen CHAR(10) PRIMARY KEY,
    TenQuyen NVARCHAR(50) NOT NULL,
    MoTa NVARCHAR(200),
    Nhom NVARCHAR(50) -- Nhóm chức năng: SACH, THANH_VIEN, BAO_CAO, etc.
);

-- Bảng vai trò - quyền hạn
CREATE TABLE VAI_TRO_QUYEN (
    MaVaiTro CHAR(10),
    MaQuyen CHAR(10),
    PRIMARY KEY (MaVaiTro, MaQuyen),
    CONSTRAINT FK_VaiTroQuyen_VaiTro FOREIGN KEY (MaVaiTro) REFERENCES VAI_TRO(MaVaiTro),
    CONSTRAINT FK_VaiTroQuyen_Quyen FOREIGN KEY (MaQuyen) REFERENCES QUYEN_HAN(MaQuyen)
);

-- Bảng người dùng hệ thống
CREATE TABLE NGUOI_DUNG (
    TenDangNhap VARCHAR(50) PRIMARY KEY,
    MatKhau VARBINARY(256) NOT NULL, -- Mã hóa
    MaThe CHAR(15), -- Liên kết với thành viên (nếu có)
    MaVaiTro CHAR(10) NOT NULL,
    TrangThai BIT DEFAULT 1,
    NgayTao DATETIME DEFAULT GETDATE(),
    LanDangNhapCuoi DATETIME,
    SoLanDangNhapThatBai INT DEFAULT 0,
    NgayKhoa DATETIME,
    CONSTRAINT FK_NguoiDung_ThanhVien FOREIGN KEY (MaThe) REFERENCES THANH_VIEN(MaThe),
    CONSTRAINT FK_NguoiDung_VaiTro FOREIGN KEY (MaVaiTro) REFERENCES VAI_TRO(MaVaiTro)
);

-- Bảng lịch sử đăng nhập
CREATE TABLE LICH_SU_DANG_NHAP (
    MaLichSu INT IDENTITY(1,1) PRIMARY KEY,
    TenDangNhap VARCHAR(50) NOT NULL,
    ThoiGianDangNhap DATETIME DEFAULT GETDATE(),
    DiaChiIP VARCHAR(45),
    ThietBi NVARCHAR(200),
    TrangThai NVARCHAR(20), -- Thành công, Thất bại
    LyDo NVARCHAR(200),
    CONSTRAINT FK_LichSuDangNhap_NguoiDung FOREIGN KEY (TenDangNhap) REFERENCES NGUOI_DUNG(TenDangNhap)
);

GO--
 =====================================================
-- 2. CHÈN DỮ LIỆU PHÂN QUYỀN MẪU
-- =====================================================

-- Vai trò
INSERT INTO VAI_TRO (MaVaiTro, TenVaiTro, MoTa) VALUES
('ADMIN', N'Quản trị viên', N'Toàn quyền hệ thống'),
('LIBRARIAN', N'Thủ thư', N'Quản lý mượn trả, sách, thành viên'),
('STAFF', N'Nhân viên', N'Xử lý mượn trả cơ bản'),
('MEMBER', N'Thành viên', N'Xem thông tin cá nhân, tìm kiếm sách');

-- Quyền hạn
INSERT INTO QUYEN_HAN (MaQuyen, TenQuyen, MoTa, Nhom) VALUES
-- Quản lý sách
('BOOK_VIEW', N'Xem sách', N'Xem thông tin sách', 'SACH'),
('BOOK_ADD', N'Thêm sách', N'Thêm sách mới', 'SACH'),
('BOOK_EDIT', N'Sửa sách', N'Chỉnh sửa thông tin sách', 'SACH'),
('BOOK_DELETE', N'Xóa sách', N'Xóa sách khỏi hệ thống', 'SACH'),

-- Quản lý thành viên
('MEMBER_VIEW', N'Xem thành viên', N'Xem thông tin thành viên', 'THANH_VIEN'),
('MEMBER_ADD', N'Thêm thành viên', N'Đăng ký thành viên mới', 'THANH_VIEN'),
('MEMBER_EDIT', N'Sửa thành viên', N'Chỉnh sửa thông tin thành viên', 'THANH_VIEN'),
('MEMBER_DELETE', N'Xóa thành viên', N'Xóa thành viên', 'THANH_VIEN'),

-- Mượn trả
('BORROW_PROCESS', N'Xử lý mượn', N'Cho mượn sách', 'MUON_TRA'),
('RETURN_PROCESS', N'Xử lý trả', N'Nhận trả sách', 'MUON_TRA'),
('RESERVATION', N'Đặt trước', N'Đặt trước sách', 'MUON_TRA'),

-- Báo cáo
('REPORT_VIEW', N'Xem báo cáo', N'Xem các báo cáo thống kê', 'BAO_CAO'),
('REPORT_EXPORT', N'Xuất báo cáo', N'Xuất báo cáo ra file', 'BAO_CAO'),

-- Hệ thống
('SYSTEM_CONFIG', N'Cấu hình hệ thống', N'Thay đổi cấu hình hệ thống', 'HE_THONG'),
('USER_MANAGE', N'Quản lý người dùng', N'Quản lý tài khoản người dùng', 'HE_THONG');

-- Phân quyền cho vai trò
-- Admin: Toàn quyền
INSERT INTO VAI_TRO_QUYEN (MaVaiTro, MaQuyen)
SELECT 'ADMIN', MaQuyen FROM QUYEN_HAN;

-- Librarian: Quản lý sách, thành viên, mượn trả, báo cáo
INSERT INTO VAI_TRO_QUYEN (MaVaiTro, MaQuyen) VALUES
('LIBRARIAN', 'BOOK_VIEW'), ('LIBRARIAN', 'BOOK_ADD'), ('LIBRARIAN', 'BOOK_EDIT'),
('LIBRARIAN', 'MEMBER_VIEW'), ('LIBRARIAN', 'MEMBER_ADD'), ('LIBRARIAN', 'MEMBER_EDIT'),
('LIBRARIAN', 'BORROW_PROCESS'), ('LIBRARIAN', 'RETURN_PROCESS'), ('LIBRARIAN', 'RESERVATION'),
('LIBRARIAN', 'REPORT_VIEW'), ('LIBRARIAN', 'REPORT_EXPORT');

-- Staff: Mượn trả cơ bản
INSERT INTO VAI_TRO_QUYEN (MaVaiTro, MaQuyen) VALUES
('STAFF', 'BOOK_VIEW'), ('STAFF', 'MEMBER_VIEW'),
('STAFF', 'BORROW_PROCESS'), ('STAFF', 'RETURN_PROCESS');

-- Member: Chỉ xem
INSERT INTO VAI_TRO_QUYEN (MaVaiTro, MaQuyen) VALUES
('MEMBER', 'BOOK_VIEW'), ('MEMBER', 'RESERVATION');

-- =====================================================
-- 3. STORED PROCEDURE BẢO MẬT
-- =====================================================

CREATE OR ALTER PROCEDURE SP_DangNhap
    @TenDangNhap VARCHAR(50),
    @MatKhau NVARCHAR(100),
    @DiaChiIP VARCHAR(45) = NULL,
    @ThietBi NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @MatKhauMaHoa VARBINARY(256);
    DECLARE @TrangThai NVARCHAR(20) = N'Thất bại';
    DECLARE @LyDo NVARCHAR(200) = N'';
    DECLARE @MaVaiTro CHAR(10);
    
    BEGIN TRY
        -- Mã hóa mật khẩu để so sánh
        SET @MatKhauMaHoa = HASHBYTES('SHA2_256', @MatKhau);
        
        -- Kiểm tra tài khoản
        SELECT @MaVaiTro = MaVaiTro
        FROM NGUOI_DUNG 
        WHERE TenDangNhap = @TenDangNhap 
            AND MatKhau = @MatKhauMaHoa
            AND TrangThai = 1
            AND (NgayKhoa IS NULL OR NgayKhoa > GETDATE());
        
        IF @MaVaiTro IS NOT NULL
        BEGIN
            SET @TrangThai = N'Thành công';
            
            -- Cập nhật thông tin đăng nhập
            UPDATE NGUOI_DUNG 
            SET LanDangNhapCuoi = GETDATE(),
                SoLanDangNhapThatBai = 0
            WHERE TenDangNhap = @TenDangNhap;
            
            -- Trả về thông tin người dùng
            SELECT 
                nd.TenDangNhap,
                nd.MaThe,
                vt.TenVaiTro,
                tv.HoTen,
                N'Đăng nhập thành công!' AS ThongBao
            FROM NGUOI_DUNG nd
            JOIN VAI_TRO vt ON nd.MaVaiTro = vt.MaVaiTro
            LEFT JOIN THANH_VIEN tv ON nd.MaThe = tv.MaThe
            WHERE nd.TenDangNhap = @TenDangNhap;
        END
        ELSE
        BEGIN
            SET @LyDo = N'Tên đăng nhập hoặc mật khẩu không đúng';
            
            -- Tăng số lần đăng nhập thất bại
            UPDATE NGUOI_DUNG 
            SET SoLanDangNhapThatBai = SoLanDangNhapThatBai + 1,
                NgayKhoa = CASE WHEN SoLanDangNhapThatBai >= 4 THEN DATEADD(HOUR, 1, GETDATE()) ELSE NgayKhoa END
            WHERE TenDangNhap = @TenDangNhap;
            
            RAISERROR(@LyDo, 16, 1);
        END
        
    END TRY
    BEGIN CATCH
        SET @TrangThai = N'Thất bại';
        SET @LyDo = ERROR_MESSAGE();
        THROW;
    END CATCH
    FINALLY
    BEGIN
        -- Ghi log đăng nhập
        INSERT INTO LICH_SU_DANG_NHAP (TenDangNhap, DiaChiIP, ThietBi, TrangThai, LyDo)
        VALUES (@TenDangNhap, @DiaChiIP, @ThietBi, @TrangThai, @LyDo);
    END
END;
GO

CREATE OR ALTER PROCEDURE SP_KiemTraQuyen
    @TenDangNhap VARCHAR(50),
    @MaQuyen CHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1 
        FROM NGUOI_DUNG nd
        JOIN VAI_TRO_QUYEN vtq ON nd.MaVaiTro = vtq.MaVaiTro
        WHERE nd.TenDangNhap = @TenDangNhap 
            AND vtq.MaQuyen = @MaQuyen
            AND nd.TrangThai = 1
    )
    BEGIN
        SELECT 1 AS CoQuyen, N'Có quyền thực hiện' AS ThongBao;
    END
    ELSE
    BEGIN
        SELECT 0 AS CoQuyen, N'Không có quyền thực hiện' AS ThongBao;
    END
END;
GO