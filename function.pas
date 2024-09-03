function ImageSearch(sSubImageFile: string; aWndHanlde: HWND): TPoint;
const
  CAPTUREBLT = $40000000;
var
  bounds: TGPRect;
  BMD1, BMD2: TBitmapData;
var
  hDesktopDC: HDC;
  hCaptureDC: HDC;
  hCaptureBitmap, hOldBmp: HBITMAP;
  gpDesktopbmp: TGPBitmap;
  xd, yd: Integer;
  bFound: Boolean;
  LpQuad1: PByte;
  LScanLine1: PByte;
  LS1, LS2: Pointer;
  bpp1, bpp2: Integer;
  StrideDif1, StrideDif2: Integer;
  LDataStride1, LDataStride2: Integer;
  bRowFound: Boolean;
  I: Integer;
  rc1: TRect;
  aTmpGpBitmap: TGPBitmap;
  aStatus: TStatus;
  aSubImageBmp: TGPBitmap;
begin
  Result.X := -1;
  Result.Y := -1;

  GetClientRect(aWndHanlde, rc1);
  MapWindowPoints(aWndHanlde, 0, rc1, 2);
  hDesktopDC := GetDC(0);
  hCaptureDC := CreateCompatibleDC(hDesktopDC);
  hCaptureBitmap := CreateCompatibleBitmap(hDesktopDC, rc1.Width, rc1.Height);
  hOldBmp := SelectObject(hCaptureDC, hCaptureBitmap);
  BitBlt(hCaptureDC, 0, 0, rc1.Width, rc1.Height, hDesktopDC, rc1.Left, rc1.Top, SRCCOPY);
  SelectObject(hCaptureDC, hOldBmp);

  try
    aSubImageBmp := TGPBitmap.Create(sSubImageFile);
    bounds.X := 0; //needle
    bounds.Y := 0;
    bounds.Width := aSubImageBmp.GetWidth;
    bounds.Height := aSubImageBmp.GetHeight;
    bpp2 := GetPixelFormatSize(aSubImageBmp.GetPixelFormat) div 8;
    aStatus := aSubImageBmp.LockBits(bounds, ImageLockModeRead, aSubImageBmp.GetPixelFormat, BMD2);
    if aStatus <> TStatus.Ok then
      Exit;

    aTmpGpBitmap := TGPBitmap.Create(hCaptureBitmap, 0);
    bounds.X := 0; //haystack
    bounds.Y := 0;
    bounds.Width := aTmpGpBitmap.GetWidth;
    bounds.Height := aTmpGpBitmap.GetHeight;
    gpDesktopbmp := aTmpGpBitmap.Clone(0, 0, aTmpGpBitmap.GetWidth, aTmpGpBitmap.GetHeight, aSubImageBmp.GetPixelFormat);
    bpp1 := GetPixelFormatSize(gpDesktopbmp.GetPixelFormat) div 8; //byte per pixel = bits / 8
    aStatus := gpDesktopbmp.LockBits(bounds, ImageLockModeRead, gpDesktopbmp.GetPixelFormat, BMD1);
    if aStatus <> TStatus.Ok then
      Exit;

    if bpp1 <> bpp2 then
      Exit;
    if (aSubImageBmp.GetWidth > gpDesktopbmp.GetWidth) or (aSubImageBmp.GetHeight > gpDesktopbmp.GetHeight) then
      Exit;
    if (BMD1.Stride < 0) then
      Exit;
    if (BMD2.Stride < 0) then
      Exit;

    StrideDif1 := BMD1.Stride mod bpp1;
    if StrideDif1 <> 0 then
      Dec(BMD1.Stride, StrideDif1);

    StrideDif2 := BMD2.Stride mod bpp2;
    if StrideDif2 <> 0 then
      Dec(BMD2.Stride, StrideDif2);

    //modify stride right and bottom to be bigger than the small image width and height

    LScanLine1 := BMD1.Scan0;
    LDataStride1 := ABS(BMD1.Stride)+StrideDif1;
    LDataStride2 := ABS(BMD2.Stride)+StrideDif2;
    bFound := False;
    bRowFound := False;

    try
    for yd := 0 to BMD1.Height-1 do  // H1
    begin
      LpQuad1 := PByte(LScanLine1);

      xd := 0;
      while xd <= BMD1.Stride-1 do   //W1
      begin
        case bpp1 of
          2:
          begin
            bFound := (
                      (PByte(LpQuad1)^ = PByte(BMD2.Scan0)^) and
                      (PByte(DWORD(LpQuad1)+1)^ = PByte(DWORD(BMD2.Scan0)+1)^)
                      );
          end;
          3:
          begin
            bFound := (
                      (PByte(LpQuad1)^ = PByte(BMD2.Scan0)^) and
                      (PByte(DWORD(LpQuad1)+1)^ = PByte(DWORD(BMD2.Scan0)+1)^) and
                      (PByte(DWORD(LpQuad1)+2)^ = PByte(DWORD(BMD2.Scan0)+2)^)
                      );
          end;
          4:
          begin
            bFound := (
                      (PByte(LpQuad1)^ = PByte(BMD2.Scan0)^) and
                      (PByte(DWORD(LpQuad1)+1)^ = PByte(DWORD(BMD2.Scan0)+1)^) and
                      (PByte(DWORD(LpQuad1)+2)^ = PByte(DWORD(BMD2.Scan0)+2)^) and
                      (PByte(DWORD(LpQuad1)+3)^ = PByte(DWORD(BMD2.Scan0)+3)^)
                      );
          end;
        end;
        if bFound then
        begin
          LS1 := Pointer(DWORD(LScanLine1)+Cardinal(xd));
          LS2 := BMD2.Scan0;
          for I := 0 to BMD2.Height-1 do
          begin
            bRowFound := CompareMem(LS1, LS2, BMD2.Stride);
            if not bRowFound then
              Break;
            LS1 := Pointer(DWORD(LS1)+Cardinal(LDataStride1));
            LS2 := Pointer(DWORD(LS2)+Cardinal(LDataStride2));
          end;
          if bRowFound then //all patteren found
          begin
            if xd > 0 then
              xd := xd div bpp1;
            Result.X := xd;
            Result.Y := yd;
            Break;
          end;
        end;
        if bRowFound then
          Break;
        Inc(LpQuad1, bpp1);
        Inc(xd, bpp1);
      end;
      if bRowFound then
        Break;
      Inc(LScanLine1, LDataStride1);
    end;
    except

    end;

  finally
    if Assigned(gpDesktopBmp) then
    begin
      gpDesktopBmp.UnlockBits(BMD1);
      FreeAndNil(gpDesktopBmp);
    end;
    if Assigned(aSubImageBmp) then
    begin
      aSubImageBmp.UnlockBits(BMD2);
      FreeAndNil(aSubImageBmp);
    end;
    if Assigned(aTmpGpBitmap) then
      FreeAndNil(aTmpGpBitmap);
    ReleaseDC(0, hDesktopDC);
    DeleteDC(hCaptureDC);
    DeleteObject(hCaptureBitmap);
    DeleteObject(hOldBmp);
  end;
end;
