# 2. Thiết kế Lược đồ Thực thể - Mối quan hệ (ERD Design)

## Các thực thể (Entities)

### 1. SACH (Book)
- **Thuộc tính**:
  - ISBN (Primary Key) - Mã sách quốc tế
  - TenSach - Tên sách
  - NamXuatBan - Năm xuất bản
  - SoLuong - Số lượng hiện có
  - GiaTien - Giá tiền
  - MaNXB (Foreign Key) - Mã nhà xuất bản

### 2. THANH_VIEN (Member)
- **Thuộc tính**:
  - MaThe (Primary Key) - Mã thẻ thư viện
  - HoTen - Họ và tên
  - DiaChi - Địa chỉ
  - SoDienThoai - Số điện thoại
  - NgayThamGia - Ngày tham gia
  - LoaiThanhVien - Loại thành viên (SV/GV)

### 3. TAC_GIA (Author)
- **Thuộc tính**:
  - MaTacGia (Primary Key) - Mã tác giả
  - HoTen - Họ và tên
  - NamSinh - Năm sinh
  - QuocTich - Quốc tịch

### 4. NHA_XUAT_BAN (Publisher)
- **Thuộc tính**:
  - MaNXB (Primary Key) - Mã nhà xuất bản
  - TenNXB - Tên nhà xuất bản
  - DiaChi - Địa chỉ
  - SoDienThoai - Số điện thoại

### 5. THE_LOAI (Category)
- **Thuộc tính**:
  - MaTheLoai (Primary Key) - Mã thể loại
  - TenTheLoai - Tên thể loại
  - MoTa - Mô tả

## Các mối quan hệ (Relationships)

### 1. MUON_TRA (Borrow-Return)
- **Giữa**: THANH_VIEN và SACH
- **Loại**: M:N (Một thành viên có thể mượn nhiều sách, một sách có thể được mượn bởi nhiều thành viên theo thời gian)
- **Thuộc tính**:
  - NgayMuon - Ngày mượn
  - NgayHenTra - Ngày hẹn trả
  - NgayThucTeTra - Ngày thực tế trả
  - TrangThai - Trạng thái (Đang mượn/Đã trả)

### 2. VIET_SACH (Write)
- **Giữa**: TAC_GIA và SACH
- **Loại**: M:N (Một tác giả có thể viết nhiều sách, một sách có thể có nhiều tác giả)
- **Thuộc tính**:
  - VaiTro - Vai trò (Tác giả chính/Đồng tác giả)

### 3. THUOC_THE_LOAI (Belong to Category)
- **Giữa**: SACH và THE_LOAI
- **Loại**: M:N (Một sách có thể thuộc nhiều thể loại, một thể loại có nhiều sách)

### 4. XUAT_BAN (Publish)
- **Giữa**: NHA_XUAT_BAN và SACH
- **Loại**: 1:N (Một NXB xuất bản nhiều sách, một sách chỉ có một NXB)

## Ràng buộc toàn vẹn
1. **Ràng buộc thực thể**: Mỗi thực thể phải có khóa chính duy nhất
2. **Ràng buộc tham chiếu**: Khóa ngoại phải tham chiếu đến khóa chính hợp lệ
3. **Ràng buộc miền**: 
   - SoLuong >= 0
   - NgayThucTeTra >= NgayMuon (nếu có)
   - NamXuatBan <= năm hiện tại
4. **Ràng buộc nghiệp vụ**:
   - Mỗi sách phải có ít nhất một tác giả
   - Thành viên không được mượn quá số sách quy định