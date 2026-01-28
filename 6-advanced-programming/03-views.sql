-- =====================================================
-- VIEWS cho Hệ thống Quản lý Thư viện
-- =====================================================

USE QuanLyThuVien;
GO

-- =====================================================
-- 1. VIEW THÔNG TIN SÁCH CHI TIẾT
-- =====================================================

CREATE OR ALTER VIEW V_ThongTinSachChiTiet
AS
SELECT 
    s.ISBN,
    s.TenSach,
    s.NamXuatBan,
    s.SoLuong,
    s.GiaTien,
    nxb.TenNXB,
    nxb.DiaChi AS DiaChiNXB,
    STRING_AGG(CONCAT(tg.HoTen, ' (', vs.VaiTro, ')'), ', ') AS ThongTinTacGia,
    STRING_AGG(tl.TenTheLoai, ', ') AS CacTheLoai,
    CASE 
        WHEN s.SoLuong > 0 THEN N'Còn hàng'
        ELSE N'Hết hàng'
    END AS TinhTrangKho
FROM SACH s
LEFT JOIN NHA_XUAT_BAN nxb ON s.MaNXB = nxb.MaNXB
LEFT JOIN VIET_SACH vs ON s.ISBN = vs.ISBN
LEFT JOIN TAC_GIA tg ON vs.MaTacGia = tg.MaTacGia
LEFT JOIN THUOC_THE_LOAI ttl ON s.ISBN = ttl.ISBN
LEFT JOIN THE_LOAI tl ON ttl.MaTheLoai = tl.MaTheLoai
GROUP BY s.ISBN, s.TenSach, s.NamXuatBan, s.SoLuong, s.GiaTien, 
         nxb.TenNXB, nxb.DiaChi;
GO

-- =====================================================
-- 2. VIEW DANH SÁCH SÁCH ĐANG ĐƯỢC MƯỢN
-- =====================================================

CREATE OR ALTER VIEW V_SachDangDuocMuon
AS
SELECT 
    mt.MaThe,
    tv.HoTen AS TenThanhVien,
    tv.LoaiThanhVien,
    tv.SoDienThoai,
    s.ISBN,
    s.TenSach,
    mt.NgayMuon,
    mt.NgayHenTra,
    DATEDIFF(DAY, GETDATE(), mt.NgayHenTra) AS SoNgayConLai,
    CASE 
        WHEN mt.NgayHenTra < GETDATE() THEN N'Quá hạn'
        WHEN DATEDIFF(DAY, GETDATE(), mt.NgayHenTra) <= 3 THEN N'Sắp hết hạn'
        ELSE N'Bình thường'
    END AS TinhTrang,
    CASE 
        WHEN mt.NgayHenTra < GETDATE() THEN DATEDIFF(DAY, mt.NgayHenTra, GETDATE()) * 5000
        ELSE 0
    END AS TienPhatDuKien
FROM MUON_TRA mt
JOIN THANH_VIEN tv ON mt.MaThe = tv.MaThe
JOIN SACH s ON mt.ISBN = s.ISBN
WHERE mt.TrangThai IN (N'Đang mượn', N'Quá hạn')
    AND mt.NgayThucTeTra IS NULL;
GO

-- =====================================================
-- 3. VIEW THỐNG KÊ THÀNH VIÊN
-- =====================================================

CREATE OR ALTER VIEW V_ThongKeThanhVien
AS
SELECT 
    tv.MaThe,
    tv.HoTen,
    tv.LoaiThanhVien,
    tv.NgayThamGia,
    DATEDIFF(MONTH, tv.NgayThamGia, GETDATE()) AS SoThangThamGia,
    COUNT(mt.MaThe) AS TongSoLanMuon,
    COUNT(CASE WHEN mt.TrangThai = N'Đang mượn' THEN 1 END) AS SachDangMuon,
    COUNT(CASE WHEN mt.TrangThai = N'Đã trả' THEN 1 END) AS SachDaTra,
    COUNT(CASE WHEN mt.TrangThai = N'Quá hạn' THEN 1 END) AS SachQuaHan,
    CASE 
        WHEN tv.LoaiThanhVien = N'Sinh viên' THEN 3
        WHEN tv.LoaiThanhVien = N'Giảng viên' THEN 10
        WHEN tv.LoaiThanhVien = N'Cán bộ' THEN 5
        ELSE 2
    END AS GioiHanMuon,
    CASE 
        WHEN COUNT(CASE WHEN mt.TrangThai = N'Quá hạn' THEN 1 END) > 0 THEN N'Có sách quá hạn'
        WHEN COUNT(CASE WHEN mt.TrangThai = N'Đang mượn' THEN 1 END) >= 
             CASE 
                WHEN tv.LoaiThanhVien = N'Sinh viên' THEN 3
                WHEN tv.LoaiThanhVien = N'Giảng viên' THEN 10
                WHEN tv.LoaiThanhVien = N'Cán bộ' THEN 5
                ELSE 2
             END THEN N'Đã đạt giới hạn'
        ELSE N'Có thể mượn thêm'
    END AS TrangThaiMuon
FROM THANH_VIEN tv
LEFT JOIN MUON_TRA mt ON tv.MaThe = mt.MaThe
GROUP BY tv.MaThe, tv.HoTen, tv.LoaiThanhVien, tv.NgayThamGia;
GO

-- =====================================================
-- 4. VIEW THỐNG KÊ SÁCH PHỔ BIẾN
-- =====================================================

CREATE OR ALTER VIEW V_ThongKeSachPhoBien
AS
SELECT 
    s.ISBN,
    s.TenSach,
    s.NamXuatBan,
    s.SoLuong,
    nxb.TenNXB,
    COUNT(mt.ISBN) AS SoLanMuon,
    COUNT(CASE WHEN mt.TrangThai = N'Đang mượn' THEN 1 END) AS DangDuocMuon,
    COUNT(CASE WHEN mt.TrangThai = N'Đã trả' THEN 1 END) AS DaTra,
    COUNT(CASE WHEN mt.TrangThai = N'Quá hạn' THEN 1 END) AS QuaHan,
    CASE 
        WHEN COUNT(mt.ISBN) = 0 THEN N'Chưa được mượn'
        WHEN COUNT(mt.ISBN) >= 10 THEN N'Rất phổ biến'
        WHEN COUNT(mt.ISBN) >= 5 THEN N'Phổ biến'
        ELSE N'Ít được mượn'
    END AS MucDoPhoBien,
    CAST(COUNT(mt.ISBN) * 100.0 / NULLIF(s.SoLuong + COUNT(mt.ISBN), 0) AS DECIMAL(5,2)) AS TyLeSuDung
FROM SACH s
LEFT JOIN MUON_TRA mt ON s.ISBN = mt.ISBN
LEFT JOIN NHA_XUAT_BAN nxb ON s.MaNXB = nxb.MaNXB
GROUP BY s.ISBN, s.TenSach, s.NamXuatBan, s.SoLuong, nxb.TenNXB;
GO

-- =====================================================
-- 5. VIEW BÁO CÁO TÀI CHÍNH
-- =====================================================

CREATE OR ALTER VIEW V_BaoCaoTaiChinh
AS
SELECT 
    YEAR(mt.NgayMuon) AS Nam,
    MONTH(mt.NgayMuon) AS Thang,
    COUNT(*) AS SoLanMuon,
    COUNT(DISTINCT mt.MaThe) AS SoThanhVienMuon,
    COUNT(DISTINCT mt.ISBN) AS SoSachKhacNhauDuocMuon,
    SUM(CASE 
        WHEN mt.NgayThucTeTra > mt.NgayHenTra 
        THEN DATEDIFF(DAY, mt.NgayHenTra, mt.NgayThucTeTra) * 5000
        ELSE 0 
    END) AS TongTienPhat,
    AVG(DATEDIFF(DAY, mt.NgayMuon, ISNULL(mt.NgayThucTeTra, GETDATE()))) AS SoNgayMuonTrungBinh
FROM MUON_TRA mt
GROUP BY YEAR(mt.NgayMuon), MONTH(mt.NgayMuon);
GO

-- =====================================================
-- 6. VIEW DANH SÁCH SÁCH CẦN MUA THÊM
-- =====================================================

CREATE OR ALTER VIEW V_SachCanMuaThem
AS
SELECT 
    s.ISBN,
    s.TenSach,
    s.SoLuong AS SoLuongHienTai,
    COUNT(mt.ISBN) AS SoLanMuonTrongThang,
    COUNT(CASE WHEN mt.TrangThai = N'Đang mượn' THEN 1 END) AS DangDuocMuon,
    CASE 
        WHEN s.SoLuong = 0 THEN N'Hết hàng - Cần mua ngay'
        WHEN s.SoLuong <= 2 AND COUNT(mt.ISBN) >= 3 THEN N'Sắp hết - Nên mua thêm'
        WHEN COUNT(CASE WHEN mt.TrangThai = N'Đang mượn' THEN 1 END) >= s.SoLuong * 0.8 
        THEN N'Nhu cầu cao - Cân nhắc mua thêm'
        ELSE N'Đủ dùng'
    END AS DeXuat,
    CASE 
        WHEN s.SoLuong = 0 THEN 5
        WHEN s.SoLuong <= 2 AND COUNT(mt.ISBN) >= 3 THEN 3
        ELSE CEILING(COUNT(mt.ISBN) / 3.0)
    END AS SoLuongDeXuatMua
FROM SACH s
LEFT JOIN MUON_TRA mt ON s.ISBN = mt.ISBN 
    AND mt.NgayMuon >= DATEADD(MONTH, -1, GETDATE())
GROUP BY s.ISBN, s.TenSach, s.SoLuong
HAVING s.SoLuong <= 2 OR COUNT(mt.ISBN) >= 3;
GO

-- =====================================================
-- 7. VIEW DASHBOARD TỔNG QUAN
-- =====================================================

CREATE OR ALTER VIEW V_DashboardTongQuan
AS
SELECT 
    (SELECT COUNT(*) FROM SACH) AS TongSoSach,
    (SELECT SUM(SoLuong) FROM SACH) AS TongSoLuongSach,
    (SELECT COUNT(*) FROM THANH_VIEN) AS TongSoThanhVien,
    (SELECT COUNT(*) FROM MUON_TRA WHERE TrangThai = N'Đang mượn') AS SachDangMuon,
    (SELECT COUNT(*) FROM MUON_TRA WHERE TrangThai = N'Quá hạn') AS SachQuaHan,
    (SELECT COUNT(*) FROM MUON_TRA WHERE NgayMuon = CAST(GETDATE() AS DATE)) AS MuonHomNay,
    (SELECT COUNT(*) FROM MUON_TRA WHERE NgayThucTeTra = CAST(GETDATE() AS DATE)) AS TraHomNay,
    (SELECT COUNT(*) FROM SACH WHERE SoLuong = 0) AS SachHetHang,
    (SELECT COUNT(DISTINCT MaThe) FROM MUON_TRA WHERE NgayMuon >= DATEADD(MONTH, -1, GETDATE())) AS ThanhVienHoatDongThangNay;
GO

-- =====================================================
-- 8. TEST CÁC VIEW
-- =====================================================

PRINT N'=== TEST VIEWS ===';

-- Test view thông tin sách chi tiết
PRINT N'Test 1: Thông tin sách chi tiết';
SELECT TOP 3 * FROM V_ThongTinSachChiTiet;

-- Test view sách đang được mượn
PRINT N'Test 2: Sách đang được mượn';
SELECT * FROM V_SachDangDuocMuon;

-- Test view thống kê thành viên
PRINT N'Test 3: Thống kê thành viên';
SELECT TOP 3 * FROM V_ThongKeThanhVien;

-- Test view dashboard tổng quan
PRINT N'Test 4: Dashboard tổng quan';
SELECT * FROM V_DashboardTongQuan;

-- Test view sách phổ biến
PRINT N'Test 5: Thống kê sách phổ biến';
SELECT TOP 3 * FROM V_ThongKeSachPhoBien ORDER BY SoLanMuon DESC;

PRINT N'Hoàn thành test views!';
GO

-- =====================================================
-- 9. TẠO CÁC VIEW SECURITY (CHỈ ĐỌC)
-- =====================================================

-- View cho thành viên chỉ xem thông tin của mình
CREATE OR ALTER VIEW V_ThongTinCaNhan
AS
SELECT 
    tv.MaThe,
    tv.HoTen,
    tv.DiaChi,
    tv.SoDienThoai,
    tv.NgayThamGia,
    tv.LoaiThanhVien,
    COUNT(mt.MaThe) AS TongSoLanMuon,
    COUNT(CASE WHEN mt.TrangThai = N'Đang mượn' THEN 1 END) AS SachDangMuon,
    COUNT(CASE WHEN mt.TrangThai = N'Quá hạn' THEN 1 END) AS SachQuaHan
FROM THANH_VIEN tv
LEFT JOIN MUON_TRA mt ON tv.MaThe = mt.MaThe
WHERE tv.MaThe = SYSTEM_USER  -- Chỉ hiển thị thông tin của user hiện tại
GROUP BY tv.MaThe, tv.HoTen, tv.DiaChi, tv.SoDienThoai, tv.NgayThamGia, tv.LoaiThanhVien;
GO

PRINT N'Tạo tất cả views thành công!';
GO