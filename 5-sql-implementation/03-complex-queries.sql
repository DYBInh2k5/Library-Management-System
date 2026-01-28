-- =====================================================
-- Các truy vấn phức tạp cho Hệ thống Quản lý Thư viện
-- =====================================================

USE QuanLyThuVien;
GO

-- =====================================================
-- 1. TRUY VẤN THÔNG TIN SÁCH VÀ TÁC GIẢ
-- =====================================================

-- 1.1. Danh sách sách kèm thông tin tác giả và nhà xuất bản
SELECT 
    s.ISBN,
    s.TenSach,
    s.NamXuatBan,
    s.SoLuong,
    s.GiaTien,
    STRING_AGG(tg.HoTen, ', ') AS CacTacGia,
    nxb.TenNXB,
    STRING_AGG(tl.TenTheLoai, ', ') AS CacTheLoai
FROM SACH s
LEFT JOIN VIET_SACH vs ON s.ISBN = vs.ISBN
LEFT JOIN TAC_GIA tg ON vs.MaTacGia = tg.MaTacGia
LEFT JOIN NHA_XUAT_BAN nxb ON s.MaNXB = nxb.MaNXB
LEFT JOIN THUOC_THE_LOAI ttl ON s.ISBN = ttl.ISBN
LEFT JOIN THE_LOAI tl ON ttl.MaTheLoai = tl.MaTheLoai
GROUP BY s.ISBN, s.TenSach, s.NamXuatBan, s.SoLuong, s.GiaTien, nxb.TenNXB
ORDER BY s.TenSach;

-- 1.2. Tìm sách theo tên tác giả
SELECT DISTINCT
    s.ISBN,
    s.TenSach,
    tg.HoTen AS TacGia,
    vs.VaiTro
FROM SACH s
JOIN VIET_SACH vs ON s.ISBN = vs.ISBN
JOIN TAC_GIA tg ON vs.MaTacGia = tg.MaTacGia
WHERE tg.HoTen LIKE N'%Nguyễn%'
ORDER BY s.TenSach;

-- =====================================================
-- 2. TRUY VẤN THÔNG TIN MƯỢN TRẢ
-- =====================================================

-- 2.1. Danh sách thành viên đang mượn sách
SELECT 
    tv.MaThe,
    tv.HoTen,
    tv.LoaiThanhVien,
    s.TenSach,
    mt.NgayMuon,
    mt.NgayHenTra,
    DATEDIFF(DAY, mt.NgayHenTra, GETDATE()) AS SoNgayQuaHan
FROM THANH_VIEN tv
JOIN MUON_TRA mt ON tv.MaThe = mt.MaThe
JOIN SACH s ON mt.ISBN = s.ISBN
WHERE mt.TrangThai = N'Đang mượn'
ORDER BY mt.NgayMuon DESC;

-- 2.2. Danh sách sách quá hạn chưa trả
SELECT 
    tv.MaThe,
    tv.HoTen,
    tv.SoDienThoai,
    s.TenSach,
    mt.NgayMuon,
    mt.NgayHenTra,
    DATEDIFF(DAY, mt.NgayHenTra, GETDATE()) AS SoNgayQuaHan
FROM THANH_VIEN tv
JOIN MUON_TRA mt ON tv.MaThe = mt.MaThe
JOIN SACH s ON mt.ISBN = s.ISBN
WHERE mt.TrangThai IN (N'Quá hạn', N'Đang mượn') 
    AND mt.NgayHenTra < GETDATE()
    AND mt.NgayThucTeTra IS NULL
ORDER BY SoNgayQuaHan DESC;

-- 2.3. Thống kê số lượng sách mượn theo thành viên
SELECT 
    tv.MaThe,
    tv.HoTen,
    tv.LoaiThanhVien,
    COUNT(CASE WHEN mt.TrangThai = N'Đang mượn' THEN 1 END) AS SachDangMuon,
    COUNT(CASE WHEN mt.TrangThai = N'Đã trả' THEN 1 END) AS SachDaTra,
    COUNT(CASE WHEN mt.TrangThai = N'Quá hạn' THEN 1 END) AS SachQuaHan,
    COUNT(*) AS TongSoLanMuon
FROM THANH_VIEN tv
LEFT JOIN MUON_TRA mt ON tv.MaThe = mt.MaThe
GROUP BY tv.MaThe, tv.HoTen, tv.LoaiThanhVien
ORDER BY TongSoLanMuon DESC;

-- =====================================================
-- 3. TRUY VẤN THỐNG KÊ VÀ BÁO CÁO
-- =====================================================

-- 3.1. Top 5 sách được mượn nhiều nhất
SELECT TOP 5
    s.ISBN,
    s.TenSach,
    COUNT(*) AS SoLanMuon,
    s.SoLuong AS SoLuongHienCo
FROM SACH s
JOIN MUON_TRA mt ON s.ISBN = mt.ISBN
GROUP BY s.ISBN, s.TenSach, s.SoLuong
ORDER BY SoLanMuon DESC;

-- 3.2. Thống kê theo thể loại sách
SELECT 
    tl.TenTheLoai,
    COUNT(DISTINCT s.ISBN) AS SoLuongSach,
    SUM(s.SoLuong) AS TongSoLuong,
    COUNT(mt.ISBN) AS SoLanMuon
FROM THE_LOAI tl
LEFT JOIN THUOC_THE_LOAI ttl ON tl.MaTheLoai = ttl.MaTheLoai
LEFT JOIN SACH s ON ttl.ISBN = s.ISBN
LEFT JOIN MUON_TRA mt ON s.ISBN = mt.ISBN
GROUP BY tl.MaTheLoai, tl.TenTheLoai
ORDER BY SoLuongSach DESC;

-- 3.3. Thống kê theo nhà xuất bản
SELECT 
    nxb.TenNXB,
    COUNT(s.ISBN) AS SoLuongSach,
    SUM(s.SoLuong) AS TongSoLuong,
    AVG(s.GiaTien) AS GiaTrungBinh
FROM NHA_XUAT_BAN nxb
LEFT JOIN SACH s ON nxb.MaNXB = s.MaNXB
GROUP BY nxb.MaNXB, nxb.TenNXB
ORDER BY SoLuongSach DESC;

-- =====================================================
-- 4. TRUY VẤN NÂNG CAO VỚI SUBQUERY VÀ CTE
-- =====================================================

-- 4.1. Tìm thành viên mượn sách nhiều nhất
WITH ThongKeMuon AS (
    SELECT 
        tv.MaThe,
        tv.HoTen,
        COUNT(*) AS SoLanMuon
    FROM THANH_VIEN tv
    JOIN MUON_TRA mt ON tv.MaThe = mt.MaThe
    GROUP BY tv.MaThe, tv.HoTen
)
SELECT * FROM ThongKeMuon
WHERE SoLanMuon = (SELECT MAX(SoLanMuon) FROM ThongKeMuon);

-- 4.2. Tìm sách chưa được mượn lần nào
SELECT 
    s.ISBN,
    s.TenSach,
    s.SoLuong
FROM SACH s
WHERE s.ISBN NOT IN (
    SELECT DISTINCT ISBN 
    FROM MUON_TRA 
    WHERE ISBN IS NOT NULL
);

-- 4.3. Tìm thành viên có thể mượn thêm sách (không có sách quá hạn)
SELECT 
    tv.MaThe,
    tv.HoTen,
    tv.LoaiThanhVien
FROM THANH_VIEN tv
WHERE tv.MaThe NOT IN (
    SELECT DISTINCT MaThe
    FROM MUON_TRA
    WHERE TrangThai = N'Quá hạn'
        OR (TrangThai = N'Đang mượn' AND NgayHenTra < GETDATE())
);

-- =====================================================
-- 5. TRUY VẤN PHÂN TÍCH THEO THỜI GIAN
-- =====================================================

-- 5.1. Thống kê mượn sách theo tháng
SELECT 
    YEAR(NgayMuon) AS Nam,
    MONTH(NgayMuon) AS Thang,
    COUNT(*) AS SoLanMuon,
    COUNT(DISTINCT MaThe) AS SoThanhVienMuon
FROM MUON_TRA
GROUP BY YEAR(NgayMuon), MONTH(NgayMuon)
ORDER BY Nam DESC, Thang DESC;

-- 5.2. Tìm sách được mượn trong khoảng thời gian
DECLARE @TuNgay DATE = '2024-02-01';
DECLARE @DenNgay DATE = '2024-03-31';

SELECT 
    s.TenSach,
    COUNT(*) AS SoLanMuon,
    MIN(mt.NgayMuon) AS LanMuonDauTien,
    MAX(mt.NgayMuon) AS LanMuonCuoiCung
FROM SACH s
JOIN MUON_TRA mt ON s.ISBN = mt.ISBN
WHERE mt.NgayMuon BETWEEN @TuNgay AND @DenNgay
GROUP BY s.ISBN, s.TenSach
ORDER BY SoLanMuon DESC;