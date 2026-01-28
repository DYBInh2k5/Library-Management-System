# 4. Chuẩn hóa Cơ sở Dữ liệu (Database Normalization)

## Kiểm tra các dạng chuẩn cho từng bảng

### 4.1. Bảng SACH
**Lược đồ**: SACH(ISBN, TenSach, NamXuatBan, SoLuong, GiaTien, MaNXB)

#### Phân tích phụ thuộc hàm:
- ISBN → TenSach, NamXuatBan, SoLuong, GiaTien, MaNXB
- MaNXB → (thông tin NXB - đã tách riêng)

#### Kiểm tra dạng chuẩn:
- **1NF**: ✅ Tất cả thuộc tính đều nguyên tử
- **2NF**: ✅ Không có phụ thuộc từng phần (ISBN là khóa đơn)
- **3NF**: ✅ Không có phụ thuộc bắc cầu (MaNXB chỉ là khóa ngoại)
- **BCNF**: ✅ Mọi phụ thuộc hàm đều có vế trái là siêu khóa

### 4.2. Bảng THANH_VIEN
**Lược đồ**: THANH_VIEN(MaThe, HoTen, DiaChi, SoDienThoai, NgayThamGia, LoaiThanhVien)

#### Phân tích phụ thuộc hàm:
- MaThe → HoTen, DiaChi, SoDienThoai, NgayThamGia, LoaiThanhVien

#### Kiểm tra dạng chuẩn:
- **1NF**: ✅ Tất cả thuộc tính đều nguyên tử
- **2NF**: ✅ Không có phụ thuộc từng phần
- **3NF**: ✅ Không có phụ thuộc bắc cầu
- **BCNF**: ✅ Đạt BCNF

### 4.3. Bảng TAC_GIA
**Lược đồ**: TAC_GIA(MaTacGia, HoTen, NamSinh, QuocTich)

#### Phân tích phụ thuộc hàm:
- MaTacGia → HoTen, NamSinh, QuocTich

#### Kiểm tra dạng chuẩn:
- **1NF**: ✅ Đạt 1NF
- **2NF**: ✅ Đạt 2NF  
- **3NF**: ✅ Đạt 3NF
- **BCNF**: ✅ Đạt BCNF

### 4.4. Bảng NHA_XUAT_BAN
**Lược đồ**: NHA_XUAT_BAN(MaNXB, TenNXB, DiaChi, SoDienThoai)

#### Phân tích phụ thuộc hàm:
- MaNXB → TenNXB, DiaChi, SoDienThoai

#### Kiểm tra dạng chuẩn:
- **1NF**: ✅ Đạt 1NF
- **2NF**: ✅ Đạt 2NF
- **3NF**: ✅ Đạt 3NF  
- **BCNF**: ✅ Đạt BCNF

### 4.5. Bảng THE_LOAI
**Lược đồ**: THE_LOAI(MaTheLoai, TenTheLoai, MoTa)

#### Phân tích phụ thuộc hàm:
- MaTheLoai → TenTheLoai, MoTa

#### Kiểm tra dạng chuẩn:
- **1NF**: ✅ Đạt 1NF
- **2NF**: ✅ Đạt 2NF
- **3NF**: ✅ Đạt 3NF
- **BCNF**: ✅ Đạt BCNF

### 4.6. Bảng MUON_TRA
**Lược đồ**: MUON_TRA(MaThe, ISBN, NgayMuon, NgayHenTra, NgayThucTeTra, TrangThai)

#### Phân tích phụ thuộc hàm:
- (MaThe, ISBN, NgayMuon) → NgayHenTra, NgayThucTeTra, TrangThai

#### Kiểm tra dạng chuẩn:
- **1NF**: ✅ Đạt 1NF
- **2NF**: ✅ Không có phụ thuộc từng phần (khóa chính là khóa tổng hợp)
- **3NF**: ✅ Đạt 3NF
- **BCNF**: ✅ Đạt BCNF

### 4.7. Bảng VIET_SACH
**Lược đồ**: VIET_SACH(MaTacGia, ISBN, VaiTro)

#### Phân tích phụ thuộc hàm:
- (MaTacGia, ISBN) → VaiTro

#### Kiểm tra dạng chuẩn:
- **1NF**: ✅ Đạt 1NF
- **2NF**: ✅ Đạt 2NF
- **3NF**: ✅ Đạt 3NF
- **BCNF**: ✅ Đạt BCNF

### 4.8. Bảng THUOC_THE_LOAI
**Lược đồ**: THUOC_THE_LOAI(ISBN, MaTheLoai)

#### Phân tích phụ thuộc hàm:
- Không có phụ thuộc hàm nào khác ngoài khóa chính

#### Kiểm tra dạng chuẩn:
- **1NF**: ✅ Đạt 1NF
- **2NF**: ✅ Đạt 2NF
- **3NF**: ✅ Đạt 3NF
- **BCNF**: ✅ Đạt BCNF

## Kết luận chuẩn hóa

✅ **Tất cả các bảng đều đạt dạng chuẩn BCNF**

### Lợi ích đạt được:
1. **Loại bỏ dư thừa dữ liệu**: Mỗi thông tin chỉ lưu trữ một lần
2. **Tránh lỗi cập nhật**: Không có anomaly khi INSERT/UPDATE/DELETE
3. **Đảm bảo tính nhất quán**: Dữ liệu luôn đồng bộ
4. **Tối ưu không gian lưu trữ**: Giảm thiểu dung lượng cần thiết

### Các ràng buộc toàn vẹn cần thêm:
1. **Check constraints**: SoLuong >= 0, NamXuatBan <= YEAR(GETDATE())
2. **Foreign key constraints**: Đảm bảo tính tham chiếu
3. **Unique constraints**: Tránh trùng lặp dữ liệu quan trọng
4. **Not null constraints**: Đảm bảo dữ liệu bắt buộc