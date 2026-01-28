-- =====================================================
-- HỆ THỐNG THÔNG BÁO (NOTIFICATION SYSTEM)
-- =====================================================

USE QuanLyThuVien;
GO

-- =====================================================
-- 1. TẠO BẢNG THÔNG BÁO
-- =====================================================

-- Bảng thông báo
CREATE TABLE THONG_BAO (
    MaThongBao INT IDENTITY(1,1) PRIMARY KEY,
    MaThe CHAR(15),
    LoaiThongBao NVARCHAR(50) NOT NULL,
    TieuDe NVARCHAR(200) NOT NULL,
    NoiDung NVARCHAR(MAX) NOT NULL,
    NgayTao DATETIME NOT NULL DEFAULT GETDATE(),
    NgayGui DATETIME,
    TrangThai NVARCHAR(20) NOT NULL DEFAULT N'Chưa gửi',
    KenhGui NVARCHAR(50), -- Email, SMS, App
    SoLanThu INT DEFAULT 0,
    CONSTRAINT FK_ThongBao_ThanhVien FOREIGN KEY (MaThe) REFERENCES THANH_VIEN(MaThe),
    CONSTRAINT CK_ThongBao_TrangThai CHECK (TrangThai IN (N'Chưa gửi', N'Đã gửi', N'Thất bại', N'Đã đọc'))
);

-- Bảng mẫu thông báo
CREATE TABLE MAU_THONG_BAO (
    MaMau INT IDENTITY(1,1) PRIMARY KEY,
    TenMau NVARCHAR(100) NOT NULL,
    LoaiThongBao NVARCHAR(50) NOT NULL,
    TieuDeMau NVARCHAR(200) NOT NULL,
    NoiDungMau NVARCHAR(MAX) NOT NULL,
    ThamSo NVARCHAR(500), -- JSON format: {"param1": "description", "param2": "description"}
    TrangThai BIT DEFAULT 1
);

-- Index
CREATE INDEX IX_ThongBao_MaThe ON THONG_BAO(MaThe);
CREATE INDEX IX_ThongBao_TrangThai ON THONG_BAO(TrangThai);
CREATE INDEX IX_ThongBao_NgayTao ON THONG_BAO(NgayTao);

GO-- =
====================================================
-- 2. CHÈN MẪU THÔNG BÁO
-- =====================================================

INSERT INTO MAU_THONG_BAO (TenMau, LoaiThongBao, TieuDeMau, NoiDungMau, ThamSo) VALUES
(N'Nhắc nhở trả sách', N'REMINDER', 
 N'Nhắc nhở: Sách "{TenSach}" sắp đến hạn trả',
 N'Xin chào {HoTen},

Bạn có sách "{TenSach}" (ISBN: {ISBN}) sắp đến hạn trả vào ngày {NgayHenTra}.
Vui lòng đến thư viện để trả sách đúng hạn để tránh bị phạt.

Thời gian mở cửa: 8:00 - 17:00 (Thứ 2 - Thứ 6)
Địa chỉ: Thư viện Trường Đại học

Trân trọng,
Hệ thống Quản lý Thư viện',
 N'{"HoTen": "Tên thành viên", "TenSach": "Tên sách", "ISBN": "Mã ISBN", "NgayHenTra": "Ngày hẹn trả"}'),

(N'Thông báo quá hạn', N'OVERDUE',
 N'Cảnh báo: Sách "{TenSach}" đã quá hạn trả',
 N'Xin chào {HoTen},

Sách "{TenSach}" (ISBN: {ISBN}) của bạn đã quá hạn {SoNgayQuaHan} ngày.
Tiền phạt hiện tại: {TienPhat} VNĐ

Vui lòng đến thư viện ngay để trả sách và thanh toán phạt.
Lưu ý: Bạn sẽ không thể mượn sách mới cho đến khi trả sách quá hạn.

Thư viện Trường Đại học',
 N'{"HoTen": "Tên thành viên", "TenSach": "Tên sách", "ISBN": "Mã ISBN", "SoNgayQuaHan": "Số ngày quá hạn", "TienPhat": "Tiền phạt"}'),

(N'Sách đã có sẵn', N'AVAILABLE',
 N'Thông báo: Sách "{TenSach}" đã có sẵn',
 N'Xin chào {HoTen},

Sách "{TenSach}" mà bạn đã đặt trước hiện đã có sẵn.
Vui lòng đến thư viện trong vòng {SoNgayGiuCho} ngày để mượn sách.

Nếu không đến trong thời hạn, đơn đặt trước sẽ bị hủy tự động.

Thư viện Trường Đại học',
 N'{"HoTen": "Tên thành viên", "TenSach": "Tên sách", "SoNgayGiuCho": "Số ngày giữ chỗ"}');

-- =====================================================
-- 3. STORED PROCEDURE TẠO THÔNG BÁO
-- =====================================================

CREATE OR ALTER PROCEDURE SP_TaoThongBao
    @MaThe CHAR(15),
    @LoaiThongBao NVARCHAR(50),
    @ThamSoJSON NVARCHAR(MAX), -- JSON format
    @KenhGui NVARCHAR(50) = N'Email'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @TieuDe NVARCHAR(200), @NoiDung NVARCHAR(MAX);
        DECLARE @TieuDeMau NVARCHAR(200), @NoiDungMau NVARCHAR(MAX);
        
        -- Lấy mẫu thông báo
        SELECT @TieuDeMau = TieuDeMau, @NoiDungMau = NoiDungMau
        FROM MAU_THONG_BAO 
        WHERE LoaiThongBao = @LoaiThongBao AND TrangThai = 1;
        
        IF @TieuDeMau IS NULL
        BEGIN
            RAISERROR(N'Không tìm thấy mẫu thông báo cho loại: %s', 16, 1, @LoaiThongBao);
            RETURN;
        END
        
        -- Thay thế tham số (đơn giản hóa, trong thực tế cần parser JSON phức tạp hơn)
        SET @TieuDe = @TieuDeMau;
        SET @NoiDung = @NoiDungMau;
        
        -- Thay thế một số tham số cơ bản
        IF @ThamSoJSON LIKE '%HoTen%'
        BEGIN
            DECLARE @HoTen NVARCHAR(100);
            SELECT @HoTen = HoTen FROM THANH_VIEN WHERE MaThe = @MaThe;
            SET @NoiDung = REPLACE(@NoiDung, '{HoTen}', @HoTen);
        END
        
        -- Tạo thông báo
        INSERT INTO THONG_BAO (MaThe, LoaiThongBao, TieuDe, NoiDung, KenhGui)
        VALUES (@MaThe, @LoaiThongBao, @TieuDe, @NoiDung, @KenhGui);
        
        SELECT N'Tạo thông báo thành công!' AS ThongBao;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO