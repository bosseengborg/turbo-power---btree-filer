(*
Title   : Efiler.Pas
Main    : grundesd /btreefilerinterface
LastEdit: 2005-02-02 22.35 vers 9.02
Author  : helleforsdata, bosse engborg, 2004-03
        : 1995-09-07 22.00 vers 7.11
        : Evalds Sport-Data HB, Evald Engborg, 1990-11
System  : Microsoft MsDos 6.22
          Borland Pascal 7.02,
          Stony Brook Pascal+ 6.13,
          Turbo Power Professional 5.23,
          Async Professional 2.00,
          B-Tree Filer 5.57,
System  : Microsoft Windows 3.11
          Borland Pascal 7.02,
          Data Entry Workshop 2.03,
          Win/Sys Librayr 1.02,
          B-Tree Filer 5.57,
System  : Microsoft Windows 95/98se/Me/2000/XP/2003
          Borland Delphi 7 personal,
          Turbo Power B-Tree Filer 5.57,
System  : Microsoft Windows 95/98se/Me/2000/XP/2003
          Borland Delphi 2005 architect,
          Turbo Power B-Tree Filer 5.57,
System  : Microsoft Windows 95/98se/Me/2000/XP/2003/Vista/7
          Embarcadero Delphi 2010 professional
          Turbo Power B-Tree Filer 5.57b,
System  : Microsoft Windows 95/98se/Me/2000/XP/2003/Vista/7/8/10
          Windows 32/64
          Embarcadero Delphi 10.2 community edition
          Turbo Power B-Tree Filer 5.57c,
*)

{$I redaconfig.inc}

unit Efiler;

interface

uses
 {$ifdef windows}
   {$ifdef win32orwin64}
    sysutils,
   {$else}
    windos, wincrt,
   {$endif}
 {$else}
   TPcrt, TPdos,
  {$ifdef msdos}
    TPems,
    EmsHeap,
  {$endif}
 {$endif}
  filer, reindex, restruct, reorg, isamtool, btisbase, btbase,
  EsdTypes, Esmall, EmsgTxt,
 {$ifdef win32orwin64}
  Eerror32,
 {$else}
  Eerror,
 {$endif}
  Glodefs;


Type
  FixtRtnTypes= (FindRtn,FindRcRtn,NextRtn,
                 SearchRtn,ClearRtn,RcRtn,PrevRtn);
  EIsamKeyStr= IsamKeyStr;
  EIsamFileBlockPtr= IsamFileBlockPtr;
  EIsamIndDescr= IsamIndDescr;
  EIsamFileBlockName= IsamFileBlockName;
 {$ifdef win64}
  TDataStatus= longint;
 {$else}
  TDataStatus= longint;
 {$endif}

  TProcFixtSelect= procedure (Const FixtRtn: FixtRtnTypes;
                              sStri: IsamKeyStr;
                              Var Rc: longint;
                              Var Exst, FileEnd: boolean);
  TProcPutRecSelect= procedure (Const dRec: longint);
  TProcAddRecSelect= procedure (Const recs: boolean; Var dRec: longint);
  TProcDelRecSelect= procedure (Const delRtn: FixtRtnTypes;
                                sStri: IsamKeyStr;
                                dRec: longint;
                                Const recs: boolean);


procedure ECloseAllFileBlocks;
procedure EDeleteAllKeys(IFBPtr: EIsamFileBlockPtr; Key: word);
procedure EIsamCheck(ss: Strng64);
function IsLockError(Ask: boolean): boolean;
procedure EExitIsam;
function EFileLen(IFBPtr: EIsamFileBlockPtr): longint;
function EUsedRecs(IFBPtr: EIsamFileBlockPtr): longint;
procedure EFlushFileBlock(IFBPtr: EIsamFileBlockPtr);
procedure ECloseFileBlock(Var IFBPtr: EIsamFileBlockPtr);
procedure ECreateFileBlock(FName: IsamFileBlockName;
                           DatSLen: longint;
                           NumberOfKeys: word;
                           IID: IsamIndDescr);
procedure EDeleteFileBlock(FName: IsamFileBlockName);
procedure EOpenFileBlock(Var IFBPtr: EIsamFileBlockPtr;
                         FName: EIsamFileBlockName);
procedure EAddKey(IFBPtr: EIsamFileBlockPtr; Key: word;
                  UserDataRef: longint; UserKey: EIsamKeyStr);
procedure EFindKey(IFBPtr: EIsamFileBlockPtr; Key: word;
                   Var UserDataRef: longint; UserKey: EIsamKeyStr);
procedure ESearchKey(IFBPtr: EIsamFileBlockPtr; Key: word;
                   Var UserDataRef: longint; Var UserKey: EIsamKeyStr);
procedure ESearchKeyAndRef(IFBPtr: EIsamFileBlockPtr; Key: word;
                   Var UserDataRef: longint; Var UserKey: EIsamKeyStr);
procedure ENextDiffKey(IFBPtr: EIsamFileBlockPtr; Key: word;
                       Var UserDataRef: longint; Var UserKey: EIsamKeyStr);
procedure EPrevDiffKey(IFBPtr: EIsamFileBlockPtr; Key: word;
                       Var UserDataRef: longint; Var UserKey: EIsamKeyStr);
procedure ENextKey(IFBPtr: EIsamFileBlockPtr; Key: word;
                   Var UserDataRef: longint; Var UserKey: EIsamKeyStr);
procedure EPrevKey(IFBPtr: EIsamFileBlockPtr; Key: word;
                   Var UserDataRef: longint; Var UserKey: EIsamKeyStr);
procedure EFindKeyAndRef(IFBPtr: EIsamFileBlockPtr; Key: word;
                         UserDataRef: longint; UserKey: EIsamKeyStr;
                         NotFoundSearchDirection: integer);
procedure EDeleteKey(IFBPtr: EIsamFileBlockPtr; Key: word;
                     UserDataRef: longint; UserKey: EIsamKeyStr);
procedure EClearKey(IFBPtr: EIsamFileBlockPtr; Key: word);
procedure EAddRec(IFBPtr: EIsamFileBlockPtr;
                  Var RefNr: longint;
                  Var Source);
procedure EGetRec(IFBPtr: EIsamFileBlockPtr; RefNr: longint;
                  Var Dest; ISOLock: boolean);
procedure EPutRec(IFBPtr: EIsamFileBlockPtr; RefNr: longint;
                  Var Source; ISOLock: boolean);
procedure EDeleteRec(IFBPtr: EIsamFileBlockPtr; RefNr: longint);
function EIsamPageStackInit: boolean;

Var
  dummyIID: IsamIndDescr;
  EIsamOk: boolean absolute IsamOk;
  EIsamError: integer absolute IsamError;
  EIsamDOSFunc  : word absolute IsamDOSFunc;
  EIsamDOSError : TbtfErrorCode absolute IsamDosError;
  EIsamLockError: boolean absolute IsamLockError;
  EIsamDefNrOfWS : Word absolute IsamDefNrOfWS;

Const
  maxdoshandles= 64;
  LockMode: boolean= false;

implementation

Const
  maxRetries= 10;
  RetryCount: integer= 10;

(*------------------------------------------------------------------------*)
procedure EIsamCheck(ss: Strng64);
Var
  ide, ie, ic: integer;
  fh: cardinal;
begin
 {$ifdef debug}
  If Not(IsamOk) Then begin
    ie:= IsamError; ide:= IsamDosError; ic:= BTIsamErrorClass;
    If (ic>= 1) Then begin
      MyMsg:= GetBMsgTxt(IsamError)+ '"'+ ss+ '"'+
              ' IsamError='+ RightNumbStr(ie,5)+
              ' IsamDosError='+ RightNumbStr(ide,5)+
              ' IsamErrorClass='+ RightNumbStr(ic,5);
      Case ie Of
        9901:
        begin
         {$ifdef win32orwin64}
         {$if compilerversion <= 17}
          fh:= FileHandlesLeft(200);
          MyMsg:= MyMsg+ ' Handles left:'+ RightNumbStr(fh,3);
          fh:= FileHandlesOpen(true);
          MyMsg:= MyMsg+ ' Open:'+ RightNumbStr(fh,3);
         {$ifend}
         {$endif}
        end;
      end;
      MyMsg:= MyMsg+ ' Avbryt';
      If ErrorMsg(101) Then Halt(ie);
    end;
  end;
 {$endif}
end;
(*------------------------------------------------------------------------*)
function IsLockError(Ask: boolean): boolean;
begin
  If IsamOk Or (BTIsamErrorClass <> 2) Then begin
    IsLockError:= false;
    RetryCount:= 0;
  end else begin
    IsLockError:= true;
    Inc(RetryCount);
    If (RetryCount > MaxRetries) Then begin
      If Not(Ask) Then
        IsLockError:= false
      else begin
        MyMsg:= 'L†st fil/filpost! F”rs”ka igen ';
        IsLockError:= Not(ErrorMsg(101));
      end;
      RetryCount:= 0;
    end;
  end;
end;
(*------------------------------------------------------------------------*)

(*------------------------------------------------------------------------*)
procedure EExitIsam;
begin
  BTExitIsam;
  EIsamCheck('ExitIsam');
end;
(*------------------------------------------------------------------------*)
function EFileLen(IFBPtr: IsamFileBlockPtr): longint;
Var
  nrecs: longint;
begin
  EFileLen:= BTFileLen(IFBPtr);
  EIsamCheck('FileLen');
end;
(*------------------------------------------------------------------------*)
function EUsedRecs(IFBPtr: IsamFileBlockPtr): longint;
Var
  nrecs: longint;
begin
  EUsedRecs:= BTUsedRecs(IFBPtr);
  EIsamCheck('UsedRecs');
end;
(*------------------------------------------------------------------------*)
procedure EFlushFileBlock(IFBPtr: IsamFileBlockPtr);
begin
  BTFlushFileBlock(IFBPtr);
  EIsamCheck('FlushFileBlock');
end;
(*------------------------------------------------------------------------*)
procedure ECloseFileBlock(Var IFBPtr: IsamFileBlockPtr);
begin
  BTCloseFileBlock(IFBPtr);
  EIsamCheck('CloseFileBlock');
end;
(*------------------------------------------------------------------------*)
procedure ECloseAllFileBlocks;
begin
  BTCloseAllFileBlocks;
  EIsamCheck('CloseAllFileBlocks');
end;
(*------------------------------------------------------------------------*)
procedure ECreateFileBlock(FName: IsamFileBlockName;
                           DatSLen: longint;
                           NumberOfKeys: word;
                           IID: IsamIndDescr);
begin
  BTCreateFileBlock(FName,DatSLen,NumberOfKeys,IID);
  EIsamCheck('CreateFileBlock:'+ FName);
end;
(*------------------------------------------------------------------------*)
procedure EDeleteFileBlock(FName: IsamFileBlockName);
begin
  BTDeleteFileBlock(FName);
  EIsamCheck('DeleteFileBlock');
end;
(*------------------------------------------------------------------------*)
procedure EDeleteAllKeys(IFBPtr: IsamFileBlockPtr; Key: word);
begin
  BTDeleteAllKeys(IFBPtr,Key);
  EIsamCheck('DeleteAllKeys');
end;
(*------------------------------------------------------------------------*)
procedure EOpenFileBlock(Var IFBPtr: IsamFileBlockPtr; FName: EIsamFileBlockName);
Var
  ReadOnly,
  AllReadOnly,
  Save,
  Net: boolean;
begin
  ReadOnly:= false;
  AllReadOnly:= false;
  Save:= true;
  Net:= false;
  BTOpenFileBlock(IFBPtr,FName,ReadOnly,AllReadOnly,Save,Net);
  EIsamCheck('OpenFileBlock: '+ FName);
end;
(*------------------------------------------------------------------------*)
procedure EAddKey(IFBPtr: IsamFileBlockPtr; Key: word;
                  UserDataRef: longint; UserKey: IsamKeyStr);
begin
  BTAddKey(IFBPtr,Key,UserDataRef,UserKey);
  EIsamCheck('AddKey');
end;
(*------------------------------------------------------------------------*)
procedure EFindKey(IFBPtr: IsamFileBlockPtr; Key: word;
                   Var UserDataRef: longint; UserKey: IsamKeyStr);
Var
  io: integer;
  pp: string;
begin
  BTFindKey(IFBPtr,Key,UserDataRef,UserKey);
  EIsamCheck('FindKey');
end;
(*------------------------------------------------------------------------*)
procedure ESearchKey(IFBPtr: IsamFileBlockPtr; Key: word;
                   Var UserDataRef: longint; Var UserKey: IsamKeyStr);
Var
  io: integer;
  pp: string;
begin
  BTSearchKey(IFBPtr,Key,UserDataRef,UserKey);
  EIsamCheck('SearchKey');
end;
(*------------------------------------------------------------------------*)
procedure ESearchKeyAndRef(IFBPtr: IsamFileBlockPtr; Key: word;
                   Var UserDataRef: longint; Var UserKey: IsamKeyStr);
Var
  io: integer;
  pp: string;
begin
  BTSearchKeyAndRef(IFBPtr,Key,UserDataRef,UserKey);
  EIsamCheck('SearchKeyAndRef');
end;
(*------------------------------------------------------------------------*)
procedure ENextDiffKey(IFBPtr: IsamFileBlockPtr; Key: word;
                       Var UserDataRef: longint; Var UserKey: IsamKeyStr);
Var
  io: integer;
  pp: string;
begin
  BTNextDiffKey(IFBPtr,Key,UserDataRef,UserKey);
  EIsamCheck('NextDiffKey');
end;
(*------------------------------------------------------------------------*)
procedure EPrevDiffKey(IFBPtr: IsamFileBlockPtr; Key: word;
                       Var UserDataRef: longint; Var UserKey: IsamKeyStr);
Var
  io: integer;
  pp: string;
begin
  BTPrevDiffKey(IFBPtr,Key,UserDataRef,UserKey);
  EIsamCheck('PrevDiffKey');
end;
(*------------------------------------------------------------------------*)
procedure ENextKey(IFBPtr: IsamFileBlockPtr; Key: word;
                   Var UserDataRef: longint; Var UserKey: IsamKeyStr);
Var
  io: integer;
  pp: string;
begin
  BTNextKey(IFBPtr,Key,UserDataRef,UserKey);
  EIsamCheck('NextKey');
end;
(*------------------------------------------------------------------------*)
procedure EPrevKey(IFBPtr: IsamFileBlockPtr; Key: word;
                   Var UserDataRef: longint; Var UserKey: IsamKeyStr);
Var
  io: integer;
  pp: string;
begin
  BTPrevKey(IFBPtr,Key,UserDataRef,UserKey);
  EIsamCheck('PrevKey');
end;
(*------------------------------------------------------------------------*)
procedure EFindKeyAndRef(IFBPtr: IsamFileBlockPtr; Key: word;
                         UserDataRef: longint; UserKey: IsamKeyStr;
                         NotFoundSearchDirection: integer);
begin
  BTFindKeyAndRef(IFBPtr,Key,UserDataRef,UserKey,NotFoundSearchDirection);
  EIsamCheck('FindKeyKeyAndRef');
end;
(*------------------------------------------------------------------------*)
procedure EDeleteKey(IFBPtr: IsamFileBlockPtr; Key: word;
                     UserDataRef: longint; UserKey: IsamKeyStr);
begin
  BTDeleteKey(IFBPtr,Key,UserDataRef,UserKey);
  EIsamCheck('DeleteKey');
end;
(*------------------------------------------------------------------------*)
procedure EClearKey(IFBPtr: IsamFileBlockPtr; Key: word);
begin
  BTClearKey(IFBPtr,Key);
  EIsamCheck('ClearKey');
end;
(*------------------------------------------------------------------------*)
procedure EAddRec(IFBPtr: IsamFileBlockPtr;
                  Var RefNr: longint;
                  Var Source);
Var
  io: integer;
begin
  BTAddRec(IFBPtr,RefNr,Source);
  EIsamCheck('AddRec');
end;
(*------------------------------------------------------------------------*)
procedure EGetRec(IFBPtr: IsamFileBlockPtr; RefNr: longint;
                  Var Dest; ISOLock: boolean);
begin
  BTGetRec(IFBPtr,RefNr,Dest,ISOLock);
  EIsamCheck('GetRec');
end;
(*------------------------------------------------------------------------*)
procedure EPutRec(IFBPtr: IsamFileBlockPtr; RefNr: longint;
                  Var Source; ISOLock: boolean);
begin
  BTPutRec(IFBPtr,RefNr,Source,ISOLock);
  EIsamCheck('PutRec');
end;
(*------------------------------------------------------------------------*)
procedure EDeleteRec(IFBPtr: IsamFileBlockPtr; RefNr: longint);
begin
  BTDeleteRec(IFBPtr,RefNr);
  EIsamCheck('DeleteRec');
end;
(*------------------------------------------------------------------------*)
function EIsamPageStackInit: boolean;
Var
  FreeSpace, mema, emsa: memNumberType;
  EmsPages: word;
  Pages: longint;
  ExpNet: NetSupportType;
  i, n: integer;
  swsz, mxtb, mxrb, mxlk, mxfi: integer;
  so: pointer;
begin
  n:= ParamCount; i:= 0;
  ExpNet:= NoNet;
  While (i< n) Do begin
    Inc(i);
    If (Pos('/NET',UpCaseStr(ParamStr(i))) <> 0) Then
      ExpNet:= MsNet;
  end;
  EXtendHandles(maxdoshandles);
  EIsamPageStackInit:= true;
 {$ifdef win32orwin64}
  FreeSpace:= (EMemAvail div 2)+ (EMemAvail div 4);
 {$else}
  FreeSpace:= (EMemAvail div 2)+ (EMemAvail div 4);
 {$endif}
  EmsPages:= 0; emsa:= 0;
 {$ifdef msdos}
 {$endif}
  mema:= EMemAvail;
 {$ifdef debug}
 {$ifdef windows}
  MyMsg:= '';
  Case ExpNet Of
    NoNet: MyMsg:= MyMsg+ 'Initiering av filer lokalt!';
    Novell: MyMsg:= MyMsg+ 'Initiering av Novell!';
    MsNet: MyMsg:= MyMsg+ 'Initiering av MsNet!';
  end;
  MyMsg:= MyMsg+ 'Filer: F”re   alloc FreeSpace:'+
          shortstring(UIntToStr(FreeSpace))+
          ' MemAvail:'+ shortstring(UIntToStr(mema));
  ErrorMsgX(201,MyMsg);
 {$else}
  Writeln;
  Case ExpNet Of
    NoNet: Writeln('Initiering av filer lokalt!');
    Novell: Writeln('Initiering av Novell!');
    MsNet: Writeln('Initiering av MsNet!');
  end;
  Writeln('Filer: F”re   alloc FreeSpace:',FreeSpace:6,' MemAvail:',mema:6);
 {$endif}
  (*
  Writeln('       F”re   alloc EmsUse   :',EmsPages* ((MaxKeyLen+ 9)* PageSize+ 18):6,' EmsAvail:',emsa:6);
  *)
 {$endif}
 {$ifdef windows}
  Pages:= BTinitIsam(ExpNet,25* 8);
 {$else}
  Pages:= BTInitIsam(ExpNet,(*FreeSpace+ *)MinimizeUseOfNormalHeap,EmsPages);
 {$endif}
 {$ifdef msdos}
  If EMSHeapInitialized Then
    emsa:= emsa- EmsMemAvail
  else
 {$endif}
  emsa:= 0;
  mema:= mema- EMemAvail;
  If HeapMemOk(mema) Then;
 {$ifdef msdos}
  If EmsMemOk(emsa) Then;
 {$endif}
 {$ifdef debug}
 {$ifdef windows}
  MyMsg:= '       Efter alloc  Använt   :'+ shortstring(UintToStr((mema))+
          ' MemAvail: '+ shortstring(uinttostr(EMemAvail))+
          ' HeapPages: '+ shortstring(uinttostr(Pages Mod 65536)));
  ErrorMsgX(201,MyMsg);
 {$else}
  Writeln('       Efter alloc  Använt   :',mema:6,' MemAvail:',EMemAvail:6,' HeapPages:',Pages Mod 65536:3);
  If EMSHeapInitialized Then
    Write('       Efter alloc  Använt   :',emsa:6,' EmsAvail:',EmsMemAvail:6,' EmsPages:',Pages Div 65536:3);
  ReadLn;
 {$endif}
 {$endif}
  If IsamOk Then exit;
 {$ifdef windows}
  MyMsg:= 'IsamDosError: '+ RightNumbStr(IsamDosError,3)+ ' IsamError: '+ RightNumbStr(IsamError,3)+
          ' IsamErrorClass:'+ RightNumbStr(BTIsamErrorClass,3);
  MyMsg:= MyMsg+ 'Ej tillr„ckligt minne vid initiering av BTREE!';
  MyMsg:= MyMsg+ 'eller, Fel nätverk. Kan endast köras lokalt!';
  MyMsg:= MyMsg+ 'eller, Arbetsstationens nummer för högt >'+ RightNumbStr(MaxNrOfWorkStations,0)+
          ' eller >'+ Chr(64+ MaxNrOfWorkStations);
  ErrorMsgX(201,MyMsg);
 {$else}
  Writeln('IsamDosError: ',IsamDosError:3,' IsamError: ',IsamError:3,' IsamErrorClass:',BTIsamErrorClass:3);
  Writeln('Ej tillr„ckligt minne vid initiering av BTREE!');
  Writeln('eller, Fel n„tverk. Kan endast k”ras lokalt!');
  Write('eller, Arbetsstationens nummer f”r h”gt >',MaxNrOfWorkStations,' eller >',Chr(64+ MaxNrOfWorkStations));
  ReadLn;
 {$endif}
  EIsamPageStackInit:= false;
end;
(*------------------------------------------------------------------------*)
 {$ifdef debug}
begin
  Write('EFILER    ');
 {$endif}
end.
