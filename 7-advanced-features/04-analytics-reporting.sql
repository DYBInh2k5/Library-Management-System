-- =====================================================
-- HỆ THỐNG PHÂN TÍCH VÀ BÁO CÁO NÂNG CAO
-- =====================================================

USE QuanLyThuVien;
GO

-- =====================================================
-- 1. TẠO BẢNG DỮ LIỆU PHÂN TÍCH
-- =====================================================

-- Bảng thống kê theo ngày
CREATE TABLE THONG_KE_NGAY (
    Ngay DATE PRIMARY KEY,
    SoLanMuon INT DEFAULT 0,
    SoLanTra INT DEFAULT 0,
    SoThanhVienMoi INT DEFAULT 0,
    SoSachMoi INT DEFAULT 0,
    DoanhThuPhat DECIMAL(12,2) DEFAULT 0,
    NgayCapNhat DATETIME DEFAULT GETDATE()
);

-- Bảng xu hướng sách
CREATE TABLE XU_HUONG_SACH (
    ISBN VARCHAR(20),
    Thang INT,
    Nam INT,
    SoLanMuon INT DEFAULT 0,
    SoLanDatTruoc INT DEFAULT 0,
    DiemPhoBien DECIMAL(5,2) DEFAULT 0, -- Điểm từ 0-10
    XepHang INT,
    PRIMARY KEY (ISBN, Thang, Nam),
    CONSTRAINT FK_XuHuongSach_Sach FOREIGN KEY (ISBN) REFERENCES SACH(ISBN)
);

-- Bảng phân tích hành vi người dùng
CREATE TABLE PHAN_TICH_NGUOI_DUNG (
    MaThe CHAR(15),
    Thang INT,
    Nam INT,
    SoLanMuon INT DEFAULT 0,
    SoNgayMuonTrungBinh DECIMAL(5,2) DEFAULT 0,
    SoLanTraMuon INT DEFAULT 0,
    TyLeTraMuon DECIMAL(5,2) DEFAULT 0,
    TheLoaiYeuThich NVARCHAR(50),
    MucDoTichCuc NVARCHAR(20), -- Cao, Trung bình, Thấp
    PRIMARY KEY (MaThe, Thang, Nam),
    CONSTRAINT FK_PhanTichNguoiDung_ThanhVien FOREIGN KEY (MaThe) REFERENCES THANH_VIEN(MaThe)
);

GO-
- =====================================================
-- 2. STORED PROCEDURE PHÂN TÍCH DỮ LIỆU
-- =====================================================

CREATE OR ALTER PROCEDURE SP_PhanTichXuHuongSach
    @Thang INT = NULL,
    @Nam INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @Thang IS NULL SET @Thang = MONTH(GETDATE());
    IF @Nam IS NULL SET @Nam = YEAR(GETDATE());
    
    -- Xóa dữ liệu cũ
    DELETE FROM XU_HUONG_SACH WHERE Thang = @Thang AND Nam = @Nam;
    
    -- Tính toán xu hướng
    WITH SachStats AS (
        SELECT 
            s.ISBN,
            COUNT(mt.ISBN) as SoLanMuon,
            COUNT(dt.ISBN) as SoLanDatTruoc,
            -- Tính điểm phổ biến (0-10)
            CASE 
                WHEN COUNT(mt.ISBN) = 0 THEN 0
                WHEN COUNT(mt.ISBN) >= 20 THEN 10
                ELSE COUNT(mt.ISBN) * 0.5
            END as DiemPhoBien
        FROM SACH s
        LEFT JOIN MUON_TRA mt ON s.ISBN = mt.ISBN 
            AND MONTH(mt.NgayMuon) = @Thang AND YEAR(mt.NgayMuon) = @Nam
        LEFT JOIN DAT_TRUOC dt ON s.ISBN = dt.ISBN 
            AND MONTH(dt.NgayDat) = @Thang AND YEAR(dt.NgayDat) = @Nam
        GROUP BY s.ISBN
    ),
    RankedBooks AS (
        SELECT *,
            ROW_NUMBER() OVER (ORDER BY DiemPhoBien DESC, SoLanMuon DESC) as XepHang
        FROM SachStats
    )
    INSERT INTO XU_HUONG_SACH (ISBN, Thang, Nam, SoLanMuon, SoLanDatTruoc, DiemPhoBien, XepHang)
    SELECT ISBN, @Thang, @Nam, SoLanMuon, SoLanDatTruoc, DiemPhoBien, XepHang
    FROM RankedBooks;
    
    SELECT N'Phân tích xu hướng sách hoàn thành!' AS ThongBao;
END;
GO

CREATE OR ALTER PROCEDURE SP_PhanTichNguoiDung
    @Thang INT = NULL,
    @Nam INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @Thang IS NULL SET @Thang = MONTH(GETDATE());
    IF @Nam IS NULL SET @Nam = YEAR(GETDATE());
    
    -- Xóa dữ liệu cũ
    DELETE FROM PHAN_TICH_NGUOI_DUNG WHERE Thang = @Thang AND Nam = @Nam;
    
    -- Phân tích hành vi người dùng
    WITH UserStats AS (
        SELECT 
            tv.MaThe,
            COUNT(mt.MaThe) as SoLanMuon,
            AVG(CAST(DATEDIFF(DAY, mt.NgayMuon, ISNULL(mt.NgayThucTeTra, GETDATE())) AS DECIMAL(5,2))) as SoNgayMuonTrungBinh,
            COUNT(CASE WHEN mt.NgayThucTeTra > mt.NgayHenTra THEN 1 END) as SoLanTraMuon,
            CASE 
                WHEN COUNT(mt.MaThe) = 0 THEN 0
                ELSE CAST(COUNT(CASE WHEN mt.NgayThucTeTra > mt.NgayHenTra THEN 1 END) * 100.0 / COUNT(mt.MaThe) AS DECIMAL(5,2))
            END as TyLeTraMuon
        FROM THANH_VIEN tv
        LEFT JOIN MUON_TRA mt ON tv.MaThe = mt.MaThe 
            AND MONTH(mt.NgayMuon) = @Thang AND YEAR(mt.NgayMuon) = @Nam
        GROUP BY tv.MaThe
    ),
    UserPreferences AS (
        SELECT 
            tv.MaThe,
            (SELECT TOP 1 tl.TenTheLoai
             FROM MUON_TRA mt2
             JOIN SACH s ON mt2.ISBN = s.ISBN
             JOIN THUOC_THE_LOAI ttl ON s.ISBN = ttl.ISBN
             JOIN THE_LOAI tl ON ttl.MaTheLoai = tl.MaTheLoai
             WHERE mt2.MaThe = tv.MaThe 
                AND MONTH(mt2.NgayMuon) = @Thang AND YEAR(mt2.NgayMuon) = @Nam
             GROUP BY tl.TenTheLoai
             ORDER BY COUNT(*) DESC) as TheLoaiYeuThich
        FROM THANH_VIEN tv
    )
    INSERT INTO PHAN_TICH_NGUOI_DUNG (MaThe, Thang, Nam, SoLanMuon, SoNgayMuonTrungBinh, SoLanTraMuon, TyLeTraMuon, TheLoaiYeuThich, MucDoTichCuc)
    SELECT 
        us.MaThe,
        @Thang,
        @Nam,
        us.SoLanMuon,
        us.SoNgayMuonTrungBinh,
        us.SoLanTraMuon,
        us.TyLeTraMuon,
        up.TheLoaiYeuThich,
        CASE 
            WHEN us.SoLanMuon >= 10 THEN N'Cao'
            WHEN us.SoLanMuon >= 3 THEN N'Trung bình'
            ELSE N'Thấp'
        END
    FROM UserStats us
    LEFT JOIN UserPreferences up ON us.MaThe = up.MaThe;
    
    SELECT N'Phân tích người dùng hoàn thành!' AS ThongBao;
END;
GO

-- =====================================================
-- 3. VIEW BÁO CÁO NÂNG CAO
-- =====================================================

-- Dashboard điều hành
CREATE OR ALTER VIEW V_DashboardDieuHanh
AS
SELECT 
    -- Thống kê hôm nay
    (SELECT COUNT(*) FROM MUON_TRA WHERE CAST(NgayMuon AS DATE) = CAST(GETDATE() AS DATE)) AS MuonHomNay,
    (SELECT COUNT(*) FROM MUON_TRA WHERE CAST(NgayThucTeTra AS DATE) = CAST(GETDATE() AS DATE)) AS TraHomNay,
    (SELECT COUNT(*) FROM DAT_TRUOC WHERE CAST(NgayDat AS DATE) = CAST(GETDATE() AS DATE)) AS DatTruocHomNay,
    
    -- Thống kê tuần này
    (SELECT COUNT(*) FROM MUON_TRA WHERE NgayMuon >= DATEADD(WEEK, -1, GETDATE())) AS MuonTuanNay,
    (SELECT COUNT(*) FROM THANH_VIEN WHERE NgayThamGia >= DATEADD(WEEK, -1, GETDATE())) AS ThanhVienMoiTuanNay,
    
    -- Cảnh báo
    (SELECT COUNT(*) FROM MUON_TRA WHERE TrangThai = N'Quá hạn') AS SachQuaHan,
    (SELECT COUNT(*) FROM SACH WHERE SoLuong = 0) AS SachHetHang,
    (SELECT COUNT(*) FROM DAT_TRUOC WHERE TrangThai = N'Chờ xử lý' AND NgayHetHan < GETDATE()) AS DatTruocHetHan,
    
    -- Hiệu suất
    (SELECT AVG(CAST(DATEDIFF(DAY, NgayMuon, NgayThucTeTra) AS DECIMAL(5,2))) 
     FROM MUON_TRA WHERE NgayThucTeTra IS NOT NULL AND NgayMuon >= DATEADD(MONTH, -1, GETDATE())) AS SoNgayMuonTrungBinh,
    
    (SELECT CAST(COUNT(CASE WHEN NgayThucTeTra <= NgayHenTra THEN 1 END) * 100.0 / COUNT(*) AS DECIMAL(5,2))
     FROM MUON_TRA WHERE NgayThucTeTra IS NOT NULL AND NgayMuon >= DATEADD(MONTH, -1, GETDATE())) AS TyLeTraDungHan;
GO

-- Báo cáo xu hướng theo thời gian
CREATE OR ALTER VIEW V_XuHuongTheoThang
AS
SELECT 
    YEAR(mt.NgayMuon) as Nam,
    MONTH(mt.NgayMuon) as Thang,
    COUNT(*) as SoLanMuon,
    COUNT(DISTINCT mt.MaThe) as SoThanhVienThamGia,
    COUNT(DISTINCT mt.ISBN) as SoSachKhacNhau,
    AVG(CAST(DATEDIFF(DAY, mt.NgayMuon, ISNULL(mt.NgayThucTeTra, GETDATE())) AS DECIMAL(5,2))) as SoNgayMuonTrungBinh,
    SUM(CASE WHEN mt.NgayThucTeTra > mt.NgayHenTra THEN DATEDIFF(DAY, mt.NgayHenTra, mt.NgayThucTeTra) * 5000 ELSE 0 END) as TongTienPhat
FROM MUON_TRA mt
GROUP BY YEAR(mt.NgayMuon), MONTH(mt.NgayMuon);
GO