; Doze - Dave's Z80 Emulator - Assembler output

bits 32

section .data

times ($$-$) & 3 db 0

; Z80 Registers
global _Doze
_Doze:
DozeAF  dw 0
DozeBC  dw 0
DozeDE  dw 0
DozeHL  dw 0
DozeIX  dw 0
DozeIY  dw 0
DozePC  dw 0
DozeSP  dw 0
DozeAF2 dw 0
DozeBC2 dw 0
DozeDE2 dw 0
DozeHL2 dw 0
DozeIR  dw 0
DozeIFF dw 0
DozeIM  db 0

times ($$-$) & 3 db 0

global _nDozeCycles
_nDozeCycles: dd 0 ; Cycles left (in T-states)
global _nDozeEi
_nDozeEi: dd 0 ; 1 = assembler quit on EI, 2 = assembler did quit on EI
SaveReg: times 6 dd 0
Tmp16: dw 0
TmpFlag: db 0
times ($$-$) & 3 db 0

global _DozeMemFetch
_DozeMemFetch: times 0x100 dd 0
global _DozeMemRead
_DozeMemRead:  times 0x100 dd 0
global _DozeMemWrite
_DozeMemWrite: times 0x100 dd 0
section .text

%macro SAVE_REGS 0
  push ebx
  push ecx
  push edx
  push esi
  push edi
  push ebp
%endmacro

%macro RESTORE_REGS 0
  pop ebp
  pop edi
  pop esi
  pop edx
  pop ecx
  pop ebx
%endmacro

%macro DOZE_TO_REG 0
  ; Load a into al, f into ah
  mov ax,word [DozeAF]
  ror ax,8
  ; Load hl into cx
  mov cx,word [DozeHL]
  mov bl,byte [DozeIR] ; Load bl <- R counter
  rol bl,1 ; bl <-- R register bits (65432107)
  xor esi,esi
  mov si,word [DozePC] ; Load si <- PC
%endmacro

%macro REG_BLANK 0
  xor edx,edx ; High 16 bits of edx kept clear
  xor edi,edi ; High 16 bits of edi kept clear
%endmacro

%macro REG_TO_DOZE 0
  ; Save a from al, f from ah
  ror ax,8
  mov word [DozeAF],ax
  ; Save hl from cx
  mov word [DozeHL],cx
  ror bl,1 ; bl --> R register bits 76543210
  mov byte [DozeIR],bl ; Save bl -> R counter
  mov word [DozePC],si ; Save si -> PC
%endmacro

%macro DAM_FETCH8 0
; Fetch byte (esi) ==> dl
  mov dx,si
  shr dx,8
  mov ebp,dword[_DozeMemFetch+edx*4]
  xor edx,edx
  mov dl,byte [ebp+esi]
  xor ebp,ebp
%endmacro

%macro DAM_FETCH16 0
; Fetch word  (esi) ==> dx
  mov dx,si
  shr dx,8
  mov ebp,dword[_DozeMemFetch+edx*4]
  xor edx,edx
  mov dx,word [ebp+esi]
  xor ebp,ebp
%endmacro

%macro DAM_READ8 0
; Read byte   (edi) ==> dl
  mov ebp,edi
  shr bp,8
  mov ebp,dword[_DozeMemRead+ebp*4]
  test ebp,ebp
  jnz %%Direct
  call Read
  jmp %%Done
%%Direct:
  mov dl,byte [ebp+edi]
%%Done:
%endmacro

%macro DAM_WRITE8 0
; Write byte  dl ==> (edi)
  mov ebp,edi
  shr bp,8
  mov ebp,dword[_DozeMemWrite+ebp*4]
  test ebp,ebp
  jnz %%Direct
  call Write
  jmp %%Done
%%Direct:
  mov byte [ebp+edi],dl
%%Done:
%endmacro

%macro DAM_READ16 0
; Read word   (edi) ==> dx
  inc di
  DAM_READ8
  dec di
  mov dh,dl
  DAM_READ8
%endmacro

%macro DAM_WRITE16 0
; Write word  dx ==> (edi)
  inc di
  ror dx,8
  DAM_WRITE8
  dec di
  ror dx,8
  DAM_WRITE8
%endmacro

%macro FETCH_OP 0
  ; Fetch next normal opcode
  DAM_FETCH8
  inc si
  xor dh,dh
  jmp [JumpTab+edx*4]
%endmacro

%macro INC_R 0
  add bl,2 ; Increase instruction counter R (bit 7 never modified)
%endmacro

times ($$-$) & 3 db 0

extern _DozeRead
Read:
  REG_TO_DOZE
  push edx
  push edi
  push edi
  call _DozeRead
  add esp,4
  pop edi
  pop edx

  mov dl,al
  DOZE_TO_REG
  ret

times ($$-$) & 3 db 0

extern _DozeWrite
Write:
  REG_TO_DOZE
  push edx
  push edi
  push edx
  push edi
  call _DozeWrite
  add esp,8
  pop edi
  pop edx

  DOZE_TO_REG
  ret

times ($$-$) & 3 db 0

extern _DozeIn
PortIn:
  REG_TO_DOZE
  push edx
  push edi
  push edi
  call _DozeIn
  add esp,4
  pop edi
  pop edx

  mov dl,al
  DOZE_TO_REG
  ret

times ($$-$) & 3 db 0

extern _DozeOut
PortOut:
  REG_TO_DOZE
  push edx
  push edi
  push edx
  push edi
  call _DozeOut
  add esp,8
  pop edi
  pop edx

  DOZE_TO_REG
  ret

times ($$-$) & 3 db 0

; Call a routine
global _DozeAsmCall
_DozeAsmCall:
  mov ax,word[esp+4] ; Get address
  mov word[Tmp16],ax
  SAVE_REGS
  REG_BLANK
  DOZE_TO_REG
  INC_R
  sub word [DozeSP],2
  mov dx,si
  mov di,word [DozeSP]
  DAM_WRITE16
  mov dx,word[Tmp16]
  mov si,dx
  REG_TO_DOZE
  RESTORE_REGS
  ret

times ($$-$) & 3 db 0

; Read a byte from memory
global _DozeAsmRead
_DozeAsmRead:
  mov ax,word[esp+4] ; Get address
  mov word[Tmp16],ax
  SAVE_REGS
  REG_BLANK
  DOZE_TO_REG
  mov di,word [Tmp16]
  DAM_READ8
  REG_TO_DOZE
  xor eax,eax
  mov al,dl
  RESTORE_REGS
  ret

times ($$-$) & 3 db 0

global _DozeAsmRun
_DozeAsmRun:

  SAVE_REGS
  REG_BLANK
  DOZE_TO_REG
  FETCH_OP ; Fetch first opcode

DozeRunEnd: ; After cycles have run out, we come back here

  REG_TO_DOZE
  RESTORE_REGS
  ret


  ; 00 - nop
;****************************************************************
times ($$-$) & 3 db 0

Op00    : INC_R


  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op01    : INC_R

; Load Immediate 16-bit
  DAM_FETCH16
  add si,2
  mov word [DozeBC],dx

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op02    : INC_R

  ; 02 - ld (bc),a
  ; Get Save address:
  mov di,word [DozeBC]
  mov dl,al
  DAM_WRITE8 ; Save to address

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op03    : INC_R

  inc word [DozeBC]
  ; (With 16-bit inc, flags aren't changed)

  sub dword [_nDozeCycles],6
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op04    : INC_R

  and ah,0x01 ; Keep carry flag
  inc byte [DozeBC+1]
  mov dl,byte [DozeBC+1]
  xor dh,dh
  or ah,byte [IncFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op05    : INC_R

  and ah,0x01 ; Keep carry flag
  dec byte [DozeBC+1]
  mov dl,byte [DozeBC+1]
  xor dh,dh
  or ah,byte [DecFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op06    : INC_R

; Load Value 8-bit
  DAM_FETCH8
  inc si
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op07    : INC_R

  mov dl,al

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  and ah,0xc4 ; ..00 0.00
  or  ah,dh   ; ..00 0.0C

  mov al,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op08    : INC_R

  ; 08 - ex af,af'
  rol ax,8
  mov dx,ax
  mov ax,word [DozeAF2]
  mov word [DozeAF2],dx
  rol ax,8

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op09    : INC_R

  mov bh,ah
  and bh,0xc4 ; Remember SZ---P--
  mov dx,word [DozeBC]
  ror ebx,16 ; Get access to a spare bit of ebx
  mov bx,dx
  mov dx,cx
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  add dl,bl
  adc dh,bh
  lahf
  mov cx,dx
  ror ebx,16 ; Done with ebx
  and ah,0x11 ; ---H---C get flags.
  and dh,0x28
  or  ah,dh   ; --5H3--C
  or  ah,bh

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op0A    : INC_R

  ; 0a - ld a,(bc)
  ; Get Load address:
  mov di,word [DozeBC]
  DAM_READ8 ; Load from address
  mov al,dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op0B    : INC_R

  dec word [DozeBC]
  ; (With 16-bit inc, flags aren't changed)

  sub dword [_nDozeCycles],6
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op0C    : INC_R

  and ah,0x01 ; Keep carry flag
  inc byte [DozeBC]
  mov dl,byte [DozeBC]
  xor dh,dh
  or ah,byte [IncFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op0D    : INC_R

  and ah,0x01 ; Keep carry flag
  dec byte [DozeBC]
  mov dl,byte [DozeBC]
  xor dh,dh
  or ah,byte [DecFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op0E    : INC_R

; Load Value 8-bit
  DAM_FETCH8
  inc si
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op0F    : INC_R

  mov dl,al

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  and ah,0xc4 ; ..00 0.00
  or  ah,dh   ; ..00 0.0C

  mov al,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op10    : INC_R

  inc si
  ; 10 nn - djnz +nn
  mov dl,byte [DozeBC+1]
  dec dl
  jnz BNotZero0
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

BNotZero0:
  mov byte [DozeBC+1],dl
  ; Get Jump offset:
  dec si
  DAM_FETCH8
  inc si
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  add si,dx

  sub dword [_nDozeCycles],13
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op11    : INC_R

; Load Immediate 16-bit
  DAM_FETCH16
  add si,2
  mov word [DozeDE],dx

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op12    : INC_R

  ; 02 - ld (de),a
  ; Get Save address:
  mov di,word [DozeDE]
  mov dl,al
  DAM_WRITE8 ; Save to address

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op13    : INC_R

  inc word [DozeDE]
  ; (With 16-bit inc, flags aren't changed)

  sub dword [_nDozeCycles],6
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op14    : INC_R

  and ah,0x01 ; Keep carry flag
  inc byte [DozeDE+1]
  mov dl,byte [DozeDE+1]
  xor dh,dh
  or ah,byte [IncFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op15    : INC_R

  and ah,0x01 ; Keep carry flag
  dec byte [DozeDE+1]
  mov dl,byte [DozeDE+1]
  xor dh,dh
  or ah,byte [DecFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op16    : INC_R

; Load Value 8-bit
  DAM_FETCH8
  inc si
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op17    : INC_R

  mov dl,al

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  and ah,0xc4 ; ..00 0.00
  or  ah,dh   ; ..00 0.0C

  mov al,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

  ; 18 nn - jr +nn
;****************************************************************
times ($$-$) & 3 db 0

Op18    : INC_R

  ; Get Jump offset:
  DAM_FETCH8
  inc si
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  add si,dx

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op19    : INC_R

  mov bh,ah
  and bh,0xc4 ; Remember SZ---P--
  mov dx,word [DozeDE]
  ror ebx,16 ; Get access to a spare bit of ebx
  mov bx,dx
  mov dx,cx
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  add dl,bl
  adc dh,bh
  lahf
  mov cx,dx
  ror ebx,16 ; Done with ebx
  and ah,0x11 ; ---H---C get flags.
  and dh,0x28
  or  ah,dh   ; --5H3--C
  or  ah,bh

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op1A    : INC_R

  ; 0a - ld a,(de)
  ; Get Load address:
  mov di,word [DozeDE]
  DAM_READ8 ; Load from address
  mov al,dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op1B    : INC_R

  dec word [DozeDE]
  ; (With 16-bit inc, flags aren't changed)

  sub dword [_nDozeCycles],6
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op1C    : INC_R

  and ah,0x01 ; Keep carry flag
  inc byte [DozeDE]
  mov dl,byte [DozeDE]
  xor dh,dh
  or ah,byte [IncFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op1D    : INC_R

  and ah,0x01 ; Keep carry flag
  dec byte [DozeDE]
  mov dl,byte [DozeDE]
  xor dh,dh
  or ah,byte [DecFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op1E    : INC_R

; Load Value 8-bit
  DAM_FETCH8
  inc si
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op1F    : INC_R

  mov dl,al

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  and ah,0xc4 ; ..00 0.00
  or  ah,dh   ; ..00 0.0C

  mov al,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op20    : INC_R

  inc si
  sahf ; Get flags so we can test for the condition
  jz ConditionFalse0
  ; Get Jump offset:
  dec si
  DAM_FETCH8
  inc si
  xor dl,0x80
  xor dh,dh
  sub dx,0x80
  add si,dx

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

ConditionFalse0:

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op21    : INC_R

; Load Immediate 16-bit
  DAM_FETCH16
  add si,2
  mov cx,dx

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op22    : INC_R

; Direct access to a memory location
  DAM_FETCH16
  add si,2
  mov di,dx
  mov dx,cx
  DAM_WRITE16

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op23    : INC_R

  inc cx
  ; (With 16-bit inc, flags aren't changed)

  sub dword [_nDozeCycles],6
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op24    : INC_R

  and ah,0x01 ; Keep carry flag
  inc ch
  mov dl,ch
  xor dh,dh
  or ah,byte [IncFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op25    : INC_R

  and ah,0x01 ; Keep carry flag
  dec ch
  mov dl,ch
  xor dh,dh
  or ah,byte [DecFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op26    : INC_R

; Load Value 8-bit
  DAM_FETCH8
  inc si
  mov ch,dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op27    : INC_R

  ; 27 - daa
  mov dh,ah
  ror dh,2   ;H-- ---- ----
  and dx,0x400
  and ax,0x3ff
  or  dx,ax ; HNC nnnn nnnn
  mov ax,word[DaaTable+edx*2] ; Get flags and value in one go

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op28    : INC_R

  inc si
  sahf ; Get flags so we can test for the condition
  jnz ConditionFalse1
  ; Get Jump offset:
  dec si
  DAM_FETCH8
  inc si
  xor dl,0x80
  xor dh,dh
  sub dx,0x80
  add si,dx

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

ConditionFalse1:

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op29    : INC_R

  mov bh,ah
  and bh,0xc4 ; Remember SZ---P--
  mov dx,cx
  ror ebx,16 ; Get access to a spare bit of ebx
  mov bx,dx
  mov dx,cx
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  add dl,bl
  adc dh,bh
  lahf
  mov cx,dx
  ror ebx,16 ; Done with ebx
  and ah,0x11 ; ---H---C get flags.
  and dh,0x28
  or  ah,dh   ; --5H3--C
  or  ah,bh

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op2A    : INC_R

; Direct access to a memory location
  DAM_FETCH16
  add si,2
  mov di,dx
  DAM_READ16
  mov cx,dx

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op2B    : INC_R

  dec cx
  ; (With 16-bit inc, flags aren't changed)

  sub dword [_nDozeCycles],6
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op2C    : INC_R

  and ah,0x01 ; Keep carry flag
  inc cl
  mov dl,cl
  xor dh,dh
  or ah,byte [IncFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op2D    : INC_R

  and ah,0x01 ; Keep carry flag
  dec cl
  mov dl,cl
  xor dh,dh
  or ah,byte [DecFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op2E    : INC_R

; Load Value 8-bit
  DAM_FETCH8
  inc si
  mov cl,dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op2F    : INC_R

  ; 2f - cpl
  and ah,0xc5 ; SZ-- -P-C
  not al
  or  ah,0x12 ; SZ-H -PNC
  mov dh,al
  and dh,0x28
  or  ah,dh   ; SZ5H 3PNC

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op30    : INC_R

  inc si
  sahf ; Get flags so we can test for the condition
  jc ConditionFalse2
  ; Get Jump offset:
  dec si
  DAM_FETCH8
  inc si
  xor dl,0x80
  xor dh,dh
  sub dx,0x80
  add si,dx

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

ConditionFalse2:

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op31    : INC_R

; Load Immediate 16-bit
  DAM_FETCH16
  add si,2
  mov word [DozeSP],dx

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op32    : INC_R

  ; 32 nn nn - ld ($nnnn),a
  ; Get Save address:
  DAM_FETCH16
  add si,2
  mov di,dx
  mov dl,al
  DAM_WRITE8 ; Save to address

  sub dword [_nDozeCycles],13
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op33    : INC_R

  inc word [DozeSP]
  ; (With 16-bit inc, flags aren't changed)

  sub dword [_nDozeCycles],6
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op34    : INC_R

  mov di,cx
; Takes more cycles from memory
  and ah,0x01 ; Keep carry flag
  DAM_READ8
  inc dl
  DAM_WRITE8
  xor dh,dh
  or ah,byte [IncFlag+edx]

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op35    : INC_R

  mov di,cx
; Takes more cycles from memory
  and ah,0x01 ; Keep carry flag
  DAM_READ8
  dec dl
  DAM_WRITE8
  xor dh,dh
  or ah,byte [DecFlag+edx]

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op36    : INC_R

; Load Value 8-bit
  DAM_FETCH8
  inc si
  mov di,cx
  DAM_WRITE8

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op37    : INC_R

  ; 37 - scf - set carry flag
  and ah,0xc4
  or  ah,0x01

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op38    : INC_R

  inc si
  sahf ; Get flags so we can test for the condition
  jnc ConditionFalse3
  ; Get Jump offset:
  dec si
  DAM_FETCH8
  inc si
  xor dl,0x80
  xor dh,dh
  sub dx,0x80
  add si,dx

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

ConditionFalse3:

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op39    : INC_R

  mov bh,ah
  and bh,0xc4 ; Remember SZ---P--
  mov dx,word [DozeSP]
  ror ebx,16 ; Get access to a spare bit of ebx
  mov bx,dx
  mov dx,cx
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  add dl,bl
  adc dh,bh
  lahf
  mov cx,dx
  ror ebx,16 ; Done with ebx
  and ah,0x11 ; ---H---C get flags.
  and dh,0x28
  or  ah,dh   ; --5H3--C
  or  ah,bh

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op3A    : INC_R

  ; 3a nn nn - ld a,($nnnn)
  ; Get Load address:
  DAM_FETCH16
  add si,2
  mov di,dx
  DAM_READ8 ; Load from address
  mov al,dl

  sub dword [_nDozeCycles],13
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op3B    : INC_R

  dec word [DozeSP]
  ; (With 16-bit inc, flags aren't changed)

  sub dword [_nDozeCycles],6
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op3C    : INC_R

  and ah,0x01 ; Keep carry flag
  inc al
  mov dl,al
  xor dh,dh
  or ah,byte [IncFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op3D    : INC_R

  and ah,0x01 ; Keep carry flag
  dec al
  mov dl,al
  xor dh,dh
  or ah,byte [DecFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op3E    : INC_R

; Load Value 8-bit
  DAM_FETCH8
  inc si
  mov al,dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op3F    : INC_R

  ; 3f - ccf - complement carry flag
  mov dh,ah
  and ah,0xc5
  rol dh,4
  xor ah,0x01
  and dh,0x10
  or  ah,dh ; H is last Carry value

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op40    : INC_R

; Load 8-bit

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op41    : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeBC]
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op42    : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeDE+1]
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op43    : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeDE]
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op44    : INC_R

; Load 8-bit
  mov byte [DozeBC+1],ch

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op45    : INC_R

; Load 8-bit
  mov byte [DozeBC+1],cl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op46    : INC_R

; Load 8-bit
  mov di,cx
; Copy to dl, then to destination
  DAM_READ8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op47    : INC_R

; Load 8-bit
  mov byte [DozeBC+1],al

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op48    : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeBC+1]
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op49    : INC_R

; Load 8-bit

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op4A    : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeDE+1]
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op4B    : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeDE]
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op4C    : INC_R

; Load 8-bit
  mov byte [DozeBC],ch

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op4D    : INC_R

; Load 8-bit
  mov byte [DozeBC],cl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op4E    : INC_R

; Load 8-bit
  mov di,cx
; Copy to dl, then to destination
  DAM_READ8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op4F    : INC_R

; Load 8-bit
  mov byte [DozeBC],al

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op50    : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeBC+1]
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op51    : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeBC]
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op52    : INC_R

; Load 8-bit

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op53    : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeDE]
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op54    : INC_R

; Load 8-bit
  mov byte [DozeDE+1],ch

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op55    : INC_R

; Load 8-bit
  mov byte [DozeDE+1],cl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op56    : INC_R

; Load 8-bit
  mov di,cx
; Copy to dl, then to destination
  DAM_READ8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op57    : INC_R

; Load 8-bit
  mov byte [DozeDE+1],al

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op58    : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeBC+1]
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op59    : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeBC]
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op5A    : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeDE+1]
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op5B    : INC_R

; Load 8-bit

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op5C    : INC_R

; Load 8-bit
  mov byte [DozeDE],ch

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op5D    : INC_R

; Load 8-bit
  mov byte [DozeDE],cl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op5E    : INC_R

; Load 8-bit
  mov di,cx
; Copy to dl, then to destination
  DAM_READ8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op5F    : INC_R

; Load 8-bit
  mov byte [DozeDE],al

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op60    : INC_R

; Load 8-bit
  mov ch,byte [DozeBC+1]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op61    : INC_R

; Load 8-bit
  mov ch,byte [DozeBC]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op62    : INC_R

; Load 8-bit
  mov ch,byte [DozeDE+1]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op63    : INC_R

; Load 8-bit
  mov ch,byte [DozeDE]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op64    : INC_R

; Load 8-bit

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op65    : INC_R

; Load 8-bit
  mov ch,cl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op66    : INC_R

; Load 8-bit
  mov di,cx
; Copy to dl, then to destination
  DAM_READ8
  mov ch,dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op67    : INC_R

; Load 8-bit
  mov ch,al

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op68    : INC_R

; Load 8-bit
  mov cl,byte [DozeBC+1]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op69    : INC_R

; Load 8-bit
  mov cl,byte [DozeBC]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op6A    : INC_R

; Load 8-bit
  mov cl,byte [DozeDE+1]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op6B    : INC_R

; Load 8-bit
  mov cl,byte [DozeDE]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op6C    : INC_R

; Load 8-bit
  mov cl,ch

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op6D    : INC_R

; Load 8-bit

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op6E    : INC_R

; Load 8-bit
  mov di,cx
; Copy to dl, then to destination
  DAM_READ8
  mov cl,dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op6F    : INC_R

; Load 8-bit
  mov cl,al

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op70    : INC_R

; Load 8-bit
  mov di,cx
; Copy to dl, then to destination
  mov dl,byte [DozeBC+1]
  DAM_WRITE8

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op71    : INC_R

; Load 8-bit
  mov di,cx
; Copy to dl, then to destination
  mov dl,byte [DozeBC]
  DAM_WRITE8

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op72    : INC_R

; Load 8-bit
  mov di,cx
; Copy to dl, then to destination
  mov dl,byte [DozeDE+1]
  DAM_WRITE8

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op73    : INC_R

; Load 8-bit
  mov di,cx
; Copy to dl, then to destination
  mov dl,byte [DozeDE]
  DAM_WRITE8

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op74    : INC_R

; Load 8-bit
  mov di,cx
; Copy to dl, then to destination
  mov dl,ch
  DAM_WRITE8

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op75    : INC_R

; Load 8-bit
  mov di,cx
; Copy to dl, then to destination
  mov dl,cl
  DAM_WRITE8

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

  ; 76 - halt
;****************************************************************
times ($$-$) & 3 db 0

Op76    : INC_R

  ; Reduce cycle counter to 1,2,3 or 4
  dec si ; Stay on halt instruction
  and dword [_nDozeCycles],3
  ; todo - add R counter by cycles/4

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op77    : INC_R

; Load 8-bit
  mov di,cx
; Copy to dl, then to destination
  mov dl,al
  DAM_WRITE8

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op78    : INC_R

; Load 8-bit
  mov al,byte [DozeBC+1]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op79    : INC_R

; Load 8-bit
  mov al,byte [DozeBC]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op7A    : INC_R

; Load 8-bit
  mov al,byte [DozeDE+1]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op7B    : INC_R

; Load 8-bit
  mov al,byte [DozeDE]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op7C    : INC_R

; Load 8-bit
  mov al,ch

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op7D    : INC_R

; Load 8-bit
  mov al,cl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op7E    : INC_R

; Load 8-bit
  mov di,cx
; Copy to dl, then to destination
  DAM_READ8
  mov al,dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op7F    : INC_R

; Load 8-bit

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op80    : INC_R

  ; Arithmetic
  mov dl,byte [DozeBC+1]
  xor ah,ah ; Start with blank flags
  add al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op81    : INC_R

  ; Arithmetic
  mov dl,byte [DozeBC]
  xor ah,ah ; Start with blank flags
  add al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op82    : INC_R

  ; Arithmetic
  mov dl,byte [DozeDE+1]
  xor ah,ah ; Start with blank flags
  add al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op83    : INC_R

  ; Arithmetic
  mov dl,byte [DozeDE]
  xor ah,ah ; Start with blank flags
  add al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op84    : INC_R

  ; Arithmetic
  mov dl,ch
  xor ah,ah ; Start with blank flags
  add al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op85    : INC_R

  ; Arithmetic
  mov dl,cl
  xor ah,ah ; Start with blank flags
  add al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op86    : INC_R

  ; Arithmetic
  mov di,cx
  DAM_READ8
  xor ah,ah ; Start with blank flags
  add al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op87    : INC_R

  ; Arithmetic
  mov dl,al
  xor ah,ah ; Start with blank flags
  add al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op88    : INC_R

  ; Arithmetic
  mov dl,byte [DozeBC+1]
  sahf ; Get the carry flag
  adc al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op89    : INC_R

  ; Arithmetic
  mov dl,byte [DozeBC]
  sahf ; Get the carry flag
  adc al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op8A    : INC_R

  ; Arithmetic
  mov dl,byte [DozeDE+1]
  sahf ; Get the carry flag
  adc al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op8B    : INC_R

  ; Arithmetic
  mov dl,byte [DozeDE]
  sahf ; Get the carry flag
  adc al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op8C    : INC_R

  ; Arithmetic
  mov dl,ch
  sahf ; Get the carry flag
  adc al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op8D    : INC_R

  ; Arithmetic
  mov dl,cl
  sahf ; Get the carry flag
  adc al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op8E    : INC_R

  ; Arithmetic
  mov di,cx
  DAM_READ8
  sahf ; Get the carry flag
  adc al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op8F    : INC_R

  ; Arithmetic
  mov dl,al
  sahf ; Get the carry flag
  adc al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op90    : INC_R

  ; Arithmetic
  mov dl,byte [DozeBC+1]
  xor ah,ah ; Start with blank flags
  sub al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op91    : INC_R

  ; Arithmetic
  mov dl,byte [DozeBC]
  xor ah,ah ; Start with blank flags
  sub al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op92    : INC_R

  ; Arithmetic
  mov dl,byte [DozeDE+1]
  xor ah,ah ; Start with blank flags
  sub al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op93    : INC_R

  ; Arithmetic
  mov dl,byte [DozeDE]
  xor ah,ah ; Start with blank flags
  sub al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op94    : INC_R

  ; Arithmetic
  mov dl,ch
  xor ah,ah ; Start with blank flags
  sub al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op95    : INC_R

  ; Arithmetic
  mov dl,cl
  xor ah,ah ; Start with blank flags
  sub al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op96    : INC_R

  ; Arithmetic
  mov di,cx
  DAM_READ8
  xor ah,ah ; Start with blank flags
  sub al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op97    : INC_R

  ; Arithmetic
  mov dl,al
  xor ah,ah ; Start with blank flags
  sub al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op98    : INC_R

  ; Arithmetic
  mov dl,byte [DozeBC+1]
  sahf ; Get the carry flag
  sbb al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op99    : INC_R

  ; Arithmetic
  mov dl,byte [DozeBC]
  sahf ; Get the carry flag
  sbb al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op9A    : INC_R

  ; Arithmetic
  mov dl,byte [DozeDE+1]
  sahf ; Get the carry flag
  sbb al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op9B    : INC_R

  ; Arithmetic
  mov dl,byte [DozeDE]
  sahf ; Get the carry flag
  sbb al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op9C    : INC_R

  ; Arithmetic
  mov dl,ch
  sahf ; Get the carry flag
  sbb al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op9D    : INC_R

  ; Arithmetic
  mov dl,cl
  sahf ; Get the carry flag
  sbb al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op9E    : INC_R

  ; Arithmetic
  mov di,cx
  DAM_READ8
  sahf ; Get the carry flag
  sbb al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

Op9F    : INC_R

  ; Arithmetic
  mov dl,al
  sahf ; Get the carry flag
  sbb al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpA0    : INC_R

  ; Arithmetic
  mov dl,byte [DozeBC+1]
  xor ah,ah ; Start with blank flags
  and al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x10 ; Set bit 4 to 1 (AND operation)

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpA1    : INC_R

  ; Arithmetic
  mov dl,byte [DozeBC]
  xor ah,ah ; Start with blank flags
  and al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x10 ; Set bit 4 to 1 (AND operation)

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpA2    : INC_R

  ; Arithmetic
  mov dl,byte [DozeDE+1]
  xor ah,ah ; Start with blank flags
  and al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x10 ; Set bit 4 to 1 (AND operation)

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpA3    : INC_R

  ; Arithmetic
  mov dl,byte [DozeDE]
  xor ah,ah ; Start with blank flags
  and al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x10 ; Set bit 4 to 1 (AND operation)

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpA4    : INC_R

  ; Arithmetic
  mov dl,ch
  xor ah,ah ; Start with blank flags
  and al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x10 ; Set bit 4 to 1 (AND operation)

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpA5    : INC_R

  ; Arithmetic
  mov dl,cl
  xor ah,ah ; Start with blank flags
  and al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x10 ; Set bit 4 to 1 (AND operation)

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpA6    : INC_R

  ; Arithmetic
  mov di,cx
  DAM_READ8
  xor ah,ah ; Start with blank flags
  and al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x10 ; Set bit 4 to 1 (AND operation)

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpA7    : INC_R

  ; Arithmetic
  mov dl,al
  xor ah,ah ; Start with blank flags
  and al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x10 ; Set bit 4 to 1 (AND operation)

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpA8    : INC_R

  ; Arithmetic
  mov dl,byte [DozeBC+1]
  xor ah,ah ; Start with blank flags
  xor al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpA9    : INC_R

  ; Arithmetic
  mov dl,byte [DozeBC]
  xor ah,ah ; Start with blank flags
  xor al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpAA    : INC_R

  ; Arithmetic
  mov dl,byte [DozeDE+1]
  xor ah,ah ; Start with blank flags
  xor al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpAB    : INC_R

  ; Arithmetic
  mov dl,byte [DozeDE]
  xor ah,ah ; Start with blank flags
  xor al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpAC    : INC_R

  ; Arithmetic
  mov dl,ch
  xor ah,ah ; Start with blank flags
  xor al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpAD    : INC_R

  ; Arithmetic
  mov dl,cl
  xor ah,ah ; Start with blank flags
  xor al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpAE    : INC_R

  ; Arithmetic
  mov di,cx
  DAM_READ8
  xor ah,ah ; Start with blank flags
  xor al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpAF    : INC_R

  ; Arithmetic
  mov dl,al
  xor ah,ah ; Start with blank flags
  xor al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpB0    : INC_R

  ; Arithmetic
  mov dl,byte [DozeBC+1]
  xor ah,ah ; Start with blank flags
  or al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpB1    : INC_R

  ; Arithmetic
  mov dl,byte [DozeBC]
  xor ah,ah ; Start with blank flags
  or al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpB2    : INC_R

  ; Arithmetic
  mov dl,byte [DozeDE+1]
  xor ah,ah ; Start with blank flags
  or al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpB3    : INC_R

  ; Arithmetic
  mov dl,byte [DozeDE]
  xor ah,ah ; Start with blank flags
  or al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpB4    : INC_R

  ; Arithmetic
  mov dl,ch
  xor ah,ah ; Start with blank flags
  or al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpB5    : INC_R

  ; Arithmetic
  mov dl,cl
  xor ah,ah ; Start with blank flags
  or al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpB6    : INC_R

  ; Arithmetic
  mov di,cx
  DAM_READ8
  xor ah,ah ; Start with blank flags
  or al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpB7    : INC_R

  ; Arithmetic
  mov dl,al
  xor ah,ah ; Start with blank flags
  or al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpB8    : INC_R

  ; Arithmetic
  mov dl,byte [DozeBC+1]
  xor ah,ah ; Start with blank flags
  cmp al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,dl
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpB9    : INC_R

  ; Arithmetic
  mov dl,byte [DozeBC]
  xor ah,ah ; Start with blank flags
  cmp al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,dl
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpBA    : INC_R

  ; Arithmetic
  mov dl,byte [DozeDE+1]
  xor ah,ah ; Start with blank flags
  cmp al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,dl
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpBB    : INC_R

  ; Arithmetic
  mov dl,byte [DozeDE]
  xor ah,ah ; Start with blank flags
  cmp al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,dl
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpBC    : INC_R

  ; Arithmetic
  mov dl,ch
  xor ah,ah ; Start with blank flags
  cmp al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,dl
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpBD    : INC_R

  ; Arithmetic
  mov dl,cl
  xor ah,ah ; Start with blank flags
  cmp al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,dl
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpBE    : INC_R

  ; Arithmetic
  mov di,cx
  DAM_READ8
  xor ah,ah ; Start with blank flags
  cmp al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,dl
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpBF    : INC_R

  ; Arithmetic
  mov dl,al
  xor ah,ah ; Start with blank flags
  cmp al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,dl
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpC0    : INC_R

  test ah,0x40
  jz DoRet0

  sub dword [_nDozeCycles],5
  jle near DozeRunEnd
  FETCH_OP

DoRet0:
  mov di,word [DozeSP]
  DAM_READ16
  mov si,dx
  add word [DozeSP],2

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpC1    : INC_R

  mov di,word [DozeSP]
  DAM_READ16
  mov word [DozeBC],dx
  add word [DozeSP],2

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpC2    : INC_R

  add si,2
  test ah,0x40
  jz DoJump0

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

DoJump0:
  sub si,2
  DAM_FETCH16
  add si,2
  mov si,dx

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpC3    : INC_R

  ; c3 nn nn - jp $nnnn
  DAM_FETCH16
  mov si,dx

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpC4    : INC_R

  add si,2
  test ah,0x40
  jz DoCall0

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

DoCall0:
  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,si
  DAM_WRITE16
  sub si,2
  DAM_FETCH16
  add si,2
  mov si,dx

  sub dword [_nDozeCycles],17
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpC5    : INC_R

  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,word [DozeBC]
  DAM_WRITE16

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpC6    : INC_R

  ; Arithmetic (Immediate value)
  ; Get value:
  DAM_FETCH8
  inc si
  xor ah,ah ; Start with blank flags
  add al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpC7    : INC_R

  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,si
  DAM_WRITE16
  mov si,0x00

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpC8    : INC_R

  test ah,0x40
  jnz DoRet1

  sub dword [_nDozeCycles],5
  jle near DozeRunEnd
  FETCH_OP

DoRet1:
  mov di,word [DozeSP]
  DAM_READ16
  mov si,dx
  add word [DozeSP],2

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpC9    : INC_R

  ; c9 - ret
  mov di,word [DozeSP]
  DAM_READ16
  mov si,dx
  add word [DozeSP],2

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCA    : INC_R

  add si,2
  test ah,0x40
  jnz DoJump1

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

DoJump1:
  sub si,2
  DAM_FETCH16
  add si,2
  mov si,dx

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB    : INC_R

  ; cb - extend opcode, take 4 cycles

  sub dword [_nDozeCycles],4
  DAM_FETCH8
  inc si
  xor dh,dh
  jmp [JumpTabCB+edx*4]

;****************************************************************
times ($$-$) & 3 db 0

OpCC    : INC_R

  add si,2
  test ah,0x40
  jnz DoCall1

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

DoCall1:
  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,si
  DAM_WRITE16
  sub si,2
  DAM_FETCH16
  add si,2
  mov si,dx

  sub dword [_nDozeCycles],17
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCD    : INC_R

  ; cd nn nn - call $nnnn
  sub word [DozeSP],2
  mov di,word [DozeSP]
  add si,2
  mov dx,si
  DAM_WRITE16
  sub si,2
  DAM_FETCH16
  add si,2
  mov si,dx

  sub dword [_nDozeCycles],17
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCE    : INC_R

  ; Arithmetic (Immediate value)
  ; Get value:
  DAM_FETCH8
  inc si
  sahf ; Get the carry flag
  adc al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCF    : INC_R

  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,si
  DAM_WRITE16
  mov si,0x08

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpD0    : INC_R

  test ah,0x01
  jz DoRet2

  sub dword [_nDozeCycles],5
  jle near DozeRunEnd
  FETCH_OP

DoRet2:
  mov di,word [DozeSP]
  DAM_READ16
  mov si,dx
  add word [DozeSP],2

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpD1    : INC_R

  mov di,word [DozeSP]
  DAM_READ16
  mov word [DozeDE],dx
  add word [DozeSP],2

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpD2    : INC_R

  add si,2
  test ah,0x01
  jz DoJump2

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

DoJump2:
  sub si,2
  DAM_FETCH16
  add si,2
  mov si,dx

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpD3    : INC_R

  ; d3 nn - out ($nn),a
  DAM_FETCH8
  inc si
  mov dh,al ; Fill high port byte with a
  mov di,dx
  mov dl,al
  call PortOut ; Write port dl --> di

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpD4    : INC_R

  add si,2
  test ah,0x01
  jz DoCall2

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

DoCall2:
  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,si
  DAM_WRITE16
  sub si,2
  DAM_FETCH16
  add si,2
  mov si,dx

  sub dword [_nDozeCycles],17
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpD5    : INC_R

  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,word [DozeDE]
  DAM_WRITE16

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpD6    : INC_R

  ; Arithmetic (Immediate value)
  ; Get value:
  DAM_FETCH8
  inc si
  xor ah,ah ; Start with blank flags
  sub al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpD7    : INC_R

  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,si
  DAM_WRITE16
  mov si,0x10

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpD8    : INC_R

  test ah,0x01
  jnz DoRet3

  sub dword [_nDozeCycles],5
  jle near DozeRunEnd
  FETCH_OP

DoRet3:
  mov di,word [DozeSP]
  DAM_READ16
  mov si,dx
  add word [DozeSP],2

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpD9    : INC_R

  ; exx - flip registers BC,DE and HL with prime registers
  mov dx,word [DozeBC]
  mov di,word[DozeBC2]
  mov word[DozeBC2],dx
  mov word [DozeBC],di
  mov dx,word [DozeDE]
  mov di,word[DozeDE2]
  mov word[DozeDE2],dx
  mov word [DozeDE],di
  mov dx,cx
  mov di,word[DozeHL2]
  mov word[DozeHL2],dx
  mov cx,di

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDA    : INC_R

  add si,2
  test ah,0x01
  jnz DoJump3

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

DoJump3:
  sub si,2
  DAM_FETCH16
  add si,2
  mov si,dx

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDB    : INC_R

  ; db nn - in a,($nn)
  DAM_FETCH8
  inc si
  mov dh,al ; Fill high port byte with a
  mov di,dx
  call PortIn ; Read port dl <-- di
  mov al,dl

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDC    : INC_R

  add si,2
  test ah,0x01
  jnz DoCall3

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

DoCall3:
  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,si
  DAM_WRITE16
  sub si,2
  DAM_FETCH16
  add si,2
  mov si,dx

  sub dword [_nDozeCycles],17
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD    : INC_R

  ; dd - extend opcode, take 4 cycles

  sub dword [_nDozeCycles],4
  DAM_FETCH8
  inc si
  xor dh,dh
  jmp [JumpTabDD+edx*4]

;****************************************************************
times ($$-$) & 3 db 0

OpDE    : INC_R

  ; Arithmetic (Immediate value)
  ; Get value:
  DAM_FETCH8
  inc si
  sahf ; Get the carry flag
  sbb al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDF    : INC_R

  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,si
  DAM_WRITE16
  mov si,0x18

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpE0    : INC_R

  test ah,0x04
  jz DoRet4

  sub dword [_nDozeCycles],5
  jle near DozeRunEnd
  FETCH_OP

DoRet4:
  mov di,word [DozeSP]
  DAM_READ16
  mov si,dx
  add word [DozeSP],2

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpE1    : INC_R

  mov di,word [DozeSP]
  DAM_READ16
  mov cx,dx
  add word [DozeSP],2

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpE2    : INC_R

  add si,2
  test ah,0x04
  jz DoJump4

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

DoJump4:
  sub si,2
  DAM_FETCH16
  add si,2
  mov si,dx

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpE3    : INC_R

  ; Find the memory location:
  mov di,word [DozeSP]
  ; Swap HL with it:
  DAM_READ16
  mov word [Tmp16],dx
  mov dx,cx
  DAM_WRITE16
  mov dx,word [Tmp16]
  mov cx,dx

  sub dword [_nDozeCycles],19
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpE4    : INC_R

  add si,2
  test ah,0x04
  jz DoCall4

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

DoCall4:
  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,si
  DAM_WRITE16
  sub si,2
  DAM_FETCH16
  add si,2
  mov si,dx

  sub dword [_nDozeCycles],17
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpE5    : INC_R

  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,cx
  DAM_WRITE16

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpE6    : INC_R

  ; Arithmetic (Immediate value)
  ; Get value:
  DAM_FETCH8
  inc si
  xor ah,ah ; Start with blank flags
  and al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x10 ; Set bit 4 to 1 (AND operation)

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpE7    : INC_R

  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,si
  DAM_WRITE16
  mov si,0x20

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpE8    : INC_R

  test ah,0x04
  jnz DoRet5

  sub dword [_nDozeCycles],5
  jle near DozeRunEnd
  FETCH_OP

DoRet5:
  mov di,word [DozeSP]
  DAM_READ16
  mov si,dx
  add word [DozeSP],2

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpE9    : INC_R

  ; e9 - jp (hl) - PC <- HL/IX/IY
  mov dx,cx
  mov si,dx

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEA    : INC_R

  add si,2
  test ah,0x04
  jnz DoJump5

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

DoJump5:
  sub si,2
  DAM_FETCH16
  add si,2
  mov si,dx

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEB    : INC_R

  ; ex de,hl  (DE <==> HL)
  mov dx,word [DozeDE]
  mov di,cx
  mov cx,dx
  mov word [DozeDE],di

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEC    : INC_R

  add si,2
  test ah,0x04
  jnz DoCall5

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

DoCall5:
  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,si
  DAM_WRITE16
  sub si,2
  DAM_FETCH16
  add si,2
  mov si,dx

  sub dword [_nDozeCycles],17
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED    : INC_R

  ; ed - extend opcode, take 4 cycles

  sub dword [_nDozeCycles],4
  DAM_FETCH8
  inc si
  xor dh,dh
  jmp [JumpTabED+edx*4]

;****************************************************************
times ($$-$) & 3 db 0

OpEE    : INC_R

  ; Arithmetic (Immediate value)
  ; Get value:
  DAM_FETCH8
  inc si
  xor ah,ah ; Start with blank flags
  xor al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEF    : INC_R

  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,si
  DAM_WRITE16
  mov si,0x28

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpF0    : INC_R

  test ah,0x80
  jz DoRet6

  sub dword [_nDozeCycles],5
  jle near DozeRunEnd
  FETCH_OP

DoRet6:
  mov di,word [DozeSP]
  DAM_READ16
  mov si,dx
  add word [DozeSP],2

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpF1    : INC_R

  mov di,word [DozeSP]
  DAM_READ16
  mov ax,dx
  ror ax,8
  add word [DozeSP],2

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpF2    : INC_R

  add si,2
  test ah,0x80
  jz DoJump6

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

DoJump6:
  sub si,2
  DAM_FETCH16
  add si,2
  mov si,dx

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpF3    : INC_R

  ; di - Disable Interrupts
  mov word [DozeIFF],0x0000

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpF4    : INC_R

  add si,2
  test ah,0x80
  jz DoCall6

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

DoCall6:
  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,si
  DAM_WRITE16
  sub si,2
  DAM_FETCH16
  add si,2
  mov si,dx

  sub dword [_nDozeCycles],17
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpF5    : INC_R

  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,ax
  ror dx,8
  DAM_WRITE16

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpF6    : INC_R

  ; Arithmetic (Immediate value)
  ; Get value:
  DAM_FETCH8
  inc si
  xor ah,ah ; Start with blank flags
  or al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpF7    : INC_R

  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,si
  DAM_WRITE16
  mov si,0x30

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpF8    : INC_R

  test ah,0x80
  jnz DoRet7

  sub dword [_nDozeCycles],5
  jle near DozeRunEnd
  FETCH_OP

DoRet7:
  mov di,word [DozeSP]
  DAM_READ16
  mov si,dx
  add word [DozeSP],2

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

  ; f9 - ld sp,HL/IX/IY
;****************************************************************
times ($$-$) & 3 db 0

OpF9    : INC_R

  mov dx,cx
  mov word [DozeSP],dx

  sub dword [_nDozeCycles],6
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFA    : INC_R

  add si,2
  test ah,0x80
  jnz DoJump7

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

DoJump7:
  sub si,2
  DAM_FETCH16
  add si,2
  mov si,dx

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFB    : INC_R

  ; ei - Enable Interrupts
  ; See if we need to quit after enabling interrupts
  test word [_nDozeEi],1
  jz EiContinue
  cmp word [DozeIFF],0x0101
  jz EiContinue ; Interrupts are already enabled
  ; Yes: need to quit now
  mov word [DozeIFF],0x0101
  mov word [_nDozeEi],2
  sub dword [_nDozeCycles],4
  jmp DozeRunEnd

EiContinue:
  mov word [DozeIFF],0x0101
  sub dword [_nDozeCycles],4
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFC    : INC_R

  add si,2
  test ah,0x80
  jnz DoCall7

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

DoCall7:
  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,si
  DAM_WRITE16
  sub si,2
  DAM_FETCH16
  add si,2
  mov si,dx

  sub dword [_nDozeCycles],17
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD    : INC_R

  ; fd - extend opcode, take 4 cycles

  sub dword [_nDozeCycles],4
  DAM_FETCH8
  inc si
  xor dh,dh
  jmp [JumpTabFD+edx*4]
;****************************************************************
times ($$-$) & 3 db 0

OpFE    : INC_R

  ; Arithmetic (Immediate value)
  ; Get value:
  DAM_FETCH8
  inc si
  xor ah,ah ; Start with blank flags
  cmp al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,dl
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFF    : INC_R

  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,si
  DAM_WRITE16
  mov si,0x38

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB00  : INC_R

  mov dl,byte [DozeBC+1]

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB01  : INC_R

  mov dl,byte [DozeBC]

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB02  : INC_R

  mov dl,byte [DozeDE+1]

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB03  : INC_R

  mov dl,byte [DozeDE]

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB04  : INC_R

  mov dl,ch

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov ch,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB05  : INC_R

  mov dl,cl

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov cl,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB06  : INC_R

  mov di,cx
  DAM_READ8

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB07  : INC_R

  mov dl,al

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov al,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB08  : INC_R

  mov dl,byte [DozeBC+1]

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB09  : INC_R

  mov dl,byte [DozeBC]

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB0A  : INC_R

  mov dl,byte [DozeDE+1]

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB0B  : INC_R

  mov dl,byte [DozeDE]

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB0C  : INC_R

  mov dl,ch

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov ch,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB0D  : INC_R

  mov dl,cl

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov cl,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB0E  : INC_R

  mov di,cx
  DAM_READ8

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB0F  : INC_R

  mov dl,al

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov al,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB10  : INC_R

  mov dl,byte [DozeBC+1]

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB11  : INC_R

  mov dl,byte [DozeBC]

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB12  : INC_R

  mov dl,byte [DozeDE+1]

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB13  : INC_R

  mov dl,byte [DozeDE]

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB14  : INC_R

  mov dl,ch

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov ch,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB15  : INC_R

  mov dl,cl

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov cl,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB16  : INC_R

  mov di,cx
  DAM_READ8

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB17  : INC_R

  mov dl,al

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov al,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB18  : INC_R

  mov dl,byte [DozeBC+1]

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB19  : INC_R

  mov dl,byte [DozeBC]

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB1A  : INC_R

  mov dl,byte [DozeDE+1]

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB1B  : INC_R

  mov dl,byte [DozeDE]

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB1C  : INC_R

  mov dl,ch

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov ch,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB1D  : INC_R

  mov dl,cl

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov cl,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB1E  : INC_R

  mov di,cx
  DAM_READ8

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB1F  : INC_R

  mov dl,al

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov al,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB20  : INC_R

  mov dl,byte [DozeBC+1]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB21  : INC_R

  mov dl,byte [DozeBC]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB22  : INC_R

  mov dl,byte [DozeDE+1]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB23  : INC_R

  mov dl,byte [DozeDE]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB24  : INC_R

  mov dl,ch

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov ch,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB25  : INC_R

  mov dl,cl

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov cl,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB26  : INC_R

  mov di,cx
  DAM_READ8

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB27  : INC_R

  mov dl,al

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov al,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB28  : INC_R

  mov dl,byte [DozeBC+1]

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB29  : INC_R

  mov dl,byte [DozeBC]

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB2A  : INC_R

  mov dl,byte [DozeDE+1]

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB2B  : INC_R

  mov dl,byte [DozeDE]

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB2C  : INC_R

  mov dl,ch

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov ch,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB2D  : INC_R

  mov dl,cl

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov cl,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB2E  : INC_R

  mov di,cx
  DAM_READ8

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB2F  : INC_R

  mov dl,al

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov al,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB30  : INC_R

  mov dl,byte [DozeBC+1]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB31  : INC_R

  mov dl,byte [DozeBC]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB32  : INC_R

  mov dl,byte [DozeDE+1]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB33  : INC_R

  mov dl,byte [DozeDE]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB34  : INC_R

  mov dl,ch

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov ch,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB35  : INC_R

  mov dl,cl

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov cl,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB36  : INC_R

  mov di,cx
  DAM_READ8

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB37  : INC_R

  mov dl,al

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov al,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB38  : INC_R

  mov dl,byte [DozeBC+1]

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB39  : INC_R

  mov dl,byte [DozeBC]

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB3A  : INC_R

  mov dl,byte [DozeDE+1]

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB3B  : INC_R

  mov dl,byte [DozeDE]

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB3C  : INC_R

  mov dl,ch

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov ch,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB3D  : INC_R

  mov dl,cl

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov cl,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB3E  : INC_R

  mov di,cx
  DAM_READ8

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB3F  : INC_R

  mov dl,al

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  mov al,dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB40  : INC_R

  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB41  : INC_R

  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB42  : INC_R

  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB43  : INC_R

  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB44  : INC_R

  mov dl,ch
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB45  : INC_R

  mov dl,cl
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB46  : INC_R

  mov di,cx
  DAM_READ8
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB47  : INC_R

  mov dl,al
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB48  : INC_R

  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB49  : INC_R

  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB4A  : INC_R

  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB4B  : INC_R

  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB4C  : INC_R

  mov dl,ch
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB4D  : INC_R

  mov dl,cl
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB4E  : INC_R

  mov di,cx
  DAM_READ8
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB4F  : INC_R

  mov dl,al
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB50  : INC_R

  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB51  : INC_R

  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB52  : INC_R

  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB53  : INC_R

  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB54  : INC_R

  mov dl,ch
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB55  : INC_R

  mov dl,cl
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB56  : INC_R

  mov di,cx
  DAM_READ8
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB57  : INC_R

  mov dl,al
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB58  : INC_R

  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB59  : INC_R

  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB5A  : INC_R

  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB5B  : INC_R

  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB5C  : INC_R

  mov dl,ch
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB5D  : INC_R

  mov dl,cl
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB5E  : INC_R

  mov di,cx
  DAM_READ8
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB5F  : INC_R

  mov dl,al
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB60  : INC_R

  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB61  : INC_R

  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB62  : INC_R

  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB63  : INC_R

  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB64  : INC_R

  mov dl,ch
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB65  : INC_R

  mov dl,cl
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB66  : INC_R

  mov di,cx
  DAM_READ8
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB67  : INC_R

  mov dl,al
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB68  : INC_R

  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB69  : INC_R

  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB6A  : INC_R

  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB6B  : INC_R

  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB6C  : INC_R

  mov dl,ch
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB6D  : INC_R

  mov dl,cl
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB6E  : INC_R

  mov di,cx
  DAM_READ8
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB6F  : INC_R

  mov dl,al
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB70  : INC_R

  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB71  : INC_R

  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB72  : INC_R

  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB73  : INC_R

  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB74  : INC_R

  mov dl,ch
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB75  : INC_R

  mov dl,cl
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB76  : INC_R

  mov di,cx
  DAM_READ8
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB77  : INC_R

  mov dl,al
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB78  : INC_R

  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB79  : INC_R

  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB7A  : INC_R

  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB7B  : INC_R

  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB7C  : INC_R

  mov dl,ch
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB7D  : INC_R

  mov dl,cl
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB7E  : INC_R

  mov di,cx
  DAM_READ8
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB7F  : INC_R

  mov dl,al
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB80  : INC_R

  and byte [DozeBC+1],0xfe

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB81  : INC_R

  and byte [DozeBC],0xfe

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB82  : INC_R

  and byte [DozeDE+1],0xfe

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB83  : INC_R

  and byte [DozeDE],0xfe

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB84  : INC_R

  and ch,0xfe

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB85  : INC_R

  and cl,0xfe

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB86  : INC_R

  mov di,cx
  DAM_READ8
  and dl,0xfe
  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB87  : INC_R

  and al,0xfe

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB88  : INC_R

  and byte [DozeBC+1],0xfd

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB89  : INC_R

  and byte [DozeBC],0xfd

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB8A  : INC_R

  and byte [DozeDE+1],0xfd

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB8B  : INC_R

  and byte [DozeDE],0xfd

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB8C  : INC_R

  and ch,0xfd

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB8D  : INC_R

  and cl,0xfd

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB8E  : INC_R

  mov di,cx
  DAM_READ8
  and dl,0xfd
  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB8F  : INC_R

  and al,0xfd

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB90  : INC_R

  and byte [DozeBC+1],0xfb

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB91  : INC_R

  and byte [DozeBC],0xfb

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB92  : INC_R

  and byte [DozeDE+1],0xfb

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB93  : INC_R

  and byte [DozeDE],0xfb

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB94  : INC_R

  and ch,0xfb

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB95  : INC_R

  and cl,0xfb

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB96  : INC_R

  mov di,cx
  DAM_READ8
  and dl,0xfb
  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB97  : INC_R

  and al,0xfb

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB98  : INC_R

  and byte [DozeBC+1],0xf7

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB99  : INC_R

  and byte [DozeBC],0xf7

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB9A  : INC_R

  and byte [DozeDE+1],0xf7

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB9B  : INC_R

  and byte [DozeDE],0xf7

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB9C  : INC_R

  and ch,0xf7

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB9D  : INC_R

  and cl,0xf7

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB9E  : INC_R

  mov di,cx
  DAM_READ8
  and dl,0xf7
  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCB9F  : INC_R

  and al,0xf7

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBA0  : INC_R

  and byte [DozeBC+1],0xef

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBA1  : INC_R

  and byte [DozeBC],0xef

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBA2  : INC_R

  and byte [DozeDE+1],0xef

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBA3  : INC_R

  and byte [DozeDE],0xef

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBA4  : INC_R

  and ch,0xef

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBA5  : INC_R

  and cl,0xef

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBA6  : INC_R

  mov di,cx
  DAM_READ8
  and dl,0xef
  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBA7  : INC_R

  and al,0xef

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBA8  : INC_R

  and byte [DozeBC+1],0xdf

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBA9  : INC_R

  and byte [DozeBC],0xdf

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBAA  : INC_R

  and byte [DozeDE+1],0xdf

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBAB  : INC_R

  and byte [DozeDE],0xdf

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBAC  : INC_R

  and ch,0xdf

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBAD  : INC_R

  and cl,0xdf

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBAE  : INC_R

  mov di,cx
  DAM_READ8
  and dl,0xdf
  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBAF  : INC_R

  and al,0xdf

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBB0  : INC_R

  and byte [DozeBC+1],0xbf

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBB1  : INC_R

  and byte [DozeBC],0xbf

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBB2  : INC_R

  and byte [DozeDE+1],0xbf

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBB3  : INC_R

  and byte [DozeDE],0xbf

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBB4  : INC_R

  and ch,0xbf

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBB5  : INC_R

  and cl,0xbf

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBB6  : INC_R

  mov di,cx
  DAM_READ8
  and dl,0xbf
  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBB7  : INC_R

  and al,0xbf

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBB8  : INC_R

  and byte [DozeBC+1],0x7f

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBB9  : INC_R

  and byte [DozeBC],0x7f

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBBA  : INC_R

  and byte [DozeDE+1],0x7f

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBBB  : INC_R

  and byte [DozeDE],0x7f

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBBC  : INC_R

  and ch,0x7f

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBBD  : INC_R

  and cl,0x7f

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBBE  : INC_R

  mov di,cx
  DAM_READ8
  and dl,0x7f
  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBBF  : INC_R

  and al,0x7f

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBC0  : INC_R

  or  byte [DozeBC+1],0x01

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBC1  : INC_R

  or  byte [DozeBC],0x01

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBC2  : INC_R

  or  byte [DozeDE+1],0x01

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBC3  : INC_R

  or  byte [DozeDE],0x01

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBC4  : INC_R

  or  ch,0x01

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBC5  : INC_R

  or  cl,0x01

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBC6  : INC_R

  mov di,cx
  DAM_READ8
  or  dl,0x01
  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBC7  : INC_R

  or  al,0x01

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBC8  : INC_R

  or  byte [DozeBC+1],0x02

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBC9  : INC_R

  or  byte [DozeBC],0x02

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBCA  : INC_R

  or  byte [DozeDE+1],0x02

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBCB  : INC_R

  or  byte [DozeDE],0x02

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBCC  : INC_R

  or  ch,0x02

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBCD  : INC_R

  or  cl,0x02

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBCE  : INC_R

  mov di,cx
  DAM_READ8
  or  dl,0x02
  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBCF  : INC_R

  or  al,0x02

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBD0  : INC_R

  or  byte [DozeBC+1],0x04

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBD1  : INC_R

  or  byte [DozeBC],0x04

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBD2  : INC_R

  or  byte [DozeDE+1],0x04

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBD3  : INC_R

  or  byte [DozeDE],0x04

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBD4  : INC_R

  or  ch,0x04

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBD5  : INC_R

  or  cl,0x04

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBD6  : INC_R

  mov di,cx
  DAM_READ8
  or  dl,0x04
  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBD7  : INC_R

  or  al,0x04

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBD8  : INC_R

  or  byte [DozeBC+1],0x08

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBD9  : INC_R

  or  byte [DozeBC],0x08

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBDA  : INC_R

  or  byte [DozeDE+1],0x08

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBDB  : INC_R

  or  byte [DozeDE],0x08

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBDC  : INC_R

  or  ch,0x08

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBDD  : INC_R

  or  cl,0x08

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBDE  : INC_R

  mov di,cx
  DAM_READ8
  or  dl,0x08
  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBDF  : INC_R

  or  al,0x08

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBE0  : INC_R

  or  byte [DozeBC+1],0x10

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBE1  : INC_R

  or  byte [DozeBC],0x10

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBE2  : INC_R

  or  byte [DozeDE+1],0x10

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBE3  : INC_R

  or  byte [DozeDE],0x10

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBE4  : INC_R

  or  ch,0x10

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBE5  : INC_R

  or  cl,0x10

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBE6  : INC_R

  mov di,cx
  DAM_READ8
  or  dl,0x10
  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBE7  : INC_R

  or  al,0x10

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBE8  : INC_R

  or  byte [DozeBC+1],0x20

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBE9  : INC_R

  or  byte [DozeBC],0x20

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBEA  : INC_R

  or  byte [DozeDE+1],0x20

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBEB  : INC_R

  or  byte [DozeDE],0x20

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBEC  : INC_R

  or  ch,0x20

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBED  : INC_R

  or  cl,0x20

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBEE  : INC_R

  mov di,cx
  DAM_READ8
  or  dl,0x20
  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBEF  : INC_R

  or  al,0x20

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBF0  : INC_R

  or  byte [DozeBC+1],0x40

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBF1  : INC_R

  or  byte [DozeBC],0x40

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBF2  : INC_R

  or  byte [DozeDE+1],0x40

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBF3  : INC_R

  or  byte [DozeDE],0x40

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBF4  : INC_R

  or  ch,0x40

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBF5  : INC_R

  or  cl,0x40

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBF6  : INC_R

  mov di,cx
  DAM_READ8
  or  dl,0x40
  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBF7  : INC_R

  or  al,0x40

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBF8  : INC_R

  or  byte [DozeBC+1],0x80

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBF9  : INC_R

  or  byte [DozeBC],0x80

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBFA  : INC_R

  or  byte [DozeDE+1],0x80

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBFB  : INC_R

  or  byte [DozeDE],0x80

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBFC  : INC_R

  or  ch,0x80

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBFD  : INC_R

  or  cl,0x80

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBFE  : INC_R

  mov di,cx
  DAM_READ8
  or  dl,0x80
  DAM_WRITE8

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpCBFF  : INC_R

  or  al,0x80

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED40  : INC_R

  mov di,word [DozeBC]
  and ah,0x01 ; Remember carry
  mov dh,ah
  xor ah,ah
  call PortIn ; Read port dl <-- di
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or ah,dh    ; SZ-- -P-C
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED41  : INC_R

  mov di,word [DozeBC]
  mov dl,byte [DozeBC+1]
  call PortOut ; Write port dl --> di

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED42  : INC_R

  mov dx,cx
  mov word[Tmp16],dx
  mov dx,word [DozeBC]
  sahf ; Get the carry flag
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  sbb byte [Tmp16]  ,dl
  setz dl
  sbb byte [Tmp16+1],dh
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,byte [Tmp16+1]
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction
  or  dl,0xfe ; 1111 1110 if high byte not zero
  rol dl,6    ; 1011 1111
  and ah,dl   ; Correct zero flag
  mov dx,word[Tmp16]
  mov cx,dx

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED43  : INC_R

; Direct access to a memory location
  DAM_FETCH16
  add si,2
  mov di,dx
  mov dx,word [DozeBC]
  DAM_WRITE16

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED44  : INC_R

  ; ed 44 (and others) - neg
  and ah,0x01 ; Remember carry
  mov dh,ah
  neg al
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or  ah,0x02

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED45  : INC_R

  ; retn/i
  mov di,word [DozeSP]
  DAM_READ16
  mov si,dx
  add word [DozeSP],2
  mov dl,byte [DozeIFF+1]
  mov byte [DozeIFF],dl ; iff1 <-- iff2

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED46  : INC_R

;  im 0
  mov byte[DozeIM],0

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED47  : INC_R

  mov byte [DozeIR+1],al ; ld i,a

  sub dword [_nDozeCycles],5
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED48  : INC_R

  mov di,word [DozeBC]
  and ah,0x01 ; Remember carry
  mov dh,ah
  xor ah,ah
  call PortIn ; Read port dl <-- di
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or ah,dh    ; SZ-- -P-C
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED49  : INC_R

  mov di,word [DozeBC]
  mov dl,byte [DozeBC]
  call PortOut ; Write port dl --> di

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED4A  : INC_R

  mov dx,cx
  mov word[Tmp16],dx
  mov dx,word [DozeBC]
  sahf ; Get the carry flag
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  adc byte [Tmp16]  ,dl
  setz dl
  adc byte [Tmp16+1],dh
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,byte [Tmp16+1]
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or  dl,0xfe ; 1111 1110 if high byte not zero
  rol dl,6    ; 1011 1111
  and ah,dl   ; Correct zero flag
  mov dx,word[Tmp16]
  mov cx,dx

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED4B  : INC_R

; Direct access to a memory location
  DAM_FETCH16
  add si,2
  mov di,dx
  DAM_READ16
  mov word [DozeBC],dx

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED4E  : INC_R

;  im 0
  mov byte[DozeIM],0

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED4F  : INC_R

  mov bl,al   ; ld r,a
  rol bl,1

  sub dword [_nDozeCycles],5
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED50  : INC_R

  mov di,word [DozeBC]
  and ah,0x01 ; Remember carry
  mov dh,ah
  xor ah,ah
  call PortIn ; Read port dl <-- di
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or ah,dh    ; SZ-- -P-C
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED51  : INC_R

  mov di,word [DozeBC]
  mov dl,byte [DozeDE+1]
  call PortOut ; Write port dl --> di

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED52  : INC_R

  mov dx,cx
  mov word[Tmp16],dx
  mov dx,word [DozeDE]
  sahf ; Get the carry flag
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  sbb byte [Tmp16]  ,dl
  setz dl
  sbb byte [Tmp16+1],dh
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,byte [Tmp16+1]
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction
  or  dl,0xfe ; 1111 1110 if high byte not zero
  rol dl,6    ; 1011 1111
  and ah,dl   ; Correct zero flag
  mov dx,word[Tmp16]
  mov cx,dx

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED53  : INC_R

; Direct access to a memory location
  DAM_FETCH16
  add si,2
  mov di,dx
  mov dx,word [DozeDE]
  DAM_WRITE16

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED56  : INC_R

;  im 1
  mov byte[DozeIM],1

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED57  : INC_R

  mov dh,ah
  and dh,0x01 ; ---- ---C
  mov al,byte [DozeIR+1] ; ld a,i
  test al,al
  lahf
  and ah,0xc0 ; SZ-- ----
  or ah,dh    ; SZ-- ---C
  mov dh,al
  and dh,0x28
  or ah,dh    ; SZ5- 3--C
  mov dh,byte [DozeIFF+1] ; get iff2
  rol dh,2
  and dh,0x04
  or ah,dh    ; SZ5- 3V-C

  sub dword [_nDozeCycles],5
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED58  : INC_R

  mov di,word [DozeBC]
  and ah,0x01 ; Remember carry
  mov dh,ah
  xor ah,ah
  call PortIn ; Read port dl <-- di
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or ah,dh    ; SZ-- -P-C
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED59  : INC_R

  mov di,word [DozeBC]
  mov dl,byte [DozeDE]
  call PortOut ; Write port dl --> di

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED5A  : INC_R

  mov dx,cx
  mov word[Tmp16],dx
  mov dx,word [DozeDE]
  sahf ; Get the carry flag
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  adc byte [Tmp16]  ,dl
  setz dl
  adc byte [Tmp16+1],dh
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,byte [Tmp16+1]
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or  dl,0xfe ; 1111 1110 if high byte not zero
  rol dl,6    ; 1011 1111
  and ah,dl   ; Correct zero flag
  mov dx,word[Tmp16]
  mov cx,dx

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED5B  : INC_R

; Direct access to a memory location
  DAM_FETCH16
  add si,2
  mov di,dx
  DAM_READ16
  mov word [DozeDE],dx

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED5E  : INC_R

;  im 2
  mov byte[DozeIM],2

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED5F  : INC_R

  mov dh,ah
  and dh,0x01 ; ---- ---C
  mov al,bl
  ror al,1 ; ld a,r
  test al,al
  lahf
  and ah,0xc0 ; SZ-- ----
  or ah,dh    ; SZ-- ---C
  mov dh,al
  and dh,0x28
  or ah,dh    ; SZ5- 3--C
  mov dh,byte [DozeIFF+1] ; get iff2
  rol dh,2
  and dh,0x04
  or ah,dh    ; SZ5- 3V-C

  sub dword [_nDozeCycles],5
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED60  : INC_R

  mov di,word [DozeBC]
  and ah,0x01 ; Remember carry
  mov dh,ah
  xor ah,ah
  call PortIn ; Read port dl <-- di
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or ah,dh    ; SZ-- -P-C
  mov ch,dl

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED61  : INC_R

  mov di,word [DozeBC]
  mov dl,ch
  call PortOut ; Write port dl --> di

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED62  : INC_R

  mov dx,cx
  mov word[Tmp16],dx
  mov dx,cx
  sahf ; Get the carry flag
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  sbb byte [Tmp16]  ,dl
  setz dl
  sbb byte [Tmp16+1],dh
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,byte [Tmp16+1]
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction
  or  dl,0xfe ; 1111 1110 if high byte not zero
  rol dl,6    ; 1011 1111
  and ah,dl   ; Correct zero flag
  mov dx,word[Tmp16]
  mov cx,dx

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED63  : INC_R

; Direct access to a memory location
  DAM_FETCH16
  add si,2
  mov di,dx
  mov dx,cx
  DAM_WRITE16

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED67  : INC_R

  mov di,cx
  DAM_READ8
  ; aaaa DDDD dddd, rotate --->
  rol dl,4    ; ---- ---- dddd DDDD
  rol dx,8    ; dddd DDDD ---- ----
  ror al,4
  mov dl,al
  ror al,4
  and dl,0xf0 ; dddd DDDD aaaa ----
  rol dx,4    ; DDDD aaaa ---- dddd
  and al,0xf0
  or  al,dl   ; GOT aaaa=dddd
  mov dl,dh   ; DDDD aaaa DDDD aaaa
  xor dh,dh   ; ---- ---- DDDD aaaa
  rol dl,4    ; ---- ---- aaaa DDDD  GOT new d
  DAM_WRITE8
  mov dh,ah
  and dh,0x01 ; Preserve Carry
  test al,al
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  sub dword [_nDozeCycles],14
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED68  : INC_R

  mov di,word [DozeBC]
  and ah,0x01 ; Remember carry
  mov dh,ah
  xor ah,ah
  call PortIn ; Read port dl <-- di
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or ah,dh    ; SZ-- -P-C
  mov cl,dl

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED69  : INC_R

  mov di,word [DozeBC]
  mov dl,cl
  call PortOut ; Write port dl --> di

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED6A  : INC_R

  mov dx,cx
  mov word[Tmp16],dx
  mov dx,cx
  sahf ; Get the carry flag
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  adc byte [Tmp16]  ,dl
  setz dl
  adc byte [Tmp16+1],dh
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,byte [Tmp16+1]
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or  dl,0xfe ; 1111 1110 if high byte not zero
  rol dl,6    ; 1011 1111
  and ah,dl   ; Correct zero flag
  mov dx,word[Tmp16]
  mov cx,dx

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED6B  : INC_R

; Direct access to a memory location
  DAM_FETCH16
  add si,2
  mov di,dx
  DAM_READ16
  mov cx,dx

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED6F  : INC_R

  mov di,cx
  DAM_READ8
  ; aaaa DDDD dddd, rotate <---
  rol dx,8    ; DDDD dddd ---- ----
  ror al,4
  mov dl,al
  ror al,4
  and dl,0xf0 ; DDDD dddd aaaa ----
  rol dx,4    ; dddd aaaa ---- DDDD
  and al,0xf0
  or  al,dl   ; GOT aaaa=DDDD
  mov dl,dh   ; dddd aaaa dddd aaaa
  xor dh,dh   ; ---- ---- dddd aaaa  GOT new d
  DAM_WRITE8
  mov dh,ah
  and dh,0x01 ; Preserve Carry
  test al,al
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  sub dword [_nDozeCycles],14
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED70  : INC_R

  mov di,word [DozeBC]
  and ah,0x01 ; Remember carry
  mov dh,ah
  xor ah,ah
  call PortIn ; Read port dl <-- di
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or ah,dh    ; SZ-- -P-C

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED71  : INC_R

  mov di,word [DozeBC]
xor dl,dl
  call PortOut ; Write port dl --> di

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED72  : INC_R

  mov dx,cx
  mov word[Tmp16],dx
  mov dx,word [DozeSP]
  sahf ; Get the carry flag
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  sbb byte [Tmp16]  ,dl
  setz dl
  sbb byte [Tmp16+1],dh
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,byte [Tmp16+1]
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction
  or  dl,0xfe ; 1111 1110 if high byte not zero
  rol dl,6    ; 1011 1111
  and ah,dl   ; Correct zero flag
  mov dx,word[Tmp16]
  mov cx,dx

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED73  : INC_R

; Direct access to a memory location
  DAM_FETCH16
  add si,2
  mov di,dx
  mov dx,word [DozeSP]
  DAM_WRITE16

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED78  : INC_R

  mov di,word [DozeBC]
  and ah,0x01 ; Remember carry
  mov dh,ah
  xor ah,ah
  call PortIn ; Read port dl <-- di
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or ah,dh    ; SZ-- -P-C
  mov al,dl

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED79  : INC_R

  mov di,word [DozeBC]
  mov dl,al
  call PortOut ; Write port dl --> di

  sub dword [_nDozeCycles],8
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED7A  : INC_R

  mov dx,cx
  mov word[Tmp16],dx
  mov dx,word [DozeSP]
  sahf ; Get the carry flag
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  adc byte [Tmp16]  ,dl
  setz dl
  adc byte [Tmp16+1],dh
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,byte [Tmp16+1]
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or  dl,0xfe ; 1111 1110 if high byte not zero
  rol dl,6    ; 1011 1111
  and ah,dl   ; Correct zero flag
  mov dx,word[Tmp16]
  mov cx,dx

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpED7B  : INC_R

; Direct access to a memory location
  DAM_FETCH16
  add si,2
  mov di,dx
  DAM_READ16
  mov word [DozeSP],dx

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEDA0  : INC_R

  ; cp/ld/i/d/r
  mov di,cx
  DAM_READ8
  mov di,word [DozeDE]
  DAM_WRITE8
  and ah,0xc1 ; SZ-H --NC  (SZC preserved, H=0, N=0)
  ; Now work out A+(HL): for bits 5 and 3
  add dl,al
  xor dh,dh
  test dl,0x02 ; Bit 5 is copied from bit 1
  setnz dh
  rol dh,5
  or ah,dh ; SZ5H --NC
  mov dh,dl
  and dh,0x08
  or ah,dh ; SZ5H 3-NC
  ; Update DE
  inc word [DozeDE]
  ; Update HL
  inc cx
  ; Update BC
  dec word [DozeBC]
; Check if BC==0
  xor dh,dh
  test word [DozeBC],0xffff
  setnz dh
  rol dh,2
  or ah,dh ; SZ5H 3VNC

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEDA1  : INC_R

  ; cp/ld/i/d/r
  mov di,cx
  DAM_READ8
  mov dh,ah
  and dh,0x01
  cmp al,dl
  lahf
  and ah,0xd0 ; SZ-H ----
  or  ah,0x02 ; SZ-H --N-
  or  ah,dh   ; SZ-H --NC
  ; Now work out A-(HL)-H: for bits 5 and 3
  sub dl,al
  neg dl ; A-(HL)
  mov dh,ah
  ror dh,4
  and dh,0x01
  sub dl,dh ; A-(HL)-H
  xor dh,dh
  test dl,0x02 ; Bit 5 is copied from bit 1
  setnz dh
  rol dh,5
  or ah,dh ; SZ5H --NC
  mov dh,dl
  and dh,0x08
  or ah,dh ; SZ5H 3-NC
  ; Update HL
  inc cx
  ; Update BC
  dec word [DozeBC]
; Check if BC==0
  xor dh,dh
  test word [DozeBC],0xffff
  setnz dh
  rol dh,2
  or ah,dh ; SZ5H 3VNC

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEDA2  : INC_R

; Repeating I/O
  ; Read port (bc)
  mov di,word [DozeBC]
  call PortIn ; Read port dl <-- di
  mov bh,dl ; Remember port byte
  ; Write to (hl)
  mov di,cx
  DAM_WRITE8
  inc di ; Increment hl
  mov cx,di
  ; Decrease b
  mov dl,byte [DozeBC+1]
  dec dl
  mov byte [DozeBC+1],dl
  xor dh,dh
  mov ah,byte [DecFlag+edx] ; flags based on dec b
  and ah,0xe8 ; SZ5- 3---
  ; Get negative bit from the port byte
  mov dh,bh
  rol dh,2
  and dh,2
  or  ah,dh   ; SZ5- 3-N-
  ; Get H and C based on c + byte
  mov dl,byte [DozeBC]
  inc dl
  add dl,bh
  setc dl
  and dl,1
  mov dh,dl
  rol dh,4
  or dl,dh
  or ah,dl ; SZ5H 3-NC

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEDA3  : INC_R

; Repeating I/O
  ; Read from (hl)
  mov di,cx
  DAM_READ8
  mov bh,dl ; Remember port byte
  inc di ; Increment hl
  mov cx,di
  ; Write to port (bc)
  mov di,word [DozeBC]
  call PortOut ; Write port dl --> di
  ; Decrease b
  mov dl,byte [DozeBC+1]
  dec dl
  mov byte [DozeBC+1],dl
  xor dh,dh
  mov ah,byte [DecFlag+edx] ; flags based on dec b
  and ah,0xe8 ; SZ5- 3---
  ; Get negative bit from the port byte
  mov dh,bh
  rol dh,2
  and dh,2
  or  ah,dh   ; SZ5- 3-N-
  ; Get H and C based on c + byte
  mov dl,byte [DozeBC]
  dec dl
  add dl,bh
  setc dl
  and dl,1
  mov dh,dl
  rol dh,4
  or dl,dh
  or ah,dl ; SZ5H 3-NC

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEDA8  : INC_R

  ; cp/ld/i/d/r
  mov di,cx
  DAM_READ8
  mov di,word [DozeDE]
  DAM_WRITE8
  and ah,0xc1 ; SZ-H --NC  (SZC preserved, H=0, N=0)
  ; Now work out A+(HL): for bits 5 and 3
  add dl,al
  xor dh,dh
  test dl,0x02 ; Bit 5 is copied from bit 1
  setnz dh
  rol dh,5
  or ah,dh ; SZ5H --NC
  mov dh,dl
  and dh,0x08
  or ah,dh ; SZ5H 3-NC
  ; Update DE
  dec word [DozeDE]
  ; Update HL
  dec cx
  ; Update BC
  dec word [DozeBC]
; Check if BC==0
  xor dh,dh
  test word [DozeBC],0xffff
  setnz dh
  rol dh,2
  or ah,dh ; SZ5H 3VNC

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEDA9  : INC_R

  ; cp/ld/i/d/r
  mov di,cx
  DAM_READ8
  mov dh,ah
  and dh,0x01
  cmp al,dl
  lahf
  and ah,0xd0 ; SZ-H ----
  or  ah,0x02 ; SZ-H --N-
  or  ah,dh   ; SZ-H --NC
  ; Now work out A-(HL)-H: for bits 5 and 3
  sub dl,al
  neg dl ; A-(HL)
  mov dh,ah
  ror dh,4
  and dh,0x01
  sub dl,dh ; A-(HL)-H
  xor dh,dh
  test dl,0x02 ; Bit 5 is copied from bit 1
  setnz dh
  rol dh,5
  or ah,dh ; SZ5H --NC
  mov dh,dl
  and dh,0x08
  or ah,dh ; SZ5H 3-NC
  ; Update HL
  dec cx
  ; Update BC
  dec word [DozeBC]
; Check if BC==0
  xor dh,dh
  test word [DozeBC],0xffff
  setnz dh
  rol dh,2
  or ah,dh ; SZ5H 3VNC

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEDAA  : INC_R

; Repeating I/O
  ; Read port (bc)
  mov di,word [DozeBC]
  call PortIn ; Read port dl <-- di
  mov bh,dl ; Remember port byte
  ; Write to (hl)
  mov di,cx
  DAM_WRITE8
  dec di ; Decrement hl
  mov cx,di
  ; Decrease b
  mov dl,byte [DozeBC+1]
  dec dl
  mov byte [DozeBC+1],dl
  xor dh,dh
  mov ah,byte [DecFlag+edx] ; flags based on dec b
  and ah,0xe8 ; SZ5- 3---
  ; Get negative bit from the port byte
  mov dh,bh
  rol dh,2
  and dh,2
  or  ah,dh   ; SZ5- 3-N-
  ; Get H and C based on c + byte
  mov dl,byte [DozeBC]
  inc dl
  add dl,bh
  setc dl
  and dl,1
  mov dh,dl
  rol dh,4
  or dl,dh
  or ah,dl ; SZ5H 3-NC

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEDAB  : INC_R

; Repeating I/O
  ; Read from (hl)
  mov di,cx
  DAM_READ8
  mov bh,dl ; Remember port byte
  dec di ; Decrement hl
  mov cx,di
  ; Write to port (bc)
  mov di,word [DozeBC]
  call PortOut ; Write port dl --> di
  ; Decrease b
  mov dl,byte [DozeBC+1]
  dec dl
  mov byte [DozeBC+1],dl
  xor dh,dh
  mov ah,byte [DecFlag+edx] ; flags based on dec b
  and ah,0xe8 ; SZ5- 3---
  ; Get negative bit from the port byte
  mov dh,bh
  rol dh,2
  and dh,2
  or  ah,dh   ; SZ5- 3-N-
  ; Get H and C based on c + byte
  mov dl,byte [DozeBC]
  dec dl
  add dl,bh
  setc dl
  and dl,1
  mov dh,dl
  rol dh,4
  or dl,dh
  or ah,dl ; SZ5H 3-NC

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEDB0  : INC_R

  ; cp/ld/i/d/r
  mov di,cx
  DAM_READ8
  mov di,word [DozeDE]
  DAM_WRITE8
  and ah,0xc1 ; SZ-H --NC  (SZC preserved, H=0, N=0)
  ; Now work out A+(HL): for bits 5 and 3
  add dl,al
  xor dh,dh
  test dl,0x02 ; Bit 5 is copied from bit 1
  setnz dh
  rol dh,5
  or ah,dh ; SZ5H --NC
  mov dh,dl
  and dh,0x08
  or ah,dh ; SZ5H 3-NC
  ; Update DE
  inc word [DozeDE]
  ; Update HL
  inc cx
  ; Update BC
  dec word [DozeBC]
; Check if BC==0
  xor dh,dh
  test word [DozeBC],0xffff
  setnz dh
  rol dh,2
  or ah,dh ; SZ5H 3VNC
; Stop repeating if BC==0
  test ah,0x04 ; ---- -V--
  jz Done0
  ; Repeat instruction
  INC_R
  sub si,2

  sub dword [_nDozeCycles],17
  jle near DozeRunEnd
  FETCH_OP

Done0:

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEDB1  : INC_R

  ; cp/ld/i/d/r
  mov di,cx
  DAM_READ8
  mov dh,ah
  and dh,0x01
  cmp al,dl
  lahf
  and ah,0xd0 ; SZ-H ----
  or  ah,0x02 ; SZ-H --N-
  or  ah,dh   ; SZ-H --NC
  ; Now work out A-(HL)-H: for bits 5 and 3
  sub dl,al
  neg dl ; A-(HL)
  mov dh,ah
  ror dh,4
  and dh,0x01
  sub dl,dh ; A-(HL)-H
  xor dh,dh
  test dl,0x02 ; Bit 5 is copied from bit 1
  setnz dh
  rol dh,5
  or ah,dh ; SZ5H --NC
  mov dh,dl
  and dh,0x08
  or ah,dh ; SZ5H 3-NC
  ; Update HL
  inc cx
  ; Update BC
  dec word [DozeBC]
; Check if BC==0
  xor dh,dh
  test word [DozeBC],0xffff
  setnz dh
  rol dh,2
  or ah,dh ; SZ5H 3VNC
; Stop repeating if BC==0
  test ah,0x04 ; ---- -V--
  jz Done1
; Stop repeating if a-(HL) == 0
  test ah,0x40 ; -Z-- ----
  jnz Done1
  ; Repeat instruction
  INC_R
  sub si,2

  sub dword [_nDozeCycles],17
  jle near DozeRunEnd
  FETCH_OP

Done1:

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEDB2  : INC_R

; Repeating I/O
  ; Read port (bc)
  mov di,word [DozeBC]
  call PortIn ; Read port dl <-- di
  mov bh,dl ; Remember port byte
  ; Write to (hl)
  mov di,cx
  DAM_WRITE8
  inc di ; Increment hl
  mov cx,di
  ; Decrease b
  mov dl,byte [DozeBC+1]
  dec dl
  mov byte [DozeBC+1],dl
  xor dh,dh
  mov ah,byte [DecFlag+edx] ; flags based on dec b
  and ah,0xe8 ; SZ5- 3---
  ; Get negative bit from the port byte
  mov dh,bh
  rol dh,2
  and dh,2
  or  ah,dh   ; SZ5- 3-N-
  ; Get H and C based on c + byte
  mov dl,byte [DozeBC]
  inc dl
  add dl,bh
  setc dl
  and dl,1
  mov dh,dl
  rol dh,4
  or dl,dh
  or ah,dl ; SZ5H 3-NC
; Stop repeating if B==0
  test ah,0x40
  jnz IoStop0
  ; Repeat instruction
  INC_R
  sub si,2

  sub dword [_nDozeCycles],17
  jle near DozeRunEnd
  FETCH_OP

IoStop0:
  or ah,0x04 ; SZ5H 3VNC

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEDB3  : INC_R

; Repeating I/O
  ; Read from (hl)
  mov di,cx
  DAM_READ8
  mov bh,dl ; Remember port byte
  inc di ; Increment hl
  mov cx,di
  ; Write to port (bc)
  mov di,word [DozeBC]
  call PortOut ; Write port dl --> di
  ; Decrease b
  mov dl,byte [DozeBC+1]
  dec dl
  mov byte [DozeBC+1],dl
  xor dh,dh
  mov ah,byte [DecFlag+edx] ; flags based on dec b
  and ah,0xe8 ; SZ5- 3---
  ; Get negative bit from the port byte
  mov dh,bh
  rol dh,2
  and dh,2
  or  ah,dh   ; SZ5- 3-N-
  ; Get H and C based on c + byte
  mov dl,byte [DozeBC]
  dec dl
  add dl,bh
  setc dl
  and dl,1
  mov dh,dl
  rol dh,4
  or dl,dh
  or ah,dl ; SZ5H 3-NC
; Stop repeating if B==0
  test ah,0x40
  jnz IoStop1
  ; Repeat instruction
  INC_R
  sub si,2

  sub dword [_nDozeCycles],17
  jle near DozeRunEnd
  FETCH_OP

IoStop1:
  or ah,0x04 ; SZ5H 3VNC

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEDB8  : INC_R

  ; cp/ld/i/d/r
  mov di,cx
  DAM_READ8
  mov di,word [DozeDE]
  DAM_WRITE8
  and ah,0xc1 ; SZ-H --NC  (SZC preserved, H=0, N=0)
  ; Now work out A+(HL): for bits 5 and 3
  add dl,al
  xor dh,dh
  test dl,0x02 ; Bit 5 is copied from bit 1
  setnz dh
  rol dh,5
  or ah,dh ; SZ5H --NC
  mov dh,dl
  and dh,0x08
  or ah,dh ; SZ5H 3-NC
  ; Update DE
  dec word [DozeDE]
  ; Update HL
  dec cx
  ; Update BC
  dec word [DozeBC]
; Check if BC==0
  xor dh,dh
  test word [DozeBC],0xffff
  setnz dh
  rol dh,2
  or ah,dh ; SZ5H 3VNC
; Stop repeating if BC==0
  test ah,0x04 ; ---- -V--
  jz Done2
  ; Repeat instruction
  INC_R
  sub si,2

  sub dword [_nDozeCycles],17
  jle near DozeRunEnd
  FETCH_OP

Done2:

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEDB9  : INC_R

  ; cp/ld/i/d/r
  mov di,cx
  DAM_READ8
  mov dh,ah
  and dh,0x01
  cmp al,dl
  lahf
  and ah,0xd0 ; SZ-H ----
  or  ah,0x02 ; SZ-H --N-
  or  ah,dh   ; SZ-H --NC
  ; Now work out A-(HL)-H: for bits 5 and 3
  sub dl,al
  neg dl ; A-(HL)
  mov dh,ah
  ror dh,4
  and dh,0x01
  sub dl,dh ; A-(HL)-H
  xor dh,dh
  test dl,0x02 ; Bit 5 is copied from bit 1
  setnz dh
  rol dh,5
  or ah,dh ; SZ5H --NC
  mov dh,dl
  and dh,0x08
  or ah,dh ; SZ5H 3-NC
  ; Update HL
  dec cx
  ; Update BC
  dec word [DozeBC]
; Check if BC==0
  xor dh,dh
  test word [DozeBC],0xffff
  setnz dh
  rol dh,2
  or ah,dh ; SZ5H 3VNC
; Stop repeating if BC==0
  test ah,0x04 ; ---- -V--
  jz Done3
; Stop repeating if a-(HL) == 0
  test ah,0x40 ; -Z-- ----
  jnz Done3
  ; Repeat instruction
  INC_R
  sub si,2

  sub dword [_nDozeCycles],17
  jle near DozeRunEnd
  FETCH_OP

Done3:

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEDBA  : INC_R

; Repeating I/O
  ; Read port (bc)
  mov di,word [DozeBC]
  call PortIn ; Read port dl <-- di
  mov bh,dl ; Remember port byte
  ; Write to (hl)
  mov di,cx
  DAM_WRITE8
  dec di ; Decrement hl
  mov cx,di
  ; Decrease b
  mov dl,byte [DozeBC+1]
  dec dl
  mov byte [DozeBC+1],dl
  xor dh,dh
  mov ah,byte [DecFlag+edx] ; flags based on dec b
  and ah,0xe8 ; SZ5- 3---
  ; Get negative bit from the port byte
  mov dh,bh
  rol dh,2
  and dh,2
  or  ah,dh   ; SZ5- 3-N-
  ; Get H and C based on c + byte
  mov dl,byte [DozeBC]
  inc dl
  add dl,bh
  setc dl
  and dl,1
  mov dh,dl
  rol dh,4
  or dl,dh
  or ah,dl ; SZ5H 3-NC
; Stop repeating if B==0
  test ah,0x40
  jnz IoStop2
  ; Repeat instruction
  INC_R
  sub si,2

  sub dword [_nDozeCycles],17
  jle near DozeRunEnd
  FETCH_OP

IoStop2:
  or ah,0x04 ; SZ5H 3VNC

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpEDBB  : INC_R

; Repeating I/O
  ; Read from (hl)
  mov di,cx
  DAM_READ8
  mov bh,dl ; Remember port byte
  dec di ; Decrement hl
  mov cx,di
  ; Write to port (bc)
  mov di,word [DozeBC]
  call PortOut ; Write port dl --> di
  ; Decrease b
  mov dl,byte [DozeBC+1]
  dec dl
  mov byte [DozeBC+1],dl
  xor dh,dh
  mov ah,byte [DecFlag+edx] ; flags based on dec b
  and ah,0xe8 ; SZ5- 3---
  ; Get negative bit from the port byte
  mov dh,bh
  rol dh,2
  and dh,2
  or  ah,dh   ; SZ5- 3-N-
  ; Get H and C based on c + byte
  mov dl,byte [DozeBC]
  dec dl
  add dl,bh
  setc dl
  and dl,1
  mov dh,dl
  rol dh,4
  or dl,dh
  or ah,dl ; SZ5H 3-NC
; Stop repeating if B==0
  test ah,0x40
  jnz IoStop3
  ; Repeat instruction
  INC_R
  sub si,2

  sub dword [_nDozeCycles],17
  jle near DozeRunEnd
  FETCH_OP

IoStop3:
  or ah,0x04 ; SZ5H 3VNC

  sub dword [_nDozeCycles],12
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD09  : INC_R

  mov bh,ah
  and bh,0xc4 ; Remember SZ---P--
  mov dx,word [DozeBC]
  ror ebx,16 ; Get access to a spare bit of ebx
  mov bx,dx
  mov dx,word [DozeIX]
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  add dl,bl
  adc dh,bh
  lahf
  mov word [DozeIX],dx
  ror ebx,16 ; Done with ebx
  and ah,0x11 ; ---H---C get flags.
  and dh,0x28
  or  ah,dh   ; --5H3--C
  or  ah,bh

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD19  : INC_R

  mov bh,ah
  and bh,0xc4 ; Remember SZ---P--
  mov dx,word [DozeDE]
  ror ebx,16 ; Get access to a spare bit of ebx
  mov bx,dx
  mov dx,word [DozeIX]
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  add dl,bl
  adc dh,bh
  lahf
  mov word [DozeIX],dx
  ror ebx,16 ; Done with ebx
  and ah,0x11 ; ---H---C get flags.
  and dh,0x28
  or  ah,dh   ; --5H3--C
  or  ah,bh

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD21  : INC_R

; Load Immediate 16-bit
  DAM_FETCH16
  add si,2
  mov word [DozeIX],dx

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD22  : INC_R

; Direct access to a memory location
  DAM_FETCH16
  add si,2
  mov di,dx
  mov dx,word [DozeIX]
  DAM_WRITE16

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD23  : INC_R

  inc word [DozeIX]
  ; (With 16-bit inc, flags aren't changed)

  sub dword [_nDozeCycles],6
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD24  : INC_R

  and ah,0x01 ; Keep carry flag
  inc byte [DozeIX+1]
  mov dl,byte [DozeIX+1]
  xor dh,dh
  or ah,byte [IncFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD25  : INC_R

  and ah,0x01 ; Keep carry flag
  dec byte [DozeIX+1]
  mov dl,byte [DozeIX+1]
  xor dh,dh
  or ah,byte [DecFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD26  : INC_R

; Load Value 8-bit
  DAM_FETCH8
  inc si
  mov byte [DozeIX+1],dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD29  : INC_R

  mov bh,ah
  and bh,0xc4 ; Remember SZ---P--
  mov dx,word [DozeIX]
  ror ebx,16 ; Get access to a spare bit of ebx
  mov bx,dx
  mov dx,word [DozeIX]
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  add dl,bl
  adc dh,bh
  lahf
  mov word [DozeIX],dx
  ror ebx,16 ; Done with ebx
  and ah,0x11 ; ---H---C get flags.
  and dh,0x28
  or  ah,dh   ; --5H3--C
  or  ah,bh

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD2A  : INC_R

; Direct access to a memory location
  DAM_FETCH16
  add si,2
  mov di,dx
  DAM_READ16
  mov word [DozeIX],dx

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD2B  : INC_R

  dec word [DozeIX]
  ; (With 16-bit inc, flags aren't changed)

  sub dword [_nDozeCycles],6
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD2C  : INC_R

  and ah,0x01 ; Keep carry flag
  inc byte [DozeIX]
  mov dl,byte [DozeIX]
  xor dh,dh
  or ah,byte [IncFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD2D  : INC_R

  and ah,0x01 ; Keep carry flag
  dec byte [DozeIX]
  mov dl,byte [DozeIX]
  xor dh,dh
  or ah,byte [DecFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD2E  : INC_R

; Load Value 8-bit
  DAM_FETCH8
  inc si
  mov byte [DozeIX],dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD34  : INC_R

  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
; Takes more cycles from memory
  and ah,0x01 ; Keep carry flag
  DAM_READ8
  inc dl
  DAM_WRITE8
  xor dh,dh
  or ah,byte [IncFlag+edx]

  sub dword [_nDozeCycles],19
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD35  : INC_R

  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
; Takes more cycles from memory
  and ah,0x01 ; Keep carry flag
  DAM_READ8
  dec dl
  DAM_WRITE8
  xor dh,dh
  or ah,byte [DecFlag+edx]

  sub dword [_nDozeCycles],19
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD36  : INC_R

; Load Value 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  DAM_FETCH8
  inc si
  add di,word [DozeIX]
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD39  : INC_R

  mov bh,ah
  and bh,0xc4 ; Remember SZ---P--
  mov dx,word [DozeSP]
  ror ebx,16 ; Get access to a spare bit of ebx
  mov bx,dx
  mov dx,word [DozeIX]
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  add dl,bl
  adc dh,bh
  lahf
  mov word [DozeIX],dx
  ror ebx,16 ; Done with ebx
  and ah,0x11 ; ---H---C get flags.
  and dh,0x28
  or  ah,dh   ; --5H3--C
  or  ah,bh

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD44  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIX+1]
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD45  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIX]
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD46  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
; Copy to dl, then to destination
  DAM_READ8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD4C  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIX+1]
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD4D  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIX]
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD4E  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
; Copy to dl, then to destination
  DAM_READ8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD54  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIX+1]
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD55  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIX]
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD56  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
; Copy to dl, then to destination
  DAM_READ8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD5C  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIX+1]
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD5D  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIX]
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD5E  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
; Copy to dl, then to destination
  DAM_READ8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD60  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeBC+1]
  mov byte [DozeIX+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD61  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeBC]
  mov byte [DozeIX+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD62  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeDE+1]
  mov byte [DozeIX+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD63  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeDE]
  mov byte [DozeIX+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD64  : INC_R

; Load 8-bit

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD65  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIX]
  mov byte [DozeIX+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD66  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
; Copy to dl, then to destination
  DAM_READ8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD67  : INC_R

; Load 8-bit
  mov byte [DozeIX+1],al

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD68  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeBC+1]
  mov byte [DozeIX],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD69  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeBC]
  mov byte [DozeIX],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD6A  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeDE+1]
  mov byte [DozeIX],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD6B  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeDE]
  mov byte [DozeIX],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD6C  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIX+1]
  mov byte [DozeIX],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD6D  : INC_R

; Load 8-bit

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD6E  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
; Copy to dl, then to destination
  DAM_READ8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD6F  : INC_R

; Load 8-bit
  mov byte [DozeIX],al

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD70  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
; Copy to dl, then to destination
  mov dl,byte [DozeBC+1]
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD71  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
; Copy to dl, then to destination
  mov dl,byte [DozeBC]
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD72  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
; Copy to dl, then to destination
  mov dl,byte [DozeDE+1]
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD73  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
; Copy to dl, then to destination
  mov dl,byte [DozeDE]
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD74  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
; Copy to dl, then to destination
  mov dl,ch
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD75  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
; Copy to dl, then to destination
  mov dl,cl
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD77  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
; Copy to dl, then to destination
  mov dl,al
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD7C  : INC_R

; Load 8-bit
  mov al,byte [DozeIX+1]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD7D  : INC_R

; Load 8-bit
  mov al,byte [DozeIX]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD7E  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
; Copy to dl, then to destination
  DAM_READ8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD84  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIX+1]
  xor ah,ah ; Start with blank flags
  add al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD85  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIX]
  xor ah,ah ; Start with blank flags
  add al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD86  : INC_R

  ; Arithmetic
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
  DAM_READ8
  xor ah,ah ; Start with blank flags
  add al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD8C  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIX+1]
  sahf ; Get the carry flag
  adc al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD8D  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIX]
  sahf ; Get the carry flag
  adc al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD8E  : INC_R

  ; Arithmetic
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
  DAM_READ8
  sahf ; Get the carry flag
  adc al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD94  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIX+1]
  xor ah,ah ; Start with blank flags
  sub al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD95  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIX]
  xor ah,ah ; Start with blank flags
  sub al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD96  : INC_R

  ; Arithmetic
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
  DAM_READ8
  xor ah,ah ; Start with blank flags
  sub al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD9C  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIX+1]
  sahf ; Get the carry flag
  sbb al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD9D  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIX]
  sahf ; Get the carry flag
  sbb al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDD9E  : INC_R

  ; Arithmetic
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
  DAM_READ8
  sahf ; Get the carry flag
  sbb al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDA4  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIX+1]
  xor ah,ah ; Start with blank flags
  and al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x10 ; Set bit 4 to 1 (AND operation)

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDA5  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIX]
  xor ah,ah ; Start with blank flags
  and al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x10 ; Set bit 4 to 1 (AND operation)

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDA6  : INC_R

  ; Arithmetic
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
  DAM_READ8
  xor ah,ah ; Start with blank flags
  and al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x10 ; Set bit 4 to 1 (AND operation)

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDAC  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIX+1]
  xor ah,ah ; Start with blank flags
  xor al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDAD  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIX]
  xor ah,ah ; Start with blank flags
  xor al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDAE  : INC_R

  ; Arithmetic
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
  DAM_READ8
  xor ah,ah ; Start with blank flags
  xor al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDB4  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIX+1]
  xor ah,ah ; Start with blank flags
  or al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDB5  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIX]
  xor ah,ah ; Start with blank flags
  or al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDB6  : INC_R

  ; Arithmetic
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
  DAM_READ8
  xor ah,ah ; Start with blank flags
  or al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDBC  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIX+1]
  xor ah,ah ; Start with blank flags
  cmp al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,dl
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDBD  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIX]
  xor ah,ah ; Start with blank flags
  cmp al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,dl
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDBE  : INC_R

  ; Arithmetic
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIX]
  DAM_READ8
  xor ah,ah ; Start with blank flags
  cmp al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,dl
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB  : INC_R

  ; ddcb - extend opcode, take another 4 cycles

  sub dword [_nDozeCycles],4
  ; Fetch op, and skip the I?+nn byte:
  inc si
  DAM_FETCH8
  dec si
  add si,2
  xor dh,dh
  jmp [JumpTabDDCB+edx*4]
;****************************************************************
times ($$-$) & 3 db 0

OpDDE1  : INC_R

  mov di,word [DozeSP]
  DAM_READ16
  mov word [DozeIX],dx
  add word [DozeSP],2

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDE3  : INC_R

  ; Find the memory location:
  mov di,word [DozeSP]
  ; Swap HL with it:
  DAM_READ16
  mov word [Tmp16],dx
  mov dx,word [DozeIX]
  DAM_WRITE16
  mov dx,word [Tmp16]
  mov word [DozeIX],dx

  sub dword [_nDozeCycles],19
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDE5  : INC_R

  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,word [DozeIX]
  DAM_WRITE16

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDE9  : INC_R

  ; e9 - jp (hl) - PC <- HL/IX/IY
  mov dx,word [DozeIX]
  mov si,dx

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

  ; f9 - ld sp,HL/IX/IY
;****************************************************************
times ($$-$) & 3 db 0

OpDDF9  : INC_R

  mov dx,word [DozeIX]
  mov word [DozeSP],dx

  sub dword [_nDozeCycles],6
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD09  : INC_R

  mov bh,ah
  and bh,0xc4 ; Remember SZ---P--
  mov dx,word [DozeBC]
  ror ebx,16 ; Get access to a spare bit of ebx
  mov bx,dx
  mov dx,word [DozeIY]
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  add dl,bl
  adc dh,bh
  lahf
  mov word [DozeIY],dx
  ror ebx,16 ; Done with ebx
  and ah,0x11 ; ---H---C get flags.
  and dh,0x28
  or  ah,dh   ; --5H3--C
  or  ah,bh

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD19  : INC_R

  mov bh,ah
  and bh,0xc4 ; Remember SZ---P--
  mov dx,word [DozeDE]
  ror ebx,16 ; Get access to a spare bit of ebx
  mov bx,dx
  mov dx,word [DozeIY]
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  add dl,bl
  adc dh,bh
  lahf
  mov word [DozeIY],dx
  ror ebx,16 ; Done with ebx
  and ah,0x11 ; ---H---C get flags.
  and dh,0x28
  or  ah,dh   ; --5H3--C
  or  ah,bh

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD21  : INC_R

; Load Immediate 16-bit
  DAM_FETCH16
  add si,2
  mov word [DozeIY],dx

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD22  : INC_R

; Direct access to a memory location
  DAM_FETCH16
  add si,2
  mov di,dx
  mov dx,word [DozeIY]
  DAM_WRITE16

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD23  : INC_R

  inc word [DozeIY]
  ; (With 16-bit inc, flags aren't changed)

  sub dword [_nDozeCycles],6
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD24  : INC_R

  and ah,0x01 ; Keep carry flag
  inc byte [DozeIY+1]
  mov dl,byte [DozeIY+1]
  xor dh,dh
  or ah,byte [IncFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD25  : INC_R

  and ah,0x01 ; Keep carry flag
  dec byte [DozeIY+1]
  mov dl,byte [DozeIY+1]
  xor dh,dh
  or ah,byte [DecFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD26  : INC_R

; Load Value 8-bit
  DAM_FETCH8
  inc si
  mov byte [DozeIY+1],dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD29  : INC_R

  mov bh,ah
  and bh,0xc4 ; Remember SZ---P--
  mov dx,word [DozeIY]
  ror ebx,16 ; Get access to a spare bit of ebx
  mov bx,dx
  mov dx,word [DozeIY]
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  add dl,bl
  adc dh,bh
  lahf
  mov word [DozeIY],dx
  ror ebx,16 ; Done with ebx
  and ah,0x11 ; ---H---C get flags.
  and dh,0x28
  or  ah,dh   ; --5H3--C
  or  ah,bh

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD2A  : INC_R

; Direct access to a memory location
  DAM_FETCH16
  add si,2
  mov di,dx
  DAM_READ16
  mov word [DozeIY],dx

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD2B  : INC_R

  dec word [DozeIY]
  ; (With 16-bit inc, flags aren't changed)

  sub dword [_nDozeCycles],6
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD2C  : INC_R

  and ah,0x01 ; Keep carry flag
  inc byte [DozeIY]
  mov dl,byte [DozeIY]
  xor dh,dh
  or ah,byte [IncFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD2D  : INC_R

  and ah,0x01 ; Keep carry flag
  dec byte [DozeIY]
  mov dl,byte [DozeIY]
  xor dh,dh
  or ah,byte [DecFlag+edx]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD2E  : INC_R

; Load Value 8-bit
  DAM_FETCH8
  inc si
  mov byte [DozeIY],dl

  sub dword [_nDozeCycles],7
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD34  : INC_R

  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
; Takes more cycles from memory
  and ah,0x01 ; Keep carry flag
  DAM_READ8
  inc dl
  DAM_WRITE8
  xor dh,dh
  or ah,byte [IncFlag+edx]

  sub dword [_nDozeCycles],19
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD35  : INC_R

  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
; Takes more cycles from memory
  and ah,0x01 ; Keep carry flag
  DAM_READ8
  dec dl
  DAM_WRITE8
  xor dh,dh
  or ah,byte [DecFlag+edx]

  sub dword [_nDozeCycles],19
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD36  : INC_R

; Load Value 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  DAM_FETCH8
  inc si
  add di,word [DozeIY]
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD39  : INC_R

  mov bh,ah
  and bh,0xc4 ; Remember SZ---P--
  mov dx,word [DozeSP]
  ror ebx,16 ; Get access to a spare bit of ebx
  mov bx,dx
  mov dx,word [DozeIY]
  ; Do operation in two bytes to get the correct z80 flags (for the msb)
  add dl,bl
  adc dh,bh
  lahf
  mov word [DozeIY],dx
  ror ebx,16 ; Done with ebx
  and ah,0x11 ; ---H---C get flags.
  and dh,0x28
  or  ah,dh   ; --5H3--C
  or  ah,bh

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD44  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIY+1]
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD45  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIY]
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD46  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
; Copy to dl, then to destination
  DAM_READ8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD4C  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIY+1]
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD4D  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIY]
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD4E  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
; Copy to dl, then to destination
  DAM_READ8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD54  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIY+1]
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD55  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIY]
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD56  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
; Copy to dl, then to destination
  DAM_READ8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD5C  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIY+1]
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD5D  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIY]
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD5E  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
; Copy to dl, then to destination
  DAM_READ8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD60  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeBC+1]
  mov byte [DozeIY+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD61  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeBC]
  mov byte [DozeIY+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD62  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeDE+1]
  mov byte [DozeIY+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD63  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeDE]
  mov byte [DozeIY+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD64  : INC_R

; Load 8-bit

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD65  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIY]
  mov byte [DozeIY+1],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD66  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
; Copy to dl, then to destination
  DAM_READ8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD67  : INC_R

; Load 8-bit
  mov byte [DozeIY+1],al

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD68  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeBC+1]
  mov byte [DozeIY],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD69  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeBC]
  mov byte [DozeIY],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD6A  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeDE+1]
  mov byte [DozeIY],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD6B  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeDE]
  mov byte [DozeIY],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD6C  : INC_R

; Load 8-bit
; Copy to dl, then to destination
  mov dl,byte [DozeIY+1]
  mov byte [DozeIY],dl

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD6D  : INC_R

; Load 8-bit

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD6E  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
; Copy to dl, then to destination
  DAM_READ8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD6F  : INC_R

; Load 8-bit
  mov byte [DozeIY],al

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD70  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
; Copy to dl, then to destination
  mov dl,byte [DozeBC+1]
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD71  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
; Copy to dl, then to destination
  mov dl,byte [DozeBC]
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD72  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
; Copy to dl, then to destination
  mov dl,byte [DozeDE+1]
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD73  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
; Copy to dl, then to destination
  mov dl,byte [DozeDE]
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD74  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
; Copy to dl, then to destination
  mov dl,ch
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD75  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
; Copy to dl, then to destination
  mov dl,cl
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD77  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
; Copy to dl, then to destination
  mov dl,al
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD7C  : INC_R

; Load 8-bit
  mov al,byte [DozeIY+1]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD7D  : INC_R

; Load 8-bit
  mov al,byte [DozeIY]

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD7E  : INC_R

; Load 8-bit
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
; Copy to dl, then to destination
  DAM_READ8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD84  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIY+1]
  xor ah,ah ; Start with blank flags
  add al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD85  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIY]
  xor ah,ah ; Start with blank flags
  add al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD86  : INC_R

  ; Arithmetic
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
  DAM_READ8
  xor ah,ah ; Start with blank flags
  add al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD8C  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIY+1]
  sahf ; Get the carry flag
  adc al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD8D  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIY]
  sahf ; Get the carry flag
  adc al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD8E  : INC_R

  ; Arithmetic
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
  DAM_READ8
  sahf ; Get the carry flag
  adc al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD94  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIY+1]
  xor ah,ah ; Start with blank flags
  sub al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD95  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIY]
  xor ah,ah ; Start with blank flags
  sub al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD96  : INC_R

  ; Arithmetic
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
  DAM_READ8
  xor ah,ah ; Start with blank flags
  sub al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD9C  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIY+1]
  sahf ; Get the carry flag
  sbb al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD9D  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIY]
  sahf ; Get the carry flag
  sbb al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFD9E  : INC_R

  ; Arithmetic
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
  DAM_READ8
  sahf ; Get the carry flag
  sbb al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDA4  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIY+1]
  xor ah,ah ; Start with blank flags
  and al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x10 ; Set bit 4 to 1 (AND operation)

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDA5  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIY]
  xor ah,ah ; Start with blank flags
  and al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x10 ; Set bit 4 to 1 (AND operation)

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDA6  : INC_R

  ; Arithmetic
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
  DAM_READ8
  xor ah,ah ; Start with blank flags
  and al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x10 ; Set bit 4 to 1 (AND operation)

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDAC  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIY+1]
  xor ah,ah ; Start with blank flags
  xor al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDAD  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIY]
  xor ah,ah ; Start with blank flags
  xor al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDAE  : INC_R

  ; Arithmetic
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
  DAM_READ8
  xor ah,ah ; Start with blank flags
  xor al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDB4  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIY+1]
  xor ah,ah ; Start with blank flags
  or al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDB5  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIY]
  xor ah,ah ; Start with blank flags
  or al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDB6  : INC_R

  ; Arithmetic
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
  DAM_READ8
  xor ah,ah ; Start with blank flags
  or al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  and ah,0xd5 ; SZ-A -P-C
  mov dh,al
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDBC  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIY+1]
  xor ah,ah ; Start with blank flags
  cmp al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,dl
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDBD  : INC_R

  ; Arithmetic
  mov dl,byte [DozeIY]
  xor ah,ah ; Start with blank flags
  cmp al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,dl
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDBE  : INC_R

  ; Arithmetic
  ; Get IX/IY offset into di
  DAM_FETCH8
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  inc si
  add di,word [DozeIY]
  DAM_READ8
  xor ah,ah ; Start with blank flags
  cmp al,dl ; DO ARITHMETIC OPERATION
  ; Get the correct flags ----
  lahf ; Flag bits -> AH
  seto dh ; dh=1 or 0
  and ah,0xd1 ; SZ-A ---C
  rol dh,2
  or ah,dh ; Get overflow flag
  mov dh,dl
  and dh,0x28 ; S-5- 3---
  or  ah,dh   ; SZ5A 3P-C
  ; End of get the correct flags ----
  or ah,0x02 ; Set bit 1 - last operation was a subtraction

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB  : INC_R

  ; fdcb - extend opcode, take another 4 cycles

  sub dword [_nDozeCycles],4
  ; Fetch op, and skip the I?+nn byte:
  inc si
  DAM_FETCH8
  dec si
  add si,2
  xor dh,dh
  jmp [JumpTabFDCB+edx*4]
;****************************************************************
times ($$-$) & 3 db 0

OpFDE1  : INC_R

  mov di,word [DozeSP]
  DAM_READ16
  mov word [DozeIY],dx
  add word [DozeSP],2

  sub dword [_nDozeCycles],10
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDE3  : INC_R

  ; Find the memory location:
  mov di,word [DozeSP]
  ; Swap HL with it:
  DAM_READ16
  mov word [Tmp16],dx
  mov dx,word [DozeIY]
  DAM_WRITE16
  mov dx,word [Tmp16]
  mov word [DozeIY],dx

  sub dword [_nDozeCycles],19
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDE5  : INC_R

  sub word [DozeSP],2
  mov di,word [DozeSP]
  mov dx,word [DozeIY]
  DAM_WRITE16

  sub dword [_nDozeCycles],11
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDE9  : INC_R

  ; e9 - jp (hl) - PC <- HL/IX/IY
  mov dx,word [DozeIY]
  mov si,dx

  sub dword [_nDozeCycles],4
  jle near DozeRunEnd
  FETCH_OP

  ; f9 - ld sp,HL/IX/IY
;****************************************************************
times ($$-$) & 3 db 0

OpFDF9  : INC_R

  mov dx,word [DozeIY]
  mov word [DozeSP],dx

  sub dword [_nDozeCycles],6
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB00: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC+1]

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB01: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC]

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB02: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE+1]

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB03: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE]

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB04: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX+1]

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB05: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX]

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB06: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB07: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,al

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB08: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC+1]

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB09: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC]

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB0A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE+1]

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB0B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE]

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB0C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX+1]

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB0D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX]

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB0E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB0F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,al

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB10: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC+1]

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB11: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC]

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB12: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE+1]

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB13: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE]

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB14: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX+1]

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB15: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX]

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB16: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB17: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,al

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB18: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC+1]

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB19: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC]

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB1A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE+1]

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB1B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE]

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB1C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX+1]

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB1D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX]

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB1E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB1F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,al

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB20: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC+1]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB21: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB22: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE+1]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB23: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB24: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX+1]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB25: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB26: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB27: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,al

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB28: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC+1]

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB29: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC]

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB2A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE+1]

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB2B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE]

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB2C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX+1]

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB2D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX]

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB2E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB2F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,al

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB30: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC+1]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB31: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB32: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE+1]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB33: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB34: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX+1]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB35: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB36: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB37: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,al

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB38: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC+1]

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB39: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC]

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB3A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE+1]

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB3B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE]

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB3C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX+1]

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB3D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX]

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB3E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB3F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,al

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB40: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB41: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB42: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB43: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB44: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX+1]
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB45: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX]
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB46: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB47: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,al
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB48: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB49: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB4A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB4B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB4C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX+1]
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB4D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX]
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB4E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB4F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,al
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB50: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB51: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB52: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB53: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB54: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX+1]
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB55: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX]
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB56: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB57: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,al
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB58: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB59: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB5A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB5B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB5C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX+1]
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB5D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX]
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB5E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB5F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,al
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB60: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB61: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB62: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB63: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB64: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX+1]
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB65: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX]
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB66: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB67: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,al
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB68: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB69: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB6A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB6B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB6C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX+1]
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB6D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX]
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB6E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB6F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,al
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB70: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB71: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB72: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB73: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB74: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX+1]
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB75: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX]
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB76: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB77: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,al
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB78: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB79: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB7A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB7B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB7C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX+1]
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB7D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,byte [DozeIX]
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB7E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB7F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  mov dl,al
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB80: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfe
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB81: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfe
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB82: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfe
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB83: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfe
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB84: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfe
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB85: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfe
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB86: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfe
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB87: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfe
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB88: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfd
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB89: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfd
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB8A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfd
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB8B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfd
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB8C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfd
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB8D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfd
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB8E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfd
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB8F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfd
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB90: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfb
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB91: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfb
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB92: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfb
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB93: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfb
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB94: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfb
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB95: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfb
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB96: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfb
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB97: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xfb
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB98: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xf7
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB99: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xf7
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB9A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xf7
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB9B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xf7
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB9C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xf7
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB9D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xf7
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB9E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xf7
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCB9F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xf7
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBA0: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xef
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBA1: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xef
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBA2: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xef
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBA3: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xef
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBA4: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xef
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBA5: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xef
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBA6: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xef
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBA7: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xef
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBA8: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xdf
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBA9: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xdf
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBAA: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xdf
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBAB: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xdf
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBAC: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xdf
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBAD: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xdf
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBAE: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xdf
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBAF: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xdf
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBB0: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xbf
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBB1: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xbf
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBB2: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xbf
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBB3: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xbf
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBB4: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xbf
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBB5: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xbf
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBB6: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xbf
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBB7: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0xbf
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBB8: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0x7f
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBB9: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0x7f
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBBA: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0x7f
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBBB: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0x7f
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBBC: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0x7f
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBBD: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0x7f
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBBE: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0x7f
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBBF: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  and dl,0x7f
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBC0: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x01
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBC1: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x01
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBC2: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x01
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBC3: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x01
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBC4: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x01
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBC5: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x01
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBC6: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x01
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBC7: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x01
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBC8: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x02
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBC9: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x02
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBCA: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x02
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBCB: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x02
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBCC: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x02
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBCD: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x02
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBCE: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x02
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBCF: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x02
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBD0: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x04
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBD1: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x04
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBD2: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x04
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBD3: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x04
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBD4: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x04
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBD5: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x04
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBD6: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x04
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBD7: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x04
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBD8: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x08
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBD9: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x08
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBDA: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x08
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBDB: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x08
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBDC: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x08
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBDD: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x08
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBDE: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x08
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBDF: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x08
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBE0: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x10
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBE1: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x10
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBE2: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x10
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBE3: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x10
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBE4: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x10
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBE5: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x10
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBE6: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x10
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBE7: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x10
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBE8: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x20
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBE9: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x20
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBEA: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x20
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBEB: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x20
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBEC: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x20
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBED: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x20
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBEE: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x20
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBEF: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x20
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBF0: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x40
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBF1: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x40
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBF2: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x40
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBF3: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x40
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBF4: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x40
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBF5: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x40
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBF6: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x40
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBF7: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x40
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBF8: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x80
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBF9: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x80
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBFA: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x80
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBFB: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x80
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBFC: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x80
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBFD: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x80
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBFE: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x80
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpDDCBFF: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIX]
  DAM_READ8
  or  dl,0x80
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB00: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC+1]

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB01: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC]

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB02: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE+1]

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB03: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE]

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB04: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY+1]

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB05: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY]

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB06: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB07: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,al

  sahf
  rol dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB08: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC+1]

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB09: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC]

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB0A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE+1]

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB0B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE]

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB0C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY+1]

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB0D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY]

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB0E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB0F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,al

  sahf
  ror dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB10: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC+1]

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB11: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC]

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB12: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE+1]

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB13: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE]

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB14: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY+1]

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB15: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY]

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB16: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB17: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,al

  sahf
  rcl dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB18: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC+1]

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB19: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC]

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB1A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE+1]

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB1B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE]

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB1C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY+1]

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB1D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY]

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB1E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB1F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,al

  sahf
  rcr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB20: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC+1]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB21: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB22: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE+1]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB23: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB24: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY+1]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB25: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB26: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB27: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,al

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB28: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC+1]

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB29: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC]

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB2A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE+1]

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB2B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE]

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB2C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY+1]

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB2D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY]

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB2E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB2F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,al

  sahf
  sar dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB30: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC+1]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB31: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB32: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE+1]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB33: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB34: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY+1]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB35: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY]

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB36: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB37: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,al

  sahf
  sal dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB38: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC+1]

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB39: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC]

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB3A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE+1]

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB3B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE]

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB3C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY+1]

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB3D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY]

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB3E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB3F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,al

  sahf
  shr dl,1
  setc dh     ; ---- ---C
  test dl,dl
  lahf
  and ah,0xc4 ; SZ-- -P--
  or  ah,dh   ; SZ-- -P-C

  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB40: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB41: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB42: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB43: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB44: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY+1]
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB45: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY]
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB46: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB47: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,al
  mov dh,ah
  and dl,0x01
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB48: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB49: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB4A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB4B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB4C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY+1]
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB4D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY]
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB4E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB4F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,al
  mov dh,ah
  and dl,0x02
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB50: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB51: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB52: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB53: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB54: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY+1]
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB55: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY]
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB56: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB57: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,al
  mov dh,ah
  and dl,0x04
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB58: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB59: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB5A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB5B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB5C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY+1]
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB5D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY]
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB5E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB5F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,al
  mov dh,ah
  and dl,0x08
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB60: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB61: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB62: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB63: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB64: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY+1]
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB65: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY]
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB66: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB67: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,al
  mov dh,ah
  and dl,0x10
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB68: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB69: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB6A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB6B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB6C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY+1]
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB6D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY]
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB6E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB6F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,al
  mov dh,ah
  and dl,0x20
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB70: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB71: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB72: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB73: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB74: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY+1]
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB75: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY]
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB76: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB77: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,al
  mov dh,ah
  and dl,0x40
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB78: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC+1]
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB79: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeBC]
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB7A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE+1]
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB7B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeDE]
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB7C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY+1]
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB7D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,byte [DozeIY]
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB7E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB7F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  mov dl,al
  mov dh,ah
  and dl,0x80
  lahf
  and dh,0x01 ; Preserve ---- ---C
  and ah,0xc4 ;          SZ-- -P--
  or  ah,dh   ;          SZ-- -P0C
  or  ah,0x10 ;          SZ-1 -P0C

  sub dword [_nDozeCycles],16
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB80: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfe
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB81: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfe
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB82: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfe
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB83: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfe
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB84: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfe
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB85: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfe
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB86: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfe
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB87: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfe
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB88: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfd
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB89: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfd
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB8A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfd
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB8B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfd
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB8C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfd
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB8D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfd
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB8E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfd
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB8F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfd
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB90: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfb
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB91: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfb
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB92: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfb
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB93: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfb
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB94: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfb
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB95: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfb
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB96: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfb
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB97: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xfb
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB98: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xf7
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB99: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xf7
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB9A: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xf7
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB9B: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xf7
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB9C: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xf7
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB9D: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xf7
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB9E: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xf7
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCB9F: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xf7
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBA0: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xef
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBA1: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xef
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBA2: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xef
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBA3: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xef
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBA4: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xef
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBA5: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xef
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBA6: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xef
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBA7: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xef
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBA8: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xdf
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBA9: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xdf
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBAA: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xdf
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBAB: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xdf
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBAC: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xdf
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBAD: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xdf
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBAE: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xdf
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBAF: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xdf
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBB0: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xbf
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBB1: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xbf
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBB2: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xbf
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBB3: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xbf
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBB4: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xbf
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBB5: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xbf
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBB6: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xbf
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBB7: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0xbf
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBB8: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0x7f
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBB9: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0x7f
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBBA: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0x7f
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBBB: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0x7f
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBBC: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0x7f
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBBD: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0x7f
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBBE: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0x7f
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBBF: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  and dl,0x7f
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBC0: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x01
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBC1: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x01
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBC2: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x01
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBC3: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x01
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBC4: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x01
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBC5: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x01
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBC6: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x01
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBC7: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x01
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBC8: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x02
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBC9: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x02
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBCA: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x02
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBCB: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x02
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBCC: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x02
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBCD: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x02
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBCE: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x02
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBCF: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x02
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBD0: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x04
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBD1: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x04
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBD2: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x04
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBD3: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x04
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBD4: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x04
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBD5: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x04
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBD6: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x04
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBD7: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x04
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBD8: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x08
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBD9: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x08
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBDA: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x08
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBDB: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x08
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBDC: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x08
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBDD: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x08
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBDE: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x08
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBDF: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x08
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBE0: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x10
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBE1: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x10
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBE2: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x10
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBE3: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x10
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBE4: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x10
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBE5: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x10
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBE6: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x10
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBE7: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x10
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBE8: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x20
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBE9: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x20
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBEA: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x20
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBEB: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x20
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBEC: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x20
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBED: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x20
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBEE: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x20
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBEF: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x20
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBF0: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x40
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBF1: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x40
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBF2: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x40
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBF3: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x40
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBF4: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x40
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBF5: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x40
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBF6: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x40
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBF7: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x40
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBF8: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x80
  DAM_WRITE8
  mov byte [DozeBC+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBF9: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x80
  DAM_WRITE8
  mov byte [DozeBC],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBFA: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x80
  DAM_WRITE8
  mov byte [DozeDE+1],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBFB: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x80
  DAM_WRITE8
  mov byte [DozeDE],dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBFC: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x80
  DAM_WRITE8
  mov ch,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBFD: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x80
  DAM_WRITE8
  mov cl,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBFE: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x80
  DAM_WRITE8

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP

;****************************************************************
times ($$-$) & 3 db 0

OpFDCBFF: INC_R

  ; Get IX/IY offset into di
  sub si,2
  DAM_FETCH8
  add si,2
  xor dh,dh
  xor dl,0x80
  sub dx,0x80
  mov di,dx
  add di,word [DozeIY]
  DAM_READ8
  or  dl,0x80
  DAM_WRITE8
  mov al,dl

  sub dword [_nDozeCycles],15
  jle near DozeRunEnd
  FETCH_OP



JumpTab:     ; Normal   opcodes:
dd Op00,Op01,Op02,Op03,Op04,Op05,Op06,Op07,Op08,Op09,Op0A,Op0B,Op0C,Op0D,Op0E,Op0F
dd Op10,Op11,Op12,Op13,Op14,Op15,Op16,Op17,Op18,Op19,Op1A,Op1B,Op1C,Op1D,Op1E,Op1F
dd Op20,Op21,Op22,Op23,Op24,Op25,Op26,Op27,Op28,Op29,Op2A,Op2B,Op2C,Op2D,Op2E,Op2F
dd Op30,Op31,Op32,Op33,Op34,Op35,Op36,Op37,Op38,Op39,Op3A,Op3B,Op3C,Op3D,Op3E,Op3F
dd Op40,Op41,Op42,Op43,Op44,Op45,Op46,Op47,Op48,Op49,Op4A,Op4B,Op4C,Op4D,Op4E,Op4F
dd Op50,Op51,Op52,Op53,Op54,Op55,Op56,Op57,Op58,Op59,Op5A,Op5B,Op5C,Op5D,Op5E,Op5F
dd Op60,Op61,Op62,Op63,Op64,Op65,Op66,Op67,Op68,Op69,Op6A,Op6B,Op6C,Op6D,Op6E,Op6F
dd Op70,Op71,Op72,Op73,Op74,Op75,Op76,Op77,Op78,Op79,Op7A,Op7B,Op7C,Op7D,Op7E,Op7F
dd Op80,Op81,Op82,Op83,Op84,Op85,Op86,Op87,Op88,Op89,Op8A,Op8B,Op8C,Op8D,Op8E,Op8F
dd Op90,Op91,Op92,Op93,Op94,Op95,Op96,Op97,Op98,Op99,Op9A,Op9B,Op9C,Op9D,Op9E,Op9F
dd OpA0,OpA1,OpA2,OpA3,OpA4,OpA5,OpA6,OpA7,OpA8,OpA9,OpAA,OpAB,OpAC,OpAD,OpAE,OpAF
dd OpB0,OpB1,OpB2,OpB3,OpB4,OpB5,OpB6,OpB7,OpB8,OpB9,OpBA,OpBB,OpBC,OpBD,OpBE,OpBF
dd OpC0,OpC1,OpC2,OpC3,OpC4,OpC5,OpC6,OpC7,OpC8,OpC9,OpCA,OpCB,OpCC,OpCD,OpCE,OpCF
dd OpD0,OpD1,OpD2,OpD3,OpD4,OpD5,OpD6,OpD7,OpD8,OpD9,OpDA,OpDB,OpDC,OpDD,OpDE,OpDF
dd OpE0,OpE1,OpE2,OpE3,OpE4,OpE5,OpE6,OpE7,OpE8,OpE9,OpEA,OpEB,OpEC,OpED,OpEE,OpEF
dd OpF0,OpF1,OpF2,OpF3,OpF4,OpF5,OpF6,OpF7,OpF8,OpF9,OpFA,OpFB,OpFC,OpFD,OpFE,OpFF

JumpTabCB:   ; CBxx     opcodes:
dd OpCB00,OpCB01,OpCB02,OpCB03,OpCB04,OpCB05,OpCB06,OpCB07,OpCB08,OpCB09,OpCB0A,OpCB0B,OpCB0C,OpCB0D,OpCB0E,OpCB0F
dd OpCB10,OpCB11,OpCB12,OpCB13,OpCB14,OpCB15,OpCB16,OpCB17,OpCB18,OpCB19,OpCB1A,OpCB1B,OpCB1C,OpCB1D,OpCB1E,OpCB1F
dd OpCB20,OpCB21,OpCB22,OpCB23,OpCB24,OpCB25,OpCB26,OpCB27,OpCB28,OpCB29,OpCB2A,OpCB2B,OpCB2C,OpCB2D,OpCB2E,OpCB2F
dd OpCB30,OpCB31,OpCB32,OpCB33,OpCB34,OpCB35,OpCB36,OpCB37,OpCB38,OpCB39,OpCB3A,OpCB3B,OpCB3C,OpCB3D,OpCB3E,OpCB3F
dd OpCB40,OpCB41,OpCB42,OpCB43,OpCB44,OpCB45,OpCB46,OpCB47,OpCB48,OpCB49,OpCB4A,OpCB4B,OpCB4C,OpCB4D,OpCB4E,OpCB4F
dd OpCB50,OpCB51,OpCB52,OpCB53,OpCB54,OpCB55,OpCB56,OpCB57,OpCB58,OpCB59,OpCB5A,OpCB5B,OpCB5C,OpCB5D,OpCB5E,OpCB5F
dd OpCB60,OpCB61,OpCB62,OpCB63,OpCB64,OpCB65,OpCB66,OpCB67,OpCB68,OpCB69,OpCB6A,OpCB6B,OpCB6C,OpCB6D,OpCB6E,OpCB6F
dd OpCB70,OpCB71,OpCB72,OpCB73,OpCB74,OpCB75,OpCB76,OpCB77,OpCB78,OpCB79,OpCB7A,OpCB7B,OpCB7C,OpCB7D,OpCB7E,OpCB7F
dd OpCB80,OpCB81,OpCB82,OpCB83,OpCB84,OpCB85,OpCB86,OpCB87,OpCB88,OpCB89,OpCB8A,OpCB8B,OpCB8C,OpCB8D,OpCB8E,OpCB8F
dd OpCB90,OpCB91,OpCB92,OpCB93,OpCB94,OpCB95,OpCB96,OpCB97,OpCB98,OpCB99,OpCB9A,OpCB9B,OpCB9C,OpCB9D,OpCB9E,OpCB9F
dd OpCBA0,OpCBA1,OpCBA2,OpCBA3,OpCBA4,OpCBA5,OpCBA6,OpCBA7,OpCBA8,OpCBA9,OpCBAA,OpCBAB,OpCBAC,OpCBAD,OpCBAE,OpCBAF
dd OpCBB0,OpCBB1,OpCBB2,OpCBB3,OpCBB4,OpCBB5,OpCBB6,OpCBB7,OpCBB8,OpCBB9,OpCBBA,OpCBBB,OpCBBC,OpCBBD,OpCBBE,OpCBBF
dd OpCBC0,OpCBC1,OpCBC2,OpCBC3,OpCBC4,OpCBC5,OpCBC6,OpCBC7,OpCBC8,OpCBC9,OpCBCA,OpCBCB,OpCBCC,OpCBCD,OpCBCE,OpCBCF
dd OpCBD0,OpCBD1,OpCBD2,OpCBD3,OpCBD4,OpCBD5,OpCBD6,OpCBD7,OpCBD8,OpCBD9,OpCBDA,OpCBDB,OpCBDC,OpCBDD,OpCBDE,OpCBDF
dd OpCBE0,OpCBE1,OpCBE2,OpCBE3,OpCBE4,OpCBE5,OpCBE6,OpCBE7,OpCBE8,OpCBE9,OpCBEA,OpCBEB,OpCBEC,OpCBED,OpCBEE,OpCBEF
dd OpCBF0,OpCBF1,OpCBF2,OpCBF3,OpCBF4,OpCBF5,OpCBF6,OpCBF7,OpCBF8,OpCBF9,OpCBFA,OpCBFB,OpCBFC,OpCBFD,OpCBFE,OpCBFF

JumpTabED:   ; EDxx     opcodes:
dd Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00
dd Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00
dd Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00
dd Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00
dd OpED40,OpED41,OpED42,OpED43,OpED44,OpED45,OpED46,OpED47,OpED48,OpED49,OpED4A,OpED4B,OpED44,OpED45,OpED4E,OpED4F
dd OpED50,OpED51,OpED52,OpED53,OpED44,OpED45,OpED56,OpED57,OpED58,OpED59,OpED5A,OpED5B,OpED44,OpED45,OpED5E,OpED5F
dd OpED60,OpED61,OpED62,OpED63,OpED44,OpED45,OpED46,OpED67,OpED68,OpED69,OpED6A,OpED6B,OpED44,OpED45,OpED4E,OpED6F
dd OpED70,OpED71,OpED72,OpED73,OpED44,OpED45,OpED56,Op00,OpED78,OpED79,OpED7A,OpED7B,OpED44,OpED45,OpED5E,Op00
dd Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00
dd Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00
dd OpEDA0,OpEDA1,OpEDA2,OpEDA3,Op00,Op00,Op00,Op00,OpEDA8,OpEDA9,OpEDAA,OpEDAB,Op00,Op00,Op00,Op00
dd OpEDB0,OpEDB1,OpEDB2,OpEDB3,Op00,Op00,Op00,Op00,OpEDB8,OpEDB9,OpEDBA,OpEDBB,Op00,Op00,Op00,Op00
dd Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00
dd Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00
dd Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00
dd Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00,Op00

JumpTabDD:   ; DDxx     opcodes:
dd Op00,Op01,Op00,Op03,Op04,Op05,Op06,Op00,Op00,OpDD09,Op00,Op0B,Op0C,Op0D,Op0E,Op00
dd Op00,Op11,Op00,Op13,Op14,Op15,Op16,Op00,Op00,OpDD19,Op00,Op1B,Op1C,Op1D,Op1E,Op00
dd Op20,OpDD21,OpDD22,OpDD23,OpDD24,OpDD25,OpDD26,Op00,Op28,OpDD29,OpDD2A,OpDD2B,OpDD2C,OpDD2D,OpDD2E,Op00
dd Op30,Op31,Op00,Op33,OpDD34,OpDD35,OpDD36,Op00,Op38,OpDD39,Op00,Op3B,Op3C,Op3D,Op3E,Op00
dd Op40,Op41,Op42,Op43,OpDD44,OpDD45,OpDD46,Op47,Op48,Op49,Op4A,Op4B,OpDD4C,OpDD4D,OpDD4E,Op4F
dd Op50,Op51,Op52,Op53,OpDD54,OpDD55,OpDD56,Op57,Op58,Op59,Op5A,Op5B,OpDD5C,OpDD5D,OpDD5E,Op5F
dd OpDD60,OpDD61,OpDD62,OpDD63,OpDD64,OpDD65,OpDD66,OpDD67,OpDD68,OpDD69,OpDD6A,OpDD6B,OpDD6C,OpDD6D,OpDD6E,OpDD6F
dd OpDD70,OpDD71,OpDD72,OpDD73,OpDD74,OpDD75,Op76,OpDD77,Op78,Op79,Op7A,Op7B,OpDD7C,OpDD7D,OpDD7E,Op7F
dd Op80,Op81,Op82,Op83,OpDD84,OpDD85,OpDD86,Op87,Op88,Op89,Op8A,Op8B,OpDD8C,OpDD8D,OpDD8E,Op8F
dd Op90,Op91,Op92,Op93,OpDD94,OpDD95,OpDD96,Op97,Op98,Op99,Op9A,Op9B,OpDD9C,OpDD9D,OpDD9E,Op9F
dd OpA0,OpA1,OpA2,OpA3,OpDDA4,OpDDA5,OpDDA6,OpA7,OpA8,OpA9,OpAA,OpAB,OpDDAC,OpDDAD,OpDDAE,OpAF
dd OpB0,OpB1,OpB2,OpB3,OpDDB4,OpDDB5,OpDDB6,OpB7,OpB8,OpB9,OpBA,OpBB,OpDDBC,OpDDBD,OpDDBE,OpBF
dd OpC0,OpC1,OpC2,Op00,OpC4,OpC5,OpC6,OpC7,OpC8,Op00,OpCA,OpDDCB,OpCC,Op00,OpCE,OpCF
dd OpD0,OpD1,OpD2,Op00,OpD4,OpD5,OpD6,OpD7,OpD8,Op00,OpDA,Op00,OpDC,Op00,OpDE,OpDF
dd OpE0,OpDDE1,OpE2,OpDDE3,OpE4,OpDDE5,OpE6,OpE7,OpE8,OpDDE9,OpEA,Op00,OpEC,Op00,OpEE,OpEF
dd OpF0,OpF1,OpF2,Op00,OpF4,OpF5,OpF6,OpF7,OpF8,OpDDF9,OpFA,Op00,OpFC,Op00,OpFE,OpFF

JumpTabFD:   ; FDxx     opcodes:
dd Op00,Op01,Op00,Op03,Op04,Op05,Op06,Op00,Op00,OpFD09,Op00,Op0B,Op0C,Op0D,Op0E,Op00
dd Op00,Op11,Op00,Op13,Op14,Op15,Op16,Op00,Op00,OpFD19,Op00,Op1B,Op1C,Op1D,Op1E,Op00
dd Op20,OpFD21,OpFD22,OpFD23,OpFD24,OpFD25,OpFD26,Op00,Op28,OpFD29,OpFD2A,OpFD2B,OpFD2C,OpFD2D,OpFD2E,Op00
dd Op30,Op31,Op00,Op33,OpFD34,OpFD35,OpFD36,Op00,Op38,OpFD39,Op00,Op3B,Op3C,Op3D,Op3E,Op00
dd Op40,Op41,Op42,Op43,OpFD44,OpFD45,OpFD46,Op47,Op48,Op49,Op4A,Op4B,OpFD4C,OpFD4D,OpFD4E,Op4F
dd Op50,Op51,Op52,Op53,OpFD54,OpFD55,OpFD56,Op57,Op58,Op59,Op5A,Op5B,OpFD5C,OpFD5D,OpFD5E,Op5F
dd OpFD60,OpFD61,OpFD62,OpFD63,OpFD64,OpFD65,OpFD66,OpFD67,OpFD68,OpFD69,OpFD6A,OpFD6B,OpFD6C,OpFD6D,OpFD6E,OpFD6F
dd OpFD70,OpFD71,OpFD72,OpFD73,OpFD74,OpFD75,Op76,OpFD77,Op78,Op79,Op7A,Op7B,OpFD7C,OpFD7D,OpFD7E,Op7F
dd Op80,Op81,Op82,Op83,OpFD84,OpFD85,OpFD86,Op87,Op88,Op89,Op8A,Op8B,OpFD8C,OpFD8D,OpFD8E,Op8F
dd Op90,Op91,Op92,Op93,OpFD94,OpFD95,OpFD96,Op97,Op98,Op99,Op9A,Op9B,OpFD9C,OpFD9D,OpFD9E,Op9F
dd OpA0,OpA1,OpA2,OpA3,OpFDA4,OpFDA5,OpFDA6,OpA7,OpA8,OpA9,OpAA,OpAB,OpFDAC,OpFDAD,OpFDAE,OpAF
dd OpB0,OpB1,OpB2,OpB3,OpFDB4,OpFDB5,OpFDB6,OpB7,OpB8,OpB9,OpBA,OpBB,OpFDBC,OpFDBD,OpFDBE,OpBF
dd OpC0,OpC1,OpC2,Op00,OpC4,OpC5,OpC6,OpC7,OpC8,Op00,OpCA,OpFDCB,OpCC,Op00,OpCE,OpCF
dd OpD0,OpD1,OpD2,Op00,OpD4,OpD5,OpD6,OpD7,OpD8,Op00,OpDA,Op00,OpDC,Op00,OpDE,OpDF
dd OpE0,OpFDE1,OpE2,OpFDE3,OpE4,OpFDE5,OpE6,OpE7,OpE8,OpFDE9,OpEA,Op00,OpEC,Op00,OpEE,OpEF
dd OpF0,OpF1,OpF2,Op00,OpF4,OpF5,OpF6,OpF7,OpF8,OpFDF9,OpFA,Op00,OpFC,Op00,OpFE,OpFF

JumpTabDDCB: ; DDCB__xx opcodes:
dd OpDDCB00,OpDDCB01,OpDDCB02,OpDDCB03,OpDDCB04,OpDDCB05,OpDDCB06,OpDDCB07,OpDDCB08,OpDDCB09,OpDDCB0A,OpDDCB0B,OpDDCB0C,OpDDCB0D,OpDDCB0E,OpDDCB0F
dd OpDDCB10,OpDDCB11,OpDDCB12,OpDDCB13,OpDDCB14,OpDDCB15,OpDDCB16,OpDDCB17,OpDDCB18,OpDDCB19,OpDDCB1A,OpDDCB1B,OpDDCB1C,OpDDCB1D,OpDDCB1E,OpDDCB1F
dd OpDDCB20,OpDDCB21,OpDDCB22,OpDDCB23,OpDDCB24,OpDDCB25,OpDDCB26,OpDDCB27,OpDDCB28,OpDDCB29,OpDDCB2A,OpDDCB2B,OpDDCB2C,OpDDCB2D,OpDDCB2E,OpDDCB2F
dd OpDDCB30,OpDDCB31,OpDDCB32,OpDDCB33,OpDDCB34,OpDDCB35,OpDDCB36,OpDDCB37,OpDDCB38,OpDDCB39,OpDDCB3A,OpDDCB3B,OpDDCB3C,OpDDCB3D,OpDDCB3E,OpDDCB3F
dd OpDDCB40,OpDDCB41,OpDDCB42,OpDDCB43,OpDDCB44,OpDDCB45,OpDDCB46,OpDDCB47,OpDDCB48,OpDDCB49,OpDDCB4A,OpDDCB4B,OpDDCB4C,OpDDCB4D,OpDDCB4E,OpDDCB4F
dd OpDDCB50,OpDDCB51,OpDDCB52,OpDDCB53,OpDDCB54,OpDDCB55,OpDDCB56,OpDDCB57,OpDDCB58,OpDDCB59,OpDDCB5A,OpDDCB5B,OpDDCB5C,OpDDCB5D,OpDDCB5E,OpDDCB5F
dd OpDDCB60,OpDDCB61,OpDDCB62,OpDDCB63,OpDDCB64,OpDDCB65,OpDDCB66,OpDDCB67,OpDDCB68,OpDDCB69,OpDDCB6A,OpDDCB6B,OpDDCB6C,OpDDCB6D,OpDDCB6E,OpDDCB6F
dd OpDDCB70,OpDDCB71,OpDDCB72,OpDDCB73,OpDDCB74,OpDDCB75,OpDDCB76,OpDDCB77,OpDDCB78,OpDDCB79,OpDDCB7A,OpDDCB7B,OpDDCB7C,OpDDCB7D,OpDDCB7E,OpDDCB7F
dd OpDDCB80,OpDDCB81,OpDDCB82,OpDDCB83,OpDDCB84,OpDDCB85,OpDDCB86,OpDDCB87,OpDDCB88,OpDDCB89,OpDDCB8A,OpDDCB8B,OpDDCB8C,OpDDCB8D,OpDDCB8E,OpDDCB8F
dd OpDDCB90,OpDDCB91,OpDDCB92,OpDDCB93,OpDDCB94,OpDDCB95,OpDDCB96,OpDDCB97,OpDDCB98,OpDDCB99,OpDDCB9A,OpDDCB9B,OpDDCB9C,OpDDCB9D,OpDDCB9E,OpDDCB9F
dd OpDDCBA0,OpDDCBA1,OpDDCBA2,OpDDCBA3,OpDDCBA4,OpDDCBA5,OpDDCBA6,OpDDCBA7,OpDDCBA8,OpDDCBA9,OpDDCBAA,OpDDCBAB,OpDDCBAC,OpDDCBAD,OpDDCBAE,OpDDCBAF
dd OpDDCBB0,OpDDCBB1,OpDDCBB2,OpDDCBB3,OpDDCBB4,OpDDCBB5,OpDDCBB6,OpDDCBB7,OpDDCBB8,OpDDCBB9,OpDDCBBA,OpDDCBBB,OpDDCBBC,OpDDCBBD,OpDDCBBE,OpDDCBBF
dd OpDDCBC0,OpDDCBC1,OpDDCBC2,OpDDCBC3,OpDDCBC4,OpDDCBC5,OpDDCBC6,OpDDCBC7,OpDDCBC8,OpDDCBC9,OpDDCBCA,OpDDCBCB,OpDDCBCC,OpDDCBCD,OpDDCBCE,OpDDCBCF
dd OpDDCBD0,OpDDCBD1,OpDDCBD2,OpDDCBD3,OpDDCBD4,OpDDCBD5,OpDDCBD6,OpDDCBD7,OpDDCBD8,OpDDCBD9,OpDDCBDA,OpDDCBDB,OpDDCBDC,OpDDCBDD,OpDDCBDE,OpDDCBDF
dd OpDDCBE0,OpDDCBE1,OpDDCBE2,OpDDCBE3,OpDDCBE4,OpDDCBE5,OpDDCBE6,OpDDCBE7,OpDDCBE8,OpDDCBE9,OpDDCBEA,OpDDCBEB,OpDDCBEC,OpDDCBED,OpDDCBEE,OpDDCBEF
dd OpDDCBF0,OpDDCBF1,OpDDCBF2,OpDDCBF3,OpDDCBF4,OpDDCBF5,OpDDCBF6,OpDDCBF7,OpDDCBF8,OpDDCBF9,OpDDCBFA,OpDDCBFB,OpDDCBFC,OpDDCBFD,OpDDCBFE,OpDDCBFF

JumpTabFDCB: ; FDCB__xx opcodes:
dd OpFDCB00,OpFDCB01,OpFDCB02,OpFDCB03,OpFDCB04,OpFDCB05,OpFDCB06,OpFDCB07,OpFDCB08,OpFDCB09,OpFDCB0A,OpFDCB0B,OpFDCB0C,OpFDCB0D,OpFDCB0E,OpFDCB0F
dd OpFDCB10,OpFDCB11,OpFDCB12,OpFDCB13,OpFDCB14,OpFDCB15,OpFDCB16,OpFDCB17,OpFDCB18,OpFDCB19,OpFDCB1A,OpFDCB1B,OpFDCB1C,OpFDCB1D,OpFDCB1E,OpFDCB1F
dd OpFDCB20,OpFDCB21,OpFDCB22,OpFDCB23,OpFDCB24,OpFDCB25,OpFDCB26,OpFDCB27,OpFDCB28,OpFDCB29,OpFDCB2A,OpFDCB2B,OpFDCB2C,OpFDCB2D,OpFDCB2E,OpFDCB2F
dd OpFDCB30,OpFDCB31,OpFDCB32,OpFDCB33,OpFDCB34,OpFDCB35,OpFDCB36,OpFDCB37,OpFDCB38,OpFDCB39,OpFDCB3A,OpFDCB3B,OpFDCB3C,OpFDCB3D,OpFDCB3E,OpFDCB3F
dd OpFDCB40,OpFDCB41,OpFDCB42,OpFDCB43,OpFDCB44,OpFDCB45,OpFDCB46,OpFDCB47,OpFDCB48,OpFDCB49,OpFDCB4A,OpFDCB4B,OpFDCB4C,OpFDCB4D,OpFDCB4E,OpFDCB4F
dd OpFDCB50,OpFDCB51,OpFDCB52,OpFDCB53,OpFDCB54,OpFDCB55,OpFDCB56,OpFDCB57,OpFDCB58,OpFDCB59,OpFDCB5A,OpFDCB5B,OpFDCB5C,OpFDCB5D,OpFDCB5E,OpFDCB5F
dd OpFDCB60,OpFDCB61,OpFDCB62,OpFDCB63,OpFDCB64,OpFDCB65,OpFDCB66,OpFDCB67,OpFDCB68,OpFDCB69,OpFDCB6A,OpFDCB6B,OpFDCB6C,OpFDCB6D,OpFDCB6E,OpFDCB6F
dd OpFDCB70,OpFDCB71,OpFDCB72,OpFDCB73,OpFDCB74,OpFDCB75,OpFDCB76,OpFDCB77,OpFDCB78,OpFDCB79,OpFDCB7A,OpFDCB7B,OpFDCB7C,OpFDCB7D,OpFDCB7E,OpFDCB7F
dd OpFDCB80,OpFDCB81,OpFDCB82,OpFDCB83,OpFDCB84,OpFDCB85,OpFDCB86,OpFDCB87,OpFDCB88,OpFDCB89,OpFDCB8A,OpFDCB8B,OpFDCB8C,OpFDCB8D,OpFDCB8E,OpFDCB8F
dd OpFDCB90,OpFDCB91,OpFDCB92,OpFDCB93,OpFDCB94,OpFDCB95,OpFDCB96,OpFDCB97,OpFDCB98,OpFDCB99,OpFDCB9A,OpFDCB9B,OpFDCB9C,OpFDCB9D,OpFDCB9E,OpFDCB9F
dd OpFDCBA0,OpFDCBA1,OpFDCBA2,OpFDCBA3,OpFDCBA4,OpFDCBA5,OpFDCBA6,OpFDCBA7,OpFDCBA8,OpFDCBA9,OpFDCBAA,OpFDCBAB,OpFDCBAC,OpFDCBAD,OpFDCBAE,OpFDCBAF
dd OpFDCBB0,OpFDCBB1,OpFDCBB2,OpFDCBB3,OpFDCBB4,OpFDCBB5,OpFDCBB6,OpFDCBB7,OpFDCBB8,OpFDCBB9,OpFDCBBA,OpFDCBBB,OpFDCBBC,OpFDCBBD,OpFDCBBE,OpFDCBBF
dd OpFDCBC0,OpFDCBC1,OpFDCBC2,OpFDCBC3,OpFDCBC4,OpFDCBC5,OpFDCBC6,OpFDCBC7,OpFDCBC8,OpFDCBC9,OpFDCBCA,OpFDCBCB,OpFDCBCC,OpFDCBCD,OpFDCBCE,OpFDCBCF
dd OpFDCBD0,OpFDCBD1,OpFDCBD2,OpFDCBD3,OpFDCBD4,OpFDCBD5,OpFDCBD6,OpFDCBD7,OpFDCBD8,OpFDCBD9,OpFDCBDA,OpFDCBDB,OpFDCBDC,OpFDCBDD,OpFDCBDE,OpFDCBDF
dd OpFDCBE0,OpFDCBE1,OpFDCBE2,OpFDCBE3,OpFDCBE4,OpFDCBE5,OpFDCBE6,OpFDCBE7,OpFDCBE8,OpFDCBE9,OpFDCBEA,OpFDCBEB,OpFDCBEC,OpFDCBED,OpFDCBEE,OpFDCBEF
dd OpFDCBF0,OpFDCBF1,OpFDCBF2,OpFDCBF3,OpFDCBF4,OpFDCBF5,OpFDCBF6,OpFDCBF7,OpFDCBF8,OpFDCBF9,OpFDCBFA,OpFDCBFB,OpFDCBFC,OpFDCBFD,OpFDCBFE,OpFDCBFF


IncFlag:
db 0x50,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08
db 0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08
db 0x30,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x28,0x28,0x28,0x28,0x28,0x28,0x28,0x28
db 0x30,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x28,0x28,0x28,0x28,0x28,0x28,0x28,0x28
db 0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08
db 0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08
db 0x30,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x28,0x28,0x28,0x28,0x28,0x28,0x28,0x28
db 0x30,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x28,0x28,0x28,0x28,0x28,0x28,0x28,0x28
db 0x94,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88
db 0x90,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88
db 0xb0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8
db 0xb0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8
db 0x90,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88
db 0x90,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88
db 0xb0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8
db 0xb0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8

DecFlag:
db 0x42,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x0a,0x0a,0x0a,0x0a,0x0a,0x0a,0x0a,0x1a
db 0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x0a,0x0a,0x0a,0x0a,0x0a,0x0a,0x0a,0x1a
db 0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x3a
db 0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x3a
db 0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x0a,0x0a,0x0a,0x0a,0x0a,0x0a,0x0a,0x1a
db 0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x0a,0x0a,0x0a,0x0a,0x0a,0x0a,0x0a,0x1a
db 0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x3a
db 0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x3e
db 0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x8a,0x8a,0x8a,0x8a,0x8a,0x8a,0x8a,0x9a
db 0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x8a,0x8a,0x8a,0x8a,0x8a,0x8a,0x8a,0x9a
db 0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xba
db 0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xba
db 0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x8a,0x8a,0x8a,0x8a,0x8a,0x8a,0x8a,0x9a
db 0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x8a,0x8a,0x8a,0x8a,0x8a,0x8a,0x8a,0x9a
db 0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xba
db 0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xba

DaaTable: ;(HNC nnnn nnnn)
dw 0x4400,0x0001,0x0002,0x0403,0x0004,0x0405,0x0406,0x0007,0x0808,0x0c09,0x1010,0x1411,0x1412,0x1013,0x1414,0x1015 ; 000
dw 0x0010,0x0411,0x0412,0x0013,0x0414,0x0015,0x0016,0x0417,0x0c18,0x0819,0x3020,0x3421,0x3422,0x3023,0x3424,0x3025 ; 010
dw 0x2020,0x2421,0x2422,0x2023,0x2424,0x2025,0x2026,0x2427,0x2c28,0x2829,0x3430,0x3031,0x3032,0x3433,0x3034,0x3435 ; 020
dw 0x2430,0x2031,0x2032,0x2433,0x2034,0x2435,0x2436,0x2037,0x2838,0x2c39,0x1040,0x1441,0x1442,0x1043,0x1444,0x1045 ; 030
dw 0x0040,0x0441,0x0442,0x0043,0x0444,0x0045,0x0046,0x0447,0x0c48,0x0849,0x1450,0x1051,0x1052,0x1453,0x1054,0x1455 ; 040
dw 0x0450,0x0051,0x0052,0x0453,0x0054,0x0455,0x0456,0x0057,0x0858,0x0c59,0x3460,0x3061,0x3062,0x3463,0x3064,0x3465 ; 050
dw 0x2460,0x2061,0x2062,0x2463,0x2064,0x2465,0x2466,0x2067,0x2868,0x2c69,0x3070,0x3471,0x3472,0x3073,0x3474,0x3075 ; 060
dw 0x2070,0x2471,0x2472,0x2073,0x2474,0x2075,0x2076,0x2477,0x2c78,0x2879,0x9080,0x9481,0x9482,0x9083,0x9484,0x9085 ; 070
dw 0x8080,0x8481,0x8482,0x8083,0x8484,0x8085,0x8086,0x8487,0x8c88,0x8889,0x9490,0x9091,0x9092,0x9493,0x9094,0x9495 ; 080
dw 0x8490,0x8091,0x8092,0x8493,0x8094,0x8495,0x8496,0x8097,0x8898,0x8c99,0x5500,0x1101,0x1102,0x1503,0x1104,0x1505 ; 090
dw 0x4500,0x0101,0x0102,0x0503,0x0104,0x0505,0x0506,0x0107,0x0908,0x0d09,0x1110,0x1511,0x1512,0x1113,0x1514,0x1115 ; 0a0
dw 0x0110,0x0511,0x0512,0x0113,0x0514,0x0115,0x0116,0x0517,0x0d18,0x0919,0x3120,0x3521,0x3522,0x3123,0x3524,0x3125 ; 0b0
dw 0x2120,0x2521,0x2522,0x2123,0x2524,0x2125,0x2126,0x2527,0x2d28,0x2929,0x3530,0x3131,0x3132,0x3533,0x3134,0x3535 ; 0c0
dw 0x2530,0x2131,0x2132,0x2533,0x2134,0x2535,0x2536,0x2137,0x2938,0x2d39,0x1140,0x1541,0x1542,0x1143,0x1544,0x1145 ; 0d0
dw 0x0140,0x0541,0x0542,0x0143,0x0544,0x0145,0x0146,0x0547,0x0d48,0x0949,0x1550,0x1151,0x1152,0x1553,0x1154,0x1555 ; 0e0
dw 0x0550,0x0151,0x0152,0x0553,0x0154,0x0555,0x0556,0x0157,0x0958,0x0d59,0x3560,0x3161,0x3162,0x3563,0x3164,0x3565 ; 0f0
dw 0x2560,0x2161,0x2162,0x2563,0x2164,0x2565,0x2566,0x2167,0x2968,0x2d69,0x3170,0x3571,0x3572,0x3173,0x3574,0x3175 ; 100
dw 0x2170,0x2571,0x2572,0x2173,0x2574,0x2175,0x2176,0x2577,0x2d78,0x2979,0x9180,0x9581,0x9582,0x9183,0x9584,0x9185 ; 110
dw 0x8180,0x8581,0x8582,0x8183,0x8584,0x8185,0x8186,0x8587,0x8d88,0x8989,0x9590,0x9191,0x9192,0x9593,0x9194,0x9595 ; 120
dw 0x8590,0x8191,0x8192,0x8593,0x8194,0x8595,0x8596,0x8197,0x8998,0x8d99,0xb5a0,0xb1a1,0xb1a2,0xb5a3,0xb1a4,0xb5a5 ; 130
dw 0xa5a0,0xa1a1,0xa1a2,0xa5a3,0xa1a4,0xa5a5,0xa5a6,0xa1a7,0xa9a8,0xada9,0xb1b0,0xb5b1,0xb5b2,0xb1b3,0xb5b4,0xb1b5 ; 140
dw 0xa1b0,0xa5b1,0xa5b2,0xa1b3,0xa5b4,0xa1b5,0xa1b6,0xa5b7,0xadb8,0xa9b9,0x95c0,0x91c1,0x91c2,0x95c3,0x91c4,0x95c5 ; 150
dw 0x85c0,0x81c1,0x81c2,0x85c3,0x81c4,0x85c5,0x85c6,0x81c7,0x89c8,0x8dc9,0x91d0,0x95d1,0x95d2,0x91d3,0x95d4,0x91d5 ; 160
dw 0x81d0,0x85d1,0x85d2,0x81d3,0x85d4,0x81d5,0x81d6,0x85d7,0x8dd8,0x89d9,0xb1e0,0xb5e1,0xb5e2,0xb1e3,0xb5e4,0xb1e5 ; 170
dw 0xa1e0,0xa5e1,0xa5e2,0xa1e3,0xa5e4,0xa1e5,0xa1e6,0xa5e7,0xade8,0xa9e9,0xb5f0,0xb1f1,0xb1f2,0xb5f3,0xb1f4,0xb5f5 ; 180
dw 0xa5f0,0xa1f1,0xa1f2,0xa5f3,0xa1f4,0xa5f5,0xa5f6,0xa1f7,0xa9f8,0xadf9,0x5500,0x1101,0x1102,0x1503,0x1104,0x1505 ; 190
dw 0x4500,0x0101,0x0102,0x0503,0x0104,0x0505,0x0506,0x0107,0x0908,0x0d09,0x1110,0x1511,0x1512,0x1113,0x1514,0x1115 ; 1a0
dw 0x0110,0x0511,0x0512,0x0113,0x0514,0x0115,0x0116,0x0517,0x0d18,0x0919,0x3120,0x3521,0x3522,0x3123,0x3524,0x3125 ; 1b0
dw 0x2120,0x2521,0x2522,0x2123,0x2524,0x2125,0x2126,0x2527,0x2d28,0x2929,0x3530,0x3131,0x3132,0x3533,0x3134,0x3535 ; 1c0
dw 0x2530,0x2131,0x2132,0x2533,0x2134,0x2535,0x2536,0x2137,0x2938,0x2d39,0x1140,0x1541,0x1542,0x1143,0x1544,0x1145 ; 1d0
dw 0x0140,0x0541,0x0542,0x0143,0x0544,0x0145,0x0146,0x0547,0x0d48,0x0949,0x1550,0x1151,0x1152,0x1553,0x1154,0x1555 ; 1e0
dw 0x0550,0x0151,0x0152,0x0553,0x0154,0x0555,0x0556,0x0157,0x0958,0x0d59,0x3560,0x3161,0x3162,0x3563,0x3164,0x3565 ; 1f0
dw 0x4600,0x0201,0x0202,0x0603,0x0204,0x0605,0x0606,0x0207,0x0a08,0x0e09,0x1204,0x1605,0x1606,0x1207,0x1a08,0x1e09 ; 200
dw 0x0210,0x0611,0x0612,0x0213,0x0614,0x0215,0x0216,0x0617,0x0e18,0x0a19,0x1614,0x1215,0x1216,0x1617,0x1e18,0x1a19 ; 210
dw 0x2220,0x2621,0x2622,0x2223,0x2624,0x2225,0x2226,0x2627,0x2e28,0x2a29,0x3624,0x3225,0x3226,0x3627,0x3e28,0x3a29 ; 220
dw 0x2630,0x2231,0x2232,0x2633,0x2234,0x2635,0x2636,0x2237,0x2a38,0x2e39,0x3234,0x3635,0x3636,0x3237,0x3a38,0x3e39 ; 230
dw 0x0240,0x0641,0x0642,0x0243,0x0644,0x0245,0x0246,0x0647,0x0e48,0x0a49,0x1644,0x1245,0x1246,0x1647,0x1e48,0x1a49 ; 240
dw 0x0650,0x0251,0x0252,0x0653,0x0254,0x0655,0x0656,0x0257,0x0a58,0x0e59,0x1254,0x1655,0x1656,0x1257,0x1a58,0x1e59 ; 250
dw 0x2660,0x2261,0x2262,0x2663,0x2264,0x2665,0x2666,0x2267,0x2a68,0x2e69,0x3264,0x3665,0x3666,0x3267,0x3a68,0x3e69 ; 260
dw 0x2270,0x2671,0x2672,0x2273,0x2674,0x2275,0x2276,0x2677,0x2e78,0x2a79,0x3674,0x3275,0x3276,0x3677,0x3e78,0x3a79 ; 270
dw 0x8280,0x8681,0x8682,0x8283,0x8684,0x8285,0x8286,0x8687,0x8e88,0x8a89,0x9684,0x9285,0x9286,0x9687,0x9e88,0x9a89 ; 280
dw 0x8690,0x8291,0x8292,0x8693,0x8294,0x8695,0x8696,0x8297,0x8a98,0x8e99,0x3334,0x3735,0x3736,0x3337,0x3b38,0x3f39 ; 290
dw 0x0340,0x0741,0x0742,0x0343,0x0744,0x0345,0x0346,0x0747,0x0f48,0x0b49,0x1744,0x1345,0x1346,0x1747,0x1f48,0x1b49 ; 2a0
dw 0x0750,0x0351,0x0352,0x0753,0x0354,0x0755,0x0756,0x0357,0x0b58,0x0f59,0x1354,0x1755,0x1756,0x1357,0x1b58,0x1f59 ; 2b0
dw 0x2760,0x2361,0x2362,0x2763,0x2364,0x2765,0x2766,0x2367,0x2b68,0x2f69,0x3364,0x3765,0x3766,0x3367,0x3b68,0x3f69 ; 2c0
dw 0x2370,0x2771,0x2772,0x2373,0x2774,0x2375,0x2376,0x2777,0x2f78,0x2b79,0x3774,0x3375,0x3376,0x3777,0x3f78,0x3b79 ; 2d0
dw 0x8380,0x8781,0x8782,0x8383,0x8784,0x8385,0x8386,0x8787,0x8f88,0x8b89,0x9784,0x9385,0x9386,0x9787,0x9f88,0x9b89 ; 2e0
dw 0x8790,0x8391,0x8392,0x8793,0x8394,0x8795,0x8796,0x8397,0x8b98,0x8f99,0x9394,0x9795,0x9796,0x9397,0x9b98,0x9f99 ; 2f0
dw 0xa7a0,0xa3a1,0xa3a2,0xa7a3,0xa3a4,0xa7a5,0xa7a6,0xa3a7,0xaba8,0xafa9,0xb3a4,0xb7a5,0xb7a6,0xb3a7,0xbba8,0xbfa9 ; 300
dw 0xa3b0,0xa7b1,0xa7b2,0xa3b3,0xa7b4,0xa3b5,0xa3b6,0xa7b7,0xafb8,0xabb9,0xb7b4,0xb3b5,0xb3b6,0xb7b7,0xbfb8,0xbbb9 ; 310
dw 0x87c0,0x83c1,0x83c2,0x87c3,0x83c4,0x87c5,0x87c6,0x83c7,0x8bc8,0x8fc9,0x93c4,0x97c5,0x97c6,0x93c7,0x9bc8,0x9fc9 ; 320
dw 0x83d0,0x87d1,0x87d2,0x83d3,0x87d4,0x83d5,0x83d6,0x87d7,0x8fd8,0x8bd9,0x97d4,0x93d5,0x93d6,0x97d7,0x9fd8,0x9bd9 ; 330
dw 0xa3e0,0xa7e1,0xa7e2,0xa3e3,0xa7e4,0xa3e5,0xa3e6,0xa7e7,0xafe8,0xabe9,0xb7e4,0xb3e5,0xb3e6,0xb7e7,0xbfe8,0xbbe9 ; 340
dw 0xa7f0,0xa3f1,0xa3f2,0xa7f3,0xa3f4,0xa7f5,0xa7f6,0xa3f7,0xabf8,0xaff9,0xb3f4,0xb7f5,0xb7f6,0xb3f7,0xbbf8,0xbff9 ; 350
dw 0x4700,0x0301,0x0302,0x0703,0x0304,0x0705,0x0706,0x0307,0x0b08,0x0f09,0x1304,0x1705,0x1706,0x1307,0x1b08,0x1f09 ; 360
dw 0x0310,0x0711,0x0712,0x0313,0x0714,0x0315,0x0316,0x0717,0x0f18,0x0b19,0x1714,0x1315,0x1316,0x1717,0x1f18,0x1b19 ; 370
dw 0x2320,0x2721,0x2722,0x2323,0x2724,0x2325,0x2326,0x2727,0x2f28,0x2b29,0x3724,0x3325,0x3326,0x3727,0x3f28,0x3b29 ; 380
dw 0x2730,0x2331,0x2332,0x2733,0x2334,0x2735,0x2736,0x2337,0x2b38,0x2f39,0x3334,0x3735,0x3736,0x3337,0x3b38,0x3f39 ; 390
dw 0x0340,0x0741,0x0742,0x0343,0x0744,0x0345,0x0346,0x0747,0x0f48,0x0b49,0x1744,0x1345,0x1346,0x1747,0x1f48,0x1b49 ; 3a0
dw 0x0750,0x0351,0x0352,0x0753,0x0354,0x0755,0x0756,0x0357,0x0b58,0x0f59,0x1354,0x1755,0x1756,0x1357,0x1b58,0x1f59 ; 3b0
dw 0x2760,0x2361,0x2362,0x2763,0x2364,0x2765,0x2766,0x2367,0x2b68,0x2f69,0x3364,0x3765,0x3766,0x3367,0x3b68,0x3f69 ; 3c0
dw 0x2370,0x2771,0x2772,0x2373,0x2774,0x2375,0x2376,0x2777,0x2f78,0x2b79,0x3774,0x3375,0x3376,0x3777,0x3f78,0x3b79 ; 3d0
dw 0x8380,0x8781,0x8782,0x8383,0x8784,0x8385,0x8386,0x8787,0x8f88,0x8b89,0x9784,0x9385,0x9386,0x9787,0x9f88,0x9b89 ; 3e0
dw 0x8790,0x8391,0x8392,0x8793,0x8394,0x8795,0x8796,0x8397,0x8b98,0x8f99,0x9394,0x9795,0x9796,0x9397,0x9b98,0x9f99 ; 3f0
dw 0x0406,0x0007,0x0808,0x0c09,0x0c0a,0x080b,0x0c0c,0x080d,0x080e,0x0c0f,0x1010,0x1411,0x1412,0x1013,0x1414,0x1015 ; 400
dw 0x0016,0x0417,0x0c18,0x0819,0x081a,0x0c1b,0x081c,0x0c1d,0x0c1e,0x081f,0x3020,0x3421,0x3422,0x3023,0x3424,0x3025 ; 410
dw 0x2026,0x2427,0x2c28,0x2829,0x282a,0x2c2b,0x282c,0x2c2d,0x2c2e,0x282f,0x3430,0x3031,0x3032,0x3433,0x3034,0x3435 ; 420
dw 0x2436,0x2037,0x2838,0x2c39,0x2c3a,0x283b,0x2c3c,0x283d,0x283e,0x2c3f,0x1040,0x1441,0x1442,0x1043,0x1444,0x1045 ; 430
dw 0x0046,0x0447,0x0c48,0x0849,0x084a,0x0c4b,0x084c,0x0c4d,0x0c4e,0x084f,0x1450,0x1051,0x1052,0x1453,0x1054,0x1455 ; 440
dw 0x0456,0x0057,0x0858,0x0c59,0x0c5a,0x085b,0x0c5c,0x085d,0x085e,0x0c5f,0x3460,0x3061,0x3062,0x3463,0x3064,0x3465 ; 450
dw 0x2466,0x2067,0x2868,0x2c69,0x2c6a,0x286b,0x2c6c,0x286d,0x286e,0x2c6f,0x3070,0x3471,0x3472,0x3073,0x3474,0x3075 ; 460
dw 0x2076,0x2477,0x2c78,0x2879,0x287a,0x2c7b,0x287c,0x2c7d,0x2c7e,0x287f,0x9080,0x9481,0x9482,0x9083,0x9484,0x9085 ; 470
dw 0x8086,0x8487,0x8c88,0x8889,0x888a,0x8c8b,0x888c,0x8c8d,0x8c8e,0x888f,0x9490,0x9091,0x9092,0x9493,0x9094,0x9495 ; 480
dw 0x8496,0x8097,0x8898,0x8c99,0x8c9a,0x889b,0x8c9c,0x889d,0x889e,0x8c9f,0x5500,0x1101,0x1102,0x1503,0x1104,0x1505 ; 490
dw 0x0506,0x0107,0x0908,0x0d09,0x0d0a,0x090b,0x0d0c,0x090d,0x090e,0x0d0f,0x1110,0x1511,0x1512,0x1113,0x1514,0x1115 ; 4a0
dw 0x0116,0x0517,0x0d18,0x0919,0x091a,0x0d1b,0x091c,0x0d1d,0x0d1e,0x091f,0x3120,0x3521,0x3522,0x3123,0x3524,0x3125 ; 4b0
dw 0x2126,0x2527,0x2d28,0x2929,0x292a,0x2d2b,0x292c,0x2d2d,0x2d2e,0x292f,0x3530,0x3131,0x3132,0x3533,0x3134,0x3535 ; 4c0
dw 0x2536,0x2137,0x2938,0x2d39,0x2d3a,0x293b,0x2d3c,0x293d,0x293e,0x2d3f,0x1140,0x1541,0x1542,0x1143,0x1544,0x1145 ; 4d0
dw 0x0146,0x0547,0x0d48,0x0949,0x094a,0x0d4b,0x094c,0x0d4d,0x0d4e,0x094f,0x1550,0x1151,0x1152,0x1553,0x1154,0x1555 ; 4e0
dw 0x0556,0x0157,0x0958,0x0d59,0x0d5a,0x095b,0x0d5c,0x095d,0x095e,0x0d5f,0x3560,0x3161,0x3162,0x3563,0x3164,0x3565 ; 4f0
dw 0x2566,0x2167,0x2968,0x2d69,0x2d6a,0x296b,0x2d6c,0x296d,0x296e,0x2d6f,0x3170,0x3571,0x3572,0x3173,0x3574,0x3175 ; 500
dw 0x2176,0x2577,0x2d78,0x2979,0x297a,0x2d7b,0x297c,0x2d7d,0x2d7e,0x297f,0x9180,0x9581,0x9582,0x9183,0x9584,0x9185 ; 510
dw 0x8186,0x8587,0x8d88,0x8989,0x898a,0x8d8b,0x898c,0x8d8d,0x8d8e,0x898f,0x9590,0x9191,0x9192,0x9593,0x9194,0x9595 ; 520
dw 0x8596,0x8197,0x8998,0x8d99,0x8d9a,0x899b,0x8d9c,0x899d,0x899e,0x8d9f,0xb5a0,0xb1a1,0xb1a2,0xb5a3,0xb1a4,0xb5a5 ; 530
dw 0xa5a6,0xa1a7,0xa9a8,0xada9,0xadaa,0xa9ab,0xadac,0xa9ad,0xa9ae,0xadaf,0xb1b0,0xb5b1,0xb5b2,0xb1b3,0xb5b4,0xb1b5 ; 540
dw 0xa1b6,0xa5b7,0xadb8,0xa9b9,0xa9ba,0xadbb,0xa9bc,0xadbd,0xadbe,0xa9bf,0x95c0,0x91c1,0x91c2,0x95c3,0x91c4,0x95c5 ; 550
dw 0x85c6,0x81c7,0x89c8,0x8dc9,0x8dca,0x89cb,0x8dcc,0x89cd,0x89ce,0x8dcf,0x91d0,0x95d1,0x95d2,0x91d3,0x95d4,0x91d5 ; 560
dw 0x81d6,0x85d7,0x8dd8,0x89d9,0x89da,0x8ddb,0x89dc,0x8ddd,0x8dde,0x89df,0xb1e0,0xb5e1,0xb5e2,0xb1e3,0xb5e4,0xb1e5 ; 570
dw 0xa1e6,0xa5e7,0xade8,0xa9e9,0xa9ea,0xadeb,0xa9ec,0xaded,0xadee,0xa9ef,0xb5f0,0xb1f1,0xb1f2,0xb5f3,0xb1f4,0xb5f5 ; 580
dw 0xa5f6,0xa1f7,0xa9f8,0xadf9,0xadfa,0xa9fb,0xadfc,0xa9fd,0xa9fe,0xadff,0x5500,0x1101,0x1102,0x1503,0x1104,0x1505 ; 590
dw 0x0506,0x0107,0x0908,0x0d09,0x0d0a,0x090b,0x0d0c,0x090d,0x090e,0x0d0f,0x1110,0x1511,0x1512,0x1113,0x1514,0x1115 ; 5a0
dw 0x0116,0x0517,0x0d18,0x0919,0x091a,0x0d1b,0x091c,0x0d1d,0x0d1e,0x091f,0x3120,0x3521,0x3522,0x3123,0x3524,0x3125 ; 5b0
dw 0x2126,0x2527,0x2d28,0x2929,0x292a,0x2d2b,0x292c,0x2d2d,0x2d2e,0x292f,0x3530,0x3131,0x3132,0x3533,0x3134,0x3535 ; 5c0
dw 0x2536,0x2137,0x2938,0x2d39,0x2d3a,0x293b,0x2d3c,0x293d,0x293e,0x2d3f,0x1140,0x1541,0x1542,0x1143,0x1544,0x1145 ; 5d0
dw 0x0146,0x0547,0x0d48,0x0949,0x094a,0x0d4b,0x094c,0x0d4d,0x0d4e,0x094f,0x1550,0x1151,0x1152,0x1553,0x1154,0x1555 ; 5e0
dw 0x0556,0x0157,0x0958,0x0d59,0x0d5a,0x095b,0x0d5c,0x095d,0x095e,0x0d5f,0x3560,0x3161,0x3162,0x3563,0x3164,0x3565 ; 5f0
dw 0xbefa,0xbafb,0xbefc,0xbafd,0xbafe,0xbeff,0x4600,0x0201,0x0202,0x0603,0x0204,0x0605,0x0606,0x0207,0x0a08,0x0e09 ; 600
dw 0x1e0a,0x1a0b,0x1e0c,0x1a0d,0x1a0e,0x1e0f,0x0210,0x0611,0x0612,0x0213,0x0614,0x0215,0x0216,0x0617,0x0e18,0x0a19 ; 610
dw 0x1a1a,0x1e1b,0x1a1c,0x1e1d,0x1e1e,0x1a1f,0x2220,0x2621,0x2622,0x2223,0x2624,0x2225,0x2226,0x2627,0x2e28,0x2a29 ; 620
dw 0x3a2a,0x3e2b,0x3a2c,0x3e2d,0x3e2e,0x3a2f,0x2630,0x2231,0x2232,0x2633,0x2234,0x2635,0x2636,0x2237,0x2a38,0x2e39 ; 630
dw 0x3e3a,0x3a3b,0x3e3c,0x3a3d,0x3a3e,0x3e3f,0x0240,0x0641,0x0642,0x0243,0x0644,0x0245,0x0246,0x0647,0x0e48,0x0a49 ; 640
dw 0x1a4a,0x1e4b,0x1a4c,0x1e4d,0x1e4e,0x1a4f,0x0650,0x0251,0x0252,0x0653,0x0254,0x0655,0x0656,0x0257,0x0a58,0x0e59 ; 650
dw 0x1e5a,0x1a5b,0x1e5c,0x1a5d,0x1a5e,0x1e5f,0x2660,0x2261,0x2262,0x2663,0x2264,0x2665,0x2666,0x2267,0x2a68,0x2e69 ; 660
dw 0x3e6a,0x3a6b,0x3e6c,0x3a6d,0x3a6e,0x3e6f,0x2270,0x2671,0x2672,0x2273,0x2674,0x2275,0x2276,0x2677,0x2e78,0x2a79 ; 670
dw 0x3a7a,0x3e7b,0x3a7c,0x3e7d,0x3e7e,0x3a7f,0x8280,0x8681,0x8682,0x8283,0x8684,0x8285,0x8286,0x8687,0x8e88,0x8a89 ; 680
dw 0x9a8a,0x9e8b,0x9a8c,0x9e8d,0x9e8e,0x9a8f,0x8690,0x8291,0x8292,0x8693,0x2334,0x2735,0x2736,0x2337,0x2b38,0x2f39 ; 690
dw 0x3f3a,0x3b3b,0x3f3c,0x3b3d,0x3b3e,0x3f3f,0x0340,0x0741,0x0742,0x0343,0x0744,0x0345,0x0346,0x0747,0x0f48,0x0b49 ; 6a0
dw 0x1b4a,0x1f4b,0x1b4c,0x1f4d,0x1f4e,0x1b4f,0x0750,0x0351,0x0352,0x0753,0x0354,0x0755,0x0756,0x0357,0x0b58,0x0f59 ; 6b0
dw 0x1f5a,0x1b5b,0x1f5c,0x1b5d,0x1b5e,0x1f5f,0x2760,0x2361,0x2362,0x2763,0x2364,0x2765,0x2766,0x2367,0x2b68,0x2f69 ; 6c0
dw 0x3f6a,0x3b6b,0x3f6c,0x3b6d,0x3b6e,0x3f6f,0x2370,0x2771,0x2772,0x2373,0x2774,0x2375,0x2376,0x2777,0x2f78,0x2b79 ; 6d0
dw 0x3b7a,0x3f7b,0x3b7c,0x3f7d,0x3f7e,0x3b7f,0x8380,0x8781,0x8782,0x8383,0x8784,0x8385,0x8386,0x8787,0x8f88,0x8b89 ; 6e0
dw 0x9b8a,0x9f8b,0x9b8c,0x9f8d,0x9f8e,0x9b8f,0x8790,0x8391,0x8392,0x8793,0x8394,0x8795,0x8796,0x8397,0x8b98,0x8f99 ; 6f0
dw 0x9f9a,0x9b9b,0x9f9c,0x9b9d,0x9b9e,0x9f9f,0xa7a0,0xa3a1,0xa3a2,0xa7a3,0xa3a4,0xa7a5,0xa7a6,0xa3a7,0xaba8,0xafa9 ; 700
dw 0xbfaa,0xbbab,0xbfac,0xbbad,0xbbae,0xbfaf,0xa3b0,0xa7b1,0xa7b2,0xa3b3,0xa7b4,0xa3b5,0xa3b6,0xa7b7,0xafb8,0xabb9 ; 710
dw 0xbbba,0xbfbb,0xbbbc,0xbfbd,0xbfbe,0xbbbf,0x87c0,0x83c1,0x83c2,0x87c3,0x83c4,0x87c5,0x87c6,0x83c7,0x8bc8,0x8fc9 ; 720
dw 0x9fca,0x9bcb,0x9fcc,0x9bcd,0x9bce,0x9fcf,0x83d0,0x87d1,0x87d2,0x83d3,0x87d4,0x83d5,0x83d6,0x87d7,0x8fd8,0x8bd9 ; 730
dw 0x9bda,0x9fdb,0x9bdc,0x9fdd,0x9fde,0x9bdf,0xa3e0,0xa7e1,0xa7e2,0xa3e3,0xa7e4,0xa3e5,0xa3e6,0xa7e7,0xafe8,0xabe9 ; 740
dw 0xbbea,0xbfeb,0xbbec,0xbfed,0xbfee,0xbbef,0xa7f0,0xa3f1,0xa3f2,0xa7f3,0xa3f4,0xa7f5,0xa7f6,0xa3f7,0xabf8,0xaff9 ; 750
dw 0xbffa,0xbbfb,0xbffc,0xbbfd,0xbbfe,0xbfff,0x4700,0x0301,0x0302,0x0703,0x0304,0x0705,0x0706,0x0307,0x0b08,0x0f09 ; 760
dw 0x1f0a,0x1b0b,0x1f0c,0x1b0d,0x1b0e,0x1f0f,0x0310,0x0711,0x0712,0x0313,0x0714,0x0315,0x0316,0x0717,0x0f18,0x0b19 ; 770
dw 0x1b1a,0x1f1b,0x1b1c,0x1f1d,0x1f1e,0x1b1f,0x2320,0x2721,0x2722,0x2323,0x2724,0x2325,0x2326,0x2727,0x2f28,0x2b29 ; 780
dw 0x3b2a,0x3f2b,0x3b2c,0x3f2d,0x3f2e,0x3b2f,0x2730,0x2331,0x2332,0x2733,0x2334,0x2735,0x2736,0x2337,0x2b38,0x2f39 ; 790
dw 0x3f3a,0x3b3b,0x3f3c,0x3b3d,0x3b3e,0x3f3f,0x0340,0x0741,0x0742,0x0343,0x0744,0x0345,0x0346,0x0747,0x0f48,0x0b49 ; 7a0
dw 0x1b4a,0x1f4b,0x1b4c,0x1f4d,0x1f4e,0x1b4f,0x0750,0x0351,0x0352,0x0753,0x0354,0x0755,0x0756,0x0357,0x0b58,0x0f59 ; 7b0
dw 0x1f5a,0x1b5b,0x1f5c,0x1b5d,0x1b5e,0x1f5f,0x2760,0x2361,0x2362,0x2763,0x2364,0x2765,0x2766,0x2367,0x2b68,0x2f69 ; 7c0
dw 0x3f6a,0x3b6b,0x3f6c,0x3b6d,0x3b6e,0x3f6f,0x2370,0x2771,0x2772,0x2373,0x2774,0x2375,0x2376,0x2777,0x2f78,0x2b79 ; 7d0
dw 0x3b7a,0x3f7b,0x3b7c,0x3f7d,0x3f7e,0x3b7f,0x8380,0x8781,0x8782,0x8383,0x8784,0x8385,0x8386,0x8787,0x8f88,0x8b89 ; 7e0
dw 0x9b8a,0x9f8b,0x9b8c,0x9f8d,0x9f8e,0x9b8f,0x8790,0x8391,0x8392,0x8793,0x8394,0x8795,0x8796,0x8397,0x8b98,0x8f99 ; 7f0

