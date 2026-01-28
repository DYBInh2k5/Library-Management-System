-- =====================================================
-- HỆ THỐNG TÍCH HỢP API VÀ WEB SERVICE
-- =====================================================

USE QuanLyThuVien;
GO

-- =====================================================
-- 1. TẠO BẢNG API LOG VÀ CONFIGURATION
-- =====================================================

-- Bảng cấu hình API
CREATE TABLE API_CONFIG (
    MaConfig INT IDENTITY(1,1) PRIMARY KEY,
    TenAPI NVARCHAR(100) NOT NULL,
    URL NVARCHAR(500) NOT NULL,
    APIKey NVARCHAR(200),
    TrangThai BIT DEFAULT 1,
    MoTa NVARCHAR(300),
    NgayTao DATETIME DEFAULT GETDATE()
);

-- Bảng log API calls
CREATE TABLE API_LOG (
    MaLog INT IDENTITY(1,1) PRIMARY KEY,
    TenAPI NVARCHAR(100) NOT NULL,
    Endpoint NVARCHAR(300),
    Method NVARCHAR(10), -- GET, POST, PUT, DELETE
    RequestData NVARCHAR(MAX),
    ResponseData NVARCHAR(MAX),
    StatusCode INT,
    ThoiGianGoi DATETIME DEFAULT GETDATE(),
    ThoiGianPhanHoi DATETIME,
    TrangThai NVARCHAR(20), -- Success, Error, Timeout
    ErrorMessage NVARCHAR(500)
);

-- Bảng webhook subscriptions
CREATE TABLE WEBHOOK_SUBSCRIPTION (
    MaWebhook INT IDENTITY(1,1) PRIMARY KEY,
    TenSuKien NVARCHAR(100) NOT NULL, -- book_borrowed, book_returned, etc.
    URL NVARCHAR(500) NOT NULL,
    Secret NVARCHAR(100), -- Để verify webhook
    TrangThai BIT DEFAULT 1,
    NgayTao DATETIME DEFAULT GETDATE(),
    LanGuiCuoi DATETIME,
    SoLanThatBai INT DEFAULT 0
);

GO-- =====
================================================
-- 2. STORED PROCEDURE CHO API
-- =====================================================

-- API lấy thông tin sách (JSON format)
CREATE OR ALTER PROCEDURE SP_API_GetBookInfo
    @ISBN VARCHAR(20) = NULL,
    @Format NVARCHAR(10) = 'JSON'
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @Format = 'JSON'
    BEGIN
        SELECT 
            s.ISBN,
            s.TenSach as title,
            s.NamXuatBan as publishYear,
            s.SoLuong as availableQuantity,
            s.GiaTien as price,
            nxb.TenNXB as publisher,
            STRING_AGG(tg.HoTen, ', ') as authors,
            STRING_AGG(tl.TenTheLoai, ', ') as categories,
            CASE WHEN s.SoLuong > 0 THEN 'available' ELSE 'unavailable' END as status
        FROM SACH s
        LEFT JOIN NHA_XUAT_BAN nxb ON s.MaNXB = nxb.MaNXB
        LEFT JOIN VIET_SACH vs ON s.ISBN = vs.ISBN
        LEFT JOIN TAC_GIA tg ON vs.MaTacGia = tg.MaTacGia
        LEFT JOIN THUOC_THE_LOAI ttl ON s.ISBN = ttl.ISBN
        LEFT JOIN THE_LOAI tl ON ttl.MaTheLoai = tl.MaTheLoai
        WHERE (@ISBN IS NULL OR s.ISBN = @ISBN)
        GROUP BY s.ISBN, s.TenSach, s.NamXuatBan, s.SoLuong, s.GiaTien, nxb.TenNXB
        FOR JSON PATH;
    END
    ELSE
    BEGIN
        -- XML format
        SELECT 
            s.ISBN,
            s.TenSach,
            s.NamXuatBan,
            s.SoLuong,
            nxb.TenNXB
        FROM SACH s
        LEFT JOIN NHA_XUAT_BAN nxb ON s.MaNXB = nxb.MaNXB
        WHERE (@ISBN IS NULL OR s.ISBN = @ISBN)
        FOR XML PATH('Book'), ROOT('Books');
    END
END;
GO

-- API mượn sách qua web service
CREATE OR ALTER PROCEDURE SP_API_BorrowBook
    @MaThe CHAR(15),
    @ISBN VARCHAR(20),
    @SoNgayMuon INT = 30,
    @APIKey NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Result NVARCHAR(MAX);
    DECLARE @StatusCode INT = 200;
    DECLARE @Message NVARCHAR(500);
    
    BEGIN TRY
        -- Validate API Key (simplified)
        IF @APIKey IS NULL OR @APIKey != 'library_api_key_2024'
        BEGIN
            SET @StatusCode = 401;
            SET @Message = N'Unauthorized: Invalid API Key';
            GOTO ReturnResult;
        END
        
        -- Thực hiện mượn sách
        EXEC SP_MuonSach @MaThe = @MaThe, @ISBN = @ISBN, @SoNgayMuon = @SoNgayMuon;
        
        SET @Message = N'Book borrowed successfully';
        
        -- Trigger webhook nếu có
        EXEC SP_TriggerWebhook @SuKien = 'book_borrowed', @DuLieu = @MaThe;
        
    END TRY
    BEGIN CATCH
        SET @StatusCode = 400;
        SET @Message = ERROR_MESSAGE();
    END CATCH
    
    ReturnResult:
    SET @Result = (
        SELECT 
            @StatusCode as statusCode,
            @Message as message,
            GETDATE() as timestamp
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );
    
    SELECT @Result as APIResponse;
    
    -- Log API call
    INSERT INTO API_LOG (TenAPI, Endpoint, Method, RequestData, ResponseData, StatusCode, TrangThai)
    VALUES ('BorrowBook', '/api/borrow', 'POST', 
            CONCAT('MaThe:', @MaThe, ',ISBN:', @ISBN), 
            @Result, @StatusCode, 
            CASE WHEN @StatusCode = 200 THEN 'Success' ELSE 'Error' END);
END;
GO

-- Stored procedure để trigger webhook
CREATE OR ALTER PROCEDURE SP_TriggerWebhook
    @SuKien NVARCHAR(100),
    @DuLieu NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Lấy danh sách webhook cần gửi
    DECLARE webhook_cursor CURSOR FOR
    SELECT MaWebhook, URL, Secret
    FROM WEBHOOK_SUBSCRIPTION
    WHERE TenSuKien = @SuKien AND TrangThai = 1;
    
    DECLARE @MaWebhook INT, @URL NVARCHAR(500), @Secret NVARCHAR(100);
    
    OPEN webhook_cursor;
    FETCH NEXT FROM webhook_cursor INTO @MaWebhook, @URL, @Secret;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Trong thực tế, đây sẽ là HTTP request
        -- Hiện tại chỉ log lại
        INSERT INTO API_LOG (TenAPI, Endpoint, Method, RequestData, TrangThai)
        VALUES ('Webhook', @URL, 'POST', 
                CONCAT('Event:', @SuKien, ',Data:', @DuLieu), 
                'Queued');
        
        -- Cập nhật webhook subscription
        UPDATE WEBHOOK_SUBSCRIPTION
        SET LanGuiCuoi = GETDATE()
        WHERE MaWebhook = @MaWebhook;
        
        FETCH NEXT FROM webhook_cursor INTO @MaWebhook, @URL, @Secret;
    END
    
    CLOSE webhook_cursor;
    DEALLOCATE webhook_cursor;
END;
GO

-- =====================================================
-- 3. VIEW CHO API ENDPOINTS
-- =====================================================

-- View API statistics
CREATE OR ALTER VIEW V_API_Statistics
AS
SELECT 
    TenAPI,
    COUNT(*) as TotalCalls,
    COUNT(CASE WHEN TrangThai = 'Success' THEN 1 END) as SuccessfulCalls,
    COUNT(CASE WHEN TrangThai = 'Error' THEN 1 END) as ErrorCalls,
    AVG(DATEDIFF(MILLISECOND, ThoiGianGoi, ThoiGianPhanHoi)) as AvgResponseTime,
    MAX(ThoiGianGoi) as LastCallTime
FROM API_LOG
WHERE ThoiGianGoi >= DATEADD(DAY, -30, GETDATE())
GROUP BY TenAPI;
GO

-- =====================================================
-- 4. SAMPLE API CONFIGURATIONS
-- =====================================================

INSERT INTO API_CONFIG (TenAPI, URL, APIKey, MoTa) VALUES
('GoogleBooks', 'https://www.googleapis.com/books/v1/volumes', 'your_google_api_key', N'Tích hợp với Google Books API'),
('OpenLibrary', 'https://openlibrary.org/api/books', NULL, N'Tích hợp với Open Library'),
('EmailService', 'https://api.sendgrid.com/v3/mail/send', 'your_sendgrid_key', N'Gửi email thông báo'),
('SMSService', 'https://api.twilio.com/2010-04-01/Accounts/your_account/Messages.json', 'your_twilio_key', N'Gửi SMS thông báo');

-- Sample webhook subscriptions
INSERT INTO WEBHOOK_SUBSCRIPTION (TenSuKien, URL, Secret) VALUES
('book_borrowed', 'https://your-app.com/webhooks/book-borrowed', 'webhook_secret_123'),
('book_returned', 'https://your-app.com/webhooks/book-returned', 'webhook_secret_123'),
('book_overdue', 'https://your-app.com/webhooks/book-overdue', 'webhook_secret_123');

PRINT N'API Integration system created successfully!';
GO