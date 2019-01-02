unit MyUtils;

interface

function IntToStr(Value: Integer): ShortString;
function StrToInt(Value: ShortString): Integer;

function StrToHex(S: string): string;
function HexToStr(S: string): string;

function IntToHex(Value: LongInt; Digits: Integer): string;
function HexToInt(S: string): LongInt;

function IntToBin(Value: LongInt): string;
function BinToInt(S: string): LongInt;

function IntToOct(Value: LongInt): LongInt;
function OctToInt(Value: LongInt): LongInt;

function StrToB64(S: string): string;
function B64ToStr(S: string): string;

function IntToRom(Value: LongInt): string;
function AnyDay(D, M, Y: Integer): string;
function CenturyCalc(Year: Integer): string;

const
  Codes64: ANSIString = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

implementation

function Pow(Base, Exponent: Integer): Integer;
begin
  if (Exponent = 0) then
    Result := 1
  else
    Result := Base * Pow(Base, Exponent - 1);
end;

function ReverseString(S: string): string;
 var
  Count: Integer;
begin
   Result := '';
   for Count := Length(S) downto 1 do
   begin
     Result := Result + Copy(S, Count, 1);
   end;
end;

function AnyDay(D, M, Y: Integer): string;
 var
  K: Integer;
  K1: Extended;
begin
  K1 := D + (2 * M) + ((3 * (M + 1)) / 5) + Y + (Y / 4) - (Y / 100) + (Y / 400) + 2;
  K := Round(K1);
  K := K mod 7;
  case K of
    0: Result := 'Sábado';
    1: Result := 'Domingo';
    2: Result := 'Segunda-feira';
    3: Result := 'Terça-feira';
    4: Result := 'Quarta-feira';
    5: Result := 'Quinta-feira';
    6: Result := 'Sexta-feira';
  else
    Result := 'Erro :(';
  end;
end;

function CenturyCalc(Year: Integer): string;
 var
  A: string;
  B: Integer;
begin
  if (Length(IntToStr(Year)) = 1) then
  begin
    Result := '1';
    Exit;
  end;
  if (Length(IntToStr(Year)) = 2) then
  begin
    A := StringOfChar('0', 2);
  end else if (Length(IntToStr(Year)) = 3) then
  begin
    A := StringOfChar('0', 1) + Copy(IntToStr(Year), 0, 1);
  end else
    A := Copy(IntToStr(Year), 0, 2);
  if (Length(IntToStr(Year)) >= 5) then
    A := Copy(IntToStr(Year), 0, 3);
  if (Copy(IntToStr(Year), Length(IntToStr(Year)) - 1, 2) <> '00') then
  begin
    B := StrToInt(A) + 1;
    Result := IntToStr(B);
  end else begin
    Result := A;
  end;
end;

function IntToStr(Value: Integer): ShortString;
// Value  = eax
// Result = edx
asm
  push ebx
  push esi
  push edi

  mov edi,edx
  xor ecx,ecx
  mov ebx,10
  xor edx,edx

  cmp eax,0 // check for negative
  setl dl
  mov esi,edx
  jnl @reads
  neg eax

  @reads:
    mov  edx,0   // edx = eax mod 10
    div  ebx     // eax = eax div 10
    add  edx,48  // '0' = #48
    push edx
    inc  ecx
    cmp  eax,0
  jne @reads

  dec esi
  jnz @positive
  push 45 // '-' = #45
  inc ecx

  @positive:
  mov [edi],cl // set length byte
  inc edi

  @writes:
    pop eax
    mov [edi],al
    inc edi
    dec ecx
  jnz @writes

  pop edi
  pop esi
  pop ebx
end;

function StrToInt(Value: ShortString): Integer;
// Value   = eax
// Result  = eax
asm
  push ebx
  push esi

  mov esi,eax
  xor eax,eax
  movzx ecx,Byte([esi]) // read length byte
  cmp ecx,0
  je @exit

  movzx ebx,Byte([esi+1])
  xor edx,edx // edx = 0
  cmp ebx,45  // check for negative '-' = #45
  jne @loop

  dec edx // edx = -1
  inc esi // skip '-'
  dec ecx

  @loop:
    inc   esi
    movzx ebx,Byte([esi])
    imul  eax,10
    sub   ebx,48 // '0' = #48
    add   eax,ebx
    dec   ecx
  jnz @loop

  mov ecx,eax
  and ecx,edx
  shl ecx,1
  sub eax,ecx

  @exit:
  pop esi
  pop ebx
end;

{function ItoS(Value : Integer):PAnsiChar; stdcall;
asm
  mov eax,[ebp+8]
  push ecx
  push edx
  push esi
    sub esp,1
    or eax,eax
    jl @IsNeg
      jmp @IsNotNeg
    @IsNeg:
      neg eax
      mov byte ptr ss:[esp],2Dh
      jmp @Start
    @IsNotNeg:
      mov byte ptr ss:[esp],0
    @Start:
    push eax
      push PAGE_EXECUTE_READWRITE
      push MEM_COMMIT or MEM_RESERVE
      push 0Ch
      push 0
      call VirtualAlloc
      mov esi,eax
      add esi,0Bh
    pop eax
    xor ecx,ecx
    xor edx,edx
    xor ebx,ebx
    or cl,0Ah
    mov byte ptr ds:[esi],0
    dec esi
    @Loop:
      div ecx
      add dl,30h
      mov byte ptr ds:[esi],dl
      xor dl,dl
      dec esi
      or eax,eax
    jnz @Loop
    cmp byte ptr ds:[esp],2Dh
    jnz @IsOk
      mov byte ptr ds:[esi],2Dh
      jmp @IsNotOk
  @IsOk:
    inc esi
  @IsNotOk:
    or eax,esi
    add esp,1
  pop esi
  pop edx
  pop ecx
end;

function StoI(S: string): Integer; stdcall;
asm
  mov eax,[ebp+8]
  push ecx
  push edx
  push esi
    sub esp,1
    or eax,eax
    jl @IsNeg
      jmp @IsNotNeg
    @IsNeg:
      neg eax
      mov byte ptr ss:[esp],2Dh
      jmp @Start
    @IsNotNeg:
      mov byte ptr ss:[esp],0
    @Start:
    push eax
      push PAGE_EXECUTE_READWRITE
      push MEM_COMMIT or MEM_RESERVE
      push 0Ch
      push 0
      call VirtualAlloc
      mov esi,eax
      add esi,0Bh
    pop eax
    xor ecx,ecx
    xor edx,edx
    xor ebx,ebx
    or cl,10h
    mov byte ptr ds:[esi],0
    dec esi
    @Loop:
      div ecx
      add dl,30h
      mov byte ptr ds:[esi],dl
      xor dl,dl
      dec esi
      or eax,eax
    jnz @Loop
    cmp byte ptr ds:[esp],2Dh
    jnz @IsOk
      mov byte ptr ds:[esi],2Dh
      jmp @IsNotOk
  @IsOk:
    inc esi
  @IsNotOk:
    or eax,esi
    add esp,1
  pop esi
  pop edx
  pop ecx
end;}

function StrToHex(S: string): string;
 var
  Count: Integer;
begin
  for Count := 1 to Length(S) do
  begin
    Result := Result + IntToHex(Ord(S[Count]), 1);
  end;
end;

function HexToStr(S: string): string;
 var
  Count: Integer;
  Aux: string;
begin
  Count := 0;
  while (Length(S) > Count) do
  begin
    Aux := Copy(S, Count + 1, 2);
    Result := Result + Char(HexToInt(Aux));
    Count := Count + 2;
  end;
end;

function IntToHex(Value: LongInt; Digits: Integer): string;
 var
  Res: string;
begin
  if (Value = 0) then
    Res := StringOfChar('0', Digits);
  if (Value < 0) then
    Res := StringOfChar('F', 16);

  while (Value > 0) do
  begin
    case (Value mod 16) of
      10: Res := 'A' + Res;
      11: Res := 'B' + Res;
      12: Res := 'C' + Res;
      13: Res := 'D' + Res;
      14: Res := 'E' + Res;
      15: Res := 'F' + Res;
    else
      Res := IntToStr(Value mod 16) + Res;
    end;
    Value := Value div 16;
  end;
  if ((Digits > 1) and (Length(Res) < Digits)) then
  begin
    Res := StringOfChar('0', (Digits - Length(Res))) + Res;
  end;
  Result := Res;
end;

function HexToInt(S: string): LongInt;
 var
  Count, Aux, Res: Integer;
begin
  if (Length(S) > 16) then
    Res := 0;
  if (Length(S) = 16) then
    Res := -1;

  Res := 0;
  S := ReverseString(S);
  for Count := 1 to Length(S) do
  begin
	  case S[Count] of
	    'A': Aux := 10;
      'B': Aux := 11;
      'C': Aux := 12;
      'D': Aux := 13;
      'E': Aux := 14;
      'F': Aux := 15;
    else
      Aux := StrToInt(S[Count]);
    end;
    Res := Res + (Aux * Pow(16, (Count - 1)));
  end;
  Result := Res;
end;

function IntToBin(Value: LongInt): string;
begin
  if (Value = 0) then
    Result := '0';
  if (Value < 0) then
    Result := StringOfChar('1', 64);

  while (Value > 0) do
  begin
    Result := IntToStr(Value mod 2) + Result;
    Value := Value div 2;
  end;
end;

function BinToInt(S: string): LongInt;
 var
  Count, Res: Integer;
begin
  if (Length(S) > 64) then
    Res := 0;
  if (Length(S) = 64) then
    Res := -1;

  Res := 0;
  S := ReverseString(S);
  for Count := 1 to Length(S) do
  begin
    Res := Res + ((StrToInt(S[Count])) * Pow(2, (Count - 1)));
  end;
  Result := Res;
end;

function IntToOct(Value: LongInt): LongInt;
 var
  Aux: Integer;
  Res: string;
begin
  while (Value > 0) do
  begin
    Aux := Value mod 8;
    Res := IntToStr(Aux) + Res;
    Value := Value div 8;
  end;
  Result := StrToInt(Res);
end;

function OctToInt(Value: LongInt): LongInt;
 var
  S: string;
  Count, Res: Integer;
begin
  Res := 0;
  S := ReverseString(IntToStr(Value));
  for Count := 1 to Length(S) do
  begin
    Res := Res + ((StrToInt(S[Count])) * Pow(8, (Count - 1)));
  end;
  Result := Res;
end;

function StrToB64(S: string): string;
 var
  a, b, i, x: Integer;
begin
  Result := '';
  a := 0;
  b := 0;
  for i := 1 to Length(S) do
  begin
    x := Ord(S[i]);
    b := b * 256 + x;
    a := a + 8;
    while (a >= 6) do
    begin
      a := a - 6;
      x := b div (1 shl a);
      b := b mod (1 shl a);
      Result := Result + Codes64[x + 1];
    end;
  end;
  if (a > 0) then
  begin
    x := b shl (6 - a);
    Result := Result + Codes64[x + 1];
  end;
end;

function B64ToStr(S: string): string;
 var
  a, b, i, x: Integer;
begin
  Result := '';
  a := 0;
  b := 0;
  for i := 1 to Length(S) do
  begin
    x := Pos(S[i], Codes64) - 1;
    if (x >= 0) then
    begin
      b := b * 64 + x;
      a := a + 6;
      if (a >= 8) then
      begin
        a := a - 8;
        x := b shr a;
        b := b mod (1 shl a);
        x := x mod 256;
        Result := Result + Chr(x);
      end;
    end else
      Exit;
  end;
end;

function IntToRom(Value: LongInt): string;
 const
  Arabics: array [1..13] of Integer =
  (1, 4, 5, 9, 10, 40, 50, 90, 100, 400, 500, 900, 1000);
  Romans: array [1..13] of string =
  ('I', 'IV', 'V', 'IX', 'X', 'XL', 'L', 'XC', 'C', 'CD', 'D', 'CM', 'M') ;
 var
  Count: Integer;
begin
  for Count := 13 downto 1 do
    while (Value >= Arabics[Count]) do
    begin
      Value := Value - Arabics[Count];
      Result := Result + Romans[Count];
    end;
end;

end.
 