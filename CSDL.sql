create View [dbo].[DanhSachChiNhanh]
As
Select TenCN = name,TenServer = subscriber_server
From dbo.sysmergepublications PUBS, dbo.sysmergesubscriptions SUBS
Where PUBS.pubid = SUBS.pubid and PUBS.publisher <> SUBS.subscriber_server


CREATE PROC [dbo].[KiemTraDangNhap]
@TENLOGIN NVARCHAR (50)
AS
DECLARE @TENUSER NVARCHAR(50)
SELECT @TENUSER=NAME FROM sys.sysusers WHERE sid = SUSER_SID(@TENLOGIN)
 SELECT USERNAME = @TENUSER, 
  TEN = (SELECT TenNV FROM NHANVIEN  WHERE MaNV = @TENUSER ),
   NAME
   FROM sys.sysusers 
   WHERE UID = (SELECT GROUPUID 
                 FROM SYS.SYSMEMBERS 
                   WHERE MEMBERUID= (SELECT UID FROM sys.sysusers 
                                      WHERE NAME=@TENUSER))
									  


go

Create trigger Add_Login on NhanVien for insert
	as
	begin
		begin transaction
		declare @TenTaiKhoan varchar(max)
		declare @matkhau varchar(max)
		set @TenTaiKhoan=(select MaNV from inserted)
		set @matkhau=(select MatKhau from inserted)
		--thêm login và user
		declare @SQLStringCreateLogin varchar(max)
		set @SQLStringCreateLogin= 'CREATE LOGIN ['+@TenTaiKhoan+'] WITH  PASSWORD = '''+@matkhau+''''+',DEFAULT_DATABASE=[QL_DT],
				DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION = ON, CHECK_POLICY = ON;'
		exec (@SQLStringCreateLogin)

		declare @SQLStringCreateUser varchar (max)
		set @SQLStringCreateUser =  'CREATE USER ['+@TenTaiKhoan+'] FOR LOGIN ['+@TenTaiKhoan+']'
		exec (@SQLStringCreateUser)


		if(@@ERROR <> 0 )
		begin
			RAISERROR (N'Có lỗi xảy ra khi tạo tài khoản !!!',16, 1)
			rollback transaction
			return
		end
			commit transaction
	end
GO

Create trigger PhanQuyen_User on NhanVien for insert as 
	begin
		
		declare @Username char(10)
		declare @Quyen char(10)
		set @Username=(select MaNV from inserted)
		set @Quyen=(select Quyen from inserted)
		IF @Quyen= 'QuanLyCuaHang' 
		BEGIN
			execute sp_addrolemember 'QuanLyCuaHang',@Username
			exec sp_addsrvrolemember @Username, 'sysadmin'
		END

		IF @Quyen= 'NhanVien'
		BEGIN 
			execute sp_addrolemember 'NhanVien',@Username
			exec sp_addsrvrolemember @Username, 'sysadmin'
		END
	end

go
Create trigger UpdateLogin on NhanVien for update
	as
	begin
		begin transaction

		--update login
		declare @TenTaiKhoan varchar(max)
		declare @matkhau varchar(max)
		set @TenTaiKhoan=(select MaNV from inserted)
		set @matkhau=(select MatKhau from inserted)
		declare @SQLStringCreateLogin varchar(max)
		set @SQLStringCreateLogin= ' alter LOGIN ['+@TenTaiKhoan+'] WITH  PASSWORD = '''+@matkhau+''''+''
		exec (@SQLStringCreateLogin)


		if(@@ERROR <> 0 )
		begin
			RAISERROR (N'Có lỗi xảy ra !!!',16, 1)
			rollback transaction
			return
			end
			commit transaction
end
Create trigger DeleteLogin on NhanVien after delete
	as
	begin
		begin transaction
		declare @TenTaiKhoan varchar(max)
		set @TenTaiKhoan=(select MaNV from deleted)
		--thêm login và user
		declare @SQLStringCreateUser varchar (max)
	 	set @SQLStringCreateUser =  'drop user ['+@TenTaiKhoan+']'
		exec (@SQLStringCreateUser)

		declare @SQLStringCreateLogin varchar (max)
		set @SQLStringCreateLogin =  'drop login ['+@TenTaiKhoan+']'
		exec (@SQLStringCreateLogin)


		if(@@ERROR <> 0 )
		begin
			RAISERROR (N'Có lỗi xảy ra khi xóa tài khoản !!!',16, 1)
			rollback transaction
			return
		end
			commit transaction
	end
GO

create procedure LoadNhanVien
	as
	Begin
		select MaNV,MatKhau,Quyen,HoNV,TenNV,SDT,DiaChi,NgaySinh,GioiTinh,MaCN,LoaiNV,Luong,GhiChu
		from NhanVien
	End

go

create procedure ThemNhanVien
	( 
			@MaNV				nvarchar(50),
			@MatKhau			nvarchar(50),
			@Quyen				nvarchar(50),
			@HoNV				nvarchar(50),
			@TenNV				nvarchar(50),
			@SDT				int,
			@DiaChi				nvarchar(50),
			@NgaySinh			datetime,
			@GioiTinh			nvarchar(50),
			@MaCN				nvarchar(50),
			@LoaiNV				nvarchar(50),
			@Luong				int,
			@GhiChu				nvarchar(255)
	)
	as
	Begin
		if exists (select * from NHANVIEN where MaNV=@MaNV)
		begin
			raiserror (N'Đã có mã nhân viên',16,1)
			return
		end
		if exists (select * from LINK.QL_DT.DBO.NHANVIEN where MaNV=@MaNV)
		begin
			raiserror (N'Đã có mã nhân viên bên chi nhánh',16,1)
			return
		end
		insert into NhanVien(MaNV,MatKhau,Quyen,HoNV,TenNV,SDT,DiaChi,NgaySinh,GioiTinh,MaCN,LoaiNV,Luong,GhiChu) values(@MaNV,@MatKhau,@Quyen,@HoNV,@TenNV,@SDT,@DiaChi,@NgaySinh,@GioiTinh,@MaCN,@LoaiNV,@Luong,@GhiChu)
		raiserror (N'Thêm nhân viên thành công',16,1)

	End
Go
	
create procedure XoaNhanVien
(
		@MaNV	nvarchar(50)
)
as
Begin
	delete from NhanVien where MaNV=@MaNV
End
go

create procedure TimKiemNhanVien
(
		@TenNV nvarchar (50)
)
as
Begin
	select MaNV,MatKhau,Quyen,HoNV,TenNV,SDT,DiaChi,NgaySinh,GioiTinh,MaCN,LoaiNV,Luong,GhiChu
	from NhanVien where TenNV like  '%'+@TenNV+'%'
End 
Go



create procedure SuaNhanVien
(
			@MaNV				nvarchar(50),
			@MatKhau			nvarchar(50),
			@Quyen				nvarchar(50),
			@HoNV				nvarchar(50),
			@TenNV				nvarchar(50),
			@SDT				int,
			@DiaChi				nvarchar(50),
			@NgaySinh			datetime,
			@GioiTinh			nvarchar(50),
			@MaCN				nvarchar(50),
			@LoaiNV				nvarchar(50),
			@Luong				int,
			@GhiChu				nvarchar(255) 
)
as
Begin
	update NhanVien set 
		MatKhau=@MatKhau,
		Quyen=@Quyen,
		HoNV=@HoNV,
		TenNV=@TenNV,
		SDT=@SDT,
		DiaChi=@DiaChi,
		NgaySinh=@NgaySinh,
		GioiTinh=@GioiTinh,
		MaCN=@MaCN,
		LoaiNV=@LoaiNV,
		Luong=@Luong,
		GhiChu=@GhiChu
											 
	where MaNV =@MaNV
End
Go




create procedure ThemDienThoai
( 
			@MaDT				nvarchar(50),
			@HinhAnh			image,
			@TenDT				nvarchar(50),
			@DonGia				int,
			@ManHinh			nvarchar(50),
			@HeDieuHanh			nvarchar(50),
			@Camera				nvarchar(50),
			@Ram				nvarchar(50),
			@BoNho				nvarchar(50),
			@DungLuongPin		nvarchar(50)
			
)
as
Begin
	
		insert into DIENTHOAI(MaDT,HinhAnh,TenDT,DonGia,ManHinh,HeDieuHanh,Camera,Ram,BoNho,DungLuongPin) values
		(@MaDT,@HinhAnh,@TenDT,@DonGia,@ManHinh,@HeDieuHanh,@Camera,@Ram,@BoNho,@DungLuongPin)
end
Go



create procedure HienThiDienThoai
as
Begin

	select MaDT,HinhAnh,TenDT,DonGia,ManHinh,HeDieuHanh,Camera,Ram,BoNho,DungLuongPin from DIENTHOAI

End
Go



create procedure XoaDienThoai
(
		@MaDT	nvarchar(50)
)
as
Begin
	delete from DIENTHOAI where MaDT=@MaDT
End
go


create procedure TimKiemDienThoai
(
		@TenDT nvarchar(50)
)
as
Begin
	select MaDT,HinhAnh,TenDT,DonGia,ManHinh,HeDieuHanh,Camera,Ram,BoNho,DungLuongPin 
	from DIENTHOAI where TenDT like  '%'+@TenDT+'%'
End 
Go

create procedure SuaDienThoai
(
			@MaDT				nvarchar(50),
			@HinhAnh			image,
			@TenDT				nvarchar(50),
			@DonGia				int,
			@ManHinh			nvarchar(50),
			@HeDieuHanh			nvarchar(50),
			@Camera				nvarchar(50),
			@Ram				nvarchar(50),
			@BoNho				nvarchar(50),
			@DungLuongPin		nvarchar(50)
)
as
Begin
	update DIENTHOAI set 
		HinhAnh=@HinhAnh,
		TenDT=@TenDT,
		DonGia=@DonGia,
		ManHinh=@ManHinh,
		HeDieuHanh=@HeDieuHanh,
		Camera=@Camera,
		Ram=@Ram,
		BoNho=@BoNho,
		DungLuongPin=@DungLuongPin
									 
	where MaDT =@MaDT
End
Go



create procedure LoadKhachHang
	as
	Begin
		select MaKH,TenKH,DiaChi,SDT
		from KhachHang
	End

go



create procedure ThemKhachHang
(
	@MaKH	nvarchar(50),
	@TenKH	nvarchar(50),
	@DiaChi	nvarchar(255),
	@SDT	int
)
as
Begin 
		insert into KHACHHANG(MaKH,TenKH, DiaChi, SDT) values (@MaKH,@TenKH,@DiaChi,@SDT)
end
Go

create procedure XoaKhachHang
(
	@MaKH nvarchar(50)
)
as
Begin
	delete from KHACHHANG where MaKH=@MaKH
End
Go




create procedure SuaKhachHang
(
	@MaKH	nvarchar(50),
	@TenKH	nvarchar(50),
	@DiaChi	nvarchar(255),
	@SDT	int
)
as
Begin
	update KHACHHANG set
	TenKH = @TenKH, 
	DiaChi = @DiaChi, 
	SDT = @SDT

	where MaKH = @MaKH
End
Go

create procedure TimKiemKhachHang
(
		@TenKH nvarchar(50)
)
as
Begin
	select MaKH,TenKH, DiaChi, SDT 
	from KHACHHANG where TenKH like  '%'+@TenKH+'%'
End 
Go


create procedure LoadHoaDon
	as
	Begin
		select MaHD,MaNV,MaKho,MaKH
		from HOADON
	End

go


create procedure ThemHoaDon
(
	@MaHD	nvarchar(50),
	@MaNV	nvarchar(50),
	@MaKho	nvarchar(50),
	@MaKH	nvarchar(50)
)
as
Begin 
		insert into HoaDon(MaHD,MaNV,MaKho,MaKH) values (@MaHD,@MaNV,@MaKho,@MaKH)
end
Go



create procedure LoadChiTietHoaDon
	as
	Begin
		select MaCTHD,MAHD,MaDT,SoLuong as "Đơn Giá",GhiChu
		from ChiTietHoaDon
	End

go



create procedure ThemChiTietHoaDon
(
	@MaCTHD	nvarchar(50),
	@MaDT	nvarchar(50),
	@SoLuong int ,
	@GhiChu nvarchar(255)
)
as
Begin 
	declare @IDHoaDon  nvarchar(50)
	set @IDHoaDon =(select top 1 MAHD from  dbo.HOADON order by MAHD desc)
		insert into ChiTietHoaDon(MaCTHD,MaHD,MaDT,SoLuong,GhiChu) values (@MaCTHD,@IDHoaDon,@MaDT,@SoLuong,@GhiChu)
end
Go

