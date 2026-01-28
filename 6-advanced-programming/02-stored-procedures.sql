-- =====================================================
-- STORED PROCEDURES cho Hệ thống Quản lý Thư viện
-- =====================================================

USE QuanLyThuVien;
GO

-- =====================================================
-- 1. STORED PROCEDURE MƯỢN SÁCH
-- =====================================================

CREATE OR ALTER PROCEDURE SP_MuonSach
    @MaThe CHAR(15),
    @ISBN VARCHAR(20),
    @SoNgayMuon INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Kiểm tra thành viên tồn tại
        IF NOT EXISTS (SELECT 1 FROM THANH_VIEN WHERE MaThe = @MaThe)
        BEGIN
            RAISERROR(N'Mã thẻ %s không tồn tại!', 16, 1, @MaThe);
            RETURN;
        END
        
        -- Kiểm tra sách tồn tại và còn trong kho
        IF NOT EXISTS (SELECT 1 FROM SACH WHERE ISBN = @ISBN AND SoLuong > 0)
        BEGIN
            RAISERROR(N'Sách ISBN %s không tồn tại hoặc đã hết!', 16, 1, @ISBN);
            RETURN;
        END
        
        -- Kiểm tra thành viên có sách quá hạn không
        IF EXISTS (
            SELECT 1 FROM MUON_TRA 
            WHERE MaThe = @MaThe 
                AND TrangThai IN (N'Quá hạn', N'Đang mượn')
                AND NgayHenTra < GETDATE()
                AND NgayThucTeTra IS NULL
        )
        BEGIN
            RAISERROR(N'Thành viên có sách quá hạn, không được mượn thêm!', 16, 1);
            RETURN;
        END
        
        -- Kiểm tra giới hạn mượn sách
        DECLARE @SoSachDangMuon INT, @LoaiThanhVien NVARCHAR(20), @GioiHan INT;
        
        SELECT @LoaiThanhVien = LoaiThanhVien FROM THANH_VIEN WHERE MaThe = @MaThe;
        
        SET @GioiHan = CASE 
            WHEN @LoaiThanhVien = N'Sinh viên' THEN 3
            WHEN @LoaiThanhVien = N'Giảng viên' THEN 10
            WHEN @LoaiThanhVien = N'Cán bộ' THEN 5
            ELSE 2
        END;
        
        SELECT @SoSachDangMuon = COUNT(*)
        FROM MUON_TRA
        WHERE MaThe = @MaThe AND TrangThai IN (N'Đang mượn', N'Quá hạn');
        
        IF @SoSachDangMuon >= @GioiHan
        BEGIN
            RAISERROR(N'Đã đạt giới hạn mượn sách (%d cuốn)!', 16, 1, @GioiHan);
            RETURN;
        END
        
        -- Thực hiện mượn sách
        DECLARE @NgayMuon DATE = GETDATE();
        DECLARE @NgayHenTra DATE = DATEADD(DAY, @SoNgayMuon, @NgayMuon);
        
        INSERT INTO MUON_TRA (MaThe, ISBN, NgayMuon, NgayHenTra, TrangThai)
        VALUES (@MaThe, @ISBN, @NgayMuon, @NgayHenTra, N'Đang mượn');
        
        COMMIT TRANSACTION;
        
        -- Thông báo thành công
        SELECT 
            N'Mượn sách thành công!' AS ThongBao,
            @MaThe AS MaThe,
            @ISBN AS ISBN,
            @NgayMuon AS NgayMuon,
            @NgayHenTra AS NgayHenTra;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- =====================================================
-- 2. STORED PROCEDURE TRẢ SÁCH
-- =====================================================

CREATE OR ALTER PROCEDURE SP_TraSach
    @MaThe CHAR(15),
    @ISBN VARCHAR(20),
    @NgayMuon DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Nếu không chỉ định ngày mượn, lấy lần mượn gần nhất chưa trả
        IF @NgayMuon IS NULL
        BEGIN
            SELECT TOP 1 @NgayMuon = NgayMuon
            FROM MUON_TRA
            WHERE MaThe = @MaThe 
                AND ISBN = @ISBN 
                AND TrangThai IN (N'Đang mượn', N'Quá hạn')
                AND NgayThucTeTra IS NULL
            ORDER BY NgayMuon DESC;
        END
        
        -- Kiểm tra phiếu mượn tồn tại
        IF NOT EXISTS (
            SELECT 1 FROM MUON_TRA 
            WHERE MaThe = @MaThe 
                AND ISBN = @ISBN 
                AND NgayMuon = @NgayMuon
                AND NgayThucTeTra IS NULL
        )
        BEGIN
            RAISERROR(N'Không tìm thấy phiếu mượn phù hợp!', 16, 1);
            RETURN;
        END
        
        -- Cập nhật thông tin trả sách
        DECLARE @NgayTraThucTe DATE = GETDATE();
        DECLARE @NgayHenTra DATE;
        DECLARE @TienPhat DECIMAL(10,2) = 0;
        
        SELECT @NgayHenTra = NgayHenTra FROM MUON_TRA 
        WHERE MaThe = @MaThe AND ISBN = @ISBN AND NgayMuon = @NgayMuon;
        
        -- Tính tiền phạt nếu trả muộn (5000đ/ngày)
        IF @NgayTraThucTe > @NgayHenTra
        BEGIN
            SET @TienPhat = DATEDIFF(DAY, @NgayHenTra, @NgayTraThucTe) * 5000;
        END
        
        UPDATE MUON_TRA
        SET NgayThucTeTra = @NgayTraThucTe,
            TrangThai = N'Đã trả'
        WHERE MaThe = @MaThe 
            AND ISBN = @ISBN 
            AND NgayMuon = @NgayMuon;
        
        COMMIT TRANSACTION;
        
        -- Thông báo kết quả
        SELECT 
            N'Trả sách thành công!' AS ThongBao,
            @MaThe AS MaThe,
            @ISBN AS ISBN,
            @NgayMuon AS NgayMuon,
            @NgayTraThucTe AS NgayTraThucTe,
            CASE 
                WHEN @TienPhat > 0 THEN CONCAT(N'Trả muộn ', DATEDIFF(DAY, @NgayHenTra, @NgayTraThucTe), N' ngày')
                ELSE N'Trả đúng hạn'
            END AS TinhTrang,
            @TienPhat AS TienPhat;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- =====================================================
-- 3. STORED PROCEDURE GIA HẠN SÁCH
-- =====================================================

CREATE OR ALTER PROCEDURE SP_GiaHanSach
    @MaThe CHAR(15),
    @ISBN VARCHAR(20),
    @SoNgayGiaHan INT = 15
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Kiểm tra phiếu mượn hợp lệ
        IF NOT EXISTS (
            SELECT 1 FROM MUON_TRA 
            WHERE MaThe = @MaThe 
                AND ISBN = @ISBN 
                AND TrangThai = N'Đang mượn'
                AND NgayThucTeTra IS NULL
        )
        BEGIN
            RAISERROR(N'Không tìm thấy phiếu mượn hợp lệ để gia hạn!', 16, 1);
            RETURN;
        END
        
        -- Kiểm tra sách chưa quá hạn
        IF EXISTS (
            SELECT 1 FROM MUON_TRA 
            WHERE MaThe = @MaThe 
                AND ISBN = @ISBN 
                AND TrangThai = N'Đang mượn'
                AND NgayHenTra < GETDATE()
        )
        BEGIN
            RAISERROR(N'Không thể gia hạn sách đã quá hạn!', 16, 1);
            RETURN;
        END
        
        -- Thực hiện gia hạn
        UPDATE MUON_TRA
        SET NgayHenTra = DATEADD(DAY, @SoNgayGiaHan, NgayHenTra)
        WHERE MaThe = @MaThe 
            AND ISBN = @ISBN 
            AND TrangThai = N'Đang mượn'
            AND NgayThucTeTra IS NULL;
        
        -- Thông báo kết quả
        SELECT 
            N'Gia hạn thành công!' AS ThongBao,
            @MaThe AS MaThe,
            @ISBN AS ISBN,
            NgayHenTra AS NgayHenTraMoi,
            @SoNgayGiaHan AS SoNgayGiaHan
        FROM MUON_TRA
        WHERE MaThe = @MaThe AND ISBN = @ISBN AND TrangThai = N'Đang mượn';
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- =====================================================
-- 4. STORED PROCEDURE TÌM KIẾM SÁCH
-- =====================================================

CREATE OR ALTER PROCEDURE SP_TimKiemSach
    @TuKhoa NVARCHAR(200) = NULL,
    @MaTheLoai CHAR(10) = NULL,
    @MaTacGia CHAR(10) = NULL,
    @MaNXB CHAR(10) = NULL,
    @NamXuatBan INT = NULL,
    @ChiLaySachConHang BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT DISTINCT
        s.ISBN,
        s.TenSach,
        s.NamXuatBan,
        s.SoLuong,
        s.GiaTien,
        nxb.TenNXB,
        STRING_AGG(tg.HoTen, ', ') AS CacTacGia,
        STRING_AGG(tl.TenTheLoai, ', ') AS CacTheLoai
    FROM SACH s
    LEFT JOIN NHA_XUAT_BAN nxb ON s.MaNXB = nxb.MaNXB
    LEFT JOIN VIET_SACH vs ON s.ISBN = vs.ISBN
    LEFT JOIN TAC_GIA tg ON vs.MaTacGia = tg.MaTacGia
    LEFT JOIN THUOC_THE_LOAI ttl ON s.ISBN = ttl.ISBN
    LEFT JOIN THE_LOAI tl ON ttl.MaTheLoai = tl.MaTheLoai
    WHERE 1=1
        AND (@TuKhoa IS NULL OR s.TenSach LIKE N'%' + @TuKhoa + N'%' OR tg.HoTen LIKE N'%' + @TuKhoa + N'%')
        AND (@MaTheLoai IS NULL OR tl.MaTheLoai = @MaTheLoai)
        AND (@MaTacGia IS NULL OR tg.MaTacGia = @MaTacGia)
        AND (@MaNXB IS NULL OR s.MaNXB = @MaNXB)
        AND (@NamXuatBan IS NULL OR s.NamXuatBan = @NamXuatBan)
        AND (@ChiLaySachConHang = 0 OR s.SoLuong > 0)
    GROUP BY s.ISBN, s.TenSach, s.NamXuatBan, s.SoLuong, s.GiaTien, nxb.TenNXB
    ORDER BY s.TenSach;
END;
GO

-- =====================================================
-- 5. STORED PROCEDURE BÁO CÁO THỐNG KÊ
-- =====================================================

CREATE OR ALTER PROCEDURE SP_BaoCaoThongKe
    @LoaiBaoCao NVARCHAR(50),
    @TuNgay DATE = NULL,
    @DenNgay DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @TuNgay IS NULL SET @TuNgay = DATEADD(MONTH, -1, GETDATE());
    IF @DenNgay IS NULL SET @DenNgay = GETDATE();
    
    IF @LoaiBaoCao = N'SACH_DUOC_MUON_NHIEU'
    BEGIN
        SELECT TOP 10
            s.ISBN,
            s.TenSach,
            COUNT(*) AS SoLanMuon,
            s.SoLuong AS SoLuongHienCo
        FROM SACH s
        JOIN MUON_TRA mt ON s.ISBN = mt.ISBN
        WHERE mt.NgayMuon BETWEEN @TuNgay AND @DenNgay
        GROUP BY s.ISBN, s.TenSach, s.SoLuong
        ORDER BY SoLanMuon DESC;
    END
    
    ELSE IF @LoaiBaoCao = N'THANH_VIEN_TICH_CUC'
    BEGIN
        SELECT TOP 10
            tv.MaThe,
            tv.HoTen,
            tv.LoaiThanhVien,
            COUNT(*) AS SoLanMuon
        FROM THANH_VIEN tv
        JOIN MUON_TRA mt ON tv.MaThe = mt.MaThe
        WHERE mt.NgayMuon BETWEEN @TuNgay AND @DenNgay
        GROUP BY tv.MaThe, tv.HoTen, tv.LoaiThanhVien
        ORDER BY SoLanMuon DESC;
    END
    
    ELSE IF @LoaiBaoCao = N'SACH_QUA_HAN'
    BEGIN
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
    END
    
    ELSE
    BEGIN
        RAISERROR(N'Loại báo cáo không hợp lệ!', 16, 1);
    END
END;
GO

-- =====================================================
-- 6. TEST CÁC STORED PROCEDURE
-- =====================================================

PRINT N'=== TEST STORED PROCEDURES ===';

-- Test mượn sách
PRINT N'Test 1: Mượn sách';
EXEC SP_MuonSach @MaThe = 'SV2024002', @ISBN = '978-0134685991', @SoNgayMuon = 30;

-- Test tìm kiếm sách
PRINT N'Test 2: Tìm kiếm sách';
EXEC SP_TimKiemSach @TuKhoa = N'Clean', @ChiLaySachConHang = 1;

-- Test báo cáo
PRINT N'Test 3: Báo cáo sách được mượn nhiều';
EXEC SP_BaoCaoThongKe @LoaiBaoCao = N'SACH_DUOC_MUON_NHIEU';

PRINT N'Hoàn thành test stored procedures!';
GO