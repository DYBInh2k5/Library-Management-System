-- =====================================================
-- Chèn dữ liệu mẫu vào hệ thống Quản lý Thư viện
-- =====================================================

USE QuanLyThuVien;
GO

-- =====================================================
-- 1. CHÈN DỮ LIỆU VÀO CÁC BẢNG CHỦ
-- =====================================================

-- Nhà xuất bản
INSERT INTO NHA_XUAT_BAN (MaNXB, TenNXB, DiaChi, SoDienThoai) VALUES
('NXB001', N'Nhà xuất bản Giáo dục Việt Nam', N'81 Trần Hưng Đạo, Hoàn Kiếm, Hà Nội', '024-3822-5568'),
('NXB002', N'Nhà xuất bản Trẻ', N'161B Lý Chính Thắng, Quận 3, TP.HCM', '028-3930-5209'),
('NXB003', N'Nhà xuất bản Thông tin và Truyền thông', N'18 Nguyễn Du, Hai Bà Trưng, Hà Nội', '024-3822-4031'),
('NXB004', N'Nhà xuất bản Lao động', N'175 Giảng Võ, Ba Đình, Hà Nội', '024-3851-3380'),
('NXB005', N'O''Reilly Media', N'1005 Gravenstein Highway North, Sebastopol, CA', '+1-707-827-7000');

-- Thể loại
INSERT INTO THE_LOAI (MaTheLoai, TenTheLoai, MoTa) VALUES
('TL001', N'Công nghệ thông tin', N'Sách về lập trình, phần mềm, mạng máy tính'),
('TL002', N'Văn học', N'Tiểu thuyết, thơ ca, truyện ngắn'),
('TL003', N'Khoa học tự nhiên', N'Toán học, Vật lý, Hóa học, Sinh học'),
('TL004', N'Kinh tế', N'Quản trị kinh doanh, Tài chính, Marketing'),
('TL005', N'Giáo dục', N'Sách giáo khoa, tài liệu học tập'),
('TL006', N'Lịch sử', N'Lịch sử Việt Nam và thế giới'),
('TL007', N'Ngoại ngữ', N'Tiếng Anh, Tiếng Nhật, Tiếng Trung');

-- Tác giả
INSERT INTO TAC_GIA (MaTacGia, HoTen, NamSinh, QuocTich) VALUES
('TG001', N'Nguyễn Văn A', 1975, N'Việt Nam'),
('TG002', N'Trần Thị B', 1980, N'Việt Nam'),
('TG003', N'Robert C. Martin', 1952, N'Mỹ'),
('TG004', N'Martin Fowler', 1963, N'Anh'),
('TG005', N'Nguyễn Du', 1765, N'Việt Nam'),
('TG006', N'Tô Hoài', 1920, N'Việt Nam'),
('TG007', N'Eric Evans', 1962, N'Mỹ'),
('TG008', N'Gang of Four', 1960, N'Quốc tế');

-- Thành viên
INSERT INTO THANH_VIEN (MaThe, HoTen, DiaChi, SoDienThoai, NgayThamGia, LoaiThanhVien) VALUES
('SV2024001', N'Lê Văn Nam', N'123 Nguyễn Trãi, Thanh Xuân, Hà Nội', '0987654321', '2024-01-15', N'Sinh viên'),
('SV2024002', N'Phạm Thị Lan', N'456 Lê Lợi, Quận 1, TP.HCM', '0976543210', '2024-02-20', N'Sinh viên'),
('GV2024001', N'TS. Hoàng Minh Tuấn', N'789 Giải Phóng, Hai Bà Trưng, Hà Nội', '0965432109', '2024-01-10', N'Giảng viên'),
('CB2024001', N'Nguyễn Thị Hoa', N'321 Cầu Giấy, Cầu Giấy, Hà Nội', '0954321098', '2024-03-01', N'Cán bộ'),
('SV2024003', N'Đỗ Văn Hùng', N'654 Trường Chinh, Đống Đa, Hà Nội', '0943210987', '2024-03-15', N'Sinh viên');

-- Sách
INSERT INTO SACH (ISBN, TenSach, NamXuatBan, SoLuong, GiaTien, MaNXB) VALUES
('978-0134685991', N'Clean Code: A Handbook of Agile Software Craftsmanship', 2008, 5, 450000, 'NXB005'),
('978-0201633610', N'Design Patterns: Elements of Reusable Object-Oriented Software', 1994, 3, 520000, 'NXB005'),
('978-0321125215', N'Domain-Driven Design: Tackling Complexity in the Heart of Software', 2003, 4, 480000, 'NXB005'),
('978-8935244829', N'Truyện Kiều', 1820, 10, 150000, 'NXB001'),
('978-8935244836', N'Dế Mèn phiêu lưu ký', 1941, 8, 120000, 'NXB002'),
('978-8935244843', N'Cấu trúc dữ liệu và giải thuật', 2020, 6, 280000, 'NXB003'),
('978-8935244850', N'Lập trình Java cơ bản', 2021, 7, 320000, 'NXB003'),
('978-8935244867', N'Quản trị cơ sở dữ liệu', 2022, 5, 350000, 'NXB004');

-- =====================================================
-- 2. CHÈN DỮ LIỆU VÀO CÁC BẢNG QUAN HỆ
-- =====================================================

-- Viết sách (Tác giả - Sách)
INSERT INTO VIET_SACH (MaTacGia, ISBN, VaiTro) VALUES
('TG003', '978-0134685991', N'Tác giả chính'),
('TG008', '978-0201633610', N'Tác giả chính'),
('TG007', '978-0321125215', N'Tác giả chính'),
('TG005', '978-8935244829', N'Tác giả chính'),
('TG006', '978-8935244836', N'Tác giả chính'),
('TG001', '978-8935244843', N'Tác giả chính'),
('TG002', '978-8935244843', N'Đồng tác giả'),
('TG001', '978-8935244850', N'Tác giả chính'),
('TG002', '978-8935244867', N'Tác giả chính');

-- Thuộc thể loại (Sách - Thể loại)
INSERT INTO THUOC_THE_LOAI (ISBN, MaTheLoai) VALUES
('978-0134685991', 'TL001'),
('978-0201633610', 'TL001'),
('978-0321125215', 'TL001'),
('978-8935244829', 'TL002'),
('978-8935244836', 'TL002'),
('978-8935244843', 'TL001'),
('978-8935244843', 'TL003'),
('978-8935244850', 'TL001'),
('978-8935244867', 'TL001');

-- Mượn trả
INSERT INTO MUON_TRA (MaThe, ISBN, NgayMuon, NgayHenTra, NgayThucTeTra, TrangThai) VALUES
-- Đã trả
('SV2024001', '978-0134685991', '2024-01-20', '2024-02-20', '2024-02-18', N'Đã trả'),
('SV2024002', '978-8935244829', '2024-02-25', '2024-03-25', '2024-03-20', N'Đã trả'),
-- Đang mượn
('GV2024001', '978-0201633610', '2024-03-01', '2024-04-01', NULL, N'Đang mượn'),
('SV2024003', '978-8935244850', '2024-03-10', '2024-04-10', NULL, N'Đang mượn'),
('CB2024001', '978-8935244867', '2024-03-15', '2024-04-15', NULL, N'Đang mượn'),
-- Quá hạn
('SV2024001', '978-8935244843', '2024-02-01', '2024-03-01', NULL, N'Quá hạn'),
('SV2024002', '978-0321125215', '2024-02-15', '2024-03-15', NULL, N'Quá hạn');

PRINT 'Chèn dữ liệu mẫu thành công!';

-- =====================================================
-- 3. KIỂM TRA DỮ LIỆU VỪa CHÈN
-- =====================================================

PRINT 'Thống kê dữ liệu trong hệ thống:';
SELECT 'Nhà xuất bản' as BangDuLieu, COUNT(*) as SoLuong FROM NHA_XUAT_BAN
UNION ALL
SELECT 'Thể loại', COUNT(*) FROM THE_LOAI
UNION ALL
SELECT 'Tác giả', COUNT(*) FROM TAC_GIA
UNION ALL
SELECT 'Thành viên', COUNT(*) FROM THANH_VIEN
UNION ALL
SELECT 'Sách', COUNT(*) FROM SACH
UNION ALL
SELECT 'Quan hệ Viết sách', COUNT(*) FROM VIET_SACH
UNION ALL
SELECT 'Quan hệ Thuộc thể loại', COUNT(*) FROM THUOC_THE_LOAI
UNION ALL
SELECT 'Giao dịch Mượn trả', COUNT(*) FROM MUON_TRA;