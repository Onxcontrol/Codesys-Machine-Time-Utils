(*
=============================================================================
    Function Block: ZamanKontrolFB
    Description   : Tracks machine running time and calculates a custom 
                    production period format (YYPP) based on running days.
    Architecture  : Hardware-independent (IEC 61131-3)
    Developed by  : ONX Control 
=============================================================================
*)
FUNCTION_BLOCK ZamanKontrolFB
VAR_INPUT
    Reset           : BOOL;
    PeriyotGunu     : UDINT := 20;  (* Referans alınan gün ölçeği *)
END_VAR

VAR_OUTPUT
    MakineCalismaSure : LTIME;
    CalismaTanim      : STRING(4);  (* İstenilen 0101 (YYPP) formatındaki çıktı *)
END_VAR

VAR
    UTC_Time_in_ms      : SYSTIME;
    Loc_Time_Str        : SYSTIMEDATE;
    Loc_Time_in_ms      : SYSTIME;
    Local_DateTime      : DATE_AND_TIME;    
    
    MakineCalismaSureBos: SYSTIME;
    StartUp             : BOOL;
    
    dwIntervalMainTask  : DWORD;        (* Main task interval *)
    hFirstTask          : RTS_IEC_HANDLE; (* First task handle *)
    iecResult           : RTS_IEC_RESULT; (* IEC task result *)
    pIecInfo            : POINTER TO CmpIecTask.Task_Info2; (* Pointer to IEC task info *)
    
    TotalDays           : UDINT;  (* Toplam geçen gün *)
    Years               : UDINT;  (* Kaç yıl geçmiş? *)
    RemainderDays       : UDINT;  (* Yıldan arta kalan gün sayısı *)
    Periods             : UDINT;  (* Periyot çarpanı *)
    
    sYear               : STRING(2);
    sPeriod             : STRING(2);
    
    c_YilGunu           : UDINT := PeriyotGunu * 12;    
END_VAR

VAR_IN_OUT
    MakineCalismaSureLog  : ULINT;
    MakinaBaslamaTarihLog : DATE_AND_TIME;
    StartUpLog            : BOOL;    
END_VAR

(* --------------------------------------------------------------------------
   System Time & Task Interval Initialization
----------------------------------------------------------------------------- *)
SysTimeRtcHighResGet(pTimestamp := UTC_Time_in_ms);
SysTimeRtcConvertHighResToLocal(pTimestamp := UTC_Time_in_ms, pDate := Loc_Time_Str);
SysTimeRtcConvertDateToHighRes(pDate := Loc_Time_Str, pTimestamp := Loc_Time_in_ms);

Local_DateTime := TO_DT(Loc_Time_in_ms / 1000);

IF StartUp = FALSE THEN
    hFirstTask := CmpIecTask.IecTaskGetCurrent(pResult := ADR(iecResult)); 
    IF ((hFirstTask <> RTS_INVALID_HANDLE) AND (iecResult = CmpErrors.Errors.ERR_OK)) THEN
        pIecInfo := CmpIecTask.IecTaskGetInfo3(hIecTask := hFirstTask, pResult := ADR(iecResult));
        dwIntervalMainTask := pIecInfo^.dwInterval; 
    END_IF
    StartUp := TRUE;
END_IF

IF StartUpLog = FALSE THEN
    MakinaBaslamaTarihLog := Local_DateTime;
    StartUpLog := TRUE;
END_IF

(* --------------------------------------------------------------------------
   Uptime Calculation & Reset Logic
----------------------------------------------------------------------------- *)
MakineCalismaSureLog := MakineCalismaSureLog + (dwIntervalMainTask * 1000);

IF Reset THEN
    StartUpLog := FALSE;
    StartUp := FALSE;
    MakineCalismaSureLog := TO_ULINT(MakineCalismaSureBos);
END_IF

MakineCalismaSure := TO_LTIME(MakineCalismaSureLog);

(* --------------------------------------------------------------------------
   Custom Period Calculations (YYPP Format)
----------------------------------------------------------------------------- *)
c_YilGunu := PeriyotGunu * 12;

(* 1. LTIME cinsinden süreyi GÜN sayısına çevirme *)
(* LTIME nanosaniye cinsinden çalışır. 1 Gün = 86.400.000.000.000 nanosaniye *)
TotalDays := TO_UDINT(TO_ULINT(MakineCalismaSure) / 86400000000000);

(* 2. Yıl ve Periyot Hesaplamaları *)
Years := TotalDays / c_YilGunu;               
RemainderDays := TotalDays MOD c_YilGunu;     
Periods := RemainderDays / PeriyotGunu;       

(* Güvenlik: Yıl 99'u geçerse kodun 4 haneyi (YYPP) aşmaması için sınırlandırıyoruz *)
IF Years > 99 THEN
    Years := 99; 
END_IF

(* 3. String Formatlama (Sıfır Ekleme) *)
IF Years < 10 THEN
    sYear := CONCAT('0', UDINT_TO_STRING(Years)); 
ELSE
    sYear := UDINT_TO_STRING(Years); 
END_IF

IF Periods < 10 THEN
    sPeriod := CONCAT('0', UDINT_TO_STRING(Periods)); 
ELSE
    sPeriod := UDINT_TO_STRING(Periods);
END_IF

(* 4. Sonucu Birleştirme *)
CalismaTanim := CONCAT(sYear, sPeriod);