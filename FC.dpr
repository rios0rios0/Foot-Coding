program FC;

uses
  Windows, Messages,
  MyUtils in 'External Uses\MyUtils.pas';

var
  WindowClass: TWndClassA;
  hFont, hFrm, hLst, hBtnProces, hBtnLimpar, hBtnColar, hBtnCopiar, hStcEntrada,
  hStcSaida, hStcSobre, hEdtEntrada, hEdtSaida, MyBrush: DWORD;
  Count: Byte;
  Msg: TMsg;

const
  ListboxContent: array [1..13] of string = ('01 - Hex <- ASCII',
  '02 - Hex -> ASCII', '03 - Base64 <- ASCII', '04 - Base64 -> ASCII',
  '05 - Hex <- Decimal', '06 - Hex -> Decimal', '07 - Binário <- Decimal',
  '08 - Binário -> Decimal', '09 - Octal <- Decimal', '10 - Octal -> Decimal',
  '11 - Decimal -> Romanos', '12 - Ano -> Século', '13 - Data -> Dia (DDMMAAAA)');

{$R XPManifest\XPManifest.res}
{$R 'ConIcon\ConIcon.res' 'ConIcon\ConIcon.rc'}

function GetText(Wnd: DWORD): string;
 var
  Text: array [0..255] of Char;
begin
  GetWindowTextA(Wnd, Text, 255);
  Result := Text;
end;

procedure XPManifest;
begin
  GetProcAddress(LoadLibrary('comctl32.dll'), 'InitCommonControls');
  asm
    CMP EAX, 0
    JZ @Fail
    CALL EAX
    @Fail:
  end;
end;

function AllocMem(Size: Cardinal): Pointer;
begin
  GetMem(Result, Size);
  FillChar(Result^, Size, 0);
end;

function StrCopy(Dest: PChar; const Source: PChar): PChar; assembler;
asm
        PUSH    EDI
        PUSH    ESI
        MOV     ESI,EAX
        MOV     EDI,EDX
        MOV     ECX,0FFFFFFFFH
        XOR     AL,AL
        REPNE   SCASB
        NOT     ECX
        MOV     EDI,ESI
        MOV     ESI,EDX
        MOV     EDX,ECX
        MOV     EAX,EDI
        SHR     ECX,2
        REP     MOVSD
        MOV     ECX,EDX
        AND     ECX,3
        REP     MOVSB
        POP     ESI
        POP     EDI
end;

function StrLCopy(Dest: PChar; const Source: PChar; MaxLen: Cardinal): PChar; assembler;
asm
        PUSH    EDI
        PUSH    ESI
        PUSH    EBX
        MOV     ESI,EAX
        MOV     EDI,EDX
        MOV     EBX,ECX
        XOR     AL,AL
        TEST    ECX,ECX
        JZ      @@1
        REPNE   SCASB
        JNE     @@1
        INC     ECX
@@1:    SUB     EBX,ECX
        MOV     EDI,ESI
        MOV     ESI,EDX
        MOV     EDX,EDI
        MOV     ECX,EBX
        SHR     ECX,2
        REP     MOVSD
        MOV     ECX,EBX
        AND     ECX,3
        REP     MOVSB
        STOSB
        MOV     EAX,EDX
        POP     EBX
        POP     ESI
        POP     EDI
end;


procedure SetClipboardText(const S: string);
 var
  H: THandle;
begin
  if not OpenClipboard(0) then
    MessageBox(hFrm, 'ERRO', 'ERRO', MB_OK);
  try
    if not EmptyClipboard then
      MessageBox(hFrm, 'ERRO', 'ERRO', MB_OK);
    H := GlobalAlloc(GMEM_MOVEABLE or GMEM_DDESHARE, Length(S) + 1);
    if (H = 0) then
      MessageBox(hFrm, 'ERRO', 'ERRO', MB_OK);
    StrCopy(GlobalLock(H), PChar(S));
    GlobalUnlock(H);
    SetClipboardData(CF_TEXT, H);
  finally
    CloseClipboard;
  end;
end;

procedure GetClipboardText(var Message: TMessage);
 var
  Handle: THandle;
begin
  if IsClipboardFormatAvailable(CF_TEXT) then
  begin
    try
      Handle := GetClipboardData(CF_TEXT);
      if Handle = 0 then
        Exit;
      GlobalUnlock(Handle);
    finally
      CloseClipBoard;
    end;
  end;
end;

procedure SetFormIcons(FormHandle: HWND; const SmallIconName, LargeIconName: string);
 var
  hIconS, hIconL: HICON;
begin
  if (SmallIconName <> '') then
  begin
    hIconS := LoadIcon(hInstance, PChar(SmallIconName));
    if (hIconS > 0) then
    begin
      SendMessage(FormHandle, WM_SETICON, ICON_SMALL, hIconS);
      SetClassLong(FormHandle, GCL_HICONSM, LPARAM(hIconS));
      if (hIconS > 0) then
        DestroyIcon(hIconS);
    end;
  end;
  if (LargeIconName <> '') then
  begin
    hIconL := LoadIcon(hInstance, PChar(LargeIconName));
    if (hIconL > 0) then
    begin
      SendMessage(FormHandle, WM_SETICON, ICON_BIG, hIconL);
      SetClassLong(FormHandle, GCL_HICON, LPARAM(hIconL));
      if (hIconL > 0) then
        DestroyIcon(hIconL);
    end;
  end;
end;

procedure CreateMyClass(out WindowClass: TWndClassA; hInst: DWORD;
WindowProc: Pointer; BackColor: DWORD; ClassName: PAnsiChar);
begin
  with WindowClass do
  begin
    hInstance     := hInst;
    lpfnWndProc   := WindowProc;
    hbrBackground := BackColor;
    lpszClassname := ClassName;
    hCursor       := LoadCursor(0, IDC_ARROW);
    style         := CS_OWNDC or CS_VREDRAW or CS_HREDRAW or CS_DROPSHADOW;
  end;
  RegisterClassA(WindowClass);
end;

function CreateMyFont(FontName: string; Size, Style: Integer;
Italic, Underline, Strikeout: Boolean): DWORD;
begin
  Result := CreateFontA(Size, 0, 0, 0, Style, DWORD(Italic), DWORD(Underline),
  DWORD(Strikeout), DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
  DEFAULT_QUALITY, DEFAULT_PITCH, PChar(FontName));
end;

function CreateMyForm(hInst: DWORD; ClassName, Caption: PAnsiChar;
Width, Heigth: Integer; Transparence: Byte): DWORD;
begin
  Result := CreateWindowExA(WS_EX_WINDOWEDGE or WS_EX_LAYERED, ClassName, Caption,
  WS_VISIBLE or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX,
  (GetSystemMetrics(SM_CXSCREEN) - Width)  div 2, //Center X
  (GetSystemMetrics(SM_CYSCREEN) - Heigth) div 2, //Center Y
  Width, Heigth, 0, 0, hInst, nil);
  SetLayeredWindowAttributes(Result, 0, Transparence, LWA_ALPHA);
  //SendMessageA(Result, WM_SETICON, 0, LoadIcon(Result, 'ICO32'));
  SetFormIcons(Result, 'ICO32', 'ICO64');
  UpdateWindow(Result);
end;

function CreateMyComponent(hInst: DWORD; ClassName, Caption: PAnsiChar;
Font, x, y, Width, Heigth, Parent: Integer; StyleEx, Style: DWORD): DWORD;
begin
  Result := CreateWindowExA(StyleEx, ClassName, Caption, WS_CHILD or WS_VISIBLE
  or Style, x, y, Width, Heigth, Parent, 0, hInst, nil);
  if (Font <> 0) then
    SendMessageA(Result, WM_SETFONT, Font, 0);
end;

function WindowProc(hWnd: DWORD; uMsg, wParam, lParam: Integer): Integer; stdcall;
 var
  Line, iValue, iCode: Integer;
  S: string;
  TxtLine: array [0..255] of Char;
  hMem    : THandle;
  dwLen   : DWORD;
  ps1, ps2: PChar;
begin
  Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
  case uMsg of
    WM_COMMAND:
    begin
      if (lParam = hBtnProces) then
      begin
        if (GetText(hEdtEntrada) <> '') then
        begin
          Line := SendMessageA(hLst, LB_GETCURSEL, 0, 0);
          if (Line <> -1) then
          begin
            SendMessageA(hLst, LB_GETTEXT, Line, Integer(@TxtLine));
            case StrToInt(Copy(string(TxtLine), 0, 2)) of
              01: SetWindowTextA(hEdtSaida, PChar(StrToHex(GetText(hEdtEntrada))));
              02: SetWindowTextA(hEdtSaida, PChar(HexToStr(GetText(hEdtEntrada))));

              03: SetWindowTextA(hEdtSaida, PChar(StrToB64(GetText(hEdtEntrada))));
              04: SetWindowTextA(hEdtSaida, PChar(B64ToStr(GetText(hEdtEntrada))));

              05: SetWindowTextA(hEdtSaida, PChar(IntToHex(StrToInt(GetText(hEdtEntrada)), 1)));
              06: begin
                    S := IntToStr(HexToInt(GetText(hEdtEntrada)));
                    SetWindowTextA(hEdtSaida, PChar(S));
                  end;
              07: SetWindowTextA(hEdtSaida, PChar(IntToBin(StrToInt(GetText(hEdtEntrada)))));
              08: begin
                    S := IntToStr(BinToInt(GetText(hEdtEntrada)));
                    SetWindowTextA(hEdtSaida, PChar(S));
                  end;
              09: begin
                    S := IntToStr(IntToOct(StrToInt(GetText(hEdtEntrada))));
                    SetWindowTextA(hEdtSaida, PChar(S));
                  end;
              10: begin
                    Val(GetText(hEdtEntrada), iValue, iCode);
                    if (iCode <> 0) then
                      Exit;
                    S := IntToStr(OctToInt(StrToInt(GetText(hEdtEntrada))));
                    SetWindowTextA(hEdtSaida, PChar(S));
                  end;
              11: begin
                    Val(GetText(hEdtEntrada), iValue, iCode);
                    if (iCode <> 0) then
                      Exit;
                    SetWindowTextA(hEdtSaida, PChar(IntToRom(StrToInt(GetText(hEdtEntrada)))));
                  end;
              12: SetWindowTextA(hEdtSaida, PChar(IntToRom(StrToInt(CenturyCalc(StrToInt(GetText(hEdtEntrada)))))));
              13: SetWindowTextA(hEdtSaida, PChar(AnyDay(StrToInt(Copy(GetText(hEdtEntrada), 0, 2)),
                  StrToInt(Copy(GetText(hEdtEntrada), 3, 2)), StrToInt(Copy(GetText(hEdtEntrada), 5, 4)))));
            end;
          end;
        end else
          MessageBoxA(hFrm, 'Entrada de Texto Vazia!', 'Erro', MB_OK
          + MB_DEFBUTTON1 + MB_ICONERROR);
      end;
      if (lParam = hBtnLimpar) then
      begin
        SetWindowTextA(hEdtSaida, '');
        SetWindowTextA(hEdtEntrada, '');
      end;
      if (lParam = hBtnColar) then
      begin
        OpenClipboard(hFrm);
        try
          hMem := GetClipboardData(CF_TEXT);
          ps1 := GlobalLock(hMem);
          dwLen := GlobalSize(hMem);
          ps2 := AllocMem(1 + dwLen);
          StrLCopy(ps2, ps1, dwLen);
          GlobalUnlock(hMem);
          SetWindowTextA(hEdtEntrada, ps2);
        finally
          CloseClipboard;
        end;
      end;
      if (lParam = hBtnCopiar) then
      begin
        SetClipboardText(GetText(hEdtSaida));
      end;
    end;
    WM_CTLCOLORLISTBOX:
    begin
      SetTextColor(wParam, $FFFFFF);
      SetBkColor(wParam, 0);
      Result := MyBrush;
      //SetTextColor(wParam, $FFFFFF);
      //SetBkColor(wParam, TRANSPARENT);  //0
      //Result := GetStockObject(BLACK_BRUSH);
    end;
    WM_CTLCOLORSTATIC:
    begin
      SetTextColor(wParam, $FFFFFF);
      SetBkColor(wParam, 0);
      Result := MyBrush;
    end;
    WM_CTLCOLOREDIT:
    begin
      SetTextColor(wParam, $FFFFFF);
      SetBkColor(wParam, 0); //$453F3F
      Result := MyBrush;
      //SetTextColor(wParam, $FFFFFF);
      //SetBkColor(wParam, TRANSPARENT);  //$453F3F
      //Result := GetStockObject(NULL_BRUSH);
    end;
    WM_DESTROY:
    begin
      PostQuitMessage(0);
      Halt;
    end;
  end;
end;

begin
  XPManifest;
  MyBrush := CreateSolidBrush(0);
  CreateMyClass(WindowClass, HInstance, @WindowProc, CreateSolidBrush(0), 'FrmFCPrincipal'); //$D9E9EC
  hFont := CreateMyFont('Times New Roman', -14, FW_NORMAL, False, False, False);
  hFrm  := CreateMyForm(HInstance, 'FrmFCPrincipal', 'Foot Coding v1.0', 500, 380, 255);
  hLst  := CreateMyComponent(HInstance, 'ListBox', '', hFont, 22, 16, 450, 97,
  hFrm, WS_EX_CLIENTEDGE, LBS_HASSTRINGS or LBS_NOTIFY or LBS_SORT or WS_VSCROLL);
  hBtnProces  := CreateMyComponent(HInstance, 'Button', 'Processar', hFont, 22, 290, 75, 27, hFrm, 0, BS_NULL);
  hBtnLimpar  := CreateMyComponent(HInstance, 'Button', 'Limpar', hFont, 395, 290, 75, 27, hFrm, 0, 0);
  hBtnColar   := CreateMyComponent(HInstance, 'Button', '< Colar', hFont, 165, 290, 75, 27, hFrm, 0, 0);
  hBtnCopiar  := CreateMyComponent(HInstance, 'Button', 'Copiar >', hFont, 250, 290, 75, 27, hFrm, 0, 0);
  hStcEntrada := CreateMyComponent(HInstance, 'Static', 'Entrada:', hFont, 22, 112, 47, 20, hFrm, 0, WS_BORDER or SS_NOTIFY);
  hStcSaida   := CreateMyComponent(HInstance, 'Static', 'Saida:', hFont, 248, 112, 34, 20, hFrm, 0, WS_BORDER or SS_NOTIFY);
  hStcSobre   := CreateMyComponent(HInstance, 'Static', 'Criado Por rios0rios0 ...',
  hFont, 22, 327, 200, 20, hFrm, 0, WS_BORDER or SS_NOTIFY);
  hEdtEntrada := CreateMyComponent(HInstance, 'Edit', '', hFont, 22, 134, 225, 145,
  hFrm, WS_EX_CLIENTEDGE, WS_BORDER or ES_AUTOVSCROLL or ES_MULTILINE or WS_VSCROLL);
  hEdtSaida   := CreateMyComponent(HInstance, 'Edit', '', hFont, 245, 134, 225, 145,
  hFrm, WS_EX_CLIENTEDGE, WS_BORDER or ES_AUTOVSCROLL or ES_MULTILINE or WS_VSCROLL);

  //ON CREATE
  for Count := 1 to Length(ListboxContent) do
  begin
    SendMessageA(hLst, LB_ADDSTRING, 0, DWORD(ListboxContent[Count]));
    SetFocus(hLst);
  end;
  while (GetMessageA(Msg, 0, 0, 0)) do
  begin
    TranslateMessage(Msg);
    DispatchMessageA(Msg);
  end;
end.
