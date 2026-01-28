-- =====================================================
-- Hệ thống Quản lý Thư viện (Library Management System)
-- Tạo cơ sở dữ liệu và các bảng
-- =====================================================

-- Tạo cơ sở dữ liệu
CREATE DATABASE QuanLyThuVien;
GO

USE QuanLyThuVien;
GO

-- =====================================================
-- 1. TẠO CÁC BẢNG CHỦ (MASTER TABLES)
-- =====================================================

-- Bảng Nhà xuất bản
CREATE TABLE NHA_XUAT_BAN (
    MaNXB CHAR(10) PRIMARY KEY,
    TenNXB NVARCHAR(100) NOT NULL,
    DiaChi NVARCHAR(200),
    SoDienThoai VARCHAR(15),
    CONSTRAINT UK_NXB_Ten UNIQUE (TenNXB)
);

-- Bảng Thể loại
CREATE TABLE THE_LOAI (
    MaTheLoai CHAR(10) PRIMARY KEY,
    TenTheLoai NVARCHAR(50) NOT NULL,
    MoTa NVARCHAR(200),
    CONSTRAINT UK_TheLoai_Ten UNIQUE (TenTheLoai)
);

-- Bảng Tác giả
CREATE TABLE TAC_GIA (
    MaTacGia CHAR(10) PRIMARY KEY,
    HoTen NVARCHAR(100) NOT NULL,
    NamSinh INT,
    QuocTich NVARCHAR(50),
    CONSTRAINT CK_TacGia_NamSinh CHECK (NamSinh BETWEEN 1800 AND YEAR(GETDATE()))
);

-- Bảng Thành viên
CREATE TABLE THANH_VIEN (
    MaThe CHAR(15) PRIMARY KEY,
    HoTen NVARCHAR(100) NOT NULL,
    DiaChi NVARCHAR(200),
    SoDienThoai VARCHAR(15),
    NgayThamGia DATE NOT NULL DEFAULT GETDATE(),
    LoaiThanhVien NVARCHAR(20) NOT NULL,
    CONSTRAINT CK_LoaiThanhVien CHECK (LoaiThanhVien IN (N'Sinh viên', N'Giảng viên', N'Cán bộ'))
);

-- Bảng Sách
CREATE TABLE SACH (
    ISBN VARCHAR(20) PRIMARY KEY,
    TenSach NVARCHAR(200) NOT NULL,
    NamXuatBan INT,
    SoLuong INT NOT NULL DEFAULT 0,
    GiaTien DECIMAL(10,2),
    MaNXB CHAR(10),
    CONSTRAINT FK_Sach_NXB FOREIGN KEY (MaNXB) REFERENCES NHA_XUAT_BAN(MaNXB),
    CONSTRAINT CK_Sach_NamXB CHECK (NamXuatBan BETWEEN 1800 AND YEAR(GETDATE())),
    CONSTRAINT CK_Sach_SoLuong CHECK (SoLuong >= 0),
    CONSTRAINT CK_Sach_GiaTien CHECK (GiaTien >= 0)
);

-- =====================================================
-- 2. TẠO CÁC BẢNG QUAN HỆ (RELATIONSHIP TABLES)
-- =====================================================

-- Bảng Viết sách (Tác giả - Sách)
CREATE TABLE VIET_SACH (
    MaTacGia CHAR(10),
    ISBN VARCHAR(20),
    VaiTro NVARCHAR(50) DEFAULT N'Tác giả',
    PRIMARY KEY (MaTacGia, ISBN),
    CONSTRAINT FK_VietSach_TacGia FOREIGN KEY (MaTacGia) REFERENCES TAC_GIA(MaTacGia),
    CONSTRAINT FK_VietSach_Sach FOREIGN KEY (ISBN) REFERENCES SACH(ISBN)
);

-- Bảng Thuộc thể loại (Sách - Thể loại)
CREATE TABLE THUOC_THE_LOAI (
    ISBN VARCHAR(20),
    MaTheLoai CHAR(10),
    PRIMARY KEY (ISBN, MaTheLoai),
    CONSTRAINT FK_ThuocTheLoai_Sach FOREIGN KEY (ISBN) REFERENCES SACH(ISBN),
    CONSTRAINT FK_ThuocTheLoai_TheLoai FOREIGN KEY (MaTheLoai) REFERENCES THE_LOAI(MaTheLoai)
);

-- Bảng Mượn trả
CREATE TABLE MUON_TRA (
    MaThe CHAR(15),
    ISBN VARCHAR(20),
    NgayMuon DATE,
    NgayHenTra DATE NOT NULL,
    NgayThucTeTra DATE,
    TrangThai NVARCHAR(20) NOT NULL DEFAULT N'Đang mượn',
    PRIMARY KEY (MaThe, ISBN, NgayMuon),
    CONSTRAINT FK_MuonTra_ThanhVien FOREIGN KEY (MaThe) REFERENCES THANH_VIEN(MaThe),
    CONSTRAINT FK_MuonTra_Sach FOREIGN KEY (ISBN) REFERENCES SACH(ISBN),
    CONSTRAINT CK_MuonTra_TrangThai CHECK (TrangThai IN (N'Đang mượn', N'Đã trả', N'Quá hạn')),
    CONSTRAINT CK_MuonTra_NgayHenTra CHECK (NgayHenTra >= NgayMuon),
    CONSTRAINT CK_MuonTra_NgayThucTeTra CHECK (NgayThucTeTra IS NULL OR NgayThucTeTra >= NgayMuon)
);

-- =====================================================
-- 3. TẠO CÁC INDEX ĐỂ TỐI ƯU HIỆU SUẤT
-- =====================================================

-- Index cho các truy vấn thường xuyên
CREATE INDEX IX_Sach_TenSach ON SACH(TenSach);
CREATE INDEX IX_ThanhVien_HoTen ON THANH_VIEN(HoTen);
CREATE INDEX IX_TacGia_HoTen ON TAC_GIA(HoTen);
CREATE INDEX IX_MuonTra_NgayMuon ON MUON_TRA(NgayMuon);
CREATE INDEX IX_MuonTra_TrangThai ON MUON_TRA(TrangThai);

PRINT 'Tạo cơ sở dữ liệu và các bảng thành công!';