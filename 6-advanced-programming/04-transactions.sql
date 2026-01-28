-- =====================================================
-- TRANSACTIONS cho Hệ thống Quản lý Thư viện
-- Đảm bảo tính ACID (Atomicity, Consistency, Isolation, Durability)
-- =====================================================

USE QuanLyThuVien;
GO

-- =====================================================
-- 1. TRANSACTION MƯỢN NHIỀU SÁCH CÙNG LÚC
-- =====================================================

CREATE OR ALTER PROCEDURE SP_MuonNhieuSach
    @MaThe CHAR(15),
    @DanhSachISBN NVARCHAR(MAX), -- Danh sách ISBN cách nhau bởi dấu phẩy
    @SoNgayMuon INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ISBN VARCHAR(20);
    DECLARE @TongSoSach INT = 0;
    DECLARE @SoSachDangMuon INT;
    DECLARE @GioiHan INT;
    DECLARE @LoaiThanhVien NVARCHAR(20);
    
    BEGIN TRY
        BEGIN TRANSACTION MuonNhieuSach;
        
        -- Kiểm tra thành viên tồn tại
        IF NOT EXISTS (SELECT 1 FROM THANH_VIEN WHERE MaThe = @MaThe)
        BEGIN
            RAISERROR(N'Mã thẻ %s không tồn tại!', 16, 1, @MaThe);
            RETURN;
        END
        
        -- Lấy thông tin thành viên
        SELECT @LoaiThanhVien = LoaiThanhVien FROM THANH_VIEN WHERE MaThe = @MaThe;
        
        SET @GioiHan = CASE 
            WHEN @LoaiThanhVien = N'Sinh viên' THEN 3
            WHEN @LoaiThanhVien = N'Giảng viên' THEN 10
            WHEN @LoaiThanhVien = N'Cán bộ' THEN 5
            ELSE 2
        END;
        
        -- Đếm số sách đang mượn
        SELECT @SoSachDangMuon = COUNT(*)
        FROM MUON_TRA
        WHERE MaThe = @MaThe AND TrangThai IN (N'Đang mượn', N'Quá hạn');
        
        -- Kiểm tra có sách quá hạn không
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
        
        -- Tạo bảng tạm để lưu danh sách ISBN
        CREATE TABLE #TempISBN (ISBN VARCHAR(20));
        
        -- Tách chuỗi ISBN và chèn vào bảng tạm
        DECLARE @Pos INT = 1;
        DECLARE @NextPos INT;
        
        WHILE @Pos <= LEN(@DanhSachISBN)
        BEGIN
            SET @NextPos = CHARINDEX(',', @DanhSachISBN, @Pos);
            IF @NextPos = 0 SET @NextPos = LEN(@DanhSachISBN) + 1;
            
            SET @ISBN = LTRIM(RTRIM(SUBSTRING(@DanhSachISBN, @Pos, @NextPos - @Pos)));
            IF @ISBN != ''
            BEGIN
                INSERT INTO #TempISBN (ISBN) VALUES (@ISBN);
                SET @TongSoSach = @TongSoSach + 1;
            END
            
            SET @Pos = @NextPos + 1;
        END
        
        -- Kiểm tra tổng số sách có vượt giới hạn không
        IF @SoSachDangMuon + @TongSoSach > @GioiHan
        BEGIN
            RAISERROR(N'Tổng số sách sẽ vượt quá giới hạn (%d cuốn)!', 16, 1, @GioiHan);
            RETURN;
        END
        
        -- Kiểm tra tất cả sách có tồn tại và còn hàng không
        IF EXISTS (
            SELECT 1 FROM #TempISBN t
            LEFT JOIN SACH s ON t.ISBN = s.ISBN
            WHERE s.ISBN IS NULL OR s.SoLuong <= 0
        )
        BEGIN
            SELECT 
                t.ISBN,
                CASE 
                    WHEN s.ISBN IS NULL THEN N'Không tồn tại'
                    WHEN s.SoLuong <= 0 THEN N'Hết hàng'
                END AS LyDo
            FROM #TempISBN t
            LEFT JOIN SACH s ON t.ISBN = s.ISBN
            WHERE s.ISBN IS NULL OR s.SoLuong <= 0;
            
            RAISERROR(N'Có sách không thể mượn (xem kết quả trên)!', 16, 1);
            RETURN;
        END
        
        -- Thực hiện mượn tất cả sách
        DECLARE @NgayMuon DATE = GETDATE();
        DECLARE @NgayHenTra DATE = DATEADD(DAY, @SoNgayMuon, @NgayMuon);
        
        INSERT INTO MUON_TRA (MaThe, ISBN, NgayMuon, NgayHenTra, TrangThai)
        SELECT @MaThe, ISBN, @NgayMuon, @NgayHenTra, N'Đang mượn'
        FROM #TempISBN;
        
        -- Cập nhật số lượng sách (trigger sẽ tự động xử lý)
        
        COMMIT TRANSACTION MuonNhieuSach;
        
        -- Thông báo kết quả
        SELECT 
            N'Mượn nhiều sách thành công!' AS ThongBao,
            @MaThe AS MaThe,
            @TongSoSach AS SoSachMuon,
            @NgayMuon AS NgayMuon,
            @NgayHenTra AS NgayHenTra;
            
        -- Hiển thị danh sách sách đã mượn
        SELECT 
            s.ISBN,
            s.TenSach,
            @NgayMuon AS NgayMuon,
            @NgayHenTra AS NgayHenTra
        FROM #TempISBN t
        JOIN SACH s ON t.ISBN = s.ISBN;
        
        DROP TABLE #TempISBN;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION MuonNhieuSach;
            
        IF OBJECT_ID('tempdb..#TempISBN') IS NOT NULL
            DROP TABLE #TempISBN;
            
        SET @ErrorMessage = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- =====================================================
-- 2. TRANSACTION CHUYỂN SÁCH GIỮA CÁC KHO
-- =====================================================

CREATE OR ALTER PROCEDURE SP_ChuyenSachGiuaKho
    @ISBNNguon VARCHAR(20),
    @ISBNDich VARCHAR(20),
    @SoLuongChuyen INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ErrorMessage NVARCHAR(4000);
    
    BEGIN TRY
        BEGIN TRANSACTION ChuyenSach;
        
        -- Kiểm tra sách nguồn có đủ số lượng không
        IF NOT EXISTS (
            SELECT 1 FROM SACH 
            WHERE ISBN = @ISBNNguon AND SoLuong >= @SoLuongChuyen
        )
        BEGIN
            RAISERROR(N'Sách nguồn không đủ số lượng để chuyển!', 16, 1);
            RETURN;
        END
        
        -- Kiểm tra sách đích có tồn tại không
        IF NOT EXISTS (SELECT 1 FROM SACH WHERE ISBN = @ISBNDich)
        BEGIN
            RAISERROR(N'Sách đích không tồn tại!', 16, 1);
            RETURN;
        END
        
        -- Thực hiện chuyển (giảm ở nguồn, tăng ở đích)
        UPDATE SACH 
        SET SoLuong = SoLuong - @SoLuongChuyen
        WHERE ISBN = @ISBNNguon;
        
        UPDATE SACH 
        SET SoLuong = SoLuong + @SoLuongChuyen
        WHERE ISBN = @ISBNDich;
        
        -- Ghi log
        INSERT INTO AUDIT_LOG (TableName, Operation, RecordID, NewValues)
        VALUES ('SACH', 'TRANSFER', 
                CONCAT(@ISBNNguon, ' -> ', @ISBNDich),
                CONCAT('SoLuong: ', @SoLuongChuyen));
        
        COMMIT TRANSACTION ChuyenSach;
        
        SELECT 
            N'Chuyển sách thành công!' AS ThongBao,
            @ISBNNguon AS SachNguon,
            @ISBNDich AS SachDich,
            @SoLuongChuyen AS SoLuongChuyen;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION ChuyenSach;
            
        SET @ErrorMessage = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- =====================================================
-- 3. TRANSACTION XỬ LÝ TRẢ SÁCH VÀ TÍNH TIỀN PHẠT
-- =====================================================

CREATE OR ALTER PROCEDURE SP_XuLyTraSachVaTinhPhat
    @MaThe CHAR(15),
    @DanhSachISBN NVARCHAR(MAX) -- Danh sách ISBN cách nhau bởi dấu phẩy
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @TongTienPhat DECIMAL(10,2) = 0;
    DECLARE @SoSachTra INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION TraSachVaTinhPhat;
        
        -- Tạo bảng tạm
        CREATE TABLE #TempTraSach (
            ISBN VARCHAR(20),
            NgayMuon DATE,
            NgayHenTra DATE,
            SoNgayQuaHan INT,
            TienPhat DECIMAL(10,2)
        );
        
        -- Tách chuỗi ISBN
        DECLARE @Pos INT = 1;
        DECLARE @NextPos INT;
        DECLARE @ISBN VARCHAR(20);
        
        WHILE @Pos <= LEN(@DanhSachISBN)
        BEGIN
            SET @NextPos = CHARINDEX(',', @DanhSachISBN, @Pos);
            IF @NextPos = 0 SET @NextPos = LEN(@DanhSachISBN) + 1;
            
            SET @ISBN = LTRIM(RTRIM(SUBSTRING(@DanhSachISBN, @Pos, @NextPos - @Pos)));
            IF @ISBN != ''
            BEGIN
                -- Lấy thông tin phiếu mượn gần nhất chưa trả
                INSERT INTO #TempTraSach (ISBN, NgayMuon, NgayHenTra, SoNgayQuaHan, TienPhat)
                SELECT TOP 1
                    mt.ISBN,
                    mt.NgayMuon,
                    mt.NgayHenTra,
                    CASE 
                        WHEN GETDATE() > mt.NgayHenTra 
                        THEN DATEDIFF(DAY, mt.NgayHenTra, GETDATE())
                        ELSE 0
                    END,
                    CASE 
                        WHEN GETDATE() > mt.NgayHenTra 
                        THEN DATEDIFF(DAY, mt.NgayHenTra, GETDATE()) * 5000
                        ELSE 0
                    END
                FROM MUON_TRA mt
                WHERE mt.MaThe = @MaThe 
                    AND mt.ISBN = @ISBN
                    AND mt.TrangThai IN (N'Đang mượn', N'Quá hạn')
                    AND mt.NgayThucTeTra IS NULL
                ORDER BY mt.NgayMuon DESC;
            END
            
            SET @Pos = @NextPos + 1;
        END
        
        -- Kiểm tra có sách nào không tìm thấy phiếu mượn
        IF EXISTS (
            SELECT 1 FROM (
                SELECT value AS ISBN FROM STRING_SPLIT(@DanhSachISBN, ',')
                WHERE LTRIM(RTRIM(value)) != ''
            ) input
            WHERE input.ISBN NOT IN (SELECT ISBN FROM #TempTraSach)
        )
        BEGIN
            SELECT 
                input.ISBN,
                N'Không tìm thấy phiếu mượn' AS LyDo
            FROM (
                SELECT LTRIM(RTRIM(value)) AS ISBN FROM STRING_SPLIT(@DanhSachISBN, ',')
                WHERE LTRIM(RTRIM(value)) != ''
            ) input
            WHERE input.ISBN NOT IN (SELECT ISBN FROM #TempTraSach);
            
            RAISERROR(N'Có sách không thể trả (xem kết quả trên)!', 16, 1);
            RETURN;
        END
        
        -- Tính tổng tiền phạt
        SELECT @TongTienPhat = SUM(TienPhat), @SoSachTra = COUNT(*)
        FROM #TempTraSach;
        
        -- Cập nhật trạng thái trả sách
        UPDATE mt
        SET NgayThucTeTra = GETDATE(),
            TrangThai = N'Đã trả'
        FROM MUON_TRA mt
        INNER JOIN #TempTraSach t ON mt.ISBN = t.ISBN 
            AND mt.NgayMuon = t.NgayMuon
        WHERE mt.MaThe = @MaThe;
        
        -- Tăng số lượng sách (trigger sẽ tự động xử lý)
        
        -- Ghi log tiền phạt nếu có
        IF @TongTienPhat > 0
        BEGIN
            INSERT INTO AUDIT_LOG (TableName, Operation, RecordID, NewValues)
            VALUES ('MUON_TRA', 'FINE', @MaThe, 
                    CONCAT('TongTienPhat: ', @TongTienPhat, '; SoSach: ', @SoSachTra));
        END
        
        COMMIT TRANSACTION TraSachVaTinhPhat;
        
        -- Thông báo kết quả
        SELECT 
            N'Trả sách thành công!' AS ThongBao,
            @MaThe AS MaThe,
            @SoSachTra AS SoSachTra,
            @TongTienPhat AS TongTienPhat,
            GETDATE() AS NgayTra;
            
        -- Chi tiết từng sách
        SELECT 
            s.TenSach,
            t.NgayMuon,
            t.NgayHenTra,
            GETDATE() AS NgayTraThucTe,
            t.SoNgayQuaHan,
            t.TienPhat
        FROM #TempTraSach t
        JOIN SACH s ON t.ISBN = s.ISBN;
        
        DROP TABLE #TempTraSach;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION TraSachVaTinhPhat;
            
        IF OBJECT_ID('tempdb..#TempTraSach') IS NOT NULL
            DROP TABLE #TempTraSach;
            
        SET @ErrorMessage = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- =====================================================
-- 4. TRANSACTION ĐỒNG BỘ DỮ LIỆU ĐỊNH KỲ
-- =====================================================

CREATE OR ALTER PROCEDURE SP_DongBoDuLieuDinhKy
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @SoLuongCapNhat INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION DongBoDuLieu;
        
        -- 1. Cập nhật trạng thái quá hạn
        UPDATE MUON_TRA
        SET TrangThai = N'Quá hạn'
        WHERE TrangThai = N'Đang mượn'
            AND NgayHenTra < GETDATE()
            AND NgayThucTeTra IS NULL;
            
        SET @SoLuongCapNhat = @@ROWCOUNT;
        
        -- 2. Cập nhật thống kê sách phổ biến (tạo bảng thống kê nếu chưa có)
        IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'THONG_KE_SACH')
        BEGIN
            CREATE TABLE THONG_KE_SACH (
                ISBN VARCHAR(20) PRIMARY KEY,
                SoLanMuonThang INT DEFAULT 0,
                SoLanMuonTong INT DEFAULT 0,
                LanCapNhatCuoi DATETIME DEFAULT GETDATE()
            );
        END
        
        -- Cập nhật thống kê
        MERGE THONG_KE_SACH AS target
        USING (
            SELECT 
                s.ISBN,
                COUNT(CASE WHEN mt.NgayMuon >= DATEADD(MONTH, -1, GETDATE()) THEN 1 END) AS SoLanMuonThang,
                COUNT(mt.ISBN) AS SoLanMuonTong
            FROM SACH s
            LEFT JOIN MUON_TRA mt ON s.ISBN = mt.ISBN
            GROUP BY s.ISBN
        ) AS source ON target.ISBN = source.ISBN
        WHEN MATCHED THEN
            UPDATE SET 
                SoLanMuonThang = source.SoLanMuonThang,
                SoLanMuonTong = source.SoLanMuonTong,
                LanCapNhatCuoi = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT (ISBN, SoLanMuonThang, SoLanMuonTong)
            VALUES (source.ISBN, source.SoLanMuonThang, source.SoLanMuonTong);
        
        -- 3. Xóa log cũ (giữ lại 6 tháng)
        DELETE FROM AUDIT_LOG 
        WHERE ChangedDate < DATEADD(MONTH, -6, GETDATE());
        
        COMMIT TRANSACTION DongBoDuLieu;
        
        SELECT 
            N'Đồng bộ dữ liệu thành công!' AS ThongBao,
            @SoLuongCapNhat AS SoPhieuCapNhatQuaHan,
            GETDATE() AS ThoiGianThucHien;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION DongBoDuLieu;
            
        SET @ErrorMessage = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- =====================================================
-- 5. TEST CÁC TRANSACTION
-- =====================================================

PRINT N'=== TEST TRANSACTIONS ===';

-- Test mượn nhiều sách
PRINT N'Test 1: Mượn nhiều sách cùng lúc';
EXEC SP_MuonNhieuSach 
    @MaThe = 'GV2024001', 
    @DanhSachISBN = '978-8935244850,978-8935244867',
    @SoNgayMuon = 45;

-- Test trả nhiều sách và tính phạt
PRINT N'Test 2: Trả nhiều sách và tính tiền phạt';
EXEC SP_XuLyTraSachVaTinhPhat 
    @MaThe = 'GV2024001',
    @DanhSachISBN = '978-8935244850,978-8935244867';

-- Test đồng bộ dữ liệu
PRINT N'Test 3: Đồng bộ dữ liệu định kỳ';
EXEC SP_DongBoDuLieuDinhKy;

PRINT N'Hoàn thành test transactions!';
GO

-- =====================================================
-- 6. TẠO JOB TỰ ĐỘNG CHẠY ĐỒNG BỘ ĐỊNH KỲ
-- =====================================================

-- Tạo stored procedure để thiết lập job tự động
CREATE OR ALTER PROCEDURE SP_TaoJobDongBoDinhKy
AS
BEGIN
    PRINT N'Để tạo SQL Server Agent Job tự động, hãy chạy lệnh sau trong SQL Server Management Studio:';
    PRINT N'';
    PRINT N'USE msdb;';
    PRINT N'GO';
    PRINT N'';
    PRINT N'EXEC dbo.sp_add_job';
    PRINT N'    @job_name = N''DongBoDuLieuThuVien'';';
    PRINT N'';
    PRINT N'EXEC dbo.sp_add_jobstep';
    PRINT N'    @job_name = N''DongBoDuLieuThuVien'',';
    PRINT N'    @step_name = N''DongBoDuLieu'',';
    PRINT N'    @command = N''EXEC QuanLyThuVien.dbo.SP_DongBoDuLieuDinhKy'';';
    PRINT N'';
    PRINT N'EXEC dbo.sp_add_schedule';
    PRINT N'    @schedule_name = N''HangNgay'',';
    PRINT N'    @freq_type = 4,';
    PRINT N'    @freq_interval = 1,';
    PRINT N'    @active_start_time = 020000;';
    PRINT N'';
    PRINT N'EXEC dbo.sp_attach_schedule';
    PRINT N'    @job_name = N''DongBoDuLieuThuVien'',';
    PRINT N'    @schedule_name = N''HangNgay'';';
    PRINT N'';
    PRINT N'EXEC dbo.sp_add_jobserver';
    PRINT N'    @job_name = N''DongBoDuLieuThuVien'';';
END;
GO

PRINT N'Hoàn thành tạo tất cả transactions và procedures!';
GO